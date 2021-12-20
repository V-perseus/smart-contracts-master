// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Tickets.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract TicketBooth is VRFConsumerBase {

    Tickets tickets;

    uint randomness;
    address public winner;
    uint public ticketPrice;
    uint public startBlock;

    bytes32 keyhash;
    uint fee;

    constructor(uint _ticketPrice, Tickets _tickets, address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash) VRFConsumerBase(_vrfCoordinator,_link){
        ticketPrice = _ticketPrice;
        tickets = Tickets(_tickets);
        fee = _fee;
        keyhash = _keyhash;
        startBlock = block.number;
    }

    function buyTicket(uint _amount) public payable {
        require(msg.value >= (_amount * ticketPrice), "Didnt send enough funds");
        require(_amount < 6, "Can only buy 5 tickets at a time");

        for (uint i = 0; i < _amount; i++) {
            tickets.printTicket(msg.sender);
        }
    }

    function endLottery() public returns(bytes32 requestID){
        require(block.number >= startBlock + 25000, "Lottery not over");

        return(requestRandomness(keyhash, fee));

    }

    function ticketsSold() public view returns(uint) {
        return(tickets.numberTickets());
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(_randomness > 0, "randomness cant be zero");
        uint winningNumber = _randomness % ticketsSold();
        winner = tickets.ownerOf(winningNumber);
        payable(winner).transfer(address(this).balance);
        startBlock = block.number;
        randomness = _randomness;
    }
}