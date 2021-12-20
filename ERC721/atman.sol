// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Atman is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // sets variables in the contract
    uint256 public maxPerMint = 10;
    uint256 public maxPerWallet = 25;
    uint256 public constant MaxTotal = 10000;
    uint256 public constant MaxMintable = 9000;
    uint256 public price = 80000000000000000; //0.08 Ether
    uint256 public onSale = 2000;
    uint256 mixedIds = 9000;
    uint256 tokenId;
    uint256 amountOwnerClaimed; // Max is 25
    string baseTokenURI;
    string baseTokenExtentsion = ".json";
    bool public saleOpen;

    mapping(uint256 => uint256) public shroomToToken;

    event TokenMinted(address _who, uint256 _tokenID);
    event shroomBurned(address _who, uint256 _shroom, uint256 _enhanced);
    event OwnerClaimed(address _to, uint256 _tokenId);
    event SaleIncreased(uint256 _amount);
    event EtherWithdrawn(uint256 _amount, address _to);
    event PriceChanged(uint256 _prevAmount, uint256 _new, address _who);
    event SaleStateChanged(bool _isOpen, address _who);
    event BaseURIChanged(address _who, string _newURI);

    // sets token Uri, winds up _tokenId to 100
    constructor(string memory baseURI, bool _start) ERC721("Atman", "SOUL") {
        saleOpen = _start;
        setBaseURI(baseURI);

    }

    //mint NFT
    function mintAtman(uint256 _count) external payable {
        require(saleOpen , "Sale is not open yet");
        require(totalSupply() + _count <= onSale, "Not enough for sale");
        require(totalSupply() + _count <= MaxMintable, "Exceeds maximum supply");
        require(msg.value >= price * _count, "Not Enough Ether");
        require(_count > 0 && _count <= maxPerMint, "Minimum 1 & Maximum 10 can be minted per transaction");
        require(_count + walletOfOwner(msg.sender).length <= maxPerWallet, "Can only have 25");
        address user = msg.sender;

        for (uint256 i = 0; i < _count; i++) {
            tokenId++;
            _mint(user, tokenId);
            emit TokenMinted(user, tokenId);
        }
    }

    // Allows user to burn a mushroom to enhance a certain NFT
    function burnAndMix(uint256 _shroom, uint256 _other) public {

        require(_shroom <= 1000, "Not a valid NFT");
        require(9000 > _other && _other > 1000, "Not a valid NFT");
        require(_exists(_shroom) && _exists(_other), "Doesnt exsist");

        shroomToToken[_shroom] = _other;
        _burn(_shroom);
        mixedIds ++;
        _mint(msg.sender, mixedIds);
        emit shroomBurned(msg.sender, _shroom, _other);
        emit TokenMinted(msg.sender, mixedIds);
    }

    // Owner gets to claim up to 25 tokens for free -- distributed to team
    function ownerClaim(address _to) public onlyOwner {
        require(amountOwnerClaimed < 25, "Owner can only claim 25");
        require(totalSupply() + 1 <= onSale, "Not enough for sale");
        require(totalSupply() + 1 <= MaxMintable, "Exceeds maximum supply");
        tokenId++;
        _mint(_to, tokenId);
        amountOwnerClaimed++;
        emit OwnerClaimed(_to, tokenId);
        emit TokenMinted(_to, tokenId);
    }

    // Increase number of NFTs available for sale
    function addToSale(uint256 _amount) public onlyOwner {
        require(onSale + _amount <= 9000);
        onSale += _amount;
        emit SaleIncreased(_amount);

    }

    // withdraws funds from the contract
    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit EtherWithdrawn(amount, msg.sender);

    }

    //Get token Ids of all tokens owned by _owner
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {

        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // returns tokenURI for selected tokenID
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
      {
        require(
          _exists(_tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = baseTokenURI;
        string memory extension = baseTokenExtentsion;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension))
            : "";
      }

    // returns the base token uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // changes the token uri
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(msg.sender, baseTokenURI);

    }

    // changes price of NFT
    function setPrice(uint256 _newPrice) external onlyOwner {
        uint256 old_price = price;
        price = _newPrice;
        emit PriceChanged(old_price, price, msg.sender);

    }

    //Close sale if open, open sale if closed
    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
        emit SaleStateChanged(saleOpen, msg.sender);

    }

}
