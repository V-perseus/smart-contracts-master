// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase {

    uint lastRandomness;
    address public winner;
    uint public entranceFee = 1 ether;
    uint public startBlock;
    bytes32 keyhash;
    uint fee;

    address[] public players;

    constructor(address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash) public VRFConsumerBase(_vrfCoordinator, _link) {
        keyhash = _keyhash;
        fee = _fee;
        startBlock = block.number;
    }

    function enter() public payable {
        require(msg.value >= entranceFee, "Didnt send enough");
        players.push(msg.sender);
    }

    function endLottery() public returns(bytes32){
        //require(block.number >= startBlock + 20000, "Lottery not over");
        return(requestRandomness(keyhash, fee));
    }

    function numberOfEntrants() public view returns(uint) {
        return(players.length);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(randomness > 0,"Randomness cant be zero");
        uint index = randomness % players.length;
        winner = players[index];
        payable(winner).transfer(address(this).balance);
        lastRandomness = randomness;
        players = new address[](0);
    }
}