// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/Rewards.sol";
import "../src/vault.sol";

contract HashDropVaultTest is Test {
    HashDropCampaign public campaign;
    HashDropRewards public rewards;
    HashDropVault public vault;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public user3 = address(0x5);
    
    function setUp() public {
        vm.startPrank(owner);
        
        campaign = new HashDropCampaign(treasury);
        rewards = new HashDropRewards();
        vault = new HashDropVault(address(campaign), address(rewards));
        
        // Setup permissions
        rewards.setMinterAuthorization(address(vault), true);
        
        vm.stopPrank();
    }
    
    function testBatchRequestCreation() public {
        address[] memory users = new address[](3);
        uint256[] memory scores = new uint256[](3);
        
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        
        scores[0] = 85;
        scores[1] = 92;
        scores[2] = 78;
        
        vm.prank(owner);
        uint256 batchId = vault.createBatchRewardRequest(1, users, scores);
        
        assertEq(batchId, 1);
        
        (
            uint256 campaignId,
            uint256 userCount,
            bool processed,
            uint256 timestamp,
            uint256 successCount,
            bool readyForProcessing,
            bool vrfSelectionNeeded
        ) = vault.getBatchInfo(batchId);
        
        assertEq(campaignId, 1);
        assertEq(userCount, 3);
        assertFalse(processed);
        assertGt(timestamp, 0);
        assertEq(successCount, 0);
        assertFalse(vrfSelectionNeeded);
    }
    
    function testBatchProcessing() public {
        // First create a campaign and configure rewards
        vm.startPrank(owner);
        vm.deal(owner, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#batchtest",
            "Batch processing test",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        // Configure rewards
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Batch Tester";
        imageURIs[0] = "https://api.example.com/batch";
        tokenAmounts[0] = 0;
        
        rewards.configureCampaignRewards(campaignId, true, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        // Add participants to campaign
        address[] memory users = new address[](3);
        uint256[] memory scores = new uint256[](3);
        
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        
        scores[0] = 85;
        scores[1] = 92;
        scores[2] = 78;
        
        uint256 participantFees = users.length * campaign.PER_PARTICIPANT_FEE();
        campaign.batchRecordParticipation{value: participantFees}(campaignId, users, scores);
        
        // Create batch request with enough users to trigger automatic processing
        address[] memory batchUsers = new address[](10);
        uint256[] memory batchScores = new uint256[](10);
        
        for (uint256 i = 0; i < 10; i++) {
            batchUsers[i] = address(uint160(0x100 + i));
            batchScores[i] = 80 + i;
        }
        
        uint256 batchId = vault.createBatchRewardRequest(campaignId, batchUsers, batchScores);
        
        // Check if batch was auto-processed (should be with 10+ users)
        (, , bool processed, , , , ) = vault.getBatchInfo(batchId);
        assertTrue(processed);
        
        vm.stopPrank();
    }
    
    function testIndividualRewardProcessing() public {
        // Setup campaign and rewards
        vm.startPrank(owner);
        vm.deal(owner, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#individual",
            "Individual test",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Individual Tester";
        imageURIs[0] = "https://api.example.com/individual";
        tokenAmounts[0] = 0;
        
        rewards.configureCampaignRewards(campaignId, true, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        // Process individual reward
        vault.processIndividualReward(campaignId, user1, 85);
        
        // Check if NFT was minted
        assertEq(rewards.balanceOf(user1), 1);
        assertTrue(rewards.hasUserClaimed(campaignId, user1));
        
        vm.stopPrank();
    }
    
    function testVaultStats() public {
        (
            uint256 totalBatches,
            uint256 totalRewardsDistributed,
            uint256 totalParticipants,
            uint256 averageBatchSize,
            uint256 lastProcessingTime,
            uint256 pendingBatches
        ) = vault.getVaultStats();
        
        assertEq(totalBatches, 0);
        assertEq(totalRewardsDistributed, 0);
        assertEq(totalParticipants, 0);
        assertEq(averageBatchSize, 0);
        assertEq(pendingBatches, 0);
    }
}