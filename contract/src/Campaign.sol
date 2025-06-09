// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HashDropCampaign is Ownable, ReentrancyGuard {
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
        mapping(address => bool) hasParticipated;
        mapping(address => uint256) participantScores;
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
        uint256 endTime,
        address rewardContract
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

    /**
     * @dev Create a new campaign with flexible NFT tier configuration
     * @param hashtag Unique hashtag for the campaign
     * @param description Campaign description
     * @param duration Campaign duration in seconds
     * @param rewardType Type of reward (NFT or TOKEN)
     * @param rewardContract Address of the reward contract (HashDropNFT for NFT campaigns)
     * @param totalBudget Total budget allocated for rewards
     * @param supportedChainIds Array of supported chain IDs for cross-chain functionality
     */
    function createCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
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
        campaign.participantCount = 0;
        campaign.crossChainEnabled = supportedChainIds.length > 1;
        campaign.supportedChainIds = supportedChainIds;
        
        hashtagToCampaignId[hashtag] = campaignId;
        creatorCampaigns[msg.sender].push(campaignId);
        
        emit CampaignCreated(
            campaignId, 
            hashtag, 
            msg.sender, 
            campaign.startTime, 
            campaign.endTime,
            rewardContract
        );
        
        return campaignId;
    }
    
    /**
     * @dev Register a vault for a specific chain
     */
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
    
    /**
     * @dev Set campaign status
     */
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
    
    /**
     * @dev Record user participation with their score
     */
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
        campaign.participantScores[participant] = score;
        campaign.participantCount++;
        
        emit ParticipationRecorded(campaignId, participant, score);
    }
    
    /**
     * @dev Get core campaign information
     */
    function getCampaignInfo(uint256 campaignId) external view validCampaign(campaignId) returns (
        uint256 id,
        string memory hashtag,
        string memory description,
        address creator,
        uint256 startTime,
        uint256 endTime,
        CampaignStatus status,
        RewardType rewardType,
        address rewardContract
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
            campaign.rewardType,
            campaign.rewardContract
        );
    }

    /**
     * @dev Get campaign financial information
     */
    function getCampaignFinancials(uint256 campaignId) external view validCampaign(campaignId) returns (
        uint256 totalBudget,
        uint256 remainingBudget,
        uint256 participantCount,
        bool crossChainEnabled
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.totalBudget,
            campaign.remainingBudget,
            campaign.participantCount,
            campaign.crossChainEnabled
        );
    }

    /**
     * @dev Get supported chain information
     */
    function getCampaignChains(uint256 campaignId) external view validCampaign(campaignId) returns (
        uint256[] memory supportedChainIds,
        bool crossChainEnabled
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.supportedChainIds,
            campaign.crossChainEnabled
        );
    }
    
    /**
     * @dev Get vault address for a specific chain
     */
    function getVaultAddress(uint256 campaignId, uint256 chainId) external view validCampaign(campaignId) returns (address) {
        return campaigns[campaignId].chainVaults[chainId];
    }
    
    /**
     * @dev Check if user has participated in campaign
     */
    function hasUserParticipated(uint256 campaignId, address user) external view validCampaign(campaignId) returns (bool) {
        return campaigns[campaignId].hasParticipated[user];
    }
    
    /**
     * @dev Get user's score for a campaign
     */
    function getUserScore(uint256 campaignId, address user) external view validCampaign(campaignId) returns (uint256) {
        require(campaigns[campaignId].hasParticipated[user], "User has not participated");
        return campaigns[campaignId].participantScores[user];
    }
    
    /**
     * @dev Get campaigns created by a specific address
     */
    function getCreatorCampaigns(address creator) external view returns (uint256[] memory) {
        return creatorCampaigns[creator];
    }
    
    /**
     * @dev Get campaign ID by hashtag
     */
    function getCampaignByHashtag(string memory hashtag) external view returns (uint256) {
        uint256 campaignId = hashtagToCampaignId[hashtag];
        require(campaignId != 0, "Campaign not found");
        return campaignId;
    }
    
    /**
     * @dev Update campaign budget (only creator or owner)
     */
    function updateCampaignBudget(
        uint256 campaignId,
        uint256 newTotalBudget
    ) external validCampaign(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.creator == msg.sender || msg.sender == owner(),
            "Unauthorized"
        );
        require(newTotalBudget >= campaign.totalBudget - campaign.remainingBudget, "Cannot reduce below spent amount");
        
        uint256 difference = newTotalBudget - campaign.totalBudget;
        campaign.totalBudget = newTotalBudget;
        campaign.remainingBudget += difference;
    }
    
    /**
     * @dev Reduce remaining budget when rewards are claimed
     */
    function consumeBudget(uint256 campaignId, uint256 amount) external validCampaign(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.chainVaults[block.chainid] == msg.sender, "Only registered vault can consume budget");
        require(campaign.remainingBudget >= amount, "Insufficient budget");
        
        campaign.remainingBudget -= amount;
    }
}