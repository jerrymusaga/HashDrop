// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract HashDropVRF is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    VRFCoordinatorV2Interface COORDINATOR;
    
    // Avalanche VRF Configuration
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 300000;
    uint16 public requestConfirmations = 3;
    
    // Selection types
    enum SelectionType {
        LIMITED_REWARDS,    // More participants than rewards available
        TIER_UPGRADE,      // Random tier bonuses
        PREMIUM_SELECTION, // Special prize winners
        VERIFICATION       // Anti-sybil random checks
    }
    
    struct RandomSelection {
        uint256 campaignId;
        address[] candidates;
        uint256 winnersCount;
        SelectionType selectionType;
        bool fulfilled;
        uint256[] selectedIndices;
        address[] winners;
        uint256 timestamp;
        address requester; // Who requested the selection
        bytes32 vrfRequestId; // VRF request ID
    }
    
    // Storage
    mapping(uint256 => RandomSelection) public selections;
    mapping(bytes32 => uint256) public requestToSelection;
    uint256 public selectionCounter;
    
    // Contract references
    address public campaignContract;
    address public rewardsContract;
    address public vaultContract;
    
    // Events
    event RandomSelectionRequested(
        uint256 indexed selectionId, 
        uint256 indexed campaignId, 
        uint256 candidatesCount, 
        uint256 winnersCount,
        SelectionType selectionType
    );
    event RandomSelectionFulfilled(
        uint256 indexed selectionId, 
        address[] winners,
        uint256[] selectedIndices
    );
    event TierUpgradeSelected(uint256 indexed campaignId, address[] upgradeWinners);
    event PremiumWinnersSelected(uint256 indexed campaignId, address[] premiumWinners);
    event SelectionEmergencyResolved(uint256 indexed selectionId, address[] manualWinners);
    event VRFConfigUpdated(uint64 subscriptionId, bytes32 keyHash, uint32 gasLimit);
    
    /**
     * @dev Constructor sets up VRF configuration
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator VRF Coordinator address
     * @param _keyHash VRF key hash for gas lane
     * @param _campaignContract Campaign contract address
     * @param _rewardsContract Rewards contract address
     */
    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _campaignContract,
        address _rewardsContract
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        campaignContract = _campaignContract;
        rewardsContract = _rewardsContract;
    }
    
    /**
     * @dev Request random selection for limited reward campaigns
     * @param campaignId The campaign ID
     * @param qualifiedParticipants Array of qualified participant addresses
     * @param availableRewards Number of available rewards
     * @return selectionId The selection request ID
     */
    function requestLimitedRewardSelection(
        uint256 campaignId,
        address[] memory qualifiedParticipants,
        uint256 availableRewards
    ) external returns (uint256) {
        require(
            msg.sender == owner() || msg.sender == vaultContract,
            "Unauthorized requester"
        );
        require(qualifiedParticipants.length > availableRewards, "No selection needed");
        require(availableRewards > 0, "No rewards available");
        require(qualifiedParticipants.length <= 10000, "Too many candidates");
        
        uint256 selectionId = ++selectionCounter;
        
        // Store selection data
        RandomSelection storage selection = selections[selectionId];
        selection.campaignId = campaignId;
        selection.candidates = qualifiedParticipants;
        selection.winnersCount = availableRewards;
        selection.selectionType = SelectionType.LIMITED_REWARDS;
        selection.fulfilled = false;
        selection.timestamp = block.timestamp;
        selection.requester = msg.sender;
        
        // Request randomness from Chainlink VRF
        bytes32 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Only need 1 random word
        );
        
        selection.vrfRequestId = requestId;
        requestToSelection[requestId] = selectionId;
        
        emit RandomSelectionRequested(
            selectionId, 
            campaignId, 
            qualifiedParticipants.length, 
            availableRewards,
            SelectionType.LIMITED_REWARDS
        );
        
        return selectionId;
    }
    
    /**
     * @dev Request random tier upgrades (bonus feature)
     * @param campaignId The campaign ID
     * @param eligibleUsers Array of users eligible for upgrade
     * @param upgradeCount Number of users to upgrade
     * @return selectionId The selection request ID
     */
    function requestTierUpgrades(
        uint256 campaignId,
        address[] memory eligibleUsers,
        uint256 upgradeCount
    ) external onlyOwner returns (uint256) {
        require(eligibleUsers.length >= upgradeCount, "Not enough candidates");
        require(upgradeCount > 0, "Must upgrade at least one user");
        
        uint256 selectionId = ++selectionCounter;
        
        RandomSelection storage selection = selections[selectionId];
        selection.campaignId = campaignId;
        selection.candidates = eligibleUsers;
        selection.winnersCount = upgradeCount;
        selection.selectionType = SelectionType.TIER_UPGRADE;
        selection.fulfilled = false;
        selection.timestamp = block.timestamp;
        selection.requester = msg.sender;
        
        bytes32 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        
        selection.vrfRequestId = requestId;
        requestToSelection[requestId] = selectionId;
        
        emit RandomSelectionRequested(
            selectionId, 
            campaignId, 
            eligibleUsers.length, 
            upgradeCount,
            SelectionType.TIER_UPGRADE
        );
        
        return selectionId;
    }
    
    /**
     * @dev Chainlink VRF callback function
     * @param requestId The VRF request ID
     * @param randomWords Array of random words from VRF
     */
    function fulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) internal override {
        uint256 selectionId = requestToSelection[requestId];
        RandomSelection storage selection = selections[selectionId];
        
        require(!selection.fulfilled, "Selection already fulfilled");
        require(randomWords.length > 0, "No random words received");
        
        uint256 randomValue = randomWords[0];
        address[] memory candidates = selection.candidates;
        uint256 winnersNeeded = selection.winnersCount;
        
        // Perform Fisher-Yates shuffle for fair selection
        uint256[] memory indices = new uint256[](candidates.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            indices[i] = i;
        }
        
        // Shuffle indices using the random value
        for (uint256 i = 0; i < winnersNeeded; i++) {
            // Generate random index using keccak256 for additional entropy
            uint256 randomIndex = uint256(keccak256(abi.encode(randomValue, i, block.timestamp))) 
                % (candidates.length - i) + i;
            
            // Swap current position with random position
            uint256 temp = indices[i];
            indices[i] = indices[randomIndex];
            indices[randomIndex] = temp;
        }
        
        // Extract winners and their indices
        address[] memory winners = new address[](winnersNeeded);
        uint256[] memory selectedIndices = new uint256[](winnersNeeded);
        
        for (uint256 i = 0; i < winnersNeeded; i++) {
            selectedIndices[i] = indices[i];
            winners[i] = candidates[indices[i]];
        }
        
        // Store results
        selection.selectedIndices = selectedIndices;
        selection.winners = winners;
        selection.fulfilled = true;
        
        // Process the selection based on type
        if (selection.selectionType == SelectionType.LIMITED_REWARDS) {
            _processLimitedRewards(selection.campaignId, winners);
        } else if (selection.selectionType == SelectionType.TIER_UPGRADE) {
            _processTierUpgrades(selection.campaignId, winners);
            emit TierUpgradeSelected(selection.campaignId, winners);
        } else if (selection.selectionType == SelectionType.PREMIUM_SELECTION) {
            emit PremiumWinnersSelected(selection.campaignId, winners);
        }
        
        emit RandomSelectionFulfilled(selectionId, winners, selectedIndices);
        
        // Clean up request mapping
        delete requestToSelection[requestId];
    }
    
    /**
     * @dev Process limited reward distribution to selected winners
     * @param campaignId The campaign ID
     * @param winners Array of selected winner addresses
     */
    function _processLimitedRewards(uint256 campaignId, address[] memory winners) internal {
        for (uint256 i = 0; i < winners.length; i++) {
            // Get user's score from campaign contract
            (bool success, bytes memory data) = campaignContract.call(
                abi.encodeWithSignature(
                    "getUserParticipation(uint256,address)",
                    campaignId,
                    winners[i]
                )
            );
            
            if (success && data.length > 0) {
                (uint256 score,,) = abi.decode(data, (uint256, uint256, bool));
                
                // Mint reward for selected winner
                (bool mintSuccess,) = rewardsContract.call(
                    abi.encodeWithSignature(
                        "mintReward(address,uint256,uint256)",
                        winners[i],
                        campaignId,
                        score
                    )
                );
                
                // Mark as rewarded if successful
                if (mintSuccess) {
                    campaignContract.call(
                        abi.encodeWithSignature(
                            "markAsRewarded(uint256,address)",
                            campaignId,
                            winners[i]
                        )
                    );
                }
            }
        }
    }
    
    /**
     * @dev Process tier upgrades for selected winners
     * @param campaignId The campaign ID
     * @param winners Array of selected winner addresses
     */
    function _processTierUpgrades(uint256 campaignId, address[] memory winners) internal {
        for (uint256 i = 0; i < winners.length; i++) {
            // Upgrade to highest tier (score 100)
            (bool success,) = rewardsContract.call(
                abi.encodeWithSignature(
                    "mintReward(address,uint256,uint256)",
                    winners[i],
                    campaignId,
                    100 // Maximum score for highest tier
                )
            );
            
            if (success) {
                campaignContract.call(
                    abi.encodeWithSignature(
                        "markAsRewarded(uint256,address)",
                        campaignId,
                        winners[i]
                    )
                );
            }
        }
    }
    
    /**
     * @dev Get selection results
     * @param selectionId The selection ID
     * @return Selection details and results
     */
    function getSelectionResults(uint256 selectionId) external view returns (
        uint256 campaignId,
        address[] memory candidates,
        address[] memory winners,
        uint256[] memory selectedIndices,
        bool fulfilled,
        SelectionType selectionType,
        uint256 timestamp
    ) {
        RandomSelection storage selection = selections[selectionId];
        return (
            selection.campaignId,
            selection.candidates,
            selection.winners,
            selection.selectedIndices,
            selection.fulfilled,
            selection.selectionType,
            selection.timestamp
        );
    }
    
    /**
     * @dev Check if selection is needed for a campaign (helper function)
     * @param campaignId The campaign ID
     * @return needed Whether selection is needed
     * @return qualified Number of qualified participants
     * @return available Number of available rewards
     */
    function isSelectionNeeded(uint256 campaignId) external view returns (
        bool needed, 
        uint256 qualified, 
        uint256 available
    ) {
        // Get participants from campaign contract
        (bool success, bytes memory data) = campaignContract.staticcall(
            abi.encodeWithSignature("getCampaignParticipants(uint256)", campaignId)
        );
        
        if (!success) return (false, 0, 0);
        
        address[] memory participants = abi.decode(data, (address[]));
        uint256 qualifiedCount = 0;
        
        // Count qualified participants
        for (uint256 i = 0; i < participants.length; i++) {
            (bool scoreSuccess, bytes memory scoreData) = campaignContract.staticcall(
                abi.encodeWithSignature(
                    "getUserParticipation(uint256,address)",
                    campaignId,
                    participants[i]
                )
            );
            
            if (scoreSuccess && scoreData.length > 0) {
                (uint256 score,,) = abi.decode(scoreData, (uint256, uint256, bool));
                if (score > 0) qualifiedCount++;
            }
        }
        
        // Get available rewards (simplified - would need full integration)
        available = 100; // Placeholder - real implementation would check rewards contract
        
        needed = qualifiedCount > available && available > 0;
        return (needed, qualifiedCount, available);
    }
    
    /**
     * @dev Update VRF configuration (owner only)
     * @param _subscriptionId New subscription ID
     * @param _keyHash New key hash
     * @param _callbackGasLimit New gas limit
     * @param _requestConfirmations New confirmation count
     */
    function updateVRFConfig(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) external onlyOwner {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        
        emit VRFConfigUpdated(_subscriptionId, _keyHash, _callbackGasLimit);
    }
    
    /**
     * @dev Set contract addresses
     * @param _campaignContract Campaign contract address
     * @param _rewardsContract Rewards contract address
     * @param _vaultContract Vault contract address
     */
    function setContractAddresses(
        address _campaignContract,
        address _rewardsContract,
        address _vaultContract
    ) external onlyOwner {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_rewardsContract != address(0), "Invalid rewards contract");
        
        campaignContract = _campaignContract;
        rewardsContract = _rewardsContract;
        vaultContract = _vaultContract;
    }
    
    /**
     * @dev Emergency selection resolution (if VRF fails)
     * @param selectionId The selection ID
     * @param manualWinners Manually selected winners
     */
    function emergencyResolveSelection(
        uint256 selectionId,
        address[] memory manualWinners
    ) external onlyOwner {
        RandomSelection storage selection = selections[selectionId];
        require(!selection.fulfilled, "Selection already fulfilled");
        require(manualWinners.length == selection.winnersCount, "Wrong number of winners");
        require(block.timestamp > selection.timestamp + 1 hours, "Must wait 1 hour before emergency resolution");
        
        // Verify all manual winners are in the candidate list
        for (uint256 i = 0; i < manualWinners.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < selection.candidates.length; j++) {
                if (selection.candidates[j] == manualWinners[i]) {
                    found = true;
                    break;
                }
            }
            require(found, "Winner not in candidate list");
        }
        
        selection.winners = manualWinners;
        selection.fulfilled = true;
        
        // Process based on selection type
        if (selection.selectionType == SelectionType.LIMITED_REWARDS) {
            _processLimitedRewards(selection.campaignId, manualWinners);
        } else if (selection.selectionType == SelectionType.TIER_UPGRADE) {
            _processTierUpgrades(selection.campaignId, manualWinners);
        }
        
        emit SelectionEmergencyResolved(selectionId, manualWinners);
    }
    
    /**
     * @dev Get pending selections (not yet fulfilled)
     * @return Array of pending selection IDs
     */
    function getPendingSelections() external view returns (uint256[] memory) {
        uint256[] memory pending = new uint256[](selectionCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= selectionCounter; i++) {
            if (!selections[i].fulfilled) {
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
     * @dev Verify selection fairness (public verification)
     * @param selectionId The selection ID
     * @param randomWord The original random word used
     * @return verified Whether the selection can be independently verified
     */
    function verifySelection(uint256 selectionId, uint256 randomWord) external view returns (bool verified) {
        RandomSelection storage selection = selections[selectionId];
        require(selection.fulfilled, "Selection not fulfilled");
        
        // Recreate the selection process for verification
        uint256[] memory indices = new uint256[](selection.candidates.length);
        for (uint256 i = 0; i < selection.candidates.length; i++) {
            indices[i] = i;
        }
        
        // Perform same shuffle algorithm
        for (uint256 i = 0; i < selection.winnersCount; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encode(randomWord, i, selection.timestamp))) 
                % (selection.candidates.length - i) + i;
            
            uint256 temp = indices[i];
            indices[i] = indices[randomIndex];
            indices[randomIndex] = temp;
        }
        
        // Check if results match
        for (uint256 i = 0; i < selection.winnersCount; i++) {
            if (selection.selectedIndices[i] != indices[i]) {
                return false;
            }
        }
        
        return true;
    }
}