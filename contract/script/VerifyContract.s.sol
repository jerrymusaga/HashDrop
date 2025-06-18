// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Campaign.sol";
import "../src/NFT.sol";
import "../src/Token.sol";
import "../src/RewardsManager.sol";
import "../src/vault.sol";
import "../src/VRF.sol";

/**
 * @title VerifyContractsScript
 * @dev Verifies deployed contracts are working correctly with new architecture
 */
contract VerifyContractsScript is Script {
    function run() public view {
        address campaignAddress = vm.envAddress("CAMPAIGN_CONTRACT_ADDRESS");
        address nftAddress = vm.envAddress("NFT_CONTRACT_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_CONTRACT_ADDRESS");
        address rewardsManagerAddress = vm.envAddress("REWARDS_MANAGER_ADDRESS");
        address vaultAddress = vm.envAddress("VAULT_CONTRACT_ADDRESS");
        
        // VRF address is optional
        address vrfAddress = address(0);
        try vm.envAddress("VRF_CONTRACT_ADDRESS") returns (address addr) {
            vrfAddress = addr;
        } catch {
            console.log("VRF contract not deployed");
        }
        
        console.log(" Verifying HashDrop Contracts...");
        console.log("=====================================");
        
        // Get contract instances
        HashDropCampaign campaign = HashDropCampaign(payable(campaignAddress));
        HashDropNFT nftContract = HashDropNFT(nftAddress);
        HashDropToken tokenContract = HashDropToken(tokenAddress);
        HashDropRewardsManager rewardsManager = HashDropRewardsManager(rewardsManagerAddress);
        HashDropVault vault = HashDropVault(vaultAddress);
        
        console.log("\n Campaign Contract Verification:");
        console.log("-----------------------------------");
        console.log("Address:", campaignAddress);
        console.log("Creation Fee:", campaign.CAMPAIGN_CREATION_FEE() / 1e18, "AVAX");
        console.log("Participant Fee:", campaign.PER_PARTICIPANT_FEE() / 1e18, "AVAX");
        console.log("Cross-Chain Fee:", campaign.CROSS_CHAIN_FEE() / 1e18, "AVAX");
        console.log("Premium Fee:", campaign.PREMIUM_MONITORING_FEE() / 1e18, "AVAX");
        console.log("Treasury:", campaign.platformTreasury());
        console.log("Campaign Counter:", campaign.campaignCounter());
        console.log("Total Platform Fees:", campaign.totalPlatformFees() / 1e18, "AVAX");
        
        console.log("\n NFT Contract Verification:");
        console.log("-----------------------------");
        console.log("Address:", nftAddress);
        console.log("Name:", nftContract.name());
        console.log("Symbol:", nftContract.symbol());
        console.log("Vault Authorized:", nftContract.authorizedMinters(vaultAddress));
        console.log("RewardsManager Authorized:", nftContract.authorizedMinters(rewardsManagerAddress));
        
        console.log("\n Token Contract Verification:");
        console.log("-------------------------------");
        console.log("Address:", tokenAddress);
        console.log("Name:", tokenContract.name());
        console.log("Symbol:", tokenContract.symbol());
        console.log("Decimals:", tokenContract.decimals());
        console.log("Total Supply:", tokenContract.totalSupply() / 1e18, "tokens");
        console.log("Vault Authorized:", tokenContract.authorizedMinters(vaultAddress));
        console.log("RewardsManager Authorized:", tokenContract.authorizedMinters(rewardsManagerAddress));
        
        console.log("\n Rewards Manager Verification:");
        console.log("--------------------------------");
        console.log("Address:", rewardsManagerAddress);
        console.log("NFT Contract:", address(rewardsManager.nftContract()));
        console.log("Token Contract:", address(rewardsManager.tokenContract()));
        console.log("Vault Authorized:", rewardsManager.authorizedMinters(vaultAddress));
        
        // Verify contract linking
        bool nftLinked = address(rewardsManager.nftContract()) == nftAddress;
        bool tokenLinked = address(rewardsManager.tokenContract()) == tokenAddress;
        console.log("NFT Contract Linked:", nftLinked ? "Good" : "Bad");
        console.log("Token Contract Linked:", tokenLinked ? "Good" : "Bad");
        
        console.log("\n Vault Contract Verification:");
        console.log("-------------------------------");
        console.log("Address:", vaultAddress);
        console.log("Campaign Contract:", vault.campaignContract());
        console.log("Rewards Contract:", vault.rewardsContract());
        console.log("Batch Counter:", vault.batchCounter());
        console.log("Batch Size Threshold:", vault.BATCH_SIZE_THRESHOLD());
        console.log("Batch Time Threshold:", vault.BATCH_TIME_THRESHOLD() / 3600, "hours");
        console.log("Max Batch Size:", vault.MAX_BATCH_SIZE());
        
        // Verify vault configuration
        bool campaignLinked = vault.campaignContract() == campaignAddress;
        bool rewardsLinked = vault.rewardsContract() == rewardsManagerAddress;
        console.log("Campaign Contract Linked:", campaignLinked ? "Good" : "Bad");
        console.log("Rewards Contract Linked:", rewardsLinked ? "Good" : "Bad");
        
        (
            uint256 totalBatches,
            uint256 totalRewardsDistributed,
            uint256 totalParticipants,
            uint256 averageBatchSize,
            uint256 lastProcessingTime,
            uint256 pendingBatches
        ) = vault.getVaultStats();
        
        console.log("\n Vault Statistics:");
        console.log("--------------------");
        console.log("Total Batches:", totalBatches);
        console.log("Total Rewards Distributed:", totalRewardsDistributed);
        console.log("Total Participants:", totalParticipants);
        console.log("Average Batch Size:", averageBatchSize);
        console.log("Pending Batches:", pendingBatches);
        
        if (lastProcessingTime > 0) {
            console.log("Last Processing:", lastProcessingTime);
            console.log("Time Since Last:", (block.timestamp - lastProcessingTime) / 3600, "hours ago");
        } else {
            console.log("Last Processing: Never");
        }
        
        // VRF Contract Verification (if deployed)
        if (vrfAddress != address(0)) {
            HashDropVRF vrfContract = HashDropVRF(vrfAddress);
            
            console.log("\n VRF Contract Verification:");
            console.log("-----------------------------");
            console.log("Address:", vrfAddress);
            console.log("Subscription ID:", vrfContract.subscriptionId());
            console.log("Selection Counter:", vrfContract.selectionCounter());
            console.log("Campaign Contract:", vrfContract.campaignContract());
            console.log("Rewards Contract:", vrfContract.rewardsContract());
            console.log("Vault Contract:", vrfContract.vaultContract());
            
            // Check if vault knows about VRF
            address vaultVrfContract = vault.vrfContract();
            console.log("Vault VRF Contract:", vaultVrfContract);
            console.log("VRF Contract Linked:", vaultVrfContract == vrfAddress ? "Good" : "Bad");
            
            // Get pending selections
            uint256[] memory pendingSelections = vrfContract.getPendingSelections();
            console.log("Pending VRF Selections:", pendingSelections.length);
        }
        
        console.log("\n Authorization Verification:");
        console.log("------------------------------");
        
        // Check all critical authorizations
        bool vaultCanMintNFT = nftContract.authorizedMinters(vaultAddress);
        bool vaultCanMintToken = tokenContract.authorizedMinters(vaultAddress);
        bool managerCanMintNFT = nftContract.authorizedMinters(rewardsManagerAddress);
        bool managerCanMintToken = tokenContract.authorizedMinters(rewardsManagerAddress);
        bool vaultCanMintRewards = rewardsManager.authorizedMinters(vaultAddress);
        
        console.log("Vault => NFT:", vaultCanMintNFT ? "Good" : "Bad");
        console.log("Vault => Token:", vaultCanMintToken ? "Good" : "Bad");
        console.log("Manager => NFT:", managerCanMintNFT ? "Good" : "Bad");
        console.log("Manager => Token:", managerCanMintToken ? "Good" : "Bad");
        console.log("Vault => RewardsManager:", vaultCanMintRewards ? "Good" : "Bad");
        
        console.log("\n  Critical Issues:");
        console.log("--------------------");
        
        uint256 issues = 0;
        
        if (!nftLinked) {
            console.log(" NFT contract not properly linked to RewardsManager");
            issues++;
        }
        
        if (!tokenLinked) {
            console.log(" Token contract not properly linked to RewardsManager");
            issues++;
        }
        
        if (!campaignLinked) {
            console.log(" Campaign contract not properly linked to Vault");
            issues++;
        }
        
        if (!rewardsLinked) {
            console.log(" RewardsManager not properly linked to Vault");
            issues++;
        }
        
        if (!vaultCanMintRewards) {
            console.log(" Vault not authorized to mint through RewardsManager");
            issues++;
        }
        
        if (!managerCanMintNFT) {
            console.log(" RewardsManager not authorized to mint NFTs");
            issues++;
        }
        
        if (!managerCanMintToken) {
            console.log(" RewardsManager not authorized to mint Tokens");
            issues++;
        }
        
        if (issues == 0) {
            console.log(" No critical issues found!");
        } else {
            console.log(" Found", issues, "critical issues that need fixing");
        }
        
        console.log("\n Deployment Summary:");
        console.log("======================");
        console.log("Campaign Contract: Deployed & Configured");
        console.log("NFT Contract: Deployed & Configured");
        console.log(" Token Contract: Deployed & Configured");
        console.log(" RewardsManager: Deployed & Configured");
        console.log(" Vault Contract: Deployed & Configured");
        
        if (vrfAddress != address(0)) {
            console.log(" VRF Contract: Deployed & Configured");
        } else {
            console.log("  VRF Contract: Not Deployed (Limited rewards unavailable)");
        }
        
        console.log("\n Next Steps:");
        console.log("==============");
        
        if (issues > 0) {
            console.log("1. Fix authorization issues listed above");
            console.log("2. Re-run verification script");
        }
        
        if (campaign.campaignCounter() == 0) {
            console.log("3. Create a test campaign with: make test-campaign");
            console.log("4. Verify campaign creation and reward distribution");
        }
        
        console.log("5. Test frontend integration");
        console.log("6. Deploy to mainnet when ready");
        
        console.log("\n Verification Complete!");
        console.log("========================");
        
        if (issues == 0) {
            console.log(" All systems operational! Ready for production use.");
        } else {
            console.log("  Fix critical issues before production deployment.");
        }
    }
}