// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {

    struct ItemForSale {
        uint highestBid;
        address highestbidder;
        uint duration;
        bool isActive;
        bool isSold;
        uint startBlock;
    }

    mapping(uint => ItemForSale) public idToItem;
    mapping(address => mapping(uint => uint)) usersBidAmount;

    ItemForSale[] items;

    modifier idExsists(uint _tokenId) {
        require(_tokenId < items.length);
        _;
    }


    function putItemForSale(uint _price, uint _duration) public onlyOwner {
        idToItem[items.length] = ItemForSale(_price, msg.sender, _duration, true, false, block.number);
        items.push(idToItem[items.length]);
    }

    function bid(uint _auctionId) public payable idExsists(_auctionId) {
        ItemForSale storage _item = idToItem[_auctionId];
        require(!_item.isSold, "item already sold");
        require(_item.isActive, "Not Active");
        require(msg.value > _item.highestBid, "Need to send a higher bid");
        _item.highestBid = msg.value;
        _item.highestbidder = msg.sender;
        usersBidAmount[msg.sender][_auctionId] = msg.value;
    }

    function claim(uint _auctionId) public idExsists(_auctionId) {
        ItemForSale storage _item = idToItem[_auctionId];
        require(block.number < _item.startBlock + _item.duration, "Auction not over");
        require(!_item.isSold, "item already sold");
        require(_item.isActive, "Not Active");
        require(_item.highestbidder == msg.sender, "Not the winner");
        _item.isActive = false;
        _item.isSold = true;
    }

    function getBidBack(uint _auctionId) public idExsists(_auctionId) {
        ItemForSale storage item = idToItem[_auctionId];
        require(msg.sender != item.highestbidder, "Cant take bid back if highest bid");
        payable(msg.sender).transfer(usersBidAmount[msg.sender][_auctionId]);
    }

    function viewBalance() public view returns(uint) {
        return address(this).balance;
    }
}