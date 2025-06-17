// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IHashDrop
 * @dev Interface definitions for HashDrop platform contracts
 */

interface IHashDropCampaign {
    enum CampaignStatus { ACTIVE, PAUSED, ENDED }
    enum RewardType { NFT, TOKEN }
    
    function createCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        RewardType rewardType,
        address rewardContract,
        uint256 totalBudget,
        uint256[] memory supportedChains,
        bool premiumMonitoring
    ) external payable returns (uint256);
    
    function batchRecordParticipation(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external payable;
    
    function markAsRewarded(uint256 campaignId, address user) external;
    function hasUserParticipated(uint256 campaignId, address user) external view returns (bool);
    function getUserParticipation(uint256 campaignId, address user) external view returns (uint256, uint256, bool);
    function getCampaignParticipants(uint256 campaignId) external view returns (address[] memory);
    function calculateCampaignCost(uint256 chainCount, bool premiumMonitoring) external pure returns (uint256);
}

interface IHashDropRewards {
    function configureCampaignRewards(
        uint256 campaignId,
        bool isNFT,
        uint256[] memory minScores,
        uint256[] memory maxSupplies,
        string[] memory names,
        string[] memory imageURIs,
        uint256[] memory tokenAmounts
    ) external;
    
    function mintReward(address to, uint256 campaignId, uint256 userScore) external returns (bool);
    function batchMintRewards(address[] memory users, uint256 campaignId, uint256[] memory scores) external returns (uint256);
    function getQualifiedTier(uint256 campaignId, uint256 score) external view returns (uint256, bool);
    function hasUserClaimed(uint256 campaignId, address user) external view returns (bool);
    function tierAvailable(uint256 campaignId, uint256 tierId) external view returns (bool);
    function setMinterAuthorization(address minter, bool authorized) external;
}

interface IHashDropVault {
    function createBatchRewardRequest(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external returns (uint256);
    
    function processBatch(uint256 batchId) external;
    function processIndividualReward(uint256 campaignId, address user, uint256 score) external;
    function getPendingBatches() external view returns (uint256[] memory);
    function getBatchInfo(uint256 batchId) external view returns (uint256, uint256, bool, uint256, uint256, bool, bool);
}

interface IHashDropVRF {
    enum SelectionType { LIMITED_REWARDS, TIER_UPGRADE, PREMIUM_SELECTION, VERIFICATION }
    
    function requestLimitedRewardSelection(
        uint256 campaignId,
        address[] memory qualifiedParticipants,
        uint256 availableRewards
    ) external returns (uint256);
    
    function requestTierUpgrades(
        uint256 campaignId,
        address[] memory eligibleUsers,
        uint256 upgradeCount
    ) external returns (uint256);
    
    function getSelectionResults(uint256 selectionId) external view returns (
        uint256, address[] memory, address[] memory, uint256[] memory, bool, SelectionType, uint256
    );
    
    function isSelectionNeeded(uint256 campaignId) external view returns (bool, uint256, uint256);
}