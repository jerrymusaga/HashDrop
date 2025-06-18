// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/Campaign.sol";

/**
 * @title SimpleGasTest
 * @dev Simple test to verify gas optimization works
 */
contract SimpleGasTest is Test {
    HashDropCampaign public campaign;
    address public treasury = address(0x123);
    
    function setUp() public {
        // Give plenty of balance to test accounts
        vm.deal(address(this), 1000 ether);
        vm.deal(treasury, 1000 ether);
        
        console.log("Starting deployment test...");
        console.log("Test contract balance:", address(this).balance / 1e18, "ETH");
        console.log("Treasury balance:", treasury.balance / 1e18, "ETH");
        
        // Deploy just the campaign contract first
        campaign = new HashDropCampaign(treasury);
        
        console.log("Campaign deployed at:", address(campaign));
        console.log("Campaign creation fee:", campaign.CAMPAIGN_CREATION_FEE() / 1e18, "AVAX");
    }
    
    function testBasicDeployment() public {
        // Test that campaign contract deployed successfully
        assertEq(campaign.platformTreasury(), treasury);
        assertEq(campaign.campaignCounter(), 0);
        
        console.log(" Basic deployment test passed!");
    }
    
    function testCalculateCampaignCost() public {
        uint256 cost = campaign.calculateCampaignCost(1, false);
        assertEq(cost, 0.1 ether);
        
        uint256 costWithPremium = campaign.calculateCampaignCost(2, true);
        assertEq(costWithPremium, 1.4 ether); // 0.1 + 0.3 + 1.0
        
        console.log(" Campaign cost calculation test passed!");
    }
}