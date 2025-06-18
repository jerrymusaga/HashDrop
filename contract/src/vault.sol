// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title HashDropVault  
 * @dev Batch processing and reward distribution with Chainlink Automation
 */
contract HashDropVault is Ownable, ReentrancyGuard, AutomationCompatibleInterface {
    
    // Contract references
    address public campaignContract;
    address public rewardsContract; // Now points to HashDropRewardsManager
    
    struct BatchRequest {
        uint256 campaignId;
        address[] users;
        uint256[] scores;
        bool processed;
        uint256 timestamp;
        uint256 successCount; // Number of successful rewards
        bool vrfSelectionNeeded; // Whether VRF selection is needed
        uint256 vrfRequestId; // VRF request ID if applicable
    }
    
    struct VaultStats {
        uint256 totalBatches;
        uint256 totalRewardsDistributed;
        uint256 totalParticipants;
        uint256 averageBatchSize;
        uint256 lastProcessingTime;
    }
    
    // Storage
    mapping(uint256 => BatchRequest) public batchRequests;
    uint256 public batchCounter;
    VaultStats public vaultStats;
    
    // Batch processing configuration
    uint256 public constant BATCH_SIZE_THRESHOLD = 10; // Process when 10+ users
    uint256 public constant BATCH_TIME_THRESHOLD = 1 hours; // Or after 1 hour
    uint256 public constant MAX_BATCH_SIZE = 100; // Maximum users per batch
    uint256 public constant CHECK_INTERVAL = 300; // 5 minutes between automation checks
    
    uint256 public lastUpkeepTime;
    address public vrfContract; // VRF contract for fair selection
    
    // Events
    event BatchRequestCreated(
        uint256 indexed batchId, 
        uint256 indexed campaignId, 
        uint256 userCount,
        bool vrfNeeded
    );
    event BatchProcessed(
        uint256 indexed batchId, 
        uint256 successCount, 
        uint256 totalUsers,
        uint256 processingTime
    );
    event IndividualRewardProcessed(
        uint256 indexed campaignId, 
        address indexed user, 
        uint256 score,
        bool success
    );
    event VRFSelectionRequested(
        uint256 indexed batchId, 
        uint256 qualified, 
        uint256 available
    );
    event ContractsUpdated(address campaignContract, address rewardsContract);
    event VRFContractUpdated(address vrfContract);
    
    modifier validContracts() {
        require(campaignContract != address(0), "Campaign contract not set");
        require(rewardsContract != address(0), "Rewards contract not set");
        _;
    }
    
    /**
     * @dev Constructor sets initial contract references
     * @param _campaignContract Address of HashDropCampaign contract
     * @param _rewardsContract Address of HashDropRewardsManager contract
     */
    constructor(address _campaignContract, address _rewardsContract) Ownable(msg.sender) {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_rewardsContract != address(0), "Invalid rewards contract");
        
        campaignContract = _campaignContract;
        rewardsContract = _rewardsContract;
        lastUpkeepTime = block.timestamp;
    }
    
    /**
     * @dev Create batch reward request with automatic processing logic
     */
    function createBatchRewardRequest(
        uint256 campaignId,
        address[] memory users,
        uint256[] memory scores
    ) external onlyOwner validContracts returns (uint256) {
        require(users.length == scores.length, "Array length mismatch");
        require(users.length > 0, "Empty batch not allowed");
        require(users.length <= MAX_BATCH_SIZE, "Batch size too large");
        
        uint256 batchId = ++batchCounter;
        
        // Check if VRF selection might be needed (this would be implemented with VRF contract)
        bool vrfNeeded = _checkIfVRFNeeded(campaignId, users.length);
        
        batchRequests[batchId] = BatchRequest({
            campaignId: campaignId,
            users: users,
            scores: scores,
            processed: false,
            timestamp: block.timestamp,
            successCount: 0,
            vrfSelectionNeeded: vrfNeeded,
            vrfRequestId: 0
        });
        
        // Update stats
        vaultStats.totalBatches++;
        vaultStats.totalParticipants += users.length;
        _updateAverageBatchSize();
        
        emit BatchRequestCreated(batchId, campaignId, users.length, vrfNeeded);
        
        // Auto-process if threshold met and no VRF needed
        if (users.length >= BATCH_SIZE_THRESHOLD && !vrfNeeded) {
            _processBatchInternal(batchId);
        }
        
        return batchId;
    }
    
    /**
     * @dev Process a specific batch (manual trigger or automation)
     */
    function processBatch(uint256 batchId) external {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        
        BatchRequest storage batch = batchRequests[batchId];
        require(!batch.processed, "Batch already processed");
        
        // Check if batch is ready for processing
        bool sizeReady = batch.users.length >= BATCH_SIZE_THRESHOLD;
        bool timeReady = block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD;
        
        require(sizeReady || timeReady, "Batch not ready for processing");
        require(!batch.vrfSelectionNeeded, "VRF selection pending");
        
        _processBatchInternal(batchId);
    }
    
    /**
     * @dev Internal batch processing logic
     */
    function _processBatchInternal(uint256 batchId) internal nonReentrant {
        BatchRequest storage batch = batchRequests[batchId];
        require(!batch.processed, "Batch already processed");
        
        uint256 startTime = block.timestamp;
        batch.processed = true;
        
        // Call rewards manager to batch mint
        (bool success, bytes memory returnData) = rewardsContract.call(
            abi.encodeWithSignature(
                "batchMintRewards(address[],uint256,uint256[])",
                batch.users,
                batch.campaignId,
                batch.scores
            )
        );
        
        uint256 successCount = 0;
        if (success && returnData.length > 0) {
            successCount = abi.decode(returnData, (uint256));
        }
        
        batch.successCount = successCount;
        
        // Mark users as rewarded in campaign contract
        for (uint256 i = 0; i < batch.users.length; i++) {
            try this.markUserRewardedExternal(batch.campaignId, batch.users[i]) {} catch {
                // Continue if marking fails
            }
        }
        
        // Update stats
        vaultStats.totalRewardsDistributed += successCount;
        vaultStats.lastProcessingTime = block.timestamp;
        
        uint256 processingTime = block.timestamp - startTime;
        
        emit BatchProcessed(batchId, successCount, batch.users.length, processingTime);
    }
    
    /**
     * @dev Process individual reward (for urgent cases or small batches)
     */
    function processIndividualReward(
        uint256 campaignId,
        address user,
        uint256 score
    ) external onlyOwner validContracts nonReentrant {
        require(user != address(0), "Invalid user address");
        require(score <= 100, "Invalid score");
        
        // Call rewards manager to mint reward
        (bool success,) = rewardsContract.call(
            abi.encodeWithSignature(
                "mintReward(address,uint256,uint256)",
                user,
                campaignId,
                score
            )
        );
        
        if (success) {
            // Mark user as rewarded
            try this.markUserRewardedExternal(campaignId, user) {} catch {}
            
            vaultStats.totalRewardsDistributed++;
        }
        
        emit IndividualRewardProcessed(campaignId, user, score, success);
    }
    
    /**
     * @dev External function to mark user as rewarded (for try-catch)
     */
    function markUserRewardedExternal(uint256 campaignId, address user) external {
        require(msg.sender == address(this), "Internal function only");
        
        (bool success,) = campaignContract.call(
            abi.encodeWithSignature(
                "markAsRewarded(uint256,address)",
                campaignId,
                user
            )
        );
        
        require(success, "Failed to mark user as rewarded");
    }
    
    /**
     * @dev Chainlink Automation - Check if upkeep is needed
     */
    function checkUpkeep(bytes calldata checkData) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) 
    {
        // Silence unused parameter warning
        checkData;
        
        // Check if enough time has passed since last upkeep
        if (block.timestamp < lastUpkeepTime + CHECK_INTERVAL) {
            return (false, "");
        }
        
        // Find batches ready for processing
        uint256[] memory readyBatches = new uint256[](batchCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= batchCounter; i++) {
            BatchRequest storage batch = batchRequests[i];
            
            if (!batch.processed && !batch.vrfSelectionNeeded) {
                bool sizeReady = batch.users.length >= BATCH_SIZE_THRESHOLD;
                bool timeReady = block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD;
                
                if (sizeReady || timeReady) {
                    readyBatches[count] = i;
                    count++;
                }
            }
        }
        
        upkeepNeeded = count > 0;
        
        if (upkeepNeeded) {
            // Resize array to actual count
            uint256[] memory batchesToProcess = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                batchesToProcess[i] = readyBatches[i];
            }
            performData = abi.encode(batchesToProcess);
        }
    }
    
    /**
     * @dev Chainlink Automation - Perform upkeep
     */
    function performUpkeep(bytes calldata performData) external override {
        uint256[] memory batchIds = abi.decode(performData, (uint256[]));
        
        for (uint256 i = 0; i < batchIds.length; i++) {
            uint256 batchId = batchIds[i];
            
            if (batchId > 0 && batchId <= batchCounter) {
                BatchRequest storage batch = batchRequests[batchId];
                
                // Double-check batch is ready and not processed
                if (!batch.processed && !batch.vrfSelectionNeeded) {
                    bool sizeReady = batch.users.length >= BATCH_SIZE_THRESHOLD;
                    bool timeReady = block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD;
                    
                    if (sizeReady || timeReady) {
                        try this.processBatchExternal(batchId) {} catch {
                            // Continue with next batch if one fails
                        }
                    }
                }
            }
        }
        
        lastUpkeepTime = block.timestamp;
    }
    
    /**
     * @dev External wrapper for batch processing (for try-catch in performUpkeep)
     */
    function processBatchExternal(uint256 batchId) external {
        require(msg.sender == address(this), "Internal function only");
        _processBatchInternal(batchId);
    }
    
    /**
     * @dev Get pending batches that can be processed
     */
    function getPendingBatches() external view returns (uint256[] memory) {
        uint256[] memory pending = new uint256[](batchCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= batchCounter; i++) {
            BatchRequest storage batch = batchRequests[i];
            
            if (!batch.processed && !batch.vrfSelectionNeeded) {
                bool sizeReady = batch.users.length >= BATCH_SIZE_THRESHOLD;
                bool timeReady = block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD;
                
                if (sizeReady || timeReady) {
                    pending[count] = i;
                    count++;
                }
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pending[i];
        }
        
        return result;
    }
    
    /**
     * @dev Get batch information
     */
    function getBatchInfo(uint256 batchId) external view returns (
        uint256 campaignId,
        uint256 userCount,
        bool processed,
        uint256 timestamp,
        uint256 successCount,
        bool readyForProcessing,
        bool vrfSelectionNeeded
    ) {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        
        BatchRequest storage batch = batchRequests[batchId];
        
        bool sizeReady = batch.users.length >= BATCH_SIZE_THRESHOLD;
        bool timeReady = block.timestamp >= batch.timestamp + BATCH_TIME_THRESHOLD;
        bool ready = !batch.processed && !batch.vrfSelectionNeeded && (sizeReady || timeReady);
        
        return (
            batch.campaignId,
            batch.users.length,
            batch.processed,
            batch.timestamp,
            batch.successCount,
            ready,
            batch.vrfSelectionNeeded
        );
    }
    
    /**
     * @dev Get vault statistics
     */
    function getVaultStats() external view returns (
        uint256 totalBatches,
        uint256 totalRewardsDistributed,
        uint256 totalParticipants,
        uint256 averageBatchSize,
        uint256 lastProcessingTime,
        uint256 pendingBatches
    ) {
        // Count pending batches
        uint256 pending = 0;
        for (uint256 i = 1; i <= batchCounter; i++) {
            if (!batchRequests[i].processed) {
                pending++;
            }
        }
        
        return (
            vaultStats.totalBatches,
            vaultStats.totalRewardsDistributed,
            vaultStats.totalParticipants,
            vaultStats.averageBatchSize,
            vaultStats.lastProcessingTime,
            pending
        );
    }
    
    /**
     * @dev Update contract addresses (owner only)
     */
    function updateContracts(address _campaignContract, address _rewardsContract) external onlyOwner {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_rewardsContract != address(0), "Invalid rewards contract");
        
        campaignContract = _campaignContract;
        rewardsContract = _rewardsContract;
        
        emit ContractsUpdated(_campaignContract, _rewardsContract);
    }
    
    /**
     * @dev Set VRF contract address (for future VRF integration)
     */
    function setVRFContract(address _vrfContract) external onlyOwner {
        vrfContract = _vrfContract;
        emit VRFContractUpdated(_vrfContract);
    }
    
    /**
     * @dev Check if VRF selection is needed (placeholder for VRF integration)
     */
    function _checkIfVRFNeeded(uint256 campaignId, uint256 participantCount) internal view returns (bool) {
        // Placeholder logic - in full implementation, this would check:
        // 1. Campaign reward supply vs participant count
        // 2. Whether VRF contract is set and campaign configured for fair selection
        // 3. If limited rewards require random selection
        
        campaignId; // Silence unused parameter warning
        participantCount; // Silence unused parameter warning
        
        return false; // For now, no VRF selection needed
    }
    
    /**
     * @dev Update average batch size calculation
     */
    function _updateAverageBatchSize() internal {
        if (vaultStats.totalBatches > 0) {
            vaultStats.averageBatchSize = vaultStats.totalParticipants / vaultStats.totalBatches;
        }
    }
    
    /**
     * @dev Emergency function to process stuck batch (owner only)
     */
    function emergencyProcessBatch(uint256 batchId) external onlyOwner {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        require(!batchRequests[batchId].processed, "Batch already processed");
        
        _processBatchInternal(batchId);
    }
    
    /**
     * @dev Get batch users and scores (for debugging)
     */
    function getBatchData(uint256 batchId) external view onlyOwner returns (
        address[] memory users,
        uint256[] memory scores
    ) {
        require(batchId > 0 && batchId <= batchCounter, "Invalid batch ID");
        
        BatchRequest storage batch = batchRequests[batchId];
        return (batch.users, batch.scores);
    }
}