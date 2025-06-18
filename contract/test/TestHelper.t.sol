// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/NFT.sol";
import "../src/Token.sol";
import "../src/RewardsManager.sol";
import "../src/vault.sol";

/**
 * @title TestHelper
 * @dev Helper contract for gas-efficient test deployments
 */
contract TestHelper is Test {
    
    // Contract instances
    HashDropCampaign public campaign;
    HashDropNFT public nftContract;
    HashDropToken public tokenContract;
    HashDropRewardsManager public rewardsManager;
    HashDropVault public vault;
    
    // Common test addresses
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public minter = address(0x5);
    
    /**
     * @dev Deploy core contracts (Campaign + RewardsManager)
     */
    function deployCore() public {
        vm.startPrank(owner);
        
        // Fund accounts
        vm.deal(owner, 1000 ether);
        vm.deal(treasury, 1000 ether);
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
        vm.deal(minter, 1000 ether);
        
        // Deploy core contracts
        campaign = new HashDropCampaign(treasury);
        nftContract = new HashDropNFT();
        tokenContract = new HashDropToken();
        rewardsManager = new HashDropRewardsManager(address(nftContract), address(tokenContract));
        
        vm.stopPrank();
    }
    
    /**
     * @dev Deploy all contracts including vault
     */
    function deployFull() public {
        deployCore();
        
        vm.startPrank(owner);
        
        // Deploy vault
        vault = new HashDropVault(address(campaign), address(rewardsManager));
        
        // Set up permissions
        rewardsManager.setMinterAuthorization(address(vault), true);
        rewardsManager.setMinterAuthorization(minter, true);
        
        vm.stopPrank();
    }
    
    /**
     * @dev Create a basic NFT campaign for testing
     */
    function createBasicNFTCampaign() public returns (uint256 campaignId) {
        require(address(campaign) != address(0), "Deploy contracts first");
        
        vm.startPrank(user1);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113; // Fuji
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        
        campaignId = campaign.createCampaign{value: cost}(
            "#testcampaign",
            "Test campaign description",
            7 days,
            HashDropCampaign.RewardType.NFT,
            address(rewardsManager),
            1000000,
            chains,
            false
        );
        
        vm.stopPrank();
        
        // Configure NFT rewards
        vm.startPrank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        string[] memory imageURIs = new string[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Test NFT";
        imageURIs[0] = "https://api.example.com/test";
        
        rewardsManager.configureNFTRewards(campaignId, minScores, maxSupplies, names, imageURIs);
        
        vm.stopPrank();
        
        return campaignId;
    }
    
    /**
     * @dev Create a basic token campaign for testing
     */
    function createBasicTokenCampaign() public returns (uint256 campaignId) {
        require(address(campaign) != address(0), "Deploy contracts first");
        
        vm.startPrank(user1);
        
        uint256[] memory chains = new uint256[](1);
        chains[0] = 43113; // Fuji
        
        uint256 cost = campaign.calculateCampaignCost(1, false);
        
        campaignId = campaign.createCampaign{value: cost}(
            "#tokencampaign",
            "Token campaign description",
            7 days,
            HashDropCampaign.RewardType.TOKEN,
            address(rewardsManager),
            1000000,
            chains,
            false
        );
        
        vm.stopPrank();
        
        // Configure token rewards
        vm.startPrank(owner);
        
        uint256[] memory minScores = new uint256[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        string[] memory names = new string[](1);
        uint256[] memory tokenAmounts = new uint256[](1);
        
        minScores[0] = 10;
        maxSupplies[0] = 1000;
        names[0] = "Test Tokens";
        tokenAmounts[0] = 100 * 10**18; // 100 tokens
        
        rewardsManager.configureTokenRewards(campaignId, minScores, maxSupplies, names, tokenAmounts);
        
        vm.stopPrank();
        
        return campaignId;
    }
    
    /**
     * @dev Add test participants to a campaign
     */
    function addTestParticipants(uint256 campaignId, uint256 count) public returns (address[] memory users, uint256[] memory scores) {
        users = new address[](count);
        scores = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            users[i] = address(uint160(0x1000 + i));
            scores[i] = 50 + (i * 10); // Scores from 50 to 50+(count-1)*10
            vm.deal(users[i], 1000 ether);
        }
        
        vm.startPrank(owner);
        uint256 participantFees = count * campaign.PER_PARTICIPANT_FEE();
        campaign.batchRecordParticipation{value: participantFees}(campaignId, users, scores);
        vm.stopPrank();
        
        return (users, scores);
    }
}