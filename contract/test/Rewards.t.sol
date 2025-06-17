// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFT.sol";

contract HashDropRewardsTest is Test {
    HashDropRewards public rewards;
    
    address public owner = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    function setUp() public {
        vm.startPrank(owner);
        
        rewards = new HashDropRewards();
        rewards.setMinterAuthorization(minter, true);
        
        vm.stopPrank();
    }
    
    function testSingleTierConfiguration() public {
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Participant";
        imageURIs[0] = "https://api.example.com/nft";
        tokenAmounts[0] = 0;
        
        rewards.configureCampaignRewards(
            1, // campaignId
            true, // isNFT
            minScores,
            maxSupplies,
            names,
            imageURIs,
            tokenAmounts
        );
        
        (bool isNFT, uint256 tierCount) = rewards.getCampaignRewardInfo(1);
        assertTrue(isNFT);
        assertEq(tierCount, 1);
        
        (uint256 minScore, uint256 maxSupply, uint256 currentSupply, string memory name, , ,) = 
            rewards.getTierInfo(1, 0);
        
        assertEq(minScore, 10);
        assertEq(maxSupply, 1000);
        assertEq(currentSupply, 0);
        assertEq(name, "Participant");
    }
    
    function testMultiTierConfiguration() public {
        vm.prank(owner);
        
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
        
        names[0] = "Bronze";
        names[1] = "Silver";
        names[2] = "Gold";
        
        imageURIs[0] = "https://api.example.com/bronze";
        imageURIs[1] = "https://api.example.com/silver";
        imageURIs[2] = "https://api.example.com/gold";
        
        tokenAmounts[0] = 0;
        tokenAmounts[1] = 0;
        tokenAmounts[2] = 0;
        
        rewards.configureCampaignRewards(
            2, // campaignId
            true, // isNFT
            minScores,
            maxSupplies,
            names,
            imageURIs,
            tokenAmounts
        );
        
        (bool isNFT, uint256 tierCount) = rewards.getCampaignRewardInfo(2);
        assertTrue(isNFT);
        assertEq(tierCount, 3);
        assertTrue(rewards.isMultiTier(2));
        assertFalse(rewards.isSingleTier(2));
    }
    
    function testTierQualification() public {
        // Setup multi-tier campaign
        vm.prank(owner);
        
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
        
        names[0] = "Bronze";
        names[1] = "Silver";
        names[2] = "Gold";
        
        for (uint256 i = 0; i < 3; i++) {
            imageURIs[i] = "https://api.example.com/tier";
            tokenAmounts[i] = 0;
        }
        
        rewards.configureCampaignRewards(3, true, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        // Test tier qualification
        (uint256 tierId, bool qualified) = rewards.getQualifiedTier(3, 15);
        assertTrue(qualified);
        assertEq(tierId, 0); // Bronze
        
        (tierId, qualified) = rewards.getQualifiedTier(3, 75);
        assertTrue(qualified);
        assertEq(tierId, 1); // Silver
        
        (tierId, qualified) = rewards.getQualifiedTier(3, 95);
        assertTrue(qualified);
        assertEq(tierId, 2); // Gold
        
        (tierId, qualified) = rewards.getQualifiedTier(3, 5);
        assertFalse(qualified); // Too low score
    }
    
    function testNFTMinting() public {
        // Setup single tier campaign
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Test NFT";
        imageURIs[0] = "https://api.example.com/test";
        tokenAmounts[0] = 0;
        
        rewards.configureCampaignRewards(4, true, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        // Mint NFT
        vm.prank(minter);
        bool success = rewards.mintReward(user1, 4, 85);
        assertTrue(success);
        
        assertEq(rewards.ownerOf(1), user1);
        assertTrue(rewards.hasUserClaimed(4, user1));
        assertFalse(rewards.hasUserClaimed(4, user2));
        
        // Try to mint again (should fail)
        vm.prank(minter);
        vm.expectRevert("Already claimed");
        rewards.mintReward(user1, 4, 85);
    }
    
    function testTokenMinting() public {
        // Setup token campaign
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Test Token";
        imageURIs[0] = "";
        tokenAmounts[0] = 100 * 10**18; // 100 tokens
        
        rewards.configureCampaignRewards(5, false, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        // Mint tokens
        vm.prank(minter);
        bool success = rewards.mintReward(user1, 5, 75);
        assertTrue(success);
        
        assertEq(rewards.balanceOf(user1), 100 * 10**18);
        assertTrue(rewards.hasUserClaimed(5, user1));
    }
    
    function testBatchMinting() public {
        // Setup campaign
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Batch Test";
        imageURIs[0] = "https://api.example.com/batch";
        tokenAmounts[0] = 0;
        
        rewards.configureCampaignRewards(6, true, minScores, maxSupplies, names, imageURIs, tokenAmounts);
        
        // Batch mint
        address[] memory users = new address[](3);
        uint256[] memory scores = new uint256[](3);
        
        users[0] = user1;
        users[1] = user2;
        users[2] = address(0x5);
        
        scores[0] = 85;
        scores[1] = 92;
        scores[2] = 78;
        
        vm.prank(minter);
        uint256 successCount = rewards.batchMintRewards(users, 6, scores);
        assertEq(successCount, 3);
        
        assertEq(rewards.ownerOf(1), user1);
        assertEq(rewards.ownerOf(2), user2);
        assertEq(rewards.ownerOf(3), address(0x5));
    }
}
