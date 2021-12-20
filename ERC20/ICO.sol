// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Token is ERC20Capped, Ownable {

    uint256 pricePerToken = 100000000000000;
    address devAddress;
    bool devsPaid = false;
    uint devsCut;

    mapping(address => bool) UserClaimed;


    constructor(uint256 _max, address _devAddress, uint _devCut) ERC20Capped(_max) ERC20("Test","TEST") {
        devAddress = _devAddress;
        devsCut = _devCut;
        _mint(devFunds, (_max * devsCut)/ 100);
        devsPaid = true;
    }

    function buyToken() public payable returns(uint256){
        require(devsPaid, "Wait til devs claim");
        require(totalSupply() < cap(), "All tokens sold");
        require(msg.value <= 1 * 10**18, "Sent to much");
        require(UserClaimed[msg.sender] == false, "Already claimed");
        UserClaimed[msg.sender] = true;
        uint256 numberOfTokens = msg.value/pricePerToken;
        _mint(msg.sender, numberOfTokens * 10**18);
        return numberOfTokens;
    }

    function tokensAvailable() public view returns(uint256){
        return (cap() - totalSupply())/10**18;
    }

    function withdraw() public onlyOwner {
        payable(communityWallet).transfer(address(this).balance);
    }

}