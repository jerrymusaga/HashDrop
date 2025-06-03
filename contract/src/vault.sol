// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HashDropNFT} from "./NFT.sol";
import {HashDropCampaign} from "./Campaign.sol";

contract HashDropVault is Ownable, ReentrancyGuard {
    
    struct VaultConfig {
        address campaignContract;
        address rewardContract;
        bool active;
        uint256 totalRewards;
        uint256 claimedRewards;
        mapping(address => bool) hasClaimed;
    }
    
    mapping(uint256 => VaultConfig) public vaultConfigs;
    mapping(address => bool) public authorizedClaimers;
    
    event VaultConfigured(uint256 indexed campaignId, address rewardContract, uint256 totalRewards);
    event RewardClaimed(uint256 indexed campaignId, address indexed user, uint256 tier, uint256 tokenId);
    event ClaimerAuthorized(address indexed claimer, bool authorized);
    
    modifier onlyAuthorizedClaimer() {
        require(authorizedClaimers[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    modifier validVault(uint256 campaignId) {
        require(vaultConfigs[campaignId].rewardContract != address(0), "Vault not configured");
        _;
    }
    
    constructor() Ownable(msg.sender) {}

    function configureVault(
        uint256 campaignId,
        address campaignContract,
        address rewardContract,
        uint256 totalRewards
    ) external onlyOwner {
        require(campaignContract != address(0), "Invalid campaign contract");
        require(rewardContract != address(0), "Invalid reward contract");
        
        VaultConfig storage config = vaultConfigs[campaignId];
        config.campaignContract = campaignContract;
        config.rewardContract = rewardContract;
        config.active = true;
        config.totalRewards = totalRewards;
        
        emit VaultConfigured(campaignId, rewardContract, totalRewards);
    }
    
    function setClaimerAuthorization(address claimer, bool authorized) external onlyOwner {
        authorizedClaimers[claimer] = authorized;
        emit ClaimerAuthorized(claimer, authorized);
    }

    function processSimpleRewardClaim(
        uint256 campaignId,
        address user,
        uint256 score
    ) external onlyAuthorizedClaimer nonReentrant validVault(campaignId) {
        VaultConfig storage config = vaultConfigs[campaignId];
        require(config.active, "Vault not active");
        require(!config.hasClaimed[user], "User already claimed");
        require(config.claimedRewards < config.totalRewards, "No rewards remaining");
        
        HashDropCampaign campaignContract = HashDropCampaign(config.campaignContract);
        HashDropCampaign.RewardMode rewardMode = campaignContract.getRewardMode(campaignId);
        require(rewardMode == HashDropCampaign.RewardMode.SIMPLE, "Campaign not in simple mode");
        
        uint256 minScore = campaignContract.getMinScore(campaignId);
        require(score >= minScore, "Score below minimum threshold");
        
        // Mark as claimed
        config.hasClaimed[user] = true;
        config.claimedRewards++;
        
        // Mint simple NFT
        HashDropNFT nftContract = HashDropNFT(config.rewardContract);
        require(nftContract.simpleNFTAvailable(), "Simple NFT not available");
        
        uint256 tokenId = nftContract.mintSimple(user);
        
        emit RewardClaimed(campaignId, user, 0, tokenId); // tier = 0 for simple NFTs
    }
    
    function processTieredRewardClaim(
        uint256 campaignId,
        address user,
        uint256 score
    ) external onlyAuthorizedClaimer validVault(campaignId) nonReentrant {
        VaultConfig storage config = vaultConfigs[campaignId];
        require(config.active, "Vault not active");
        require(!config.hasClaimed[user], "Already claimed");
        require(config.claimedRewards < config.totalRewards, "No rewards left");
        
        HashDropCampaign campaignContract = HashDropCampaign(config.campaignContract);
        HashDropCampaign.RewardMode rewardMode = campaignContract.getRewardMode(campaignId);
        require(rewardMode == HashDropCampaign.RewardMode.TIERED, "Campaign not in tiered mode");

        HashDropNFT.Tier tier = _determineTier(campaignId, score);
        HashDropNFT nftContract = HashDropNFT(config.rewardContract);
        
        require(nftContract.tierAvailable(tier), "Tier unavailable");
        
        unchecked {
            config.claimedRewards++;
        }
        config.hasClaimed[user] = true;
        
        uint256 tokenId = nftContract.mintTiered(user, tier);
        emit RewardClaimed(campaignId, user, uint256(tier), tokenId);
    }
    
    function _determineTier(uint256 campaignId, uint256 score) internal view returns (HashDropNFT.Tier) {
        VaultConfig storage config = vaultConfigs[campaignId];
        (uint256 bronze, uint256 silver, uint256 gold) = 
            HashDropCampaign(config.campaignContract).getScoreThresholds(campaignId);

        if (score >= gold) return HashDropNFT.Tier.GOLD;
        if (score >= silver) return HashDropNFT.Tier.SILVER;
        if (score >= bronze) return HashDropNFT.Tier.BRONZE;
        revert("Score too low");
    }
    
    function hasUserClaimed(uint256 campaignId, address user) external view validVault(campaignId) returns (bool) {
        return vaultConfigs[campaignId].hasClaimed[user];
    }
    
    function getVaultStats(uint256 campaignId) external view validVault(campaignId) returns (
        address rewardContract,
        bool active,
        uint256 totalRewards,
        uint256 claimedRewards,
        uint256 remainingRewards
    ) {
        VaultConfig storage config = vaultConfigs[campaignId];
        return (
            config.rewardContract,
            config.active,
            config.totalRewards,
            config.claimedRewards,
            config.totalRewards - config.claimedRewards
        );
    }
    
    function pauseVault(uint256 campaignId) external onlyOwner validVault(campaignId) {
        vaultConfigs[campaignId].active = false;
    }
    
    function resumeVault(uint256 campaignId) external onlyOwner validVault(campaignId) {
        vaultConfigs[campaignId].active = true;
    }
}