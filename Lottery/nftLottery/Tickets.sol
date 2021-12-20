// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Tickets is ERC721, Ownable {

    uint ticketId;

    constructor() ERC721("Ticket", "TICK"){
    }

    function printTicket(address _to) public onlyOwner returns(uint) {
        ticketId++;
        _safeMint(_to, ticketId);
        return(ticketId);
    }

    function numberTickets() public view returns(uint) {
        return(ticketId);
    }
}