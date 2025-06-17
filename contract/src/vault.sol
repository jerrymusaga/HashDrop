// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "chainlink-brownie-contracts/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Campaign.sol";
import "./Rewards.sol";

contract HashDropVault is Ownable, ReentrancyGuard, AutomationCompatibleInterface {
    HashDropCampaign public campaignContract;
    HashDropRewards public rewardsContract;

    // Automation config
    uint256 public constant CHECK_INTERVAL = 1 hours;
    uint256 public lastUpkeepTime;
    
    struct BatchRequest {
        uint256 campaignId;
        address[] users;
        uint256[] scores;
        bool processed;
        uint256 timestamp;
    }
    
    mapping(uint256 => BatchRequest) public batchRequests;
    uint256 public batchCounter;
    
    // Batch processing config
    uint256 public constant BATCH_SIZE_THRESHOLD = 10; // Process when 10+ users
    uint256 public constant BATCH_TIME_THRESHOLD = 1 hours; // Or process after 1 hour
    
    event BatchRequestCreated(uint256 indexed batchId, uint256 campaignId, uint256 userCount);
    event BatchProcessed(uint256 indexed batchId, uint256 successCount);
    event RewardDistributed(uint256 indexed campaignId, address indexed user, uint256 tierId);
    
    constructor(address _campaignContract, address _rewardsContract) Ownable(msg.sender) {
        campaignContract = HashDropCampaign(_campaignContract);
        rewardsContract = HashDropRewards(_rewardsContract);
    }
    
    /**
     * @dev Create batch reward request - automatically processes if threshold met
     */
    function createBatchRewardRequest(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external onlyOwner returns (uint256) {
        require(users.length == scores.length, "Array length mismatch");
        require(users.length > 0, "Empty batch");
        
        uint256 batchId = ++batchCounter;
        
        batchRequests[batchId] = BatchRequest({
            campaignId: campaignId,
            users: users,
            scores: scores,
            processed: false,
            timestamp: block.timestamp
        });
        
        emit BatchRequestCreated(batchId, campaignId, users.length);
        
        // Auto-process if threshold met
        if (users.length >= BATCH_SIZE_THRESHOLD) {
            _processBatch(batchId);
        }
        
        return batchId;
    }
    
    /**
     * @dev Process batch manually or by automation
     */
    function processBatch(uint256 batchId) external {
        BatchRequest storage batch = batchRequests[batchId];
        require(!batch.processed, "Batch already processed");
        require(
            batch.users.length >= BATCH_SIZE_THRESHOLD ||
            block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD,
            "Batch not ready for processing"
        );
        
        _processBatch(batchId);
    }
    
    /**
     * @dev Internal batch processing
     */
    function _processBatch(uint256 batchId) internal nonReentrant {
        BatchRequest storage batch = batchRequests[batchId];
        require(!batch.processed, "Batch already processed");
        
        batch.processed = true;
        
        uint256 successCount = rewardsContract.batchMintRewards(
            batch.users,
            batch.campaignId,
            batch.scores
        );
        
        // Mark users as rewarded in campaign contract
        for (uint256 i = 0; i < batch.users.length; i++) {
            try campaignContract.markAsRewarded(batch.campaignId, batch.users[i]) {} catch {}
        }
        
        emit BatchProcessed(batchId, successCount);
    }
    
    /**
     * @dev Process individual reward (for immediate processing)
     */
    function processIndividualReward(
        uint256 campaignId,
        address user,
        uint256 score
    ) external onlyOwner nonReentrant {
        bool success = rewardsContract.mintReward(user, campaignId, score);
        require(success, "Reward minting failed");
        
        campaignContract.markAsRewarded(campaignId, user);
        
        // Get tier info for event
        (uint256 tierId,) = rewardsContract.getQualifiedTier(campaignId, score);
        emit RewardDistributed(campaignId, user, tierId);
    }
    
    /**
     * @dev Get pending batches that can be processed
     */
    function getPendingBatches() external view returns (uint256[] memory) {
        uint256[] memory pending = new uint256[](batchCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= batchCounter; i++) {
            BatchRequest storage batch = batchRequests[i];
            if (!batch.processed && (
                batch.users.length >= BATCH_SIZE_THRESHOLD ||
                block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD
            )) {
                pending[count] = i;
                count++;
            }
        }
        
        // Resize array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pending[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get batch info
     */
    function getBatchInfo(uint256 batchId) external view returns (
        uint256 campaignId,
        uint256 userCount,
        bool processed,
        uint256 timestamp,
        bool readyForProcessing
    ) {
        BatchRequest storage batch = batchRequests[batchId];
        return (
            batch.campaignId,
            batch.users.length,
            batch.processed,
            batch.timestamp,
            !batch.processed && (
                batch.users.length >= BATCH_SIZE_THRESHOLD ||
                block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD
            )
        );
    }
    
    /**
     * @dev Update contract addresses
     */
    function updateContracts(address _campaignContract, address _rewardsContract) external onlyOwner {
        campaignContract = HashDropCampaign(_campaignContract);
        rewardsContract = HashDropRewards(_rewardsContract);
    }

    /**
     * @dev Chainlink Automation - Check if upkeep is needed
     */
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // Check if there are batches ready for processing
        uint256[] memory pendingBatches = new uint256[](batchCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= batchCounter; i++) {
            BatchRequest storage batch = batchRequests[i];
            if (!batch.processed && (
                batch.users.length >= BATCH_SIZE_THRESHOLD ||
                block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD
            )) {
                pendingBatches[count] = i;
                count++;
            }
        }
        
        upkeepNeeded = count > 0 && (block.timestamp - lastUpkeepTime) >= CHECK_INTERVAL;
        
        // Return batch IDs to process
        uint256[] memory batchesToProcess = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            batchesToProcess[i] = pendingBatches[i];
        }
        
        performData = abi.encode(batchesToProcess);
    }
    
    /**
     * @dev Chainlink Automation - Perform upkeep
     */
    function performUpkeep(bytes calldata performData) external override {
        uint256[] memory batchIds = abi.decode(performData, (uint256[]));
        
        for (uint256 i = 0; i < batchIds.length; i++) {
            if (batchIds[i] > 0 && batchIds[i] <= batchCounter) {
                try this.processBatch(batchIds[i]) {} catch {}
            }
        }
        
        lastUpkeepTime = block.timestamp;
    }
}