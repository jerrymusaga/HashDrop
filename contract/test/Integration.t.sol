// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/NFT.sol";
import "../src/vault.sol";

contract IntegrationTest is Test {
    HashDropCampaign public campaign;
    HashDropRewards public rewards;
    HashDropVault public vault;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public brand = address(0x3);
    
    function setUp() public {
        vm.startPrank(owner);
        
        campaign = new HashDropCampaign(treasury);
        rewards = new HashDropRewards();
        vault = new HashDropVault(address(campaign), address(rewards));
        
        rewards.setMinterAuthorization(address(vault), true);
        
        vm.stopPrank();
    }
    
    function testCompleteWorkflow() public {
        console.log("Testing Complete HashDrop Workflow");
        
        // 1. Brand creates campaign
        vm.startPrank(brand);
        vm.deal(brand, 100 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#complete",
            "Complete workflow test",
            30 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            5000000,
            chains,
            false
        );
        
        console.log("Campaign created:", campaignId);
        
        vm.stopPrank();
        
        // 2. Owner configures rewards
        vm.startPrank(owner);
        
        uint256[] memory minScores = new uint256[](3);
        uint256[] memory maxSupplies = new uint256[](3);
        string[] memory names = new string[](3);
        string[] memory imageURIs = new string[](3);
        uint256[] memory tokenAmounts = new uint256[](3);
        
        minScores[0] = 10;
        minScores[1] = 50;
        minScores[2] = 80;
        
        maxSupplies[0] = 500;
        maxSupplies[1] = 300;
        maxSupplies[2] = 100;
        
        names[0] = "Bronze Complete";
        names[1] = "Silver Complete";
        names[2] = "Gold Complete";
        
        imageURIs[0] = "https://api.complete.com/bronze";
        imageURIs[1] = "https://api.complete.com/silver";
        imageURIs[2] = "https://api.complete.com/gold";
        
        for (uint256 i = 0; i < 3; i++) {
            tokenAmounts[i] = 0;
        }
        
        rewards.configureCampaignRewards(campaignId, true, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        console.log(" Rewards configured");
        
        // 3. Simulate participants
        address[] memory participants = new address[](5);
        uint256[] memory scores = new uint256[](5);
        
        for (uint256 i = 0; i < 5; i++) {
            participants[i] = address(uint160(0x1000 + i));
            scores[i] = 20 + (i * 20); // Scores: 20, 40, 60, 80, 100
        }
        
        uint256 participantFees = participants.length * campaign.PER_PARTICIPANT_FEE();
        vm.deal(owner, participantFees);
        
        campaign.batchRecordParticipation{value: participantFees}(
            campaignId,
            participants,
            scores
        );
        
        console.log(" Participants recorded:", participants.length);
        
        // 4. Create batch request
        uint256 batchId = vault.createBatchRewardRequest(campaignId, participants, scores);
        
        console.log("Batch request created:", batchId);
        
        // 5. Process batch (simulate time passing)
        vm.warp(block.timestamp + 2 hours);
        vault.processBatch(batchId);
        
        console.log(" Batch processed");
        
        // 6. Verify results
        for (uint256 i = 0; i < participants.length; i++) {
            if (scores[i] >= 10) { // Should qualify for some tier
                assertGt(rewards.balanceOf(participants[i]), 0);
                assertTrue(rewards.hasUserClaimed(campaignId, participants[i]));
                
                (uint256 userScore, , bool rewarded) = campaign.getUserParticipation(campaignId, participants[i]);
                assertEq(userScore, scores[i]);
                assertTrue(rewarded);
            }
        }
        
        console.log(" Verification complete");
        
        // 7. Check vault stats
        (
            uint256 totalBatches,
            uint256 totalRewardsDistributed,
            uint256 totalParticipants,
            , , 
        ) = vault.getVaultStats();
        
        assertEq(totalBatches, 1);
        assertEq(totalParticipants, participants.length);
        assertGt(totalRewardsDistributed, 0);
        
        console.log(" Vault stats verified");
        console.log("Total rewards distributed:", totalRewardsDistributed);
        
        vm.stopPrank();
        
        console.log(" Complete workflow test passed!");
    }
}