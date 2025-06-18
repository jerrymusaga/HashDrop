// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";
import "./Token.sol";

/**
 * @title HashDropRewardsManager
 * @dev Unified interface for managing both NFT and Token rewards
 */
contract HashDropRewardsManager is Ownable {
    
    HashDropNFT public nftContract;
    HashDropToken public tokenContract;
    
    enum RewardType { NFT, TOKEN }
    
    mapping(uint256 => RewardType) public campaignRewardType;
    mapping(uint256 => address) public campaignRewardContract;
    mapping(address => bool) public authorizedMinters;
    
    event CampaignRewardsConfigured(uint256 indexed campaignId, RewardType rewardType, address rewardContract);
    event RewardMinted(uint256 indexed campaignId, address indexed user, RewardType rewardType);
    
    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _;
    }
    
    constructor(address _nftContract, address _tokenContract) Ownable(msg.sender) {
        nftContract = HashDropNFT(_nftContract);
        tokenContract = HashDropToken(_tokenContract);
    }
    
    /**
     * @dev Configure NFT rewards for a campaign
     */
    function configureNFTRewards(
        uint256 campaignId,
        uint256[] memory minScores,
        uint256[] memory maxSupplies,
        string[] memory names,
        string[] memory imageURIs
    ) external onlyOwner {
        nftContract.configureCampaignRewards(campaignId, minScores, maxSupplies, names, imageURIs);
        
        campaignRewardType[campaignId] = RewardType.NFT;
        campaignRewardContract[campaignId] = address(nftContract);
        
        emit CampaignRewardsConfigured(campaignId, RewardType.NFT, address(nftContract));
    }
    
    /**
     * @dev Configure Token rewards for a campaign
     */
    function configureTokenRewards(
        uint256 campaignId,
        uint256[] memory minScores,
        uint256[] memory maxSupplies,
        string[] memory names,
        uint256[] memory tokenAmounts
    ) external onlyOwner {
        tokenContract.configureCampaignRewards(campaignId, minScores, maxSupplies, names, tokenAmounts);
        
        campaignRewardType[campaignId] = RewardType.TOKEN;
        campaignRewardContract[campaignId] = address(tokenContract);
        
        emit CampaignRewardsConfigured(campaignId, RewardType.TOKEN, address(tokenContract));
    }
    
    /**
     * @dev Mint reward to user (automatically detects NFT vs Token)
     */
    function mintReward(
        address to,
        uint256 campaignId,
        uint256 userScore
    ) external onlyAuthorizedMinter returns (bool) {
        require(campaignRewardContract[campaignId] != address(0), "Campaign not configured");
        
        bool success;
        
        if (campaignRewardType[campaignId] == RewardType.NFT) {
            success = nftContract.mintReward(to, campaignId, userScore);
        } else {
            success = tokenContract.mintReward(to, campaignId, userScore);
        }
        
        if (success) {
            emit RewardMinted(campaignId, to, campaignRewardType[campaignId]);
        }
        
        return success;
    }
    
    /**
     * @dev Batch mint rewards
     */
    function batchMintRewards(
        address[] memory users,
        uint256 campaignId,
        uint256[] memory scores
    ) external onlyAuthorizedMinter returns (uint256) {
        require(campaignRewardContract[campaignId] != address(0), "Campaign not configured");
        
        if (campaignRewardType[campaignId] == RewardType.NFT) {
            return nftContract.batchMintRewards(users, campaignId, scores);
        } else {
            return tokenContract.batchMintRewards(users, campaignId, scores);
        }
    }
    
    /**
     * @dev Check if user has claimed reward
     */
    function hasUserClaimed(uint256 campaignId, address user) external view returns (bool) {
        if (campaignRewardType[campaignId] == RewardType.NFT) {
            return nftContract.hasUserClaimed(campaignId, user);
        } else {
            return tokenContract.hasUserClaimed(campaignId, user);
        }
    }
    
    /**
     * @dev Get campaign reward info
     */
    function getCampaignRewardInfo(uint256 campaignId) external view returns (
        RewardType rewardType,
        uint256 tierCount,
        address rewardContract
    ) {
        rewardType = campaignRewardType[campaignId];
        rewardContract = campaignRewardContract[campaignId];
        
        if (rewardType == RewardType.NFT) {
            tierCount = nftContract.getCampaignRewardInfo(campaignId);
        } else {
            tierCount = tokenContract.getCampaignRewardInfo(campaignId);
        }
        
        return (rewardType, tierCount, rewardContract);
    }
    
    /**
     * @dev Check tier qualification
     */
    function getQualifiedTier(uint256 campaignId, uint256 score) external view returns (uint256, bool) {
        if (campaignRewardType[campaignId] == RewardType.NFT) {
            return nftContract.getQualifiedTier(campaignId, score);
        } else {
            return tokenContract.getQualifiedTier(campaignId, score);
        }
    }
    
    /**
     * @dev Set minter authorization
     */
    function setMinterAuthorization(address minter, bool authorized) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinters[minter] = authorized;
        
        // Also authorize on both underlying contracts
        nftContract.setMinterAuthorization(minter, authorized);
        tokenContract.setMinterAuthorization(minter, authorized);
    }
    
    /**
     * @dev Update contract addresses
     */
    function updateContracts(address _nftContract, address _tokenContract) external onlyOwner {
        require(_nftContract != address(0) && _tokenContract != address(0), "Invalid contract addresses");
        nftContract = HashDropNFT(_nftContract);
        tokenContract = HashDropToken(_tokenContract);
    }
}