// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CookieToken is ERC20, Ownable {


    constructor() ERC20("Cookie", "COOK"){
    }

    function bake(address _receiver, uint256 _amount) public onlyOwner {
        _mint(_receiver, _amount);
    }
}