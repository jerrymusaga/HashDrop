// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HashDropNFT} from "./NFT.sol";
import {HashDropCampaign} from "./Campaign.sol";
import {HashDropVault} from "./vault.sol";
import {HashDropOracle} from "./Oracle.sol";

interface IHashDropCCIPManager {
    enum MessageType { PARTICIPATION, CLAIM_REWARD, SYNC_DATA }
    
    function configureChains(uint256[] calldata chainIds, uint64[] calldata chainSelectors) external;
    function allowlistSender(address _sender, bool allowed) external;
    function setFeeToken(address _feeToken) external;
    function getEstimatedFee(
        uint256 destinationChainId,
        MessageType msgType,
        uint256 campaignId,
        address user,
        uint256 score
    ) external view returns (uint256);
    function isChainSupported(uint256 chainId) external view returns (bool);
}

/**
 * @title HashDrop Campaign Factory - User-Friendly Version
 * @dev Simplified factory that handles all technical complexity for users
 */
contract HashDropCampaignFactory is Ownable, ReentrancyGuard {
    
    // Simplified user input - no technical CCIP details needed
    struct SimpleCampaignParams {
        string hashtag;              // #myhashtag
        string description;          // Campaign description
        uint256 durationDays;        // Duration in days (more user-friendly)
        uint256 nftRewardCount;      // How many NFTs to give out
        string nftName;              // NFT collection name
        string nftImageURL;          // Single image URL for NFTs
        bool enableMultiChain;       // Simple on/off for cross-chain
    }
    
    // Advanced users can still customize if needed
    struct AdvancedCampaignParams {
        SimpleCampaignParams basic;
        
        // Optional tier customization
        string[] tierNames;          // ["Bronze", "Silver", "Gold"] 
        string[] tierImageURLs;      // Different images per tier
        uint256[] tierDistribution;  // [70, 25, 5] = 70% bronze, 25% silver, 5% gold
        uint256[] tierThresholds;    // [1, 5, 20] = min engagement scores
        
        // Optional chain selection (defaults to popular chains)
        uint256[] specificChains;    // If empty, uses default popular chains
        
        // Optional monitoring settings
        uint256 monitoringHours;     // How often to check (defaults to 1 hour)
    }
    
    struct ContractAddresses {
        address campaignContract;
        address nftContract;
        address vaultContract;
        address oracleContract;
        address ccipManager;
        address feeToken;            // LINK token for CCIP fees
    }
    
    ContractAddresses public contractAddresses;
    
    // Default supported chains (popular L2s that users actually use)
    uint256[] public defaultSupportedChains;
    mapping(uint256 => bool) public supportedChains;
    
    // Cost calculation constants
    uint256 public constant BASE_COST_PER_NFT = 0.001 ether;      // Base cost per NFT
    uint256 public constant MULTICHAIN_MULTIPLIER = 150;          // 1.5x cost for multichain
    uint256 public constant MONITORING_COST_PER_DAY = 0.01 ether; // Daily monitoring cost
    
    // Default configurations
    uint256 public constant DEFAULT_MONITORING_HOURS = 1;
    uint256 public constant MAX_CAMPAIGN_DAYS = 365;
    uint256 public constant MIN_CAMPAIGN_DAYS = 1;
    uint256 public constant MAX_NFT_REWARDS = 10000;
    
    // Track campaigns
    mapping(uint256 => address) public campaignCreators;
    mapping(address => uint256[]) public creatorCampaigns;
    uint256 public totalCampaignsLaunched;
    
    event SimpleCampaignLaunched(
        uint256 indexed campaignId,
        address indexed creator,
        string hashtag,
        uint256 nftCount,
        bool multiChain,
        uint256 totalCost
    );
    
    event AdvancedCampaignLaunched(
        uint256 indexed campaignId,
        address indexed creator,
        string hashtag,
        uint256 tierCount,
        uint256[] chainIds,
        uint256 totalCost
    );
    
    constructor(
        address _campaignContract,
        address _nftContract,
        address _vaultContract,
        address _oracleContract,
        address _ccipManager,
        address _feeToken
    ) Ownable(msg.sender) {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_vaultContract != address(0), "Invalid vault contract");
        require(_oracleContract != address(0), "Invalid oracle contract");
        require(_ccipManager != address(0), "Invalid CCIP manager");
        require(_feeToken != address(0), "Invalid fee token");
        
        contractAddresses = ContractAddresses({
            campaignContract: _campaignContract,
            nftContract: _nftContract,
            vaultContract: _vaultContract,
            oracleContract: _oracleContract,
            ccipManager: _ccipManager,
            feeToken: _feeToken
        });
        
        // Set up default popular chains (Polygon, Arbitrum, Optimism, Base)
        _initializeDefaultChains();
    }
    
    /**
     * @dev Initialize default supported chains with popular L2s
     */
    function _initializeDefaultChains() internal {
        // Popular L2 chains that users actually use
        defaultSupportedChains = [
            137,    // Polygon
            42161,  // Arbitrum One  
            10,     // Optimism
            8453,   // Base
            43114   // Avalanche
        ];
        
        for (uint256 i = 0; i < defaultSupportedChains.length; i++) {
            supportedChains[defaultSupportedChains[i]] = true;
        }
    }
    
    /**
     * @dev Calculate total campaign cost for user
     * @param nftCount Number of NFTs to distribute
     * @param durationDays Campaign duration in days
     * @param multiChain Whether to enable multichain
     * @return totalCost Total cost in ETH
     */
    function calculateCampaignCost(
        uint256 nftCount,
        uint256 durationDays,
        bool multiChain
    ) public pure returns (uint256 totalCost) {
        require(nftCount > 0 && nftCount <= MAX_NFT_REWARDS, "Invalid NFT count");
        require(durationDays >= MIN_CAMPAIGN_DAYS && durationDays <= MAX_CAMPAIGN_DAYS, "Invalid duration");
        
        // Base cost: number of NFTs * base cost
        totalCost = nftCount * BASE_COST_PER_NFT;
        
        // Multichain premium (50% more)
        if (multiChain) {
            totalCost = totalCost * MULTICHAIN_MULTIPLIER / 100;
        }
        
        // Monitoring cost (daily)
        totalCost += durationDays * MONITORING_COST_PER_DAY;
        
        return totalCost;
    }
    
    /**
     * @dev Get cost estimate without creating campaign
     */
    function getCostEstimate(
        uint256 nftCount,
        uint256 durationDays,
        bool multiChain
    ) external pure returns (
        uint256 totalCost,
        uint256 nftCost,
        uint256 multichainPremium,
        uint256 monitoringCost
    ) {
        nftCost = nftCount * BASE_COST_PER_NFT;
        multichainPremium = multiChain ? (nftCost * 50 / 100) : 0;
        monitoringCost = durationDays * MONITORING_COST_PER_DAY;
        totalCost = nftCost + multichainPremium + monitoringCost;
        
        return (totalCost, nftCost, multichainPremium, monitoringCost);
    }
    
    /**
     * @dev Super simple campaign launch - just the essentials!
     * Users only need: hashtag, description, duration, NFT count, NFT name, image
     * Everything else is handled automatically
     */
    function launchSimpleCampaign(
        string memory hashtag,           // "#mycampaign"
        string memory description,       // "My awesome campaign"
        uint256 durationDays,           // 30 (days)
        uint256 nftRewardCount,         // 1000 (NFTs to give out)
        string memory nftName,          // "My Campaign NFT"
        string memory nftImageURL,      // "https://myimage.com/nft.png"
        bool enableMultiChain           // true/false
    ) external payable nonReentrant returns (uint256 campaignId) {
        
        // Validate inputs
        require(_isValidHashtag(hashtag), "Invalid hashtag - must start with # and contain only letters/numbers");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(nftName).length > 0, "NFT name cannot be empty");
        require(bytes(nftImageURL).length > 0, "NFT image URL cannot be empty");
        require(durationDays >= MIN_CAMPAIGN_DAYS && durationDays <= MAX_CAMPAIGN_DAYS, "Duration must be 1-365 days");
        require(nftRewardCount > 0 && nftRewardCount <= MAX_NFT_REWARDS, "NFT count must be 1-10,000");
        
        // Calculate required payment
        uint256 requiredCost = calculateCampaignCost(nftRewardCount, durationDays, enableMultiChain);
        require(msg.value >= requiredCost, "Insufficient payment");
        
        // Build campaign parameters automatically
        SimpleCampaignParams memory params = SimpleCampaignParams({
            hashtag: hashtag,
            description: description,
            durationDays: durationDays,
            nftRewardCount: nftRewardCount,
            nftName: nftName,
            nftImageURL: nftImageURL,
            enableMultiChain: enableMultiChain
        });
        
        // Launch the campaign with auto-configuration
        campaignId = _executeSimpleCampaignLaunch(params);
        
        // Refund excess payment
        if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value - requiredCost);
        }
        
        emit SimpleCampaignLaunched(
            campaignId,
            msg.sender,
            hashtag,
            nftRewardCount,
            enableMultiChain,
            requiredCost
        );
        
        return campaignId;
    }
    
    /**
     * @dev Advanced campaign launch for users who want more control
     */
    function launchAdvancedCampaign(
        AdvancedCampaignParams memory params
    ) external payable nonReentrant returns (uint256 campaignId) {
        
        // Validate basic parameters
        _validateAdvancedParams(params);
        
        // Calculate cost based on configuration
        uint256 totalNFTs = params.basic.nftRewardCount;
        bool isMultiChain = params.basic.enableMultiChain || params.specificChains.length > 1;
        uint256 requiredCost = calculateCampaignCost(totalNFTs, params.basic.durationDays, isMultiChain);
        
        require(msg.value >= requiredCost, "Insufficient payment");
        
        // Execute advanced campaign launch
        campaignId = _executeAdvancedCampaignLaunch(params);
        
        // Refund excess
        if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value - requiredCost);
        }
        
        // Determine final chain configuration
        uint256[] memory finalChains = params.specificChains.length > 0 ? 
            params.specificChains : 
            (isMultiChain ? defaultSupportedChains : _getCurrentChainArray());
        
        emit AdvancedCampaignLaunched(
            campaignId,
            msg.sender,
            params.basic.hashtag,
            params.tierNames.length > 0 ? params.tierNames.length : 1,
            finalChains,
            requiredCost
        );
        
        return campaignId;
    }
    
    /**
     * @dev Execute simple campaign launch with auto-configuration
     */
    function _executeSimpleCampaignLaunch(
        SimpleCampaignParams memory params
    ) internal returns (uint256 campaignId) {
        
        // Get contract instances
        HashDropCampaign campaignContract = HashDropCampaign(contractAddresses.campaignContract);
        HashDropNFT nftContract = HashDropNFT(contractAddresses.nftContract);
        HashDropVault vaultContract = HashDropVault(contractAddresses.vaultContract);
        HashDropOracle oracleContract = HashDropOracle(contractAddresses.oracleContract);
        
        // Determine chain configuration automatically
        uint256[] memory supportedChainIds = params.enableMultiChain ? 
            defaultSupportedChains : 
            _getCurrentChainArray();
        
        // Auto-configure CCIP if multichain
        if (params.enableMultiChain) {
            _autoConfigureCCIP();
        }
        
        // Create campaign with auto-calculated budget
        uint256 totalBudget = _calculateAutoBudget(params.nftRewardCount, params.durationDays);
        campaignId = campaignContract.createCampaign(
            params.hashtag,
            params.description,
            params.durationDays * 1 days, // Convert days to seconds
            HashDropCampaign.RewardType.NFT,
            contractAddresses.nftContract,
            totalBudget,
            supportedChainIds
        );
        
        // Configure single-tier NFT (most users want simple single NFT)
        string[] memory tierNames = new string[](1);
        string[] memory baseURIs = new string[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory scoreThresholds = new uint256[](1);
        
        tierNames[0] = params.nftName;
        baseURIs[0] = params.nftImageURL;
        maxSupplies[0] = params.nftRewardCount;
        scoreThresholds[0] = 1; // Anyone who participates gets NFT
        
        nftContract.configureCampaign(
            campaignId,
            tierNames,
            baseURIs,
            maxSupplies,
            scoreThresholds
        );
        
        // Configure vault
        vaultContract.configureVault(
            campaignId,
            contractAddresses.campaignContract,
            contractAddresses.nftContract,
            params.nftRewardCount
        );
        
        // Register vault on all chains
        for (uint256 i = 0; i < supportedChainIds.length; i++) {
            campaignContract.registerVault(
                campaignId,
                supportedChainIds[i],
                contractAddresses.vaultContract
            );
        }
        
        // Start automatic Farcaster monitoring
        oracleContract.startCampaignMonitoring(
            campaignId,
            params.hashtag,
            contractAddresses.campaignContract,
            DEFAULT_MONITORING_HOURS * 1 hours
        );
        
        // Activate campaign
        campaignContract.setCampaignStatus(
            campaignId,
            HashDropCampaign.CampaignStatus.ACTIVE
        );
        
        // Track campaign
        campaignCreators[campaignId] = msg.sender;
        creatorCampaigns[msg.sender].push(campaignId);
        totalCampaignsLaunched++;
        
        return campaignId;
    }
    
    /**
     * @dev Execute advanced campaign launch
     */
    function _executeAdvancedCampaignLaunch(
        AdvancedCampaignParams memory params
    ) internal returns (uint256 campaignId) {
        // Implementation similar to simple launch but with custom tiers, chains, etc.
        // This is for power users who want more control
        
        // Get contract instances
        HashDropCampaign campaignContract = HashDropCampaign(contractAddresses.campaignContract);
        HashDropNFT nftContract = HashDropNFT(contractAddresses.nftContract);
        HashDropVault vaultContract = HashDropVault(contractAddresses.vaultContract);
        HashDropOracle oracleContract = HashDropOracle(contractAddresses.oracleContract);
        
        // Use custom chains or defaults
        uint256[] memory supportedChainIds = params.specificChains.length > 0 ? 
            params.specificChains : 
            (params.basic.enableMultiChain ? defaultSupportedChains : _getCurrentChainArray());
        
        // Auto-configure CCIP for multichain
        if (supportedChainIds.length > 1) {
            _autoConfigureCCIP();
        }
        
        // Create campaign
        uint256 totalBudget = _calculateAutoBudget(params.basic.nftRewardCount, params.basic.durationDays);
        campaignId = campaignContract.createCampaign(
            params.basic.hashtag,
            params.basic.description,
            params.basic.durationDays * 1 days,
            HashDropCampaign.RewardType.NFT,
            contractAddresses.nftContract,
            totalBudget,
            supportedChainIds
        );
        
        // Configure tiers (custom or default)
        if (params.tierNames.length > 0) {
            // Use custom tier configuration
            _configureCustomTiers(campaignId, params, nftContract);
        } else {
            // Use simple single-tier configuration
            _configureSimpleTier(campaignId, params.basic, nftContract);
        }
        
        // Configure vault and monitoring (similar to simple launch)
        vaultContract.configureVault(
            campaignId,
            contractAddresses.campaignContract,
            contractAddresses.nftContract,
            params.basic.nftRewardCount
        );
        
        // Register vault on all chains
        for (uint256 i = 0; i < supportedChainIds.length; i++) {
            campaignContract.registerVault(
                campaignId,
                supportedChainIds[i],
                contractAddresses.vaultContract
            );
        }
        
        // Start monitoring with custom interval
        uint256 monitoringInterval = params.monitoringHours > 0 ? 
            params.monitoringHours * 1 hours : 
            DEFAULT_MONITORING_HOURS * 1 hours;
            
        oracleContract.startCampaignMonitoring(
            campaignId,
            params.basic.hashtag,
            contractAddresses.campaignContract,
            monitoringInterval
        );
        
        // Activate campaign
        campaignContract.setCampaignStatus(
            campaignId,
            HashDropCampaign.CampaignStatus.ACTIVE
        );
        
        // Track campaign
        campaignCreators[campaignId] = msg.sender;
        creatorCampaigns[msg.sender].push(campaignId);
        totalCampaignsLaunched++;
        
        return campaignId;
    }
    
    /**
     * @dev Auto-configure CCIP settings (hidden from users)
     */
    function _autoConfigureCCIP() internal {
        IHashDropCCIPManager ccipManager = IHashDropCCIPManager(contractAddresses.ccipManager);
        
        // Set LINK as fee token automatically
        ccipManager.setFeeToken(contractAddresses.feeToken);
        
        // Allow necessary contracts
        ccipManager.allowlistSender(address(this), true);
        ccipManager.allowlistSender(contractAddresses.campaignContract, true);
        ccipManager.allowlistSender(contractAddresses.vaultContract, true);
    }
    
    /**
     * @dev Calculate budget automatically based on NFT count and duration
     */
    function _calculateAutoBudget(uint256 nftCount, uint256 durationDays) internal pure returns (uint256) {
        // Simple budget calculation - in real implementation this would be more sophisticated
        return nftCount * 1000 + (durationDays * 100);
    }
    
    /**
     * @dev Get current chain as single-element array
     */
    function _getCurrentChainArray() internal view returns (uint256[] memory) {
        uint256[] memory currentChain = new uint256[](1);
        currentChain[0] = block.chainid;
        return currentChain;
    }
    
    /**
     * @dev Configure custom tiers for advanced users
     */
    function _configureCustomTiers(
        uint256 campaignId,
        AdvancedCampaignParams memory params,
        HashDropNFT nftContract
    ) internal {
        // Distribute NFTs according to tier percentages
        uint256[] memory maxSupplies = new uint256[](params.tierNames.length);
        for (uint256 i = 0; i < params.tierNames.length; i++) {
            maxSupplies[i] = params.basic.nftRewardCount * params.tierDistribution[i] / 100;
        }
        
        nftContract.configureCampaign(
            campaignId,
            params.tierNames,
            params.tierImageURLs.length > 0 ? params.tierImageURLs : _createDefaultImageArray(params.basic.nftImageURL, params.tierNames.length),
            maxSupplies,
            params.tierThresholds
        );
    }
    
    /**
     * @dev Configure simple single tier
     */
    function _configureSimpleTier(
        uint256 campaignId,
        SimpleCampaignParams memory params,
        HashDropNFT nftContract
    ) internal {
        string[] memory tierNames = new string[](1);
        string[] memory baseURIs = new string[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory scoreThresholds = new uint256[](1);
        
        tierNames[0] = params.nftName;
        baseURIs[0] = params.nftImageURL;
        maxSupplies[0] = params.nftRewardCount;
        scoreThresholds[0] = 1;
        
        nftContract.configureCampaign(
            campaignId,
            tierNames,
            baseURIs,
            maxSupplies,
            scoreThresholds
        );
    }
    
    /**
     * @dev Create default image array when user doesn't provide tier-specific images
     */
    function _createDefaultImageArray(string memory baseImage, uint256 length) internal pure returns (string[] memory) {
        string[] memory images = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            images[i] = baseImage;
        }
        return images;
    }
    
    /**
     * @dev Validate advanced campaign parameters
     */
    function _validateAdvancedParams(AdvancedCampaignParams memory params) internal view {
        // Validate basic params
        require(_isValidHashtag(params.basic.hashtag), "Invalid hashtag");
        require(bytes(params.basic.description).length > 0, "Description required");
        require(params.basic.durationDays >= MIN_CAMPAIGN_DAYS && params.basic.durationDays <= MAX_CAMPAIGN_DAYS, "Invalid duration");
        require(params.basic.nftRewardCount > 0 && params.basic.nftRewardCount <= MAX_NFT_REWARDS, "Invalid NFT count");
        
        // Validate tier configuration if provided
        if (params.tierNames.length > 0) {
            require(params.tierNames.length <= 10, "Max 10 tiers");
            require(params.tierDistribution.length == params.tierNames.length, "Tier arrays length mismatch");
            require(params.tierThresholds.length == params.tierNames.length, "Threshold array length mismatch");
            
            // Validate distribution sums to 100
            uint256 totalDistribution = 0;
            for (uint256 i = 0; i < params.tierDistribution.length; i++) {
                totalDistribution += params.tierDistribution[i];
            }
            require(totalDistribution == 100, "Tier distribution must sum to 100%");
        }
        
        // Validate specific chains if provided
        if (params.specificChains.length > 0) {
            require(params.specificChains.length <= 10, "Max 10 chains");
            for (uint256 i = 0; i < params.specificChains.length; i++) {
                require(supportedChains[params.specificChains[i]], "Unsupported chain");
            }
        }
    }
    
    /**
     * @dev Validate hashtag format
     */
    function _isValidHashtag(string memory hashtag) internal pure returns (bool) {
        bytes memory hashtagBytes = bytes(hashtag);
        
        if (hashtagBytes.length == 0 || hashtagBytes[0] != bytes1("#")) {
            return false;
        }
        
        if (hashtagBytes.length == 1) {
            return false;
        }
        
        // Check valid characters
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
    
    // ===== VIEW FUNCTIONS =====
    
    /**
     * @dev Get supported chains list
     */
    function getSupportedChains() external view returns (uint256[] memory) {
        return defaultSupportedChains;
    }
    
    /**
     * @dev Get user's campaigns
     */
    function getUserCampaigns(address user) external view returns (uint256[] memory) {
        return creatorCampaigns[user];
    }
    
    /**
     * @dev Check if chain is supported
     */
    function isChainSupported(uint256 chainId) external view returns (bool) {
        return supportedChains[chainId];
    }
    
    // ===== ADMIN FUNCTIONS =====
    
    /**
     * @dev Add supported chain (admin only)
     */
    function addSupportedChain(uint256 chainId) external onlyOwner {
        require(!supportedChains[chainId], "Chain already supported");
        supportedChains[chainId] = true;
        defaultSupportedChains.push(chainId);
    }
    
    /**
     * @dev Remove supported chain (admin only)
     */
    function removeSupportedChain(uint256 chainId) external onlyOwner {
        require(supportedChains[chainId], "Chain not supported");
        supportedChains[chainId] = false;
        
        // Remove from default array
        for (uint256 i = 0; i < defaultSupportedChains.length; i++) {
            if (defaultSupportedChains[i] == chainId) {
                defaultSupportedChains[i] = defaultSupportedChains[defaultSupportedChains.length - 1];
                defaultSupportedChains.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Update contract addresses (admin only)
     */
    function updateContractAddresses(
        address _campaignContract,
        address _nftContract,
        address _vaultContract,
        address _oracleContract,
        address _ccipManager,
        address _feeToken
    ) external onlyOwner {
        contractAddresses.campaignContract = _campaignContract;
        contractAddresses.nftContract = _nftContract;
        contractAddresses.vaultContract = _vaultContract;
        contractAddresses.oracleContract = _oracleContract;
        contractAddresses.ccipManager = _ccipManager;
        contractAddresses.feeToken = _feeToken;
    }
    
    /**
     * @dev Withdraw collected fees (admin only)
     */
    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Emergency pause (admin only)
     */
    function emergencyPause() external onlyOwner {
        // Implementation for emergency scenarios
    }
}