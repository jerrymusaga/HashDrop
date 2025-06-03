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
    enum NFTMode { SIMPLE, TIERED }
    
    struct TierMetadata {
        string baseURI;
        uint256 maxSupply;
        uint256 currentSupply;
        bool active;
    }

    struct SimpleNFTConfig {
        string baseURI;
        uint256 maxSupply;
        uint256 currentSupply;
        bool active;
    }

    NFTMode public nftMode;
    
    mapping(Tier => TierMetadata) public tierMetadata;
    mapping(uint256 => Tier) public tokenTier;

    SimpleNFTConfig public simpleConfig;
    mapping(address => bool) public authorizedMinters;
    
    event TierConfigured(Tier tier, string baseURI, uint256 maxSupply);
    event TierNFTMinted(address indexed to, uint256 tokenId, Tier tier);
    event SimpleNFTConfigured(string baseURI, uint256 maxSupply);
    event SimpleNFTMinted(address indexed to, uint256 tokenId);
    event MinterAuthorized(address indexed minter, bool authorized);
    event NFTModeSet(NFTMode mode);
    
    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _;
    }
    
    constructor(string memory name, string memory symbol, NFTMode _nftMode) ERC721(name, symbol) Ownable(msg.sender) {
        nftMode = _nftMode;
        emit NFTModeSet(_nftMode);
    }

    function configureSimpleNFT(
        string memory baseURI,
        uint256 maxSupply
    ) external onlyOwner {
        require(nftMode == NFTMode.SIMPLE, "Contract not in simple mode");
        
        simpleConfig = SimpleNFTConfig({
            baseURI: baseURI,
            maxSupply: maxSupply,
            currentSupply: 0,
            active: true
        });
        
        emit SimpleNFTConfigured(baseURI, maxSupply);
    }

    function configureTier(
        Tier tier,
        string memory baseURI,
        uint256 maxSupply,
        bool active
    ) external onlyOwner {
        require(nftMode == NFTMode.TIERED, "Contract not in tiered mode");
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

    function mintSimple(address to) external onlyAuthorizedMinter returns (uint256) {
        require(nftMode == NFTMode.SIMPLE, "Contract not in simple mode");
        require(simpleConfig.active, "Simple NFT not active");
        require(simpleConfig.currentSupply < simpleConfig.maxSupply, "Supply exhausted");
        
        uint256 tokenId = _nextTokenId++;
        
        simpleConfig.currentSupply++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(simpleConfig.baseURI, Strings.toString(tokenId))));
        
        emit SimpleNFTMinted(to, tokenId);
        return tokenId;
    }
    
    function mintTiered(address to, Tier tier) external onlyAuthorizedMinter returns (uint256) {
        require(nftMode == NFTMode.TIERED, "Contract not in tiered mode");
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

    function simpleNFTAvailable() external view returns (bool) {
        return nftMode == NFTMode.SIMPLE && 
               simpleConfig.active && 
               simpleConfig.currentSupply < simpleConfig.maxSupply;
    }
    
    /**
     * @dev Get simple NFT info
     */
    function getSimpleNFTInfo() external view returns (SimpleNFTConfig memory) {
        require(nftMode == NFTMode.SIMPLE, "Contract not in simple mode");
        return simpleConfig;
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