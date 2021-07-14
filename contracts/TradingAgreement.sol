pragma solidity <0.6.5;

contract TradingAgreement{

    // Receiveing Company Information
    string public ownerCompanyName;
    address public ownerReceiver;

    // Sender Company Information
    string public senderCompanyName;
    address public senderAddress;

    bool public senderAgreement; // flagSign will be set true

    // Consignment count, it will always start from 1, because initialization is always zero
    uint countOfShipper;

    // ETA of Consignment
    uint public consignmentETARange;

    // contract's TimeInformation;
    uint public T_Deployment;
    uint public T_start;
    uint public T_end;
    uint public T_agreement;
    uint public total_Slots;

    // Contract Consignment Order;
    uint public N_min;
    uint public N_max;

    // ΔT, i.e. time slot
    uint public time_slot = 10;

    // Time to process the order
    uint public timeProcessOrder;

    // Rate of success
    uint rate_of_success;

    // NΔ, i.e.n number of allowed orders within time_slot.
    uint public orderPerSlot;

    // initialzing, performance variable;
    uint public OrderBookIncrementor; // this is sepatate and will increment sepatately
    uint public N;
    uint public s;
    uint public f;
    uint public d;
    bool public flagContinue;
    bool public ContractEndAgreement; //default false

    constructor(address _senderAddress, uint _startTime, uint _endTime) public {
        // For the moment, the following information is hardcoded.

        // Predeclaring information for Rob, The Receiver
        ownerCompanyName = "Rob's Company";
        ownerReceiver = msg.sender;

        // Predeclaring information for Sally, The Sender
        senderCompanyName = "Sally's Company";
        senderAddress = _senderAddress;

        // initiallizing shipping counter.
        countOfShipper = 1; // Start from 0....

        // Contract Information Timeline
        T_Deployment = 0;
        T_start = _startTime 	; // Later: 1577858400, Wed Jan 01 2020 09:00:00 GMT+0300 (Moscow Standard Time)
        T_end = _endTime; // Later: 1609426800, Thu Dec 31 2020 18:00:00 GMT+0300 (Moscow Standard Time)

        total_Slots = 10;

        orderPerSlot = 2;
        N_min = orderPerSlot;
        N_max = orderPerSlot * ((T_end-T_start)/time_slot);


        // agreement time is 2 days
        T_agreement = 10; // Later: 172800

        // We are assuming that time to process each order will be fixed time, lets say 2 days, i.e. 172800 seconds is the ETA and this will have ± 10% margin, therefore:= 4,8 hours
        timeProcessOrder = 2; //later: 2 days for now 2 sec.
        consignmentETARange = 2; // ±2 days (inluding)

        // Rate of success
        rate_of_success = 98; // % of rate of success

        flagContinue = true;
    }

    mapping(uint => bool[]) public timeSlotOrderPerSlot;

    struct orderBook{

        uint consignmentnumber;

        uint timeSlotOfOrder;
        uint timeOfOrder;

        address consignmentSender;
        uint ETA;
        bool DeliveryReviewed;
    }


    mapping(uint => orderBook) public orderBookConsignment;

    enum DeliveryStatus {NONE, SUCCESS, FAILED, DISPUTE}

    struct deliveryConsignmentInformation{
        uint consignmentnumber;
        uint consignmentOrderTime;
        uint consignmnetShippingTime; // this should be 24 hrs plus, i.e it is T_processing

        uint ETAasPerOrder; //This is time which should be within that week
        uint RobETA;
        uint SallyETA;

        address consignmentSender;

        DeliveryStatus DeliveryStatusOnDelivery;
        bool flagDecision;
    }

    mapping(uint => deliveryConsignmentInformation) public receivingConsignmentBook;

    function orderConsignment(uint _timeSlotOrder, uint _timeOfOrder,uint _OrderETA) public onlyOwner{ //Question do we need to iterate sequestion for making orders or random is possible
        // TimeSlot should be in range
        require(0<_timeSlotOrder && _timeSlotOrder<=total_Slots,'Not in total slot range');

        //Order Shouldbe Withing the range.
        require(_timeOfOrder>=T_start && _timeOfOrder<T_end - timeProcessOrder,"The order should be within the range");

        // ETA > _timeOfOrder + timeProcessOrder
        require(_OrderETA > _timeOfOrder + timeProcessOrder, "Such order cannot be processed");

        //Order Should be Withing the range.
        require(OrderBookIncrementor<N_max,'Maximum Orders Reached!');
        OrderBookIncrementor++;
        if(OrderBookIncrementor==N_max){
            flagContinue = false;
        }

        require(timeSlotOrderPerSlot[_timeSlotOrder].length < orderPerSlot,"Time Slot order Maxed");
        timeSlotOrderPerSlot[_timeSlotOrder].push(true);
        orderBookConsignment[OrderBookIncrementor] = orderBook(OrderBookIncrementor,_timeSlotOrder,_timeOfOrder,senderAddress,_OrderETA,false);
    }

    // Some non repetative internal functions
    function _completeOrderReview(uint _orderNumber) private{
        require(orderBookConsignment[_orderNumber].DeliveryReviewed == false, 'This order has already being modified!');
        orderBookConsignment[_orderNumber].DeliveryReviewed = true;
    }

    function _settingFlag(uint _cosignmentOrderNumber) private {
        receivingConsignmentBook[_cosignmentOrderNumber].flagDecision = true;
    }

    function receiverConsignement(uint _cosignmentOrderNumber, bool _acceptinOrder, uint _eta) public onlyOwner noDecision(_cosignmentOrderNumber){
        // require that status of the DeliveryStatusOnDelivery = 0, i.e. enum status = NONE
        require(ContractEndAgreement == false, "All deliveries Received");
        require(receivingConsignmentBook[_cosignmentOrderNumber].DeliveryStatusOnDelivery == DeliveryStatus.NONE,"The status on Delivery is final");

        //Delivery order should not be empty
        require(orderBookConsignment[_cosignmentOrderNumber].consignmentnumber !=0, 'Delivery is empty');

        receivingConsignmentBook[_cosignmentOrderNumber].consignmentnumber = _cosignmentOrderNumber;

        // ETA as per order
        receivingConsignmentBook[_cosignmentOrderNumber].ETAasPerOrder =  orderBookConsignment[_cosignmentOrderNumber].ETA;

        if (_acceptinOrder == true){
            receivingConsignmentBook[_cosignmentOrderNumber].RobETA = _eta;
            _completeOrderReview(_cosignmentOrderNumber);
        }

        else if(_acceptinOrder == false){
            receivingConsignmentBook[_cosignmentOrderNumber].DeliveryStatusOnDelivery = DeliveryStatus.FAILED;
            _completeOrderReview(_cosignmentOrderNumber);
            _settingFlag(_cosignmentOrderNumber);
            f++;
        }
        N++;
        if(N == N_max){
            ContractEndAgreement = true;
        }
    }

    // initiallizing Sally and Rob Details
    function senderETA(uint _cosignmentOrderNumber, uint _eta) public onlySender noDecision(_cosignmentOrderNumber){
        receivingConsignmentBook[_cosignmentOrderNumber].SallyETA = _eta;
    }

    // setting flagDecision
    function settingFlagDecision(uint _cosignmentOrderNumber) public noDecision(_cosignmentOrderNumber){
        // checking that it should either be failed transaction or ETAs not empty
        require(receivingConsignmentBook[_cosignmentOrderNumber].SallyETA != 0 && receivingConsignmentBook[_cosignmentOrderNumber].RobETA !=0,"ETA not delivered!");

        uint _etaUp = orderBookConsignment[_cosignmentOrderNumber].ETA + 1;
        uint _etaLow = orderBookConsignment[_cosignmentOrderNumber].ETA - 1;

        uint _etaSally = receivingConsignmentBook[_cosignmentOrderNumber].SallyETA;
        uint _etaRob = receivingConsignmentBook[_cosignmentOrderNumber].RobETA;

        /* checking the range:
        _etaLow <= (etaSally and etaRob) <= _etaUp
        */
        if(_etaLow <= _etaSally && _etaSally <= _etaUp && _etaLow <= _etaRob && _etaRob <=_etaUp){
            // setting flag to Success
            receivingConsignmentBook[_cosignmentOrderNumber].DeliveryStatusOnDelivery = DeliveryStatus.SUCCESS;
            _settingFlag(_cosignmentOrderNumber);
            s++;
        }

        else{
            receivingConsignmentBook[_cosignmentOrderNumber].DeliveryStatusOnDelivery = DeliveryStatus.DISPUTE;
            d++;
        }
    }


    // NOW we want to resolve the dispuite
    struct multiSig{
        uint courierNumber;
        bool signatureSally;
        bool signatureRob;
    }

    mapping(uint => multiSig) public multiSigBook;

    function sallySignature(uint _consignmentOrderNumber) public disputed(_consignmentOrderNumber) onlySender{
        multiSigBook[_consignmentOrderNumber].signatureSally = true;
    }

    function RobSignature(uint _consignmentOrderNumber) public disputed(_consignmentOrderNumber) onlyOwner{
        multiSigBook[_consignmentOrderNumber].signatureRob = true;
    }

    function resolveDispute(uint _consignmentOrderNumber,bool _statusResolved) public disputed(_consignmentOrderNumber){
        // signatures should not be empty
        require(multiSigBook[_consignmentOrderNumber].signatureRob == true && multiSigBook[_consignmentOrderNumber].signatureSally == true, 'Both should sign!');
        // It is success
        if(_statusResolved == true){
            receivingConsignmentBook[_consignmentOrderNumber].DeliveryStatusOnDelivery = DeliveryStatus.SUCCESS;
            _settingFlag(_consignmentOrderNumber);
            s++;
        }

        else if(_statusResolved == false){
            receivingConsignmentBook[_consignmentOrderNumber].DeliveryStatusOnDelivery = DeliveryStatus.FAILED;
            _settingFlag(_consignmentOrderNumber);
            f++;
        }
        d--;
    }

    function asserOrders() public view flagFalse returns(bool){
        if (OrderBookIncrementor == s + d + f){
            return true;
        }
        else{
            return false;
        }
    }



    function checkPerformance(uint _enterPercent) public view flagFalse returns(string memory){


        if(_enterPercent >= 98){
            return "Success";
        }

        else{
            return "Fail";
        }
    }

    modifier onlyOwner(){
        require(ownerReceiver == msg.sender,"Only Rob can Order!");
        _;
    }

    modifier onlySender(){
        require(senderAddress == msg.sender,"Only Sally can access!");
        _;
    }

    modifier flagFalse(){
        require(flagContinue == false,"Cannot check because flagContinue is true");
        _;
    }

    modifier onlyTansactingParties(){
        require(ownerReceiver == msg.sender || senderAddress == msg.sender, "Either Sally or Rob should audit");
        _;
    }

    modifier noDecision(uint _consignmentOrderNumber){
        require(receivingConsignmentBook[_consignmentOrderNumber].flagDecision == false,"Decision is Made!");
        _;
    }

    modifier disputed(uint _consignmentOrderNumber){
        require(receivingConsignmentBook[_consignmentOrderNumber].DeliveryStatusOnDelivery == DeliveryStatus.DISPUTE,"A DISPUTE is required");
        _;
    }


}
