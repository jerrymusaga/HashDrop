// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HashDropNFT} from "./NFT.sol";
import {HashDropCampaign} from "./Campaign.sol";
import {HashDropVault} from "./vault.sol";
import {HashDropOracle} from "./Oracle.sol";

/**
 * @title HashDropCampaignFactory with Oracle Integration
 * @dev Enhanced factory contract that includes Farcaster monitoring setup
 */
contract HashDropCampaignFactory is Ownable, ReentrancyGuard {
    
    struct CampaignSetupParams {
        // Campaign parameters
        string hashtag;
        string description;
        uint256 duration;
        uint256 totalBudget;
        uint256[] supportedChainIds;
        
        // NFT Tier configuration
        string[] tierNames;
        string[] baseURIs;
        uint256[] maxSupplies;
        uint256[] scoreThresholds;
        
        // Vault configuration
        uint256 totalRewards;
        
        // Oracle monitoring configuration
        uint256 monitoringInterval; // seconds between Farcaster checks
        bool enableMonitoring;
    }
    
    struct MultiTierConfig {
        string bronzeURI;
        string silverURI;
        string goldURI;
        string tierPrefix; // Optional prefix for tier names (e.g., campaign name)
    }
    
    struct ContractAddresses {
        address campaignContract;
        address nftContract;
        address vaultContract;
        address oracleContract;
    }
    
    ContractAddresses public contractAddresses;
    
    // Default monitoring interval (1 hour)
    uint256 public constant DEFAULT_MONITORING_INTERVAL = 3600;
    // Minimum monitoring interval (5 minutes)
    uint256 public constant MIN_MONITORING_INTERVAL = 300;
    
    // Track launched campaigns
    mapping(uint256 => address) public campaignCreators;
    mapping(address => uint256[]) public creatorCampaigns;
    uint256 public totalCampaignsLaunched;
    
    event CampaignLaunched(
        uint256 indexed campaignId,
        address indexed creator,
        string hashtag,
        uint256 tierCount,
        bool isMultiTier,
        bool monitoringEnabled
    );
    
    event ContractAddressesUpdated(
        address campaignContract,
        address nftContract,
        address vaultContract,
        address oracleContract
    );
    
    event MonitoringConfigured(
        uint256 indexed campaignId,
        string hashtag,
        uint256 interval,
        bool enabled
    );
    
    constructor(
        address _campaignContract,
        address _nftContract,
        address _vaultContract,
        address _oracleContract
    ) Ownable(msg.sender) {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_vaultContract != address(0), "Invalid vault contract");
        require(_oracleContract != address(0), "Invalid oracle contract");
        
        contractAddresses = ContractAddresses({
            campaignContract: _campaignContract,
            nftContract: _nftContract,
            vaultContract: _vaultContract,
            oracleContract: _oracleContract
        });
    }
    
    /**
     * @dev Launch a complete campaign with NFT tiers, vault, and Farcaster monitoring
     * @param params All campaign setup parameters bundled together
     * @return campaignId The created campaign ID
     */
    function launchCampaignWithMonitoring(
        CampaignSetupParams memory params
    ) public nonReentrant returns (uint256 campaignId) {
        
        // Validate input parameters
        _validateCampaignParams(params);
        
        // Get contract instances
        HashDropCampaign campaignContract = HashDropCampaign(contractAddresses.campaignContract);
        HashDropNFT nftContract = HashDropNFT(contractAddresses.nftContract);
        HashDropVault vaultContract = HashDropVault(contractAddresses.vaultContract);
        HashDropOracle oracleContract = HashDropOracle(contractAddresses.oracleContract);
        
        // Step 1: Create the campaign
        campaignId = campaignContract.createCampaign(
            params.hashtag,
            params.description,
            params.duration,
            HashDropCampaign.RewardType.NFT,
            contractAddresses.nftContract,
            params.totalBudget,
            params.supportedChainIds
        );
        
        // Step 2: Configure NFT tiers for the campaign
        nftContract.configureCampaign(
            campaignId,
            params.tierNames,
            params.baseURIs,
            params.maxSupplies,
            params.scoreThresholds
        );
        
        // Step 3: Configure vault for the campaign
        vaultContract.configureVault(
            campaignId,
            contractAddresses.campaignContract,
            contractAddresses.nftContract,
            params.totalRewards
        );
        
        // Step 4: Register vault in campaign contract for current chain
        campaignContract.registerVault(
            campaignId,
            block.chainid,
            contractAddresses.vaultContract
        );
        
        // Step 5: Set up Farcaster monitoring if enabled
        if (params.enableMonitoring) {
            uint256 interval = params.monitoringInterval > 0 ? params.monitoringInterval : DEFAULT_MONITORING_INTERVAL;
            
            oracleContract.startCampaignMonitoring(
                campaignId,
                params.hashtag,
                contractAddresses.campaignContract,
                interval
            );
        }
        
        // Step 6: Activate the campaign
        campaignContract.setCampaignStatus(
            campaignId,
            HashDropCampaign.CampaignStatus.ACTIVE
        );
        
        // Track campaign creation
        campaignCreators[campaignId] = msg.sender;
        creatorCampaigns[msg.sender].push(campaignId);
        totalCampaignsLaunched++;
        
        emit CampaignLaunched(
            campaignId,
            msg.sender,
            params.hashtag,
            params.tierNames.length,
            params.tierNames.length > 1,
            params.enableMonitoring
        );
        
        return campaignId;
    }
    
    /**
     * @dev Quick launch for Farcaster campaigns with automatic monitoring
     * @param hashtag Campaign hashtag (must include # symbol)
     * @param description Campaign description
     * @param duration Campaign duration in seconds
     * @param tierName Name of the single tier
     * @param baseURI Base URI for NFT metadata
     * @param maxSupply Maximum supply for the tier
     * @param totalBudget Total campaign budget
     * @param totalRewards Total rewards available
     * @param monitoringInterval How often to check Farcaster (in seconds)
     * @return campaignId The created campaign ID
     */
    function quickLaunchFarcasterCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        string memory tierName,
        string memory baseURI,
        uint256 maxSupply,
        uint256 totalBudget,
        uint256 totalRewards,
        uint256 monitoringInterval
    ) external nonReentrant returns (uint256 campaignId) {
        
        // Validate hashtag format for Farcaster
        require(_isValidHashtag(hashtag), "Invalid hashtag format - must start with #");
        
        // Create single-tier arrays
        string[] memory tierNames = new string[](1);
        string[] memory baseURIs = new string[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory scoreThresholds = new uint256[](1);
        uint256[] memory supportedChainIds = new uint256[](1);
        
        tierNames[0] = tierName;
        baseURIs[0] = baseURI;
        maxSupplies[0] = maxSupply;
        scoreThresholds[0] = 1; // Minimum score of 1 for single tier
        supportedChainIds[0] = block.chainid;
        
        CampaignSetupParams memory params = CampaignSetupParams({
            hashtag: hashtag,
            description: description,
            duration: duration,
            totalBudget: totalBudget,
            supportedChainIds: supportedChainIds,
            tierNames: tierNames,
            baseURIs: baseURIs,
            maxSupplies: maxSupplies,
            scoreThresholds: scoreThresholds,
            totalRewards: totalRewards,
            monitoringInterval: monitoringInterval,
            enableMonitoring: true
        });
        
        return this.launchCampaignWithMonitoring(params);
    }
    
    /**
     * @dev Launch flexible multi-tier Farcaster campaign with custom tier configuration
     * @param hashtag Campaign hashtag
     * @param description Campaign description  
     * @param duration Campaign duration in seconds
     * @param totalBudget Total campaign budget
     * @param totalRewards Total rewards available
     * @param monitoringInterval Monitoring check interval
     * @param tierNames Array of tier names (e.g., ["Supporter", "Champion"])
     * @param tierURIs Array of URIs for each tier
     * @param tierDistributions Array of percentage distributions (must sum to 100)
     * @param tierThresholds Array of score thresholds for each tier
     * @param tierPrefix Optional prefix for tier names
     * @return campaignId The created campaign ID
     */
    function launchMultiTierFarcasterCampaign(
        string memory hashtag,
        string memory description,
        uint256 duration,
        uint256 totalBudget,
        uint256 totalRewards,
        uint256 monitoringInterval,
        string[] memory tierNames,
        string[] memory tierURIs,
        uint256[] memory tierDistributions, // Percentages (e.g., [70, 30] for 70%/30% split)
        uint256[] memory tierThresholds,
        string memory tierPrefix
    ) external nonReentrant returns (uint256 campaignId) {
        
        require(_isValidHashtag(hashtag), "Invalid hashtag format");
        require(tierNames.length >= 1, "Must have at least 1 tier");
        require(tierNames.length <= 10, "Maximum 10 tiers allowed");
        require(
            tierNames.length == tierURIs.length && 
            tierURIs.length == tierDistributions.length && 
            tierDistributions.length == tierThresholds.length,
            "All tier arrays must have same length"
        );
        
        // Validate tier parameters
        uint256 totalDistribution = 0;
        for (uint256 i = 0; i < tierNames.length; i++) {
            require(bytes(tierNames[i]).length > 0, "Tier name cannot be empty");
            require(bytes(tierURIs[i]).length > 0, "Tier URI cannot be empty");
            require(tierDistributions[i] > 0, "Tier distribution must be positive");
            require(tierThresholds[i] <= 100, "Score threshold cannot exceed 100");
            totalDistribution += tierDistributions[i];
        }
        require(totalDistribution == 100, "Tier distributions must sum to 100");
        
        // Validate thresholds are ascending for multi-tier campaigns
        if (tierNames.length > 1) {
            for (uint256 i = 1; i < tierThresholds.length; i++) {
                require(tierThresholds[i-1] < tierThresholds[i], "Thresholds must be ascending");
            }
        }
        
        // Build tier configuration
        string[] memory finalTierNames = new string[](tierNames.length);
        string[] memory baseURIs = new string[](tierNames.length);
        uint256[] memory maxSupplies = new uint256[](tierNames.length);
        uint256[] memory scoreThresholds = new uint256[](tierNames.length);
        uint256[] memory supportedChainIds = new uint256[](1);
        
        // Use provided prefix or default to hashtag for tier names
        string memory prefix = bytes(tierPrefix).length > 0 ? 
            tierPrefix : 
            _removeHashSymbol(hashtag);
        
        for (uint256 i = 0; i < tierNames.length; i++) {
            finalTierNames[i] = string(abi.encodePacked(prefix, " ", tierNames[i]));
            baseURIs[i] = tierURIs[i];
            maxSupplies[i] = totalRewards * tierDistributions[i] / 100;
            scoreThresholds[i] = tierThresholds[i];
        }
        
        supportedChainIds[0] = block.chainid;
        
        CampaignSetupParams memory params = CampaignSetupParams({
            hashtag: hashtag,
            description: description,
            duration: duration,
            totalBudget: totalBudget,
            supportedChainIds: supportedChainIds,
            tierNames: finalTierNames,
            baseURIs: baseURIs,
            maxSupplies: maxSupplies,
            scoreThresholds: scoreThresholds,
            totalRewards: totalRewards,
            monitoringInterval: monitoringInterval,
            enableMonitoring: true
        });
        
        return this.launchCampaignWithMonitoring(params);
    }
    
    
    /**
     * @dev Enable monitoring for an existing campaign
     * @param campaignId The campaign ID
     * @param hashtag The hashtag to monitor
     * @param monitoringInterval Check interval in seconds
     */
    function enableCampaignMonitoring(
        uint256 campaignId,
        string memory hashtag,
        uint256 monitoringInterval
    ) external onlyOwner {
        require(_isValidHashtag(hashtag), "Invalid hashtag format");
        
        HashDropOracle oracleContract = HashDropOracle(contractAddresses.oracleContract);
        
        uint256 interval = monitoringInterval > 0 ? 
            monitoringInterval : DEFAULT_MONITORING_INTERVAL;
        
        oracleContract.startCampaignMonitoring(
            campaignId,
            hashtag,
            contractAddresses.campaignContract,
            interval
        );
        
        emit MonitoringConfigured(campaignId, hashtag, interval, true);
    }
    
    /**
     * @dev Disable monitoring for a campaign
     * @param campaignId The campaign ID
     */
    function disableCampaignMonitoring(uint256 campaignId) external onlyOwner {
        HashDropOracle oracleContract = HashDropOracle(contractAddresses.oracleContract);
        oracleContract.stopCampaignMonitoring(campaignId);
        
        emit MonitoringConfigured(campaignId, "", 0, false);
    }
    
    /**
     * @dev Get campaign monitoring status
     * @param campaignId The campaign ID
     */
    function getCampaignMonitoringStatus(uint256 campaignId) external view returns (
        string memory hashtag,
        bool active,
        uint256 lastUpdateTime,
        uint256 checkInterval,
        uint256 trackedUserCount
    ) {
        HashDropOracle oracleContract = HashDropOracle(contractAddresses.oracleContract);
        
        (
            hashtag,
            ,
            active,
            lastUpdateTime,
            checkInterval,
            ,
            trackedUserCount
        ) = oracleContract.getCampaignMonitorStatus(campaignId);
        
        return (hashtag, active, lastUpdateTime, checkInterval, trackedUserCount);
    }
    
    /**
     * @dev Update contract addresses (only owner)
     * @param _campaignContract New campaign contract address
     * @param _nftContract New NFT contract address
     * @param _vaultContract New vault contract address
     * @param _oracleContract New oracle contract address
     */
    function updateContractAddresses(
        address _campaignContract,
        address _nftContract,
        address _vaultContract,
        address _oracleContract
    ) external onlyOwner {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_vaultContract != address(0), "Invalid vault contract");
        require(_oracleContract != address(0), "Invalid oracle contract");
        
        contractAddresses.campaignContract = _campaignContract;
        contractAddresses.nftContract = _nftContract;
        contractAddresses.vaultContract = _vaultContract;
        contractAddresses.oracleContract = _oracleContract;
        
        emit ContractAddressesUpdated(
            _campaignContract,
            _nftContract,
            _vaultContract,
            _oracleContract
        );
    }
    
    /**
     * @dev Get campaigns created by a specific creator
     * @param creator The creator address
     * @return Array of campaign IDs created by the creator
     */
    function getCreatorCampaigns(address creator) external view returns (uint256[] memory) {
        return creatorCampaigns[creator];
    }
    
    /**
     * @dev Get campaign creator
     * @param campaignId The campaign ID
     * @return The address of the campaign creator
     */
    function getCampaignCreator(uint256 campaignId) external view returns (address) {
        return campaignCreators[campaignId];
    }
    
    /**
     * @dev Batch launch multiple campaigns
     * @param paramsList Array of campaign setup parameters
     * @return campaignIds Array of created campaign IDs
     */
    function batchLaunchCampaigns(
        CampaignSetupParams[] memory paramsList
    ) external nonReentrant returns (uint256[] memory campaignIds) {
        require(paramsList.length > 0, "No campaigns to launch");
        require(paramsList.length <= 10, "Maximum 10 campaigns per batch");
        
        campaignIds = new uint256[](paramsList.length);
        
        for (uint256 i = 0; i < paramsList.length; i++) {
            campaignIds[i] = this.launchCampaignWithMonitoring(paramsList[i]);
        }
        
        return campaignIds;
    }
    
    /**
     * @dev Get factory statistics
     * @return totalCampaigns Total campaigns launched
     * @return totalCreators Number of unique creators
     * @return contractAddrs Current contract addresses
     */
    function getFactoryStats() external view returns (
        uint256 totalCampaigns,
        uint256 totalCreators,
        ContractAddresses memory contractAddrs
    ) {
        // Note: totalCreators would require additional tracking in a real implementation
        return (totalCampaignsLaunched, 0, contractAddresses);
    }
    
    /**
     * @dev Remove # symbol from hashtag for use in tier names
     * @param hashtag The hashtag string
     * @return cleanTag The hashtag without the # symbol
     */
    function _removeHashSymbol(string memory hashtag) internal pure returns (string memory) {
        bytes memory hashtagBytes = bytes(hashtag);
        if (hashtagBytes.length > 0 && hashtagBytes[0] == bytes1("#")) {
            bytes memory result = new bytes(hashtagBytes.length - 1);
            for (uint256 i = 1; i < hashtagBytes.length; i++) {
                result[i - 1] = hashtagBytes[i];
            }
            return string(result);
        }
        return hashtag;
    }
    
    /**
     * @dev Validate hashtag format for Farcaster
     * @param hashtag The hashtag string to validate
     * @return isValid Whether the hashtag is valid
     */
    function _isValidHashtag(string memory hashtag) internal pure returns (bool) {
        bytes memory hashtagBytes = bytes(hashtag);
        
        // Must not be empty and must start with #
        if (hashtagBytes.length == 0 || hashtagBytes[0] != bytes1("#")) {
            return false;
        }
        
        // Must have content after #
        if (hashtagBytes.length == 1) {
            return false;
        }
        
        // Check for valid characters (alphanumeric + underscore)
        for (uint256 i = 1; i < hashtagBytes.length; i++) {
            bytes1 char = hashtagBytes[i];
            if (!(
                (char >= bytes1("a") && char <= bytes1("z")) ||
                (char >= bytes1("A") && char <= bytes1("Z")) ||
                (char >= bytes1("0") && char <= bytes1("9")) ||
                char == bytes1("_")
            )) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Internal validation function
     */
    function _validateCampaignParams(CampaignSetupParams memory params) internal pure {
        require(bytes(params.hashtag).length > 0, "Hashtag cannot be empty");
        require(params.duration > 0, "Duration must be positive");
        require(params.totalBudget > 0, "Budget must be positive");
        require(params.totalRewards > 0, "Total rewards must be positive");
        require(params.supportedChainIds.length > 0, "Must support at least one chain");
        
        require(params.tierNames.length > 0, "Must have at least one tier");
        require(params.tierNames.length <= 10, "Maximum 10 tiers allowed");
        require(
            params.tierNames.length == params.baseURIs.length && 
            params.baseURIs.length == params.maxSupplies.length && 
            params.maxSupplies.length == params.scoreThresholds.length,
            "Tier array lengths must match"
        );
        
        // Validate individual tier parameters
        for (uint256 i = 0; i < params.tierNames.length; i++) {
            require(bytes(params.tierNames[i]).length > 0, "Tier name cannot be empty");
            require(bytes(params.baseURIs[i]).length > 0, "Base URI cannot be empty");
            require(params.maxSupplies[i] > 0, "Max supply must be positive");
            require(params.scoreThresholds[i] <= 100, "Score threshold cannot exceed 100");
        }
        
        // For multi-tier campaigns, validate score thresholds are ascending
        if (params.tierNames.length > 1) {
            for (uint256 i = 1; i < params.scoreThresholds.length; i++) {
                require(
                    params.scoreThresholds[i-1] < params.scoreThresholds[i], 
                    "Score thresholds must be ascending"
                );
            }
        }
        
        // Validate monitoring parameters
        if (params.enableMonitoring) {
            require(
                params.monitoringInterval == 0 || params.monitoringInterval >= MIN_MONITORING_INTERVAL, 
                "Monitoring interval must be at least 5 minutes"
            );
        }
    }
    
    /**
     * @dev Emergency pause function
     */
    function emergencyPause() external onlyOwner {
        // In a real implementation, you might want to pause all active campaigns
        // This would require additional state management
    }
    
    /**
     * @dev Check if factory is properly configured
     * @return isConfigured Whether all contract addresses are set
     */
    function isFactoryConfigured() external view returns (bool isConfigured) {
        return (
            contractAddresses.campaignContract != address(0) &&
            contractAddresses.nftContract != address(0) &&
            contractAddresses.vaultContract != address(0) &&
            contractAddresses.oracleContract != address(0)
        );
    }
}