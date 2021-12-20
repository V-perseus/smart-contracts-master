// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmToken is ERC20Capped, Ownable {

    constructor() ERC20Capped(100000000000000000000000) ERC20("farm", "FARM"){

    }

    function farmMint(address receiver) public onlyOwner {
        _mint(receiver, cap());
    }
}