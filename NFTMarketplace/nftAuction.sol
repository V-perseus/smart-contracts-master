// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Auction {

    struct ItemForAuction {
        uint highestBid;
        address highestbidder;
        address tokenAddress;
        uint tokenId;
        address seller;
        uint duration;
        bool isActive;
        uint startBlock;
    }

    mapping(uint => ItemForAuction) idToItem;
    mapping(address => mapping(uint => uint)) public usersBidAmount;

    uint auctionId = 0;


    event ItemOnAuction(address _tokenAddress, uint _tokenId, uint _duration, uint _startPrice, address _seller);
    event ItemClaimed(address _tokenAddress, uint _tokenId, address _buyer, address _seller, uint _buyprice);

    modifier idExsists(uint _auctionId) {
        require(_auctionId < auctionId);
        _;
    }


    function putItemForAuction(uint _price, uint _duration, address _tokenAddress, uint _tokenId) public {
        require(IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender, "You do not own the token");
        require(IERC721(_tokenAddress).getApproved(_tokenId) == address(this), "Need to approve NFT");
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
        auctionId++;
        uint indexId = auctionId;
        idToItem[indexId] = ItemForAuction(_price, msg.sender, _tokenAddress, _tokenId, msg.sender, _duration, true, block.number);
        emit ItemOnAuction(_tokenAddress, _tokenId, _duration, _price, msg.sender);
    }

    function bid(uint _auctionId) public payable idExsists(_auctionId) {
        ItemForAuction storage auctionItem = idToItem[_auctionId];
        require(msg.value > auctionItem.highestBid, "Didnt send enoguh");
        require(block.number < auctionItem.startBlock + auctionItem.duration, "Auction is over");
        require(auctionItem.isActive, "Sale is inactive");
        auctionItem.highestBid = msg.value;
        auctionItem.highestbidder = msg.sender;
        if (usersBidAmount[msg.sender][_auctionId] == 0) {
            usersBidAmount[msg.sender][_auctionId] = msg.value;
        } else {
            usersBidAmount[msg.sender][_auctionId] += msg.value;
        }
    }

    function claim(uint _auctionId) public idExsists(_auctionId) {
        ItemForAuction storage auctionItem = idToItem[_auctionId];
        require(auctionItem.isActive, "Item already sold");
        require(block.number > auctionItem.startBlock + auctionItem.duration, "auction isnt over");
        require(msg.sender == auctionItem.highestbidder || msg.sender == auctionItem.seller, "Not the highest bidder");
        auctionItem.isActive = false;
        IERC721(auctionItem.tokenAddress).transferFrom(address(this), auctionItem.highestbidder, auctionItem.tokenId);
        uint taxedAmount = (auctionItem.highestBid * 4 )/ 100;
        payable(auctionItem.seller).transfer(auctionItem.highestBid - taxedAmount);
        emit ItemClaimed(auctionItem.tokenAddress, auctionItem.tokenId, auctionItem.highestbidder, auctionItem.seller, auctionItem.highestBid);
    }

    function getBidBack(uint _auctionId) public idExsists(_auctionId) {
        ItemForAuction memory auctionItem = idToItem[_auctionId];
        require(usersBidAmount[msg.sender][_auctionId] > 0, "No bid to withdraw");
        require(msg.sender != auctionItem.highestbidder, "Cant withdraw highest bid");
        uint _amount = usersBidAmount[msg.sender][_auctionId];
        usersBidAmount[msg.sender][_auctionId] = 0;
        payable(msg.sender).transfer(_amount);
    }

    function cancelAuction(uint _auctionId) public idExsists(_auctionId) {
        ItemForAuction storage auctionItem = idToItem[_auctionId];
        require(auctionItem.seller == msg.sender,"Only seller can cancel");
        require(auctionItem.isActive, "Already sold");
        auctionItem.isActive = false;
        IERC721(auctionItem.tokenAddress).transferFrom(address(this), auctionItem.seller, auctionItem.tokenId);
    }

    function viewAuction(uint _auctionId) public view idExsists(_auctionId) returns(ItemForAuction memory) {
        return idToItem[_auctionId];
    }

    function viewBalance() public view returns(uint) {
        return address(this).balance;
    }
}