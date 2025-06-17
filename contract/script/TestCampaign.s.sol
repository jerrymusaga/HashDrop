// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Campaign.sol";
import "../src/RewardsManager.sol";
import "../src/vault.sol";

/**
 * @title TestCampaignScript
 * @dev Creates a test campaign to verify deployment with separated contracts
 */
contract TestCampaignScript is Script {
    function run() public {
        // Load deployed contract addresses from environment
        address campaignAddress = vm.envAddress("CAMPAIGN_CONTRACT_ADDRESS");
        address rewardsManagerAddress = vm.envAddress("REWARDS_MANAGER_ADDRESS");
        address vaultAddress = vm.envAddress("VAULT_CONTRACT_ADDRESS");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get contract instances
        HashDropCampaign campaign = HashDropCampaign(payable(campaignAddress));
        HashDropRewardsManager rewardsManager = HashDropRewardsManager(rewardsManagerAddress);
        HashDropVault vault = HashDropVault(vaultAddress);
        
        console.log(" Creating Test Campaign...");
        console.log("Using contracts:");
        console.log("Campaign:", campaignAddress);
        console.log("Rewards Manager:", rewardsManagerAddress);
        console.log("Vault:", vaultAddress);
        
        // 1. Calculate campaign cost
        uint256 cost = campaign.calculateCampaignCost(1, false); // Single chain, no premium
        console.log("Campaign Cost:", cost / 1e18, "AVAX");
        require(address(msg.sender).balance >= cost, "Insufficient balance for test campaign");
        
        // 2. Create test campaign
        uint256[] memory chains = new uint256[](1);
        chains[0] = block.chainid;
        
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#hashdroptest",
            "HashDrop Test Campaign - Verify platform functionality",
            7 days, // 1 week duration
            HashDropCampaign.RewardType.NFT,
            address(rewardsManager),
            1000000, // 1M budget (arbitrary for testing)
            chains,
            false // no premium monitoring
        );
        
        console.log(" Test Campaign Created!");
        console.log("Campaign ID:", campaignId);
        console.log("Hashtag: #hashdroptest");
        
        // 3. Configure NFT rewards (single tier)
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10; // Minimum score of 10 (very low threshold for testing)
        maxSupplies[0] = 100; // Max 100 NFTs
        names[0] = "HashDrop Alpha Tester";
        imageURIs[0] = "https://api.hashdrop.example/metadata/alpha-tester";
        
        rewardsManager.configureNFTRewards(
            campaignId,
            minScores,
            maxSupplies,
            names,
            imageURIs
        );
        
        console.log(" NFT Rewards Configured");
        console.log("Tier: Alpha Tester NFT");
        console.log("Min Score: 10");
        console.log("Max Supply: 100");
        
        // 4. Simulate test participation (3 test users)
        address[] memory testUsers = new address[](3);
        uint256[] memory testScores = new uint256[](3);
        
        // Generate deterministic test addresses
        testUsers[0] = address(uint160(uint256(keccak256("hashdrop.test.user.1"))));
        testUsers[1] = address(uint160(uint256(keccak256("hashdrop.test.user.2"))));
        testUsers[2] = address(uint160(uint256(keccak256("hashdrop.test.user.3"))));
        
        testScores[0] = 85; // High quality post
        testScores[1] = 92; // Very high quality post
        testScores[2] = 78; // Good quality post
        
        console.log("\n Adding Test Participants...");
        console.log("User 1:", testUsers[0], "- Score:", testScores[0]);
        console.log("User 2:", testUsers[1], "- Score:", testScores[1]);
        console.log("User 3:", testUsers[2], "- Score:", testScores[2]);
        
        // Calculate participant fees (0.01 AVAX per participant)
        uint256 participantFees = testUsers.length * campaign.PER_PARTICIPANT_FEE();
        console.log("Participant Fees:", participantFees / 1e18, "AVAX");
        
        // Record test participation
        campaign.batchRecordParticipation{value: participantFees}(
            campaignId,
            testUsers,
            testScores
        );
        
        console.log(" Test Participants Added");
        
        // 5. Create batch request for rewards
        uint256 batchId = vault.createBatchRewardRequest(campaignId, testUsers, testScores);
        console.log(" Batch Reward Request Created");
        console.log("Batch ID:", batchId);
        
        vm.stopBroadcast();
        
        console.log("\n Test Campaign Setup Complete!");
        console.log("--------------------------------------------");
        console.log(" Campaign created and configured");
        console.log(" NFT rewards configured");
        console.log(" Test participants added");
        console.log(" Batch processing initiated");
        
        console.log("\n To Test Further:");
        console.log("1. Wait for batch processing (10 users or 1 hour)");
        console.log("2. Call vault.processBatch(", batchId, ") manually");
        console.log("3. Check if NFTs were minted to test users");
        console.log("4. Verify platform fees were collected");
    }
}