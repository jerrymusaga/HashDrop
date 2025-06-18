// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFT.sol";
import "../src/Token.sol";
import "../src/RewardsManager.sol";

contract HashDropRewardsTest is Test {
    HashDropNFT public nftContract;
    HashDropToken public tokenContract;
    HashDropRewardsManager public rewardsManager;
    
    address public owner = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    
    function setUp() public {
        vm.startPrank(owner);
        
        nftContract = new HashDropNFT();
        tokenContract = new HashDropToken();
        rewardsManager = new HashDropRewardsManager(address(nftContract), address(tokenContract));
        
        rewardsManager.setMinterAuthorization(minter, true);
        
        vm.stopPrank();
    }
    
    function testNFTSingleTierConfiguration() public {
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Participant";
        imageURIs[0] = "https://api.example.com/nft";
        
        rewardsManager.configureNFTRewards(
            1, // campaignId
            minScores,
            maxSupplies,
            names,
            imageURIs
        );
        
        (
            HashDropRewardsManager.RewardType rewardType,
            uint256 tierCount,
            address rewardContract
        ) = rewardsManager.getCampaignRewardInfo(1);
        
        assertTrue(rewardType == HashDropRewardsManager.RewardType.NFT);
        assertEq(tierCount, 1);
        assertEq(rewardContract, address(nftContract));
    }
    
    function testTokenSingleTierConfiguration() public {
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Participant Tokens";
        tokenAmounts[0] = 100 * 10**18;
        
        rewardsManager.configureTokenRewards(
            2, // campaignId
            minScores,
            maxSupplies,
            names,
            tokenAmounts
        );
        
        (
            HashDropRewardsManager.RewardType rewardType,
            uint256 tierCount,
            address rewardContract
        ) = rewardsManager.getCampaignRewardInfo(2);
        
        assertTrue(rewardType == HashDropRewardsManager.RewardType.TOKEN);
        assertEq(tierCount, 1);
        assertEq(rewardContract, address(tokenContract));
    }
    
    function testNFTMultiTierConfiguration() public {
        vm.prank(owner);
        
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
        
        names[0] = "Bronze";
        names[1] = "Silver";
        names[2] = "Gold";
        
        imageURIs[0] = "https://api.example.com/bronze";
        imageURIs[1] = "https://api.example.com/silver";
        imageURIs[2] = "https://api.example.com/gold";
        
        rewardsManager.configureNFTRewards(
            3, // campaignId
            minScores,
            maxSupplies,
            names,
            imageURIs
        );
        
        (
            HashDropRewardsManager.RewardType rewardType,
            uint256 tierCount,
            
        ) = rewardsManager.getCampaignRewardInfo(3);
        
        assertTrue(rewardType == HashDropRewardsManager.RewardType.NFT);
        assertEq(tierCount, 3);
    }
    
    function testTierQualification() public {
        // Setup multi-tier NFT campaign
        vm.prank(owner);
        
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
        
        names[0] = "Bronze";
        names[1] = "Silver";
        names[2] = "Gold";
        
        for (uint256 i = 0; i < 3; i++) {
            imageURIs[i] = "https://api.example.com/tier";
        }
        
        rewardsManager.configureNFTRewards(4, minScores, maxSupplies, names, imageURIs);
        
        // Test tier qualification
        (uint256 tierId, bool qualified) = rewardsManager.getQualifiedTier(4, 15);
        assertTrue(qualified);
        assertEq(tierId, 0); // Bronze
        
        (tierId, qualified) = rewardsManager.getQualifiedTier(4, 75);
        assertTrue(qualified);
        assertEq(tierId, 1); // Silver
        
        (tierId, qualified) = rewardsManager.getQualifiedTier(4, 95);
        assertTrue(qualified);
        assertEq(tierId, 2); // Gold
        
        (tierId, qualified) = rewardsManager.getQualifiedTier(4, 5);
        assertFalse(qualified); // Too low score
    }
    
    function testNFTMinting() public {
        // Setup single tier NFT campaign
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Test NFT";
        imageURIs[0] = "https://api.example.com/test";
        
        rewardsManager.configureNFTRewards(5, minScores, maxSupplies, names, imageURIs);
        
        // Mint NFT
        vm.prank(minter);
        bool success = rewardsManager.mintReward(user1, 5, 85);
        assertTrue(success);
        
        assertEq(nftContract.balanceOf(user1), 1);
        assertTrue(rewardsManager.hasUserClaimed(5, user1));
        assertFalse(rewardsManager.hasUserClaimed(5, user2));
        
        // Try to mint again (should fail)
        vm.prank(minter);
        bool secondAttempt = rewardsManager.mintReward(user1, 5, 85);
        assertFalse(secondAttempt);
    }
    
    function testTokenMinting() public {
        // Setup token campaign
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Test Token";
        tokenAmounts[0] = 100 * 10**18; // 100 tokens
        
        rewardsManager.configureTokenRewards(6, minScores, maxSupplies, names, tokenAmounts);
        
        // Mint tokens
        vm.prank(minter);
        bool success = rewardsManager.mintReward(user1, 6, 75);
        assertTrue(success);
        
        assertEq(tokenContract.balanceOf(user1), 100 * 10**18);
        assertTrue(rewardsManager.hasUserClaimed(6, user1));
    }
    
    function testBatchMinting() public {
        // Setup NFT campaign
        vm.prank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Batch Test";
        imageURIs[0] = "https://api.example.com/batch";
        
        rewardsManager.configureNFTRewards(7, minScores, maxSupplies, names, imageURIs);
        
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
        uint256 successCount = rewardsManager.batchMintRewards(users, 7, scores);
        assertEq(successCount, 3);
        
        assertEq(nftContract.balanceOf(user1), 1);
        assertEq(nftContract.balanceOf(user2), 1);
        assertEq(nftContract.balanceOf(address(0x5)), 1);
    }
    
    function testMixedCampaigns() public {
        vm.startPrank(owner);
        
        // Configure both NFT and Token campaigns
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Mixed Test";
        imageURIs[0] = "https://api.example.com/mixed";
        tokenAmounts[0] = 50 * 10**18;
        
        // Campaign 8: NFT
        rewardsManager.configureNFTRewards(8, minScores, maxSupplies, names, imageURIs);
        
        // Campaign 9: Token
        rewardsManager.configureTokenRewards(9, minScores, maxSupplies, names, tokenAmounts);
        
        vm.stopPrank();
        
        // Mint from both campaigns
        vm.startPrank(minter);
        
        bool nftSuccess = rewardsManager.mintReward(user1, 8, 75);
        bool tokenSuccess = rewardsManager.mintReward(user1, 9, 75);
        
        assertTrue(nftSuccess);
        assertTrue(tokenSuccess);
        
        assertEq(nftContract.balanceOf(user1), 1);
        assertEq(tokenContract.balanceOf(user1), 50 * 10**18);
        
        vm.stopPrank();
    }
}