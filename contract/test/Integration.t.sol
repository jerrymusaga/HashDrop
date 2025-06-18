// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/NFT.sol";
import "../src/Token.sol";
import "../src/RewardsManager.sol";
import "../src/vault.sol";

contract IntegrationTest is Test {
    HashDropCampaign public campaign;
    HashDropNFT public nftContract;
    HashDropToken public tokenContract;
    HashDropRewardsManager public rewardsManager;
    HashDropVault public vault;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public brand = address(0x3);
    
    function setUp() public {
        vm.startPrank(owner);
        
        campaign = new HashDropCampaign(treasury);
        nftContract = new HashDropNFT();
        tokenContract = new HashDropToken();
        rewardsManager = new HashDropRewardsManager(address(nftContract), address(tokenContract));
        vault = new HashDropVault(address(campaign), address(rewardsManager));
        
        rewardsManager.setMinterAuthorization(address(vault), true);
        
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
            address(rewardsManager),
            5000000,
            chains,
            false
        );
        
        console.log("Campaign created:", campaignId);
        
        vm.stopPrank();
        
        // 2. Owner configures NFT rewards
        vm.startPrank(owner);
        
        uint256[] memory minScores = new uint256[](3);
        uint256[] memory maxSupplies = new uint256[](3);
        string[] memory names = new string[](3);
        string[] memory imageURIs = new string[](3);
        
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
        
        rewardsManager.configureNFTRewards(campaignId, minScores, maxSupplies, names, imageURIs);
        
        console.log(" NFT Rewards configured");
        
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
                assertGt(nftContract.balanceOf(participants[i]), 0);
                assertTrue(rewardsManager.hasUserClaimed(campaignId, participants[i]));
                
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
        
        console.log("Vault stats verified");
        console.log("Total rewards distributed:", totalRewardsDistributed);
        
        vm.stopPrank();
        
        console.log(" Complete workflow test passed!");
    }
    
    function testTokenRewardWorkflow() public {
        console.log("Testing Token Reward Workflow");
        
        // 1. Brand creates token campaign
        vm.startPrank(brand);
        vm.deal(brand, 100 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#tokentest",
            "Token reward test",
            30 days,
            HashDropCampaign.RewardType.TOKEN,
            address(rewardsManager),
            5000000,
            chains,
            false
        );
        
        vm.stopPrank();
        
        // 2. Configure token rewards
        vm.startPrank(owner);
        
        uint256[] memory minScores = new uint256[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        string[] memory names = new string[](2);
        uint256[] memory tokenAmounts = new uint256[](2);
        
        minScores[0] = 10;
        minScores[1] = 70;
        
        maxSupplies[0] = 1000;
        maxSupplies[1] = 500;
        
        names[0] = "Participation Tokens";
        names[1] = "Quality Tokens";
        
        tokenAmounts[0] = 50 * 10**18; // 50 tokens
        tokenAmounts[1] = 150 * 10**18; // 150 tokens
        
        rewardsManager.configureTokenRewards(campaignId, minScores, maxSupplies, names, tokenAmounts);
        
        // 3. Add participants and process
        address[] memory participants = new address[](3);
        uint256[] memory scores = new uint256[](3);
        
        participants[0] = address(0x1001);
        participants[1] = address(0x1002);
        participants[2] = address(0x1003);
        
        scores[0] = 25;  // Gets tier 0
        scores[1] = 85;  // Gets tier 1
        scores[2] = 5;   // No reward
        
        uint256 participantFees = participants.length * campaign.PER_PARTICIPANT_FEE();
        vm.deal(owner, participantFees);
        
        campaign.batchRecordParticipation{value: participantFees}(
            campaignId,
            participants,
            scores
        );
        
        uint256 batchId = vault.createBatchRewardRequest(campaignId, participants, scores);
        vm.warp(block.timestamp + 2 hours);
        vault.processBatch(batchId);
        
        // 4. Verify token balances
        assertEq(tokenContract.balanceOf(participants[0]), 50 * 10**18);
        assertEq(tokenContract.balanceOf(participants[1]), 150 * 10**18);
        assertEq(tokenContract.balanceOf(participants[2]), 0);
        
        console.log(" Token reward workflow completed");
        
        vm.stopPrank();
    }
}