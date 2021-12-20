// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MerryPranksters is ERC721Enumerable, Ownable {
  using Strings for uint256;

  event MemberSold(address _to, uint256 _tokenId);
  event CostChange(uint256 _price);
  event TokenURIset(string _tokenURI);
  event BaseExtensionSet(string _base);
  event IsPaused(bool _active);
  event UserWhitelisted(address _user);
  event UserWhitelistRemove(address _user);
  event FundsWithdrawn(address _to);


  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 10;
  uint256 public fee = .09 ether;

  bool public paused = false;

  mapping(address => bool) public whitelisted;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }



  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }



  // call to mint ERC-721
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(msg.value >= fee);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
      emit MemberSold(_to, supply + i);
    }
  }




  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  // gets tokenURI
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // change base cost
  function setCost(uint256 _newCost) public onlyOwner() {
    fee = _newCost;
    emit CostChange(fee);
  }

  // changes max mint amount
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  // sets token URI
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    emit TokenURIset(baseURI);
  }

  // sets base extension
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
    emit BaseExtensionSet(baseExtension);
  }

  // pauses trading
  function pause(bool _state) public onlyOwner {
    paused = _state;
    emit IsPaused(paused);
  }

 // add user to whitelist
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
    emit UserWhitelisted(_user);
  }

  // removes whitelist
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
    emit  UserWhitelistRemove(_user);
  }

  // Owner withdraws funds from contract
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
    emit FundsWithdrawn(msg.sender);
  }
}