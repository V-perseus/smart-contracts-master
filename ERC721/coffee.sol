// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CoffeeBuddies is ERC721Enumerable, Ownable {
  using Strings for uint256;

  event BeanSold(address _to, uint256 _tokenId);
  event CostChange(uint256 _price);
  event TokenURIset(string _tokenURI);
  event BaseExtensionSet(string _base);
  event IsPaused(bool _active);
  event UserWhitelisted(address _user);
  event UserWhitelistRemove(address _user);
  event FundsWithdrawn(address _to);


  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 500000;
  uint256 public maxMintAmount = 10;
  uint256 public fivePack = 5;
  uint256 public tenPack = 10;
  bool public paused = false;
  AggregatorV3Interface internal ethUsdPriceFeed;
  uint256 public usdEntryFee;
  mapping(address => bool) public whitelisted;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    AggregatorV3Interface _priceFeedAddress,
    uint256 _fee
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    usdEntryFee = _fee * (10**18);
  }

  //checks to see if user sent enough
  modifier sentEnough(uint256 _amount) {
      if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= getEntranceFee() * _amount);
        }
    }
    _;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //mint 1
  function mintSolo() public payable sentEnough(1) {

      mint(msg.sender, 1);
  }


  //mint 5
  function mintFive() public payable sentEnough(fivePack) {

      mint(msg.sender, fivePack);
  }


  //mint 10
  function mintTen() public payable sentEnough(tenPack) {

      mint(msg.sender, tenPack);
  }

  // call to mint ERC-721
  function mint(address _to, uint256 _mintAmount) internal {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
      emit BeanSold(_to, supply + i);
    }
  }

  // gets ethereum price from chainlink then converts to the $USD value
  function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $4, $2,000 / ETH
        // 4/2,000
        // 4 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
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
    usdEntryFee = _newCost;
    emit CostChange(usdEntryFee);
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