// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Campaign.sol";
import "../src/Rewards.sol";
import "../src/vault.sol";

/**
 * @title VerifyContractsScript
 * @dev Verifies deployed contracts are working correctly
 */
contract VerifyContractsScript is Script {
    function run() public view {
        address campaignAddress = vm.envAddress("CAMPAIGN_CONTRACT_ADDRESS");
        address rewardsAddress = vm.envAddress("REWARDS_CONTRACT_ADDRESS");
        address vaultAddress = vm.envAddress("VAULT_CONTRACT_ADDRESS");
        
        console.log(" Verifying HashDrop Contracts...");
        
        // Get contract instances
        HashDropCampaign campaign = HashDropCampaign(payable(campaignAddress));
        HashDropRewards rewards = HashDropRewards(rewardsAddress);
        HashDropVault vault = HashDropVault(vaultAddress);
        
        console.log("\n Campaign Contract Verification:");
        console.log("Address:", campaignAddress);
        console.log("Creation Fee:", campaign.CAMPAIGN_CREATION_FEE() / 1e18, "AVAX");
        console.log("Participant Fee:", campaign.PER_PARTICIPANT_FEE() / 1e18, "AVAX");
        console.log("Treasury:", campaign.platformTreasury());
        console.log("Campaign Counter:", campaign.campaignCounter());
        
        console.log("\n Rewards Contract Verification:");
        console.log("Address:", rewardsAddress);
        console.log("NFT Name:", rewards.name());
        console.log("NFT Symbol:", rewards.symbol());
        console.log("Token Name:", rewards.name());
        console.log("Token Symbol:", rewards.symbol());
        console.log("Vault Authorized:", rewards.authorizedMinters(vaultAddress));
        
        console.log("\n Vault Contract Verification:");
        console.log("Address:", vaultAddress);
        console.log("Campaign Contract:", vault.campaignContract());
        console.log("Rewards Contract:", vault.rewardsContract());
        console.log("Batch Counter:", vault.batchCounter());
        
        (
            uint256 totalBatches,
            uint256 totalRewardsDistributed,
            uint256 totalParticipants,
            uint256 averageBatchSize,
            uint256 lastProcessingTime,
            uint256 pendingBatches
        ) = vault.getVaultStats();
        
        console.log("\n Vault Statistics:");
        console.log("Total Batches:", totalBatches);
        console.log("Total Rewards Distributed:", totalRewardsDistributed);
        console.log("Total Participants:", totalParticipants);
        console.log("Average Batch Size:", averageBatchSize);
        console.log("Pending Batches:", pendingBatches);
        
        console.log("\n Contract verification complete!");
    }
}