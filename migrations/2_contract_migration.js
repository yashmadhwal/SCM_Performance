var myArgs = process.argv.slice(3); // We start from 3, not because first is argument will be 'imgrate' 
_senderAddress = myArgs[0];
_startTime = Number(myArgs[1]);
_endTime = Number(myArgs[2]);

// console.log(myArgs)
//
// console.log(_senderAddress);
// console.log(_startTime);
// console.log(_endTime);
//
// console.log(typeof _senderAddress);
// console.log(typeof _startTime);
// console.log(typeof _endTime);

const TradingAgreement = artifacts.require("TradingAgreement");

module.exports = function (deployer) {
  deployer.deploy(TradingAgreement, _senderAddress, _startTime, _endTime);
};
