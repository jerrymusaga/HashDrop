// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HashDropCampaign is Ownable, ReentrancyGuard {
    uint256 public campaignCounter;
    
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
        address rewardContract;
        uint256 totalBudget;
        uint256 participantCount;
        bool crossChainEnabled;
    }
    
    struct Participation {
        address user;
        uint256 score; // 0-100, set by off-chain AI
        uint256 timestamp;
        bool rewarded;
    }
    
    // Storage
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => Participation)) public participation;
    mapping(uint256 => address[]) public campaignParticipants;
    mapping(string => uint256) public hashtagToCampaign;
    
    // Events
    event CampaignCreated(uint256 indexed campaignId, string hashtag, address creator);
    event ParticipationRecorded(uint256 indexed campaignId, address indexed user, uint256 score);
    event CampaignStatusChanged(uint256 indexed campaignId, CampaignStatus status);
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Create a new campaign
     */
    function createCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration, // in seconds
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
        bool crossChainEnabled
    ) external returns (uint256) {
        require(bytes(hashtag).length > 0, "Hashtag required");
        require(hashtagToCampaign[hashtag] == 0, "Hashtag already used");
        require(duration > 0, "Invalid duration");
        
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
            crossChainEnabled: crossChainEnabled
        });
        
        hashtagToCampaign[hashtag] = campaignId;
        
        emit CampaignCreated(campaignId, hashtag, msg.sender);
        return campaignId;
    }
    
    /**
     * @dev Record user participation with AI-generated score
     * This will be called by off-chain system after AI analysis
     */
    function recordParticipation(
        uint256 campaignId,
        address user,
        uint256 score // 0-100 from AI analysis
    ) external onlyOwner nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(block.timestamp <= campaign.endTime, "Campaign ended");
        require(score <= 100, "Invalid score");
        require(participation[campaignId][user].user == address(0), "Already participated");
        
        participation[campaignId][user] = Participation({
            user: user,
            score: score,
            timestamp: block.timestamp,
            rewarded: false
        });
        
        campaignParticipants[campaignId].push(user);
        campaign.participantCount++;
        
        emit ParticipationRecorded(campaignId, user, score);
    }
    
    /**
     * @dev Batch record multiple participations (for cost efficiency)
     */
    function batchRecordParticipation(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external onlyOwner nonReentrant {
        require(users.length == scores.length, "Array length mismatch");
        require(users.length > 0, "Empty arrays");
        
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign not found");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(block.timestamp <= campaign.endTime, "Campaign ended");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (participation[campaignId][users[i]].user == address(0) && scores[i] <= 100) {
                participation[campaignId][users[i]] = Participation({
                    user: users[i],
                    score: scores[i],
                    timestamp: block.timestamp,
                    rewarded: false
                });
                
                campaignParticipants[campaignId].push(users[i]);
                campaign.participantCount++;
                
                emit ParticipationRecorded(campaignId, users[i], scores[i]);
            }
        }
    }
    
    /**
     * @dev Mark user as rewarded
     */
    function markAsRewarded(uint256 campaignId, address user) external {
        require(
            msg.sender == campaigns[campaignId].rewardContract || 
            msg.sender == owner(),
            "Unauthorized"
        );
        participation[campaignId][user].rewarded = true;
    }
    
    /**
     * @dev Get campaign info
     */
    function getCampaignInfo(uint256 campaignId) external view returns (
        string memory hashtag,
        string memory description,
        address creator,
        uint256 startTime,
        uint256 endTime,
        CampaignStatus status,
        RewardType rewardType,
        uint256 participantCount
    ) {
        Campaign memory campaign = campaigns[campaignId];
        return (
            campaign.hashtag,
            campaign.description,
            campaign.creator,
            campaign.startTime,
            campaign.endTime,
            campaign.status,
            campaign.rewardType,
            campaign.participantCount
        );
    }
    
    /**
     * @dev Get user participation
     */
    function getUserParticipation(uint256 campaignId, address user) external view returns (
        uint256 score,
        uint256 timestamp,
        bool rewarded
    ) {
        Participation memory p = participation[campaignId][user];
        return (p.score, p.timestamp, p.rewarded);
    }
    
    /**
     * @dev Get all participants for batch processing
     */
    function getCampaignParticipants(uint256 campaignId) external view returns (address[] memory) {
        return campaignParticipants[campaignId];
    }
    
    /**
     * @dev Update campaign status
     */
    function setCampaignStatus(uint256 campaignId, CampaignStatus status) external {
        require(
            msg.sender == campaigns[campaignId].creator || 
            msg.sender == owner(),
            "Unauthorized"
        );
        campaigns[campaignId].status = status;
        emit CampaignStatusChanged(campaignId, status);
    }
}