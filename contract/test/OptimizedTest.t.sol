// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "./TestHelper.t.sol";

/**
 * @title OptimizedTest
 * @dev Example test using the gas-efficient helper
 */
contract OptimizedTest is TestHelper {
    
    function setUp() public {
        console.log(" Starting optimized test setup...");
        deployFull();
        console.log(" All contracts deployed successfully!");
    }
    
    function testCampaignCreationOptimized() public {
        console.log(" Testing campaign creation...");
        
        uint256 campaignId = createBasicNFTCampaign();
        
        assertEq(campaignId, 1);
        assertEq(campaign.hashtagToCampaign("#testcampaign"), 1);
        
        console.log(" Campaign created with ID:", campaignId);
    }
    
    function testRewardDistributionOptimized() public {
        console.log(" Testing reward distribution...");
        
        uint256 campaignId = createBasicNFTCampaign();
        (address[] memory users, uint256[] memory scores) = addTestParticipants(campaignId, 3);
        
        // Create and process batch
        vm.startPrank(owner);
        uint256 batchId = vault.createBatchRewardRequest(campaignId, users, scores);
        
        // Simulate enough users for auto-processing
        if (users.length >= 10) {
            // Batch should auto-process
        } else {
            // Manually process after time delay
            vm.warp(block.timestamp + 2 hours);
            vault.processBatch(batchId);
        }
        vm.stopPrank();
        
        // Verify rewards were distributed
        for (uint256 i = 0; i < users.length; i++) {
            if (scores[i] >= 10) {
                assertEq(nftContract.balanceOf(users[i]), 1);
                assertTrue(rewardsManager.hasUserClaimed(campaignId, users[i]));
            }
        }
        
        console.log(" Rewards distributed to", users.length, "participants");
    }
    
    function testTokenRewardsOptimized() public {
        console.log(" Testing token rewards...");
        
        uint256 campaignId = createBasicTokenCampaign();
        (address[] memory users, uint256[] memory scores) = addTestParticipants(campaignId, 2);
        
        // Process individual rewards
        vm.startPrank(owner);
        for (uint256 i = 0; i < users.length; i++) {
            vault.processIndividualReward(campaignId, users[i], scores[i]);
        }
        vm.stopPrank();
        
        // Verify token rewards
        for (uint256 i = 0; i < users.length; i++) {
            if (scores[i] >= 10) {
                assertEq(tokenContract.balanceOf(users[i]), 100 * 10**18);
                assertTrue(rewardsManager.hasUserClaimed(campaignId, users[i]));
            }
        }
        
        console.log(" Token rewards distributed successfully");
    }
    
    function testVaultStatsOptimized() public {
        console.log(" Testing vault statistics...");
        
        uint256 campaignId = createBasicNFTCampaign();
        (address[] memory users, uint256[] memory scores) = addTestParticipants(campaignId, 5);
        
        // Process rewards
        vm.startPrank(owner);
        vault.processIndividualReward(campaignId, users[0], scores[0]);
        vault.processIndividualReward(campaignId, users[1], scores[1]);
        vm.stopPrank();
        
        // Check stats
        (
            uint256 totalBatches,
            uint256 totalRewardsDistributed,
            uint256 totalParticipants,
            uint256 averageBatchSize,
            uint256 lastProcessingTime,
            uint256 pendingBatches
        ) = vault.getVaultStats();
        
        assertGt(totalRewardsDistributed, 0);
        assertGt(lastProcessingTime, 0);
        
        console.log("Total rewards distributed:", totalRewardsDistributed);
        console.log(" Vault statistics test passed");
    }
}