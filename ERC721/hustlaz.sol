// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LilHustlaz is ERC721Enumerable, Ownable {

    using Strings for uint256;


    // sets variables in the contract
    uint256 public maxPerMint = 10;
    uint256 public constant MAX_HUSL = 10000;
    uint256 public price = 70000000000000000; //0.07 Ether
    string baseTokenURI;
    string baseTokenExtentsion = ".json";
    bool public saleOpen = false;
    uint256 ownersCut = 0;
    uint256 _tokenId = 150;

    event LilHustlazMinted(uint256 totalMinted);
    event TokenUriSet(string _uri);
    event PriceChanged(address _who, uint256 _price);
    event SaleStateFlip(bool _open);
    event FundsWithdrawn(address _who, uint256 _amount);

    // sets token Uri, winds up _tokenId to 100
    constructor(string memory baseURI) ERC721("Lil Hustlaz", "HUSL") {
        setBaseURI(baseURI);

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

    // changes the token uri
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit TokenUriSet(baseTokenURI);
    }


    // changes price of NFT
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceChanged(msg.sender, price);
    }

    //Close sale if open, open sale if closed
    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
        emit SaleStateFlip(saleOpen);
    }

    // withdraws funds from the contract
    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    //mint LilHustlaz
    function mintLilHustlaz(uint256 _count) external payable {
        require(totalSupply() + _count <= MAX_HUSL, "Exceeds maximum supply of Lil Hustlaz");
        address user = msg.sender;

        if (msg.sender != owner()) {
            require(saleOpen , "Sale is not open yet");
            require(msg.value >= price * _count, "Ether sent with this transaction is not correct");
            require(_count > 0 && _count <= maxPerMint, "Minimum 1 & Maximum 7 Lil Hustlaz can be minted per transaction");
            require(_count + walletOfOwner(msg.sender).length <= 100, "Can only have 100");

            for (uint256 i = 0; i < _count; i++) {
                _mint(user);
            }
        }
    }

    // function that handles the tokenId increment and mints the token (201-10000)
    function _mint(address _to) private {
        _tokenId++;
        _safeMint(_to, _tokenId);
        emit LilHustlazMinted(_tokenId);
    }

    // allows only owner to mint tokens, and sends to designated address (1-200)
    function _ownerMint(address _to) public onlyOwner {
        ownersCut++;
        require(ownersCut < 151);
        uint256 tokenId = ownersCut;
        _safeMint(_to, tokenId);
        emit LilHustlazMinted(tokenId);
    }

    // allows owner to mint many to an array of addresses (1-200)
    function _ownerMintMany(address[] memory people, uint256 howMany) public onlyOwner {
        require(people.length == howMany, "unequal data input");
        require(howMany <= 20, "20 is the max amount");
        for (uint256 i = 0; i < howMany; i++) {
            _ownerMint(people[i]);
        }
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = baseTokenURI;
    string memory extension = baseTokenExtentsion;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension))
        : "";
  }

    // returns the token uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

}