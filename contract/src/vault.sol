// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HashDropNFT} from "./NFT.sol";
import {HashDropCampaign} from "./Campaign.sol";
import {HashDropCCIPManager} from "./CCIPManager.sol";

contract HashDropVault is Ownable, ReentrancyGuard {

    HashDropCCIPManager public ccipManager;
    
    struct VaultConfig {
        address campaignContract;
        address rewardContract;
        bool active;
        uint256 totalRewards;
        uint256 claimedRewards;
        mapping(address => bool) hasClaimed;
        mapping(address => uint256) userTokenIds; // Track minted token IDs for users
    }
    
    mapping(uint256 => VaultConfig) public vaultConfigs;
    mapping(address => bool) public authorizedClaimers;
    
    event VaultConfigured(uint256 indexed campaignId, address campaignContract, address rewardContract, uint256 totalRewards);
    event RewardClaimed(uint256 indexed campaignId, address indexed user, uint256 tierId, uint256 tokenId, string tierName);
    event ClaimerAuthorized(address indexed claimer, bool authorized);
    event VaultStatusChanged(uint256 indexed campaignId, bool active);
    
    modifier onlyAuthorizedClaimer() {
    require(
        authorizedClaimers[msg.sender] || 
        msg.sender == owner() ||
        (address(ccipManager) != address(0) && msg.sender == address(ccipManager)),
        "Not authorized to process claims"
    );
    _;
}

    modifier validVault(uint256 campaignId) {
        require(vaultConfigs[campaignId].rewardContract != address(0), "Vault not configured");
        _;
    }
    
    constructor() Ownable(msg.sender) {}

    function setCCIPManager(address _ccipManager) external onlyOwner {
        ccipManager = HashDropCCIPManager(payable(_ccipManager));
    }

    /**
     * @dev Configure vault for a campaign
     * @param campaignId The campaign ID
     * @param campaignContract Address of the campaign contract
     * @param rewardContract Address of the NFT reward contract
     * @param totalRewards Maximum number of rewards that can be claimed
     */
    function configureVault(
        uint256 campaignId,
        address campaignContract,
        address rewardContract,
        uint256 totalRewards
    ) external onlyOwner {
        require(campaignContract != address(0), "Invalid campaign contract");
        require(rewardContract != address(0), "Invalid reward contract");
        require(totalRewards > 0, "Total rewards must be positive");
        
        VaultConfig storage config = vaultConfigs[campaignId];
        config.campaignContract = campaignContract;
        config.rewardContract = rewardContract;
        config.active = true;
        config.totalRewards = totalRewards;
        config.claimedRewards = 0;
        
        emit VaultConfigured(campaignId, campaignContract, rewardContract, totalRewards);
    }
    
    /**
     * @dev Set claimer authorization
     */
    function setClaimerAuthorization(address claimer, bool authorized) external onlyOwner {
        require(claimer != address(0), "Invalid claimer address");
        authorizedClaimers[claimer] = authorized;
        emit ClaimerAuthorized(claimer, authorized);
    }

    /**
     * @dev Process reward claim for a user based on their score
     * @param campaignId The campaign ID
     * @param user Address of the user claiming the reward
     * @param score User's engagement score (0-100)
     */
    function processRewardClaim(
        uint256 campaignId,
        address user,
        uint256 score
    ) external onlyAuthorizedClaimer nonReentrant validVault(campaignId) {
        VaultConfig storage config = vaultConfigs[campaignId];
        require(config.active, "Vault not active");
        require(!config.hasClaimed[user], "User already claimed reward");
        require(config.claimedRewards < config.totalRewards, "No rewards remaining");
        require(score > 0 && score <= 100, "Invalid score range");
        
        // Verify user participated in campaign
        HashDropCampaign campaignContract = HashDropCampaign(config.campaignContract);
        require(campaignContract.hasUserParticipated(campaignId, user), "User has not participated");
        
        // Get stored score matches provided score
        uint256 storedScore = campaignContract.getUserScore(campaignId, user);
        require(storedScore == score, "Score mismatch");
        
        HashDropNFT nftContract = HashDropNFT(config.rewardContract);
        
        // Determine which tier the user qualifies for based on their score
        uint256 qualifiedTierId = nftContract.determineTierForScore(campaignId, score);
        
        // Check if the tier is available for minting
        require(nftContract.tierAvailable(campaignId, qualifiedTierId), "Qualified tier not available");
        
        // Mark as claimed before minting to prevent reentrancy
        config.hasClaimed[user] = true;
        config.claimedRewards++;
        
        // Mint the NFT
        uint256 tokenId = nftContract.mint(user, campaignId, qualifiedTierId);
        config.userTokenIds[user] = tokenId;
        
        // Get tier name for event
        (string memory tierName,,,,,) = nftContract.getTierInfo(campaignId, qualifiedTierId);
        
        // Consume budget from campaign contract
        try campaignContract.consumeBudget(campaignId, 1) {} catch {
            // Continue even if budget tracking fails
        }
        
        emit RewardClaimed(campaignId, user, qualifiedTierId, tokenId, tierName);
    }
    
    /**
     * @dev Batch process multiple reward claims
     */
    function batchProcessRewardClaims(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external onlyAuthorizedClaimer nonReentrant validVault(campaignId) {
        require(users.length == scores.length, "Arrays length mismatch");
        require(users.length > 0, "No users provided");
        
        VaultConfig storage config = vaultConfigs[campaignId];
        require(config.active, "Vault not active");
        require(config.claimedRewards + users.length <= config.totalRewards, "Not enough rewards remaining");
        
        HashDropCampaign campaignContract = HashDropCampaign(config.campaignContract);
        HashDropNFT nftContract = HashDropNFT(config.rewardContract);
        
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 score = scores[i];
            
            // Skip if user already claimed
            if (config.hasClaimed[user]) continue;
            
            // Verify participation and score
            if (!campaignContract.hasUserParticipated(campaignId, user)) continue;
            if (campaignContract.getUserScore(campaignId, user) != score) continue;
            
            try nftContract.determineTierForScore(campaignId, score) returns (uint256 qualifiedTierId) {
                if (nftContract.tierAvailable(campaignId, qualifiedTierId)) {
                    config.hasClaimed[user] = true;
                    config.claimedRewards++;
                    
                    uint256 tokenId = nftContract.mint(user, campaignId, qualifiedTierId);
                    config.userTokenIds[user] = tokenId;
                    
                    (string memory tierName,,,,,) = nftContract.getTierInfo(campaignId, qualifiedTierId);
                    emit RewardClaimed(campaignId, user, qualifiedTierId, tokenId, tierName);
                }
            } catch {
                // Skip users who don't qualify for any tier
                continue;
            }
        }
        
        // Update campaign budget
        try campaignContract.consumeBudget(campaignId, config.claimedRewards) {} catch {}
    }
    
    /**
     * @dev Check if user has claimed reward
     */
    function hasUserClaimed(uint256 campaignId, address user) external view validVault(campaignId) returns (bool) {
        return vaultConfigs[campaignId].hasClaimed[user];
    }
    
    /**
     * @dev Get user's minted token ID
     */
    function getUserTokenId(uint256 campaignId, address user) external view validVault(campaignId) returns (uint256) {
        require(vaultConfigs[campaignId].hasClaimed[user], "User has not claimed");
        return vaultConfigs[campaignId].userTokenIds[user];
    }
    
    /**
     * @dev Get vault statistics
     */
    function getVaultStats(uint256 campaignId) external view validVault(campaignId) returns (
        address campaignContract,
        address rewardContract,
        bool active,
        uint256 totalRewards,
        uint256 claimedRewards,
        uint256 remainingRewards
    ) {
        VaultConfig storage config = vaultConfigs[campaignId];
        return (
            config.campaignContract,
            config.rewardContract,
            config.active,
            config.totalRewards,
            config.claimedRewards,
            config.totalRewards - config.claimedRewards
        );
    }

    /**
    * @dev Initiate cross-chain reward claim
    */
    function initiateXChainClaim(
        uint256 destinationChainId,
        uint256 campaignId,
        address user
    ) external onlyAuthorizedClaimer validVault(campaignId) {
        require(address(ccipManager) != address(0), "CCIP Manager not set");
        
        VaultConfig storage config = vaultConfigs[campaignId];
        require(config.active, "Vault not active");
        require(!config.hasClaimed[user], "User already claimed reward");
        
        // Get user's score from campaign contract
        HashDropCampaign campaignContract = HashDropCampaign(config.campaignContract);
        require(campaignContract.hasUserParticipated(campaignId, user), "User has not participated");
        
        uint256 score = campaignContract.getUserScore(campaignId, user);
        
        // Send cross-chain claim request
        ccipManager.sendRewardClaim(destinationChainId, campaignId, user, score);
    }
    
    /**
     * @dev Preview what tier a user would qualify for
     */
    function previewUserTier(uint256 campaignId, address user) external view validVault(campaignId) returns (
        uint256 tierId,
        string memory tierName,
        bool available
    ) {
        VaultConfig storage config = vaultConfigs[campaignId];
        HashDropCampaign campaignContract = HashDropCampaign(config.campaignContract);
        
        require(campaignContract.hasUserParticipated(campaignId, user), "User has not participated");
        
        uint256 score = campaignContract.getUserScore(campaignId, user);
        HashDropNFT nftContract = HashDropNFT(config.rewardContract);
        
        uint256 qualifiedTierId = nftContract.determineTierForScore(campaignId, score);
        (string memory name,,,,,) = nftContract.getTierInfo(campaignId, qualifiedTierId);
        bool isAvailable = nftContract.tierAvailable(campaignId, qualifiedTierId);
        
        return (qualifiedTierId, name, isAvailable);
    }
    
    /**
     * @dev Pause vault operations
     */
    function pauseVault(uint256 campaignId) external onlyOwner validVault(campaignId) {
        vaultConfigs[campaignId].active = false;
        emit VaultStatusChanged(campaignId, false);
    }
    
    /**
     * @dev Resume vault operations
     */
    function resumeVault(uint256 campaignId) external onlyOwner validVault(campaignId) {
        vaultConfigs[campaignId].active = true;
        emit VaultStatusChanged(campaignId, true);
    }
    
    /**
     * @dev Update vault reward limits
     */
    function updateVaultLimits(uint256 campaignId, uint256 newTotalRewards) external onlyOwner validVault(campaignId) {
        VaultConfig storage config = vaultConfigs[campaignId];
        require(newTotalRewards >= config.claimedRewards, "Cannot reduce below claimed amount");
        
        config.totalRewards = newTotalRewards;
    }
    
    /**
     * @dev Emergency function to update reward contract
     */
    function updateRewardContract(uint256 campaignId, address newRewardContract) external onlyOwner validVault(campaignId) {
        require(newRewardContract != address(0), "Invalid reward contract");
        vaultConfigs[campaignId].rewardContract = newRewardContract;
    }
}