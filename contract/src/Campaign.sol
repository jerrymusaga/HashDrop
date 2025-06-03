// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HashDropCampaign is Ownable, ReentrancyGuard {
    uint256 private _campaignIdCounter;
    
    enum CampaignStatus { CREATED, ACTIVE, PAUSED, ENDED }
    enum RewardType { NFT, TOKEN }
    enum RewardMode { SIMPLE, TIERED }
    
    struct Campaign {
        uint256 id;
        string hashtag;
        string description;
        address creator;
        uint256 startTime;
        uint256 endTime;
        CampaignStatus status;
        RewardType rewardType;
        RewardMode rewardMode;
        address rewardContract;
        uint256 totalBudget;
        uint256 remainingBudget;
        uint256 minScore;
        mapping(uint256 => uint256) scoreThresholds;
        mapping(address => bool) hasParticipated;
        uint256 participantCount;
        bool crossChainEnabled;
        uint256[] supportedChainIds;
        mapping(uint256 => address) chainVaults;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(string => uint256) public hashtagToCampaignId;
    mapping(address => uint256[]) public creatorCampaigns;
    
    event CampaignCreated(
        uint256 indexed campaignId,
        string hashtag,
        address indexed creator,
        uint256 startTime,
        uint256 endTime
    );
    event CampaignStatusChanged(uint256 indexed campaignId, CampaignStatus newStatus);
    event VaultRegistered(uint256 indexed campaignId, uint256 chainId, address vault);
    event ParticipationRecorded(uint256 indexed campaignId, address indexed participant, uint256 score);
    
    modifier onlyCampaignCreator(uint256 campaignId) {
        require(campaigns[campaignId].creator == msg.sender, "Only campaign creator");
        _;
    }

    modifier validCampaign(uint256 campaignId) {
        require(campaigns[campaignId].id != 0, "Campaign does not exist");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function createSimpleCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
        uint256 minScore, 
        uint256[] memory supportedChainIds
    ) external returns (uint256) {
        require(bytes(hashtag).length > 0, "Hashtag cannot be empty");
        require(hashtagToCampaignId[hashtag] == 0, "Hashtag already in use");
        require(duration > 0, "Duration must be positive");
        require(rewardContract != address(0), "Invalid reward contract");
        require(minScore > 0 && minScore <= 100, "Invalid minimum score");
        require(supportedChainIds.length > 0, "Must support at least one chain");
        
        uint256 campaignId = _createBaseCampaign(
            hashtag, 
            description, 
            duration, 
            rewardType, 
            rewardContract, 
            totalBudget, 
            supportedChainIds
        );
        
        Campaign storage campaign = campaigns[campaignId];
        campaign.rewardMode = RewardMode.SIMPLE;
        campaign.minScore = minScore;
        
        return campaignId;
    }
    
    function createTieredCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
        uint256[] memory scoreThresholds,
        uint256[] memory supportedChainIds
    ) external returns (uint256) {
        require(bytes(hashtag).length > 0, "Hashtag cannot be empty");
        require(hashtagToCampaignId[hashtag] == 0, "Hashtag already in use");
        require(duration > 0, "Duration must be positive");
        require(rewardContract != address(0), "Invalid reward contract");
        require(supportedChainIds.length > 0, "Must support at least one chain");
        require(scoreThresholds.length >= 3, "Need bronze, silver, gold thresholds");
        require(scoreThresholds[0] < scoreThresholds[1] && scoreThresholds[1] < scoreThresholds[2], "Thresholds must be ascending");
        
        uint256 campaignId = _createBaseCampaign(
            hashtag, 
            description, 
            duration, 
            rewardType, 
            rewardContract, 
            totalBudget, 
            supportedChainIds
        );
        
        Campaign storage campaign = campaigns[campaignId];
        campaign.rewardMode = RewardMode.TIERED;
        
        // Set tier thresholds (bronze=0, silver=1, gold=2)
        campaign.scoreThresholds[0] = scoreThresholds[0];
        campaign.scoreThresholds[1] = scoreThresholds[1];
        campaign.scoreThresholds[2] = scoreThresholds[2];
        
        return campaignId;
    }

    function _createBaseCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
        uint256[] memory supportedChainIds
    ) internal returns (uint256) {
        uint256 campaignId = _campaignIdCounter;
        _campaignIdCounter++;
        
        Campaign storage campaign = campaigns[campaignId];
        campaign.id = campaignId;
        campaign.hashtag = hashtag;
        campaign.description = description;
        campaign.creator = msg.sender;
        campaign.startTime = block.timestamp;
        campaign.endTime = block.timestamp + duration;
        campaign.status = CampaignStatus.CREATED;
        campaign.rewardType = rewardType;
        campaign.rewardContract = rewardContract;
        campaign.totalBudget = totalBudget;
        campaign.remainingBudget = totalBudget;
        campaign.participantCount = 0;
        campaign.crossChainEnabled = supportedChainIds.length > 1;
        campaign.supportedChainIds = supportedChainIds;
        
        hashtagToCampaignId[hashtag] = campaignId;
        creatorCampaigns[msg.sender].push(campaignId);
        
        emit CampaignCreated(campaignId, hashtag, msg.sender, campaign.startTime, campaign.endTime);
        return campaignId;
    }
    
    function registerVault(
        uint256 campaignId,
        uint256 chainId,
        address vault
    ) external onlyCampaignCreator(campaignId) validCampaign(campaignId) {
        require(vault != address(0), "Invalid vault address");
        Campaign storage campaign = campaigns[campaignId];
        
        bool chainSupported = false;
        for (uint i = 0; i < campaign.supportedChainIds.length; i++) {
            if (campaign.supportedChainIds[i] == chainId) {
                chainSupported = true;
                break;
            }
        }
        require(chainSupported, "Chain not supported");
        
        campaign.chainVaults[chainId] = vault;
        emit VaultRegistered(campaignId, chainId, vault);
    }
    
    function setCampaignStatus(
        uint256 campaignId,
        CampaignStatus newStatus
    ) external validCampaign(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.creator == msg.sender || msg.sender == owner(),
            "Unauthorized"
        );
        
        campaign.status = newStatus;
        emit CampaignStatusChanged(campaignId, newStatus);
    }
    
    function recordParticipation(
        uint256 campaignId,
        address participant,
        uint256 score
    ) external onlyOwner nonReentrant validCampaign(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(
            block.timestamp >= campaign.startTime && 
            block.timestamp <= campaign.endTime,
            "Campaign not in active time window"
        );
        require(!campaign.hasParticipated[participant], "Already participated");
        require(score > 0 && score <= 100, "Invalid score range");
        
        campaign.hasParticipated[participant] = true;
        campaign.participantCount++;
        
        emit ParticipationRecorded(campaignId, participant, score);
    }
    
    function getCampaignCoreInfo(uint256 campaignId) external view validCampaign(campaignId) returns (
        uint256 id,
        string memory hashtag,
        string memory description,
        address creator,
        uint256 startTime,
        uint256 endTime,
        CampaignStatus status,
        RewardType rewardType
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.id,
            campaign.hashtag,
            campaign.description,
            campaign.creator,
            campaign.startTime,
            campaign.endTime,
            campaign.status,
            campaign.rewardType
        );
    }

    function getCampaignFinancialInfo(uint256 campaignId) external view validCampaign(campaignId) returns (
        address rewardContract,
        uint256 totalBudget,
        uint256 remainingBudget,
        uint256 participantCount,
        bool crossChainEnabled
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.rewardContract,
            campaign.totalBudget,
            campaign.remainingBudget,
            campaign.participantCount,
            campaign.crossChainEnabled
        );
    }

    function getCampaignChainInfo(uint256 campaignId) external view validCampaign(campaignId) returns (
        uint256[] memory supportedChainIds,
        bool crossChainEnabled
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.supportedChainIds,
            campaign.crossChainEnabled
        );
    }
    
    function getVaultAddress(uint256 campaignId, uint256 chainId) external view validCampaign(campaignId) returns (address) {
        return campaigns[campaignId].chainVaults[chainId];
    }
    
    function hasUserParticipated(uint256 campaignId, address user) external view validCampaign(campaignId) returns (bool) {
        return campaigns[campaignId].hasParticipated[user];
    }

    function getRewardMode(uint256 campaignId) external view validCampaign(campaignId) returns (RewardMode) {
        return campaigns[campaignId].rewardMode;
    }

    function getMinScore(uint256 campaignId) external view validCampaign(campaignId) returns (uint256) {
        require(campaigns[campaignId].rewardMode == RewardMode.SIMPLE, "Not a simple campaign");
        return campaigns[campaignId].minScore;
    }
    
    function getScoreThresholds(uint256 campaignId) external view validCampaign(campaignId) returns (
        uint256 bronze,
        uint256 silver,
        uint256 gold
    ) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.rewardMode == RewardMode.TIERED, "Not a tiered campaign");
        return (
            campaign.scoreThresholds[0],
            campaign.scoreThresholds[1],
            campaign.scoreThresholds[2]
        );
    }
}