// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HashDropNFT} from "./NFT.sol";
import {HashDropCampaign} from "./Campaign.sol";
import {HashDropVault} from "./vault.sol";

/**
 * @title HashDropCampaignFactory
 * @dev Factory contract to bundle all campaign setup operations into a single transaction
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
    }
    
    struct ContractAddresses {
        address campaignContract;
        address nftContract;
        address vaultContract;
    }
    
    ContractAddresses public contractAddresses;
    
    event CampaignLaunched(
        uint256 indexed campaignId,
        address indexed creator,
        string hashtag,
        uint256 tierCount,
        bool isMultiTier
    );
    
    event ContractAddressesUpdated(
        address campaignContract,
        address nftContract,
        address vaultContract
    );
    
    constructor(
        address _campaignContract,
        address _nftContract,
        address _vaultContract
    ) Ownable(msg.sender) {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_vaultContract != address(0), "Invalid vault contract");
        
        contractAddresses = ContractAddresses({
            campaignContract: _campaignContract,
            nftContract: _nftContract,
            vaultContract: _vaultContract
        });
    }
    
    /**
     * @dev Launch a complete campaign with NFT tiers and vault in a single transaction
     * @param params All campaign setup parameters bundled together
     * @return campaignId The created campaign ID
     */
    function launchCampaign(
        CampaignSetupParams memory params
    ) public nonReentrant returns (uint256 campaignId) {
        
        // Validate input parameters
        _validateCampaignParams(params);
        
        // Get contract instances
        HashDropCampaign campaignContract = HashDropCampaign(contractAddresses.campaignContract);
        HashDropNFT nftContract = HashDropNFT(contractAddresses.nftContract);
        HashDropVault vaultContract = HashDropVault(contractAddresses.vaultContract);
        
        // Step 1: Create the campaign
        campaignId = campaignContract.createCampaign(
            params.hashtag,
            params.description,
            params.duration,
            HashDropCampaign.RewardType.NFT, // Always NFT for this factory
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
        
        // Step 5: Activate the campaign
        campaignContract.setCampaignStatus(
            campaignId,
            HashDropCampaign.CampaignStatus.ACTIVE
        );
        
        emit CampaignLaunched(
            campaignId,
            msg.sender,
            params.hashtag,
            params.tierNames.length,
            params.tierNames.length > 1
        );
        
        return campaignId;
    }
    
    /**
     * @dev Launch a campaign with cross-chain vault setup
     * @param params Campaign setup parameters
     * @param chainIds Array of chain IDs to deploy vaults on
     * @param vaultAddresses Array of vault contract addresses on each chain
     * @return campaignId The created campaign ID
     */
    function launchCrossChainCampaign(
        CampaignSetupParams memory params,
        uint256[] memory chainIds,
        address[] memory vaultAddresses
    ) external nonReentrant returns (uint256 campaignId) {
        
        require(chainIds.length == vaultAddresses.length, "Chain and vault arrays mismatch");
        require(chainIds.length > 0, "Must specify at least one chain");
        
        // Validate input parameters
        _validateCampaignParams(params);
        
        // Get contract instances
        HashDropCampaign campaignContract = HashDropCampaign(contractAddresses.campaignContract);
        HashDropNFT nftContract = HashDropNFT(contractAddresses.nftContract);
        HashDropVault vaultContract = HashDropVault(contractAddresses.vaultContract);
        
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
        
        // Step 2: Configure NFT tiers
        nftContract.configureCampaign(
            campaignId,
            params.tierNames,
            params.baseURIs,
            params.maxSupplies,
            params.scoreThresholds
        );
        
        // Step 3: Configure vault for current chain
        vaultContract.configureVault(
            campaignId,
            contractAddresses.campaignContract,
            contractAddresses.nftContract,
            params.totalRewards
        );
        
        // Step 4: Register vaults for all specified chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            campaignContract.registerVault(
                campaignId,
                chainIds[i],
                vaultAddresses[i]
            );
        }
        
        // Step 5: Activate the campaign
        campaignContract.setCampaignStatus(
            campaignId,
            HashDropCampaign.CampaignStatus.ACTIVE
        );
        
        emit CampaignLaunched(
            campaignId,
            msg.sender,
            params.hashtag,
            params.tierNames.length,
            params.tierNames.length > 1
        );
        
        return campaignId;
    }
    
    /**
     * @dev Quick launch for simple single-tier campaigns
     * @param hashtag Campaign hashtag
     * @param description Campaign description
     * @param duration Campaign duration in seconds
     * @param tierName Name of the single tier
     * @param baseURI Base URI for NFT metadata
     * @param maxSupply Maximum supply for the tier
     * @param totalBudget Total campaign budget
     * @param totalRewards Total rewards available
     * @return campaignId The created campaign ID
     */
    function quickLaunchSingleTier(
        string memory hashtag,
        string memory description,
        uint256 duration,
        string memory tierName,
        string memory baseURI,
        uint256 maxSupply,
        uint256 totalBudget,
        uint256 totalRewards
    ) external nonReentrant returns (uint256 campaignId) {
        
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
            totalRewards: totalRewards
        });
        
        return this.launchCampaign(params);
    }
    
    /**
     * @dev Preview campaign setup without executing (for frontend validation)
     * @param params Campaign setup parameters
     * @return isValid Whether the parameters are valid
     * @return errorMessage Error message if invalid
     * @return estimatedGas Estimated gas cost for the operation
     */
    function previewCampaignLaunch(
        CampaignSetupParams memory params
    ) external view returns (
        bool isValid,
        string memory errorMessage,
        uint256 estimatedGas
    ) {
        
        // Validate parameters
        try this.validateCampaignParams(params) {
            isValid = true;
            errorMessage = "";
            // Rough gas estimate (actual cost will vary)
            estimatedGas = 800000 + (params.tierNames.length * 100000);
        } catch Error(string memory reason) {
            isValid = false;
            errorMessage = reason;
            estimatedGas = 0;
        } catch {
            isValid = false;
            errorMessage = "Unknown validation error";
            estimatedGas = 0;
        }
        
        return (isValid, errorMessage, estimatedGas);
    }
    
    /**
     * @dev External validation function for preview
     */
    function validateCampaignParams(CampaignSetupParams memory params) external pure {
        _validateCampaignParams(params);
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
    }
    
    /**
     * @dev Update contract addresses (only owner)
     */
    function updateContractAddresses(
        address _campaignContract,
        address _nftContract,
        address _vaultContract
    ) external onlyOwner {
        require(_campaignContract != address(0), "Invalid campaign contract");
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_vaultContract != address(0), "Invalid vault contract");
        
        contractAddresses = ContractAddresses({
            campaignContract: _campaignContract,
            nftContract: _nftContract,
            vaultContract: _vaultContract
        });
        
        emit ContractAddressesUpdated(_campaignContract, _nftContract, _vaultContract);
    }
    
    /**
     * @dev Get current contract addresses
     */
    function getContractAddresses() external view returns (
        address campaignContract,
        address nftContract,
        address vaultContract
    ) {
        return (
            contractAddresses.campaignContract,
            contractAddresses.nftContract,
            contractAddresses.vaultContract
        );
    }
    
    /**
     * @dev Emergency pause function (owner only)
     */
    function pause() external onlyOwner {
        // Implementation would depend on the pause mechanism
        // This is a placeholder for emergency stopping
    }
}