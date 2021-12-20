// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./cookieToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CookieFarm is Ownable{
    CookieToken cookieToken;

    uint256 bakeFee = 100000000000000;
    uint256 baseCookiePerBatch = 13;

    // Maps user to their baker stats
    mapping(address => Baker) public addyToBaker;

    mapping(address => bool) bakedBefore;

    /*
        Tracks users stats
        baker = users address
        cookies = number of "cookie tokens" they have
        startBlock = when users starts baking
        bakeLength = how long it takes for the cookies to be ready
        cookiePerBatch = how many cookies user receives for bake session
        numOvens = how many ovens a player owns. affects cookiePerBatch
        baking = if a user is in the oven or not
    */
    struct Baker {
        address baker;
        uint256 cookies;
        uint256 startBlock;
        uint256 bakeLength;
        uint256 cookiePerBatch;
        uint256 numOvens;
        bool baking;
    }

    constructor(CookieToken _cookieToken) {
        cookieToken = _cookieToken;
    }

    /*
        function to start baking.
        checks if user sent enough to start the bake .0001 Ether
        checks if user is already baking
        if user has baked before it will update the startBlock and then set baking to true
        else it will create a new Baker struct with the intial settings
    */
    function startBaking() public payable {
        require(msg.value == bakeFee , "Need to match the entry fee");
        require(addyToBaker[msg.sender].baking != true, "Already Baking");

        if (bakedBefore[msg.sender]) {
            Baker storage _baker = addyToBaker[msg.sender];
            _baker.startBlock = block.number;
            _baker.baking = true;
        } else {
            addyToBaker[msg.sender] = Baker(msg.sender, 0, block.number, 6, baseCookiePerBatch, 1, true);
            bakedBefore[msg.sender] = true;
        }
    }

    /*
        For user to claim cookies
        checks if baking is true to signfy user has initiated baking
        checks if it has been at least the bakeLength
        sets users baking to false
        sets startBlock to 0
        contract mints user their tokens
        sets users cookie balance to num of tokens
    */
    function getCookies() public {
        Baker storage _baker = addyToBaker[msg.sender];
        require(_baker.baking, "User not baking");
        require(_baker.startBlock + _baker.bakeLength <= block.number, "Still in the oven");
        uint256 reward = _baker.cookiePerBatch;
        _baker.baking = false;
        _baker.startBlock = 0;
        cookieToken.bake(_baker.baker, reward);
        _baker.cookies = cookieToken.balanceOf(_baker.baker);
    }

    /*
        user will have to approve tokens to contract
        cost per oven is set at (numOvens * 1000)
        oven will add 13 more cookies per bake
        checks if user has enough cookies to pay for it
        user then sends contract the cookies
        sets users number of cookies
        adds 1 to the numOvens
        sets cookiePerBatch
    */
    function buyOven() public payable{
        Baker storage _baker = addyToBaker[msg.sender];
        uint256 ovenCost = _baker.numOvens * 10;
        require(_baker.cookies >= ovenCost);
        cookieToken.transferFrom(msg.sender, address(this), ovenCost);
        _baker.cookies = cookieToken.balanceOf(_baker.baker);
        _baker.numOvens += 1;
        _baker.cookiePerBatch = _baker.numOvens * baseCookiePerBatch;
    }

    // Owner withdraw Ether from the contract
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}