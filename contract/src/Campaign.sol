// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract HashDropCampaign is Ownable, ReentrancyGuard {
    uint256 public campaignCounter;
    
    // Platform Fee Configuration (in AVAX)
    uint256 public constant CAMPAIGN_CREATION_FEE = 0.1 ether; // 0.1 AVAX per campaign
    uint256 public constant PER_PARTICIPANT_FEE = 0.01 ether; // 0.01 AVAX per participant
    uint256 public constant CROSS_CHAIN_FEE = 0.3 ether; // 0.3 AVAX per additional chain
    uint256 public constant PREMIUM_MONITORING_FEE = 1 ether; // 1 AVAX for premium AI
    
    address public platformTreasury;
    uint256 public totalPlatformFees;
    
    enum CampaignStatus { ACTIVE, PAUSED, ENDED }
    enum RewardType { NFT, TOKEN }
    
    struct Campaign {
        uint256 id;
        string hashtag; 
        string description;
        address creator;
        uint256 startTime;
        uint256 endTime;
        CampaignStatus status;
        RewardType rewardType;
        address rewardContract; // HashDropRewards contract address
        uint256 totalBudget;
        uint256 participantCount;
        bool crossChainEnabled;
        uint256[] supportedChains;
        uint256 platformFeesCollected;
        bool premiumMonitoring;
    }
    
    struct Participation {
        address user;
        uint256 score; // 0-100, set by off-chain AI after analysis
        uint256 timestamp;
        bool rewarded; // Has user claimed their reward?
    }
    
    // Storage mappings
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => Participation)) public participation;
    mapping(uint256 => address[]) public campaignParticipants;
    mapping(string => uint256) public hashtagToCampaign; // hashtag => campaignId
    
    // Events
    event CampaignCreated(
        uint256 indexed campaignId, 
        string hashtag, 
        address indexed creator, 
        uint256 totalCost
    );
    event ParticipationRecorded(
        uint256 indexed campaignId, 
        address indexed user, 
        uint256 score
    );
    event PlatformFeesCollected(
        uint256 indexed campaignId, 
        uint256 amount, 
        string feeType
    );
    event FeesWithdrawn(address treasury, uint256 amount);
    event CampaignStatusChanged(uint256 indexed campaignId, CampaignStatus status);
    
    /**
     * @dev Constructor sets the platform treasury address
     * @param _platformTreasury Address where platform fees are collected
     */
    constructor(address _platformTreasury) Ownable(msg.sender) {
        require(_platformTreasury != address(0), "Invalid treasury address");
        platformTreasury = _platformTreasury;
    }
    
    function createCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
        uint256[] memory supportedChains,
        bool premiumMonitoring
    ) external payable returns (uint256) {
        require(bytes(hashtag).length > 0, "Hashtag cannot be empty");
        require(hashtagToCampaign[hashtag] == 0, "Hashtag already in use");
        require(duration > 0, "Duration must be positive");
        require(rewardContract != address(0), "Invalid reward contract");
        require(supportedChains.length > 0, "Must support at least one chain");
        
        // Calculate total platform fees required
        uint256 totalFees = CAMPAIGN_CREATION_FEE;
        
        // Add cross-chain fees (first chain is free)
        if (supportedChains.length > 1) {
            totalFees += (supportedChains.length - 1) * CROSS_CHAIN_FEE;
        }
        
        // Add premium monitoring fee
        if (premiumMonitoring) {
            totalFees += PREMIUM_MONITORING_FEE;
        }
        
        require(msg.value >= totalFees, "Insufficient platform fees");
        
        // Create new campaign
        uint256 campaignId = ++campaignCounter;
        
        campaigns[campaignId] = Campaign({
            id: campaignId,
            hashtag: hashtag,
            description: description,
            creator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            status: CampaignStatus.ACTIVE,
            rewardType: rewardType,
            rewardContract: rewardContract,
            totalBudget: totalBudget,
            participantCount: 0,
            crossChainEnabled: supportedChains.length > 1,
            supportedChains: supportedChains,
            platformFeesCollected: totalFees,
            premiumMonitoring: premiumMonitoring
        });
        
        // Map hashtag to campaign ID for easy lookup
        hashtagToCampaign[hashtag] = campaignId;
        totalPlatformFees += totalFees;
        
        // Refund excess payment
        if (msg.value > totalFees) {
            payable(msg.sender).transfer(msg.value - totalFees);
        }
        
        emit CampaignCreated(campaignId, hashtag, msg.sender, totalFees);
        emit PlatformFeesCollected(campaignId, totalFees, "creation");
        
        return campaignId;
    }
    
    /**
     * @dev Calculate the cost to create a campaign (for frontend display)
     * @param chainCount Number of chains to support
     * @param premiumMonitoring Whether to enable premium monitoring
     * @return totalCost Total cost in AVAX (wei)
     */
    function calculateCampaignCost(
        uint256 chainCount,
        bool premiumMonitoring
    ) external pure returns (uint256 totalCost) {
        totalCost = CAMPAIGN_CREATION_FEE;
        
        if (chainCount > 1) {
            totalCost += (chainCount - 1) * CROSS_CHAIN_FEE;
        }
        
        if (premiumMonitoring) {
            totalCost += PREMIUM_MONITORING_FEE;
        }
        
        return totalCost;
    }
    
    /**
     * @dev Record participation for multiple users (called by backend/owner)
     * @param campaignId The campaign ID
     * @param users Array of user addresses
     * @param scores Array of AI-generated scores (0-100)
     */
    function batchRecordParticipation(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external payable onlyOwner nonReentrant {
        require(users.length == scores.length, "Array length mismatch");
        require(users.length > 0, "Empty arrays");
        
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(block.timestamp <= campaign.endTime, "Campaign has ended");
        
        uint256 newParticipants = 0;
        
        // Process each participant
        for (uint256 i = 0; i < users.length; i++) {
            // Skip if user already participated or invalid score
            if (participation[campaignId][users[i]].user == address(0) && scores[i] <= 100) {
                participation[campaignId][users[i]] = Participation({
                    user: users[i],
                    score: scores[i],
                    timestamp: block.timestamp,
                    rewarded: false
                });
                
                campaignParticipants[campaignId].push(users[i]);
                campaign.participantCount++;
                newParticipants++;
                
                emit ParticipationRecorded(campaignId, users[i], scores[i]);
            }
        }
        
        // Collect per-participant fees
        uint256 participantFees = newParticipants * PER_PARTICIPANT_FEE;
        if (participantFees > 0) {
            require(msg.value >= participantFees, "Insufficient participant fees");
            campaign.platformFeesCollected += participantFees;
            totalPlatformFees += participantFees;
            
            emit PlatformFeesCollected(campaignId, participantFees, "participants");
            
            // Refund excess payment
            if (msg.value > participantFees) {
                payable(msg.sender).transfer(msg.value - participantFees);
            }
        }
    }
    
    /**
     * @dev Record single participation (for testing or individual processing)
     * @param campaignId The campaign ID
     * @param user User address
     * @param score AI-generated score (0-100)
     */
    function recordParticipation(
        uint256 campaignId,
        address user,
        uint256 score
    ) external payable onlyOwner nonReentrant {
        require(score <= 100, "Score must be 0-100");
        
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(block.timestamp <= campaign.endTime, "Campaign has ended");
        require(participation[campaignId][user].user == address(0), "User already participated");
        
        // Record participation
        participation[campaignId][user] = Participation({
            user: user,
            score: score,
            timestamp: block.timestamp,
            rewarded: false
        });
        
        campaignParticipants[campaignId].push(user);
        campaign.participantCount++;
        
        // Collect participant fee
        require(msg.value >= PER_PARTICIPANT_FEE, "Insufficient participant fee");
        campaign.platformFeesCollected += PER_PARTICIPANT_FEE;
        totalPlatformFees += PER_PARTICIPANT_FEE;
        
        // Refund excess
        if (msg.value > PER_PARTICIPANT_FEE) {
            payable(msg.sender).transfer(msg.value - PER_PARTICIPANT_FEE);
        }
        
        emit ParticipationRecorded(campaignId, user, score);
        emit PlatformFeesCollected(campaignId, PER_PARTICIPANT_FEE, "participant");
    }
    
    /**
     * @dev Mark a user as having received their reward (called by vault contract)
     * @param campaignId The campaign ID
     * @param user User address
     */
    function markAsRewarded(uint256 campaignId, address user) external {
        require(
            msg.sender == campaigns[campaignId].rewardContract || 
            msg.sender == owner(),
            "Unauthorized caller"
        );
        require(participation[campaignId][user].user != address(0), "User not found");
        
        participation[campaignId][user].rewarded = true;
    }
    
    function getCampaignInfo(uint256 campaignId) external view returns (
        string memory hashtag,
        string memory description,
        address creator,
        uint256 startTime,
        uint256 endTime,
        CampaignStatus status,
        RewardType rewardType,
        uint256 participantCount,
        uint256 platformFeesCollected
    ) {
        Campaign memory campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        
        return (
            campaign.hashtag,
            campaign.description,
            campaign.creator,
            campaign.startTime,
            campaign.endTime,
            campaign.status,
            campaign.rewardType,
            campaign.participantCount,
            campaign.platformFeesCollected
        );
    }
    
   
    function getUserParticipation(uint256 campaignId, address user) external view returns (
        uint256 score,
        uint256 timestamp,
        bool rewarded
    ) {
        Participation memory p = participation[campaignId][user];
        return (p.score, p.timestamp, p.rewarded);
    }
    
    /**
     * @dev Get all participants for a campaign (for batch processing)
     * @param campaignId The campaign ID
     * @return Array of participant addresses
     */
    function getCampaignParticipants(uint256 campaignId) external view returns (address[] memory) {
        return campaignParticipants[campaignId];
    }
    
    /**
     * @dev Get campaign ID by hashtag
     * @param hashtag The hashtag to look up
     * @return The campaign ID
     */
    function getCampaignByHashtag(string memory hashtag) external view returns (uint256) {
        uint256 campaignId = hashtagToCampaign[hashtag];
        require(campaignId != 0, "Campaign not found");
        return campaignId;
    }
    
    
    function hasUserParticipated(uint256 campaignId, address user) external view returns (bool) {
        return participation[campaignId][user].user != address(0);
    }
    
   
    function getCampaignChains(uint256 campaignId) external view returns (
        uint256[] memory supportedChains,
        bool crossChainEnabled
    ) {
        Campaign memory campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        
        return (campaign.supportedChains, campaign.crossChainEnabled);
    }
    
    /**
     * @dev Update campaign status (creator or owner only)
     * @param campaignId The campaign ID
     * @param status New status
     */
    function setCampaignStatus(uint256 campaignId, CampaignStatus status) external {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        require(
            msg.sender == campaign.creator || msg.sender == owner(),
            "Unauthorized"
        );
        
        campaign.status = status;
        emit CampaignStatusChanged(campaignId, status);
    }
    
    
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        payable(platformTreasury).transfer(balance);
        emit FeesWithdrawn(platformTreasury, balance);
    }
    
    
    function updatePlatformTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        platformTreasury = newTreasury;
    }
    
    
    function getCampaignCostBreakdown(
        uint256 chainCount,
        bool premiumMonitoring
    ) external pure returns (
        uint256 creationFee,
        uint256 crossChainFees,
        uint256 premiumFee,
        uint256 totalCost
    ) {
        creationFee = CAMPAIGN_CREATION_FEE;
        crossChainFees = chainCount > 1 ? (chainCount - 1) * CROSS_CHAIN_FEE : 0;
        premiumFee = premiumMonitoring ? PREMIUM_MONITORING_FEE : 0;
        totalCost = creationFee + crossChainFees + premiumFee;
        
        return (creationFee, crossChainFees, premiumFee, totalCost);
    }
    
    
    receive() external payable {
        // Contract can receive AVAX for fee payments
    }
}