// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Basic is ERC721, Ownable {
    uint256 tokenId;

    constructor() ERC721("Basic", "BASIC"){

    }

    function userMint(uint256 _amount) public payable {
        require(msg.value >= _amount * 10000000000000000);

        for (uint256 i = 0; i < _amount; i++) {
            tokenId++;
            _mint(msg.sender, tokenId);
        }

    }

}