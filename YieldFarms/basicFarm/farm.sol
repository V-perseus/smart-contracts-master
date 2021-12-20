// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./farmToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Farm is Ownable{

    FarmToken farmToken;

    uint256 totalStakedBalance;
    mapping(address => Farmer) public addressToFarm;
    mapping(address => bool) userExsists;

    struct Farmer {
        address _farmer;
        uint256 _depositAmount;
        uint256 _startBlock;
        uint256 _reward;
        bool _staking;
    }

    constructor(FarmToken _farmToken) {
        farmToken = _farmToken;
    }

    function initalClaim() public onlyOwner {
        farmToken.farmMint(address(this));
    }

    function deposit() public payable {
        require(msg.value > 0);
        if (userExsists[msg.sender]) {
            Farmer storage _farmer = addressToFarm[msg.sender];
            _farmer._reward += (10**18)*(block.number - _farmer._startBlock);
            _farmer._startBlock = block.number;
            _farmer._depositAmount += msg.value;
            if (_farmer._staking != true) {
                _farmer._staking = true;
            }
        } else {
            addressToFarm[msg.sender] = Farmer(msg.sender, msg.value, block.number, 0, true);
            userExsists[msg.sender] = true;
        }
        totalStakedBalance += msg.value;
    }

    function withdraw(uint256 _amount) public {
        Farmer storage _farmer = addressToFarm[msg.sender];
        require(_amount <= _farmer._depositAmount);
        _farmer._depositAmount -= _amount;
        if (_farmer._depositAmount == 0) {
            claimReward(msg.sender);
            _farmer._staking = false;
            _farmer._startBlock = 0;
        }
        totalStakedBalance -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function claimReward(address _farmer) public {
        Farmer storage _farmerClaim = addressToFarm[_farmer];
        _farmerClaim._reward += (10**18)*(block.number - _farmerClaim._startBlock);
        if (_farmerClaim._staking) {
            _farmerClaim._startBlock = block.number;
        }
        uint256 _claimAmount = _farmerClaim._reward;
        _farmerClaim._reward = 0;
        farmToken.transfer(_farmer, _claimAmount);
    }
}
