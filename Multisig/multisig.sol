// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MultiSig {

    address[] public Owners;
    uint public numberOfConfimationsRequired;
    mapping(address => bool) isOwner;
    mapping(address => mapping(uint => bool)) ownerConfirmed;
    mapping(uint => address) creatorOfTx;

    struct Transaction {
        address _to;
        uint _value;
        bytes _data;
        bool _executed;
        uint _confirmations;
        uint _nonce;
    }

    Transaction[] public Transactions;

    event Deposit(address _sender, uint _amount, uint _balance);
    event SubmitTransaction(address _owner, uint _nonce, address _to, uint _value, bytes _data);
    event ConfirmTransaction(address _owner, uint _nonce);
    event RevokeConfirmation(address  _owner, uint _nonce);
    event ExecuteTransaction(address _owner, uint _nonce);
    event RevokeTransaction(address _owner, uint _nonce);

    constructor(address[] memory _owners, uint _confirms) {
        numberOfConfimationsRequired = _confirms;
        for (uint i = 0; i < _owners.length; i++){
            require(!isOwner[_owners[i]]);
            Owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an Owner");
        _;
    }

    modifier exsistsUnexecuted(uint _nonce) {
        require(Transactions.length > _nonce, "Not valid Nonce");
        require(!Transactions[_nonce]._executed, "Tx already executed");
        _;
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint nonce = Transactions.length;
        Transactions.push(Transaction({
            _to: _to,
            _value: _value,
            _data: _data,
            _executed: false,
            _confirmations: 0,
            _nonce: nonce
        }));
        creatorOfTx[nonce] = msg.sender;
        emit SubmitTransaction(msg.sender, nonce, _to, _value, _data);
    }

    function confirmTransaction(uint _nonce) public onlyOwner exsistsUnexecuted(_nonce){
        Transaction storage transaction = Transactions[_nonce];
        require(!ownerConfirmed[msg.sender][_nonce], "Already confirmed transaction");
        ownerConfirmed[msg.sender][_nonce] = true;
        transaction._confirmations++;
        emit ConfirmTransaction(msg.sender, _nonce);
    }

    function executeTransaction(uint _nonce) public onlyOwner exsistsUnexecuted(_nonce) {
        Transaction storage transaction = Transactions[_nonce];
        require(transaction._confirmations >= numberOfConfimationsRequired, "Not enough confirmations");
        transaction._executed = true;
        (bool success, ) = transaction._to.call{value: transaction._value}(transaction._data);
        require(success, "Tx failed");
        emit ExecuteTransaction(msg.sender, _nonce);
    }

    function revokeConfirmation(uint _nonce) public onlyOwner exsistsUnexecuted(_nonce) {
        Transaction storage transaction = Transactions[_nonce];
        require(ownerConfirmed[msg.sender][_nonce], "Haven't confirmed");
        ownerConfirmed[msg.sender][_nonce] = false;
        transaction._confirmations--;
        emit RevokeConfirmation(msg.sender, _nonce);
    }

    function revokeTransaction(uint _nonce) public onlyOwner exsistsUnexecuted(_nonce) {
        require(msg.sender == creatorOfTx[_nonce], "Only the creator can revoke");
        Transactions[_nonce]._executed = true;
        emit RevokeTransaction(msg.sender, _nonce);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function getOwners() public view returns(address[] memory) {
        return Owners;
    }

    function getTransaction(uint _nonce) public view returns(Transaction memory) {
        return Transactions[_nonce];
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}