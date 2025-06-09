// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title HashDropNFT - Unified NFT System
 * @dev Single system that handles both single-tier and multi-tier campaigns
 */
contract HashDropNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    
    struct TierConfig {
        uint256 tierId;
        string name;
        string baseURI;
        uint256 maxSupply;
        uint256 currentSupply;
        bool active;
    }

    struct CampaignConfig {
        uint256 tierCount;
        mapping(uint256 => TierConfig) tiers;
        mapping(uint256 => uint256) scoreThresholds; // tierId => minScore
        bool active;
    }

    // Campaign ID => Campaign's configuration
    mapping(uint256 => CampaignConfig) public campaigns;
    mapping(uint256 => uint256) public tokenCampaign; // tokenId => campaignId
    mapping(uint256 => uint256) public tokenTier; // tokenId => tierId
    mapping(address => bool) public authorizedMinters;
    
    event CampaignConfigured(uint256 indexed campaignId, uint256 tierCount);
    event TierConfigured(uint256 indexed campaignId, uint256 tierId, string name, uint256 maxSupply, uint256 scoreThreshold);
    event NFTMinted(address indexed to, uint256 tokenId, uint256 campaignId, uint256 tierId, string tierName);
    event MinterAuthorized(address indexed minter, bool authorized);
    event CampaignStatusChanged(uint256 indexed campaignId, bool active);
    
    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _;
    }
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    /**
     * @dev Configure a campaign with custom tiers
     * @param campaignId The campaign ID
     * @param tierNames Array of tier names
     * @param baseURIs Array of base URIs for each tier
     * @param maxSupplies Array of max supplies for each tier
     * @param scoreThresholds Array of minimum scores for each tier
     * 
     * Examples:
     * Single Tier: ["Standard"], ["ipfs://standard/"], [1000], [0]
     * Multi Tier: ["Bronze", "Silver", "Gold"], ["ipfs://bronze/", "ipfs://silver/", "ipfs://gold/"], [500, 300, 100], [10, 50, 80]
     */
    function configureCampaign(
        uint256 campaignId,
        string[] memory tierNames,
        string[] memory baseURIs,
        uint256[] memory maxSupplies,
        uint256[] memory scoreThresholds
    ) external onlyOwner {
        require(tierNames.length > 0, "Must have at least one tier");
        require(tierNames.length <= 10, "Maximum 10 tiers allowed");
        require(
            tierNames.length == baseURIs.length && 
            baseURIs.length == maxSupplies.length && 
            maxSupplies.length == scoreThresholds.length,
            "Array lengths must match"
        );
        
        // For multi-tier campaigns, validate score thresholds are in ascending order
        if (tierNames.length > 1) {
            for (uint256 i = 1; i < scoreThresholds.length; i++) {
                require(scoreThresholds[i-1] < scoreThresholds[i], "Score thresholds must be ascending");
            }
        }
        
        // Validate all score thresholds are within valid range
        for (uint256 i = 0; i < scoreThresholds.length; i++) {
            require(scoreThresholds[i] <= 100, "Score threshold cannot exceed 100");
        }
        
        CampaignConfig storage campaign = campaigns[campaignId];
        campaign.tierCount = tierNames.length;
        campaign.active = true;
        
        for (uint256 i = 0; i < tierNames.length; i++) {
            require(bytes(tierNames[i]).length > 0, "Tier name cannot be empty");
            require(bytes(baseURIs[i]).length > 0, "Base URI cannot be empty");
            require(maxSupplies[i] > 0, "Max supply must be positive");
            
            campaign.tiers[i] = TierConfig({
                tierId: i,
                name: tierNames[i],
                baseURI: baseURIs[i],
                maxSupply: maxSupplies[i],
                currentSupply: 0,
                active: true
            });
            campaign.scoreThresholds[i] = scoreThresholds[i];
            
            emit TierConfigured(campaignId, i, tierNames[i], maxSupplies[i], scoreThresholds[i]);
        }
        
        emit CampaignConfigured(campaignId, tierNames.length);
    }
    
    /**
     * @dev Update tier configuration
     */
    function updateTierConfig(
        uint256 campaignId,
        uint256 tierId,
        string memory baseURI,
        uint256 maxSupply,
        bool active
    ) external onlyOwner {
        require(campaigns[campaignId].tierCount > 0, "Campaign not configured");
        require(tierId < campaigns[campaignId].tierCount, "Invalid tier ID");
        require(maxSupply >= campaigns[campaignId].tiers[tierId].currentSupply, "Max supply cannot be less than current supply");
        
        TierConfig storage tier = campaigns[campaignId].tiers[tierId];
        if (bytes(baseURI).length > 0) {
            tier.baseURI = baseURI;
        }
        tier.maxSupply = maxSupply;
        tier.active = active;
    }
    
    
    function mint(
        address to, 
        uint256 campaignId, 
        uint256 tierId
    ) external onlyAuthorizedMinter returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");
        require(campaigns[campaignId].active, "Campaign not active");
        require(campaigns[campaignId].tierCount > 0, "Campaign not configured");
        require(tierId < campaigns[campaignId].tierCount, "Invalid tier ID");
        
        TierConfig storage tier = campaigns[campaignId].tiers[tierId];
        require(tier.active, "Tier not active");
        require(tier.currentSupply < tier.maxSupply, "Tier supply exhausted");
        
        uint256 tokenId = _nextTokenId++;
        tier.currentSupply++;
        tokenCampaign[tokenId] = campaignId;
        tokenTier[tokenId] = tierId;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(tier.baseURI, Strings.toString(tokenId))));
        
        emit NFTMinted(to, tokenId, campaignId, tierId, tier.name);
        return tokenId;
    }
    
    /**
     * @dev Determine which tier a score qualifies for
     * For single-tier campaigns, always returns tier 0
     * For multi-tier campaigns, returns highest qualifying tier
     */
    function determineTierForScore(uint256 campaignId, uint256 score) external view returns (uint256) {
        require(campaigns[campaignId].tierCount > 0, "Campaign not configured");
        require(score <= 100, "Score cannot exceed 100");
        
        CampaignConfig storage campaign = campaigns[campaignId];
        
        // For single-tier campaigns, always return tier 0 if score meets minimum
        if (campaign.tierCount == 1) {
            require(score >= campaign.scoreThresholds[0], "Score too low");
            return 0;
        }
        
        // For multi-tier campaigns, find highest qualifying tier
        for (uint256 i = campaign.tierCount; i > 0; i--) {
            uint256 tierId = i - 1;
            if (score >= campaign.scoreThresholds[tierId]) {
                return tierId;
            }
        }
        
        revert("Score too low for any tier");
    }
    
    /**
     * @dev Check if a tier is available for minting
     */
    function tierAvailable(uint256 campaignId, uint256 tierId) external view returns (bool) {
        if (!campaigns[campaignId].active || campaigns[campaignId].tierCount == 0 || tierId >= campaigns[campaignId].tierCount) {
            return false;
        }
        
        TierConfig storage tier = campaigns[campaignId].tiers[tierId];
        return tier.active && tier.currentSupply < tier.maxSupply;
    }
    
    /**
     * @dev Check if campaign is single-tier (what used to be "simple")
     */
    function isSingleTier(uint256 campaignId) external view returns (bool) {
        return campaigns[campaignId].tierCount == 1;
    }
    
    /**
     * @dev Check if campaign is multi-tier (what used to be "tiered")
     */
    function isMultiTier(uint256 campaignId) external view returns (bool) {
        return campaigns[campaignId].tierCount > 1;
    }
    
    /**
     * @dev Get tier information
     */
    function getTierInfo(uint256 campaignId, uint256 tierId) external view returns (
        string memory name,
        string memory baseURI,
        uint256 maxSupply,
        uint256 currentSupply,
        uint256 scoreThreshold,
        bool active
    ) {
        require(tierId < campaigns[campaignId].tierCount, "Invalid tier ID");
        
        TierConfig storage tier = campaigns[campaignId].tiers[tierId];
        return (
            tier.name,
            tier.baseURI,
            tier.maxSupply,
            tier.currentSupply,
            campaigns[campaignId].scoreThresholds[tierId],
            tier.active
        );
    }
    
    /**
     * @dev Get campaign information
     */
    function getCampaignInfo(uint256 campaignId) external view returns (
        uint256 tierCount,
        bool active,
        string[] memory tierNames
    ) {
        CampaignConfig storage campaign = campaigns[campaignId];
        string[] memory names = new string[](campaign.tierCount);
        
        for (uint256 i = 0; i < campaign.tierCount; i++) {
            names[i] = campaign.tiers[i].name;
        }
        
        return (campaign.tierCount, campaign.active, names);
    }
    
    /**
     * @dev Get all tier thresholds for a campaign
     */
    function getCampaignThresholds(uint256 campaignId) external view returns (uint256[] memory) {
        require(campaigns[campaignId].tierCount > 0, "Campaign not configured");
        
        uint256 tierCount = campaigns[campaignId].tierCount;
        uint256[] memory thresholds = new uint256[](tierCount);
        
        for (uint256 i = 0; i < tierCount; i++) {
            thresholds[i] = campaigns[campaignId].scoreThresholds[i];
        }
        
        return thresholds;
    }
    
    /**
     * @dev Get token's campaign and tier information
     */
    function getTokenInfo(uint256 tokenId) external view returns (
        uint256 campaignId,
        uint256 tierId,
        string memory tierName
    ) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        uint256 campId = tokenCampaign[tokenId];
        uint256 tId = tokenTier[tokenId];
        string memory tName = campaigns[campId].tiers[tId].name;
        
        return (campId, tId, tName);
    }
    
    /**
     * @dev Set campaign active status
     */
    function setCampaignStatus(uint256 campaignId, bool active) external onlyOwner {
        require(campaigns[campaignId].tierCount > 0, "Campaign not configured");
        campaigns[campaignId].active = active;
        emit CampaignStatusChanged(campaignId, active);
    }
    
    /**
     * @dev Set minter authorization
     */
    function setMinterAuthorization(address minter, bool authorized) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinters[minter] = authorized;
        emit MinterAuthorized(minter, authorized);
    }
    
    /**
     * @dev Get total supply for a campaign
     */
    function getCampaignTotalSupply(uint256 campaignId) external view returns (uint256 totalSupply, uint256 totalMinted) {
        require(campaigns[campaignId].tierCount > 0, "Campaign not configured");
        
        uint256 supply = 0;
        uint256 minted = 0;
        
        for (uint256 i = 0; i < campaigns[campaignId].tierCount; i++) {
            supply += campaigns[campaignId].tiers[i].maxSupply;
            minted += campaigns[campaignId].tiers[i].currentSupply;
        }
        
        return (supply, minted);
    }
    
    /**
     * @dev Override functions for ERC721URIStorage
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}