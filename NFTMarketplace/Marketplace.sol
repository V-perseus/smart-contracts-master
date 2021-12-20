// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nftAuction.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace is Auction {

    // fee for dev for every sale
    uint fee;

    // setup for an item on sale
    struct ForSale {
        address tokenAddress;
        uint tokenId;
        uint amount;
        address seller;
        bool isActive;
    }

    uint listingId = 0;
    mapping(uint => ForSale) indexToItem;

    event ItemAddedToSale(address tokenAddress, uint tokenID, uint price, address seller);
    event ItemSold(address tokenAddress, uint tokenId, uint price, address buyer);

    constructor(uint _fee) {
        fee = _fee;
    }

    /*
        requires sender owns the token and user approved the contract to spend the token
        creates a forSale object and pushes it to the array
    */
    function addItemToSale(uint _price, address _tokenAddress, uint _tokenID) public {
        require(IERC721(_tokenAddress).ownerOf(_tokenID) == msg.sender, "Must be owner of token");
        require(IERC721(_tokenAddress).getApproved(_tokenID) == address(this), "Token must be approved for contract");
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenID);
        listingId++;
        indexToItem[listingId] = ForSale(_tokenAddress, _tokenID, _price, msg.sender, true);
        emit ItemAddedToSale(_tokenAddress, _tokenID, _price, msg.sender);
    }

    /*
        requires the id exsists the item isnt sold, and the user sent enough
        contract only accpets correct value
        sets the item to being sold, sends the token to the buyer
        taxes the seller and sends them their portion
    */
    function buyItemFromSale(uint _saleId) public payable {
        require(_saleId < listingId, "Id doesnt exsist");
        ForSale storage item = indexToItem[_saleId];
        require(item.isActive, "Item sold already");
        require(msg.value == item.amount, "didnt send enough");
        item.isActive = false;
        IERC721(item.tokenAddress).transferFrom(address(this), msg.sender, item.tokenId);
        uint taxxedAmount = (msg.value * fee) / 100;
        payable(item.seller).transfer(msg.value - taxxedAmount);
        emit ItemSold(item.tokenAddress, item.tokenId, item.amount, msg.sender);
    }

    function cancelSale(uint _saleId) public {
        require(_saleId < listingId, "Id doesnt exsist");
        ForSale storage item = indexToItem[_saleId];
        require(msg.sender == item.seller, "Only seller can cancel");
        require(item.isActive, "Already sold");
        item.isActive = false;
        IERC721(item.tokenAddress).transferFrom(address(this), item.seller, item.tokenId);
    }

    // views item through the index Id of the Sale
    function viewItemForSale(uint _indexId) public view returns(ForSale memory) {
        return indexToItem[_indexId];
    }

    function viewbalance() public view returns(uint) {
        return address(this).balance;
    }
}