// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    Basic implementation of  a ERC-20 token
*/

contract BasicToken is ERC20 {

    constructor(uint _initialSupply) ERC20("Basic", "BASIC") {
        _mint(msg.sender, _initialSupply);
    }

    function mintTokens(uint _amount) public {
        _mint(msg.sender, _amount);
    }

}