// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HashDropNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    
    enum Tier { BRONZE, SILVER, GOLD }
    
    struct TierMetadata {
        string baseURI;
        uint256 maxSupply;
        uint256 currentSupply;
        bool active;
    }
    
    mapping(Tier => TierMetadata) public tierMetadata;
    mapping(uint256 => Tier) public tokenTier;
    mapping(address => bool) public authorizedMinters;
    
    event TierConfigured(Tier tier, string baseURI, uint256 maxSupply);
    event TierNFTMinted(address indexed to, uint256 tokenId, Tier tier);
    event MinterAuthorized(address indexed minter, bool authorized);
    
    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _;
    }
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    function configureTier(
        Tier tier,
        string memory baseURI,
        uint256 maxSupply,
        bool active
    ) external onlyOwner {
        tierMetadata[tier] = TierMetadata({
            baseURI: baseURI,
            maxSupply: maxSupply,
            currentSupply: 0,
            active: active
        });
        emit TierConfigured(tier, baseURI, maxSupply);
    }
    
    function setMinterAuthorization(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
        emit MinterAuthorized(minter, authorized);
    }
    
    function mintTiered(address to, Tier tier) external onlyAuthorizedMinter returns (uint256) {
        TierMetadata storage tierData = tierMetadata[tier];
        require(tierData.active, "Tier not active");
        require(tierData.currentSupply < tierData.maxSupply, "Tier supply exhausted");
        
        uint256 tokenId = _nextTokenId++;
        tierData.currentSupply++;
        tokenTier[tokenId] = tier;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(tierData.baseURI, Strings.toString(tokenId))));
        
        emit TierNFTMinted(to, tokenId, tier);
        return tokenId;
    }
    
    function getTierInfo(Tier tier) external view returns (TierMetadata memory) {
        return tierMetadata[tier];
    }
    
    function tierAvailable(Tier tier) external view returns (bool) {
        TierMetadata memory tierData = tierMetadata[tier];
        return tierData.active && tierData.currentSupply < tierData.maxSupply;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}