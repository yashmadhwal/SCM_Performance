# Proof of Delivery Smart Contract for Performance Measurements
by Yash Madhwal, Niloofar Etemadi, Yury Yanovich and Yari Borbon

### Recreating Project
Prerequisites:
- [Truffle Suite](https://trufflesuite.com/)
- [Python](https://www.python.org/) 3.7 or later
- [Jupyter Notebook](https://jupyter.org/install)
- [Node](https://nodejs.org/en/download/)
- [Ganache](https://trufflesuite.com/blog/introducing-ganache-7/index.html)

## Installation

1. Clone repository, In terminal: 
    ```
    git clone https://github.com/yashmadhwal/SCM_Performance.git
    ```
    
2. Compile contracts
    ```
    truffle compile
    ```
3. Open Ganache, and select sender, **Note** Receiver and Sender's address should not be same 
 (_Trick: Let the first address in the Ganache address list be that of Receiver's i.e., Rob and Second be that of Sender i.e., Sally_) 
    ```
    truffle migrate <sender's Address> 10 110
    ```
    `10` and `110` are start and end time of a contract.
4. Simulate scenario by running `Ipython` notebook
    ```
    jupyter notebook SCM_Performance_Measurement_Presentation.ipynb
    ```
    
**Important Note:** _Beause of the latest update and code migration to upgraded version in solidty, it is recommended that the Step 5 in the simulation, redeploy the contract and run the python notebook from step 5._
