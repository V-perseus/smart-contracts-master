// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Weth is ERC20 {


    constructor() ERC20("Weth", "WETH"){
    }

    function getWeth() public payable {
        _mint(msg.sender, msg.value);
    }

    function burnWeth(uint256 _amount) public {
        require(balanceOf(msg.sender) >= _amount, "not enough");
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
    }

}