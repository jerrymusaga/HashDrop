// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/NFT.sol";
import "../src/Token.sol";
import "../src/RewardsManager.sol";
import "../src/vault.sol";

contract HashDropVaultTest is Test {
    HashDropCampaign public campaign;
    HashDropNFT public nftContract;
    HashDropToken public tokenContract;
    HashDropRewardsManager public rewardsManager;
    HashDropVault public vault;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public user3 = address(0x5);
    
    function setUp() public {
        vm.startPrank(owner);
        
        campaign = new HashDropCampaign(treasury);
        nftContract = new HashDropNFT();
        tokenContract = new HashDropToken();
        rewardsManager = new HashDropRewardsManager(address(nftContract), address(tokenContract));
        vault = new HashDropVault(address(campaign), address(rewardsManager));
        
        // Setup permissions
        rewardsManager.setMinterAuthorization(address(vault), true);
        
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
            address(rewardsManager),
            1000000,
            chains,
            false
        );
        
        // Configure NFT rewards
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Batch Tester";
        imageURIs[0] = "https://api.example.com/batch";
        
        rewardsManager.configureNFTRewards(campaignId, minScores, maxSupplies, names, imageURIs);
        
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
            address(rewardsManager),
            1000000,
            chains,
            false
        );
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Individual Tester";
        imageURIs[0] = "https://api.example.com/individual";
        
        rewardsManager.configureNFTRewards(campaignId, minScores, maxSupplies, names, imageURIs);
        
        // Process individual reward
        vault.processIndividualReward(campaignId, user1, 85);
        
        // Check if NFT was minted
        assertEq(nftContract.balanceOf(user1), 1);
        assertTrue(rewardsManager.hasUserClaimed(campaignId, user1));
        
        vm.stopPrank();
    }
    
    function testTokenRewardBatchProcessing() public {
        // Setup token campaign and rewards
        vm.startPrank(owner);
        vm.deal(owner, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#tokentest",
            "Token test",
            7 days,
            HashDropCampaign.RewardType.TOKEN,
            address(rewardsManager),
            1000000,
            chains,
            false
        );
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Token Tester";
        tokenAmounts[0] = 100 * 10**18;
        
        rewardsManager.configureTokenRewards(campaignId, minScores, maxSupplies, names, tokenAmounts);
        
        // Create and process batch
        address[] memory batchUsers = new address[](10);
        uint256[] memory batchScores = new uint256[](10);
        
        for (uint256 i = 0; i < 10; i++) {
            batchUsers[i] = address(uint160(0x200 + i));
            batchScores[i] = 50 + i; // All qualify
        }
        
        uint256 batchId = vault.createBatchRewardRequest(campaignId, batchUsers, batchScores);
        
        // Check if tokens were distributed
        for (uint256 i = 0; i < 10; i++) {
            assertEq(tokenContract.balanceOf(batchUsers[i]), 100 * 10**18);
        }
        
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
    
    function testManualBatchProcessing() public {
        // Setup campaign
        vm.startPrank(owner);
        vm.deal(owner, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#manual",
            "Manual processing test",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewardsManager),
            1000000,
            chains,
            false
        );
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Manual Tester";
        imageURIs[0] = "https://api.example.com/manual";
        
        rewardsManager.configureNFTRewards(campaignId, minScores, maxSupplies, names, imageURIs);
        
        // Create small batch that won't auto-process
        address[] memory users = new address[](3);
        uint256[] memory scores = new uint256[](3);
        
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        
        scores[0] = 85;
        scores[1] = 92;
        scores[2] = 78;
        
        uint256 batchId = vault.createBatchRewardRequest(campaignId, users, scores);
        
        // Should not be auto-processed
        (, , bool processed, , , , ) = vault.getBatchInfo(batchId);
        assertFalse(processed);
        
        // Simulate time passing and manual process
        vm.warp(block.timestamp + 2 hours);
        vault.processBatch(batchId);
        
        // Should now be processed
        (, , processed, , , , ) = vault.getBatchInfo(batchId);
        assertTrue(processed);
        
        // Check rewards were distributed
        assertEq(nftContract.balanceOf(user1), 1);
        assertEq(nftContract.balanceOf(user2), 1);
        assertEq(nftContract.balanceOf(user3), 1);
        
        vm.stopPrank();
    }
}