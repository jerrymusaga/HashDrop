// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HashDropCampaign is Ownable(msg.sender), ReentrancyGuard {
    uint256 private _campaignIdCounter;
    
    enum CampaignStatus { CREATED, ACTIVE, PAUSED, ENDED }
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
        uint256 remainingBudget;
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
    
    function createCampaign(
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
        
        uint256 campaignId = _campaignIdCounter++;
        
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
        campaign.crossChainEnabled = supportedChainIds.length > 1;
        campaign.supportedChainIds = supportedChainIds;
        
        // Set default thresholds if not provided
        campaign.scoreThresholds[0] = scoreThresholds.length > 0 ? scoreThresholds[0] : 50;
        campaign.scoreThresholds[1] = scoreThresholds.length > 1 ? scoreThresholds[1] : 70;
        campaign.scoreThresholds[2] = scoreThresholds.length > 2 ? scoreThresholds[2] : 85;
        
        hashtagToCampaignId[hashtag] = campaignId;
        creatorCampaigns[msg.sender].push(campaignId);
        
        emit CampaignCreated(campaignId, hashtag, msg.sender, campaign.startTime, campaign.endTime);
        return campaignId;
    }
    
    function registerVault(
        uint256 campaignId,
        uint256 chainId,
        address vault
    ) external onlyCampaignCreator(campaignId) {
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
    ) external {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.creator == msg.sender || msg.sender == owner(),
            "Unauthorized"
        );
        require(campaign.id != 0, "Campaign does not exist");
        
        campaign.status = newStatus;
        emit CampaignStatusChanged(campaignId, newStatus);
    }
    
    function recordParticipation(
        uint256 campaignId,
        address participant,
        uint256 score
    ) external onlyOwner nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.id != 0, "Campaign does not exist");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(
            block.timestamp >= campaign.startTime && 
            block.timestamp <= campaign.endTime,
            "Campaign not active"
        );
        require(!campaign.hasParticipated[participant], "Already participated");
        
        campaign.hasParticipated[participant] = true;
        campaign.participantCount++;
        
        emit ParticipationRecorded(campaignId, participant, score);
    }
    
    function getCampaignCoreInfo(uint256 campaignId) external view returns (
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

    function getCampaignFinancialInfo(uint256 campaignId) external view returns (
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

    
    function getCampaignChainInfo(uint256 campaignId) external view returns (
        uint256[] memory supportedChainIds,
        bool crossChainEnabled
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.supportedChainIds,
            campaign.crossChainEnabled
        );
    }
    
    function getVaultAddress(uint256 campaignId, uint256 chainId) external view returns (address) {
        return campaigns[campaignId].chainVaults[chainId];
    }
    
    function hasUserParticipated(uint256 campaignId, address user) external view returns (bool) {
        return campaigns[campaignId].hasParticipated[user];
    }
    
    function getScoreThresholds(uint256 campaignId) external view returns (
        uint256 bronze,
        uint256 silver,
        uint256 gold
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.scoreThresholds[0],
            campaign.scoreThresholds[1],
            campaign.scoreThresholds[2]
        );
    }
}