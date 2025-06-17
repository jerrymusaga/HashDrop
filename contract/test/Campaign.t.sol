// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/Rewards.sol";

contract HashDropCampaignTest is Test {
    HashDropCampaign public campaign;
    HashDropRewards public rewards;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    event CampaignCreated(uint256 indexed campaignId, string hashtag, address indexed creator, uint256 totalCost);
    event ParticipationRecorded(uint256 indexed campaignId, address indexed user, uint256 score);
    
    function setUp() public {
        vm.startPrank(owner);
        
        campaign = new HashDropCampaign(treasury);
        rewards = new HashDropRewards();
        
        vm.stopPrank();
    }
    
    function testCampaignCreation() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113; // Fuji
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        assertEq(cost, 0.1 ether); // 0.1 AVAX creation fee
        
        vm.expectEmit(true, true, true, true);
        emit CampaignCreated(1, "#testcampaign", user1, cost);
        
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#testcampaign",
            "Test campaign description",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        assertEq(campaignId, 1);
        assertEq(campaign.hashtagToCampaign("#testcampaign"), 1);
        
        vm.stopPrank();
    }
    
    function testCampaignCreationWithPremium() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        
        uint256[] memory chains = new uint256[](2);
        chains[0] = 43113; // Fuji
        chains[1] = 43114; // Avalanche
        
        uint256 cost = campaign.calculateCampaignCost(2, true);
        assertEq(cost, 3.5 ether); // 2 + 0.5 + 1 AVAX
        
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#premiumtest",
            "Premium test campaign",
            30 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            2000000,
            chains,
            true // premium monitoring
        );
        
        assertEq(campaignId, 1);
        
        vm.stopPrank();
    }
    
    function testParticipationRecording() public {
        // First create a campaign
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 campaignId = campaign.createCampaign{value: cost}(
            "#participation",
            "Participation test",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        vm.stopPrank();
        
        // Record participation as owner
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);
        
        address[] memory users = new address[](2);
        uint256[] memory scores = new uint256[](2);
        
        users[0] = user1;
        users[1] = user2;
        scores[0] = 85;
        scores[1] = 92;
        
        uint256 participantFees = users.length * campaign.PER_PARTICIPANT_FEE();
        
        vm.expectEmit(true, true, true, true);
        emit ParticipationRecorded(campaignId, user1, 85);
        
        campaign.batchRecordParticipation{value: participantFees}(
            campaignId,
            users,
            scores
        );
        
        // Verify participation
        (uint256 score, uint256 timestamp, bool rewarded) = campaign.getUserParticipation(campaignId, user1);
        assertEq(score, 85);
        assertFalse(rewarded);
        assertGt(timestamp, 0);
        
        assertTrue(campaign.hasUserParticipated(campaignId, user1));
        assertTrue(campaign.hasUserParticipated(campaignId, user2));
        
        vm.stopPrank();
    }
    
    function testFailDuplicateHashtag() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        
        // Create first campaign
        campaign.createCampaign{value: cost}(
            "#duplicate",
            "First campaign",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        // Try to create second campaign with same hashtag (should fail)
        campaign.createCampaign{value: cost}(
            "#duplicate",
            "Second campaign",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        vm.stopPrank();
    }
    
    function testFailInsufficientFee() public {
        vm.startPrank(user1);
        vm.deal(user1, 0.05 ether); // Not enough for 0.1 AVAX fee
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        campaign.createCampaign{value: 0.05 ether}( // Should fail
            "#insufficient",
            "Insufficient fee test",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        vm.stopPrank();
    }
    
    function testPlatformFeeCollection() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113;
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        uint256 initialBalance = treasury.balance;
        
        campaign.createCampaign{value: cost}(
            "#feetest",
            "Fee collection test",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewards),
            1000000,
            chains,
            false
        );
        
        vm.stopPrank();
        
        // Withdraw fees as owner
        vm.prank(owner);
        campaign.withdrawPlatformFees();
        
        assertEq(treasury.balance, initialBalance + cost);
    }
}


