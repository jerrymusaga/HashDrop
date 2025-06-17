// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Campaign.sol";
import "../src/NFT.sol";
import "../src/Token.sol";
import "../src/RewardsManager.sol";
import "../src/vault.sol";
import "../src/VRF.sol";

/**
 * @title HashDropDeployment
 * @dev Main deployment script for HashDrop platform 
 */
contract HashDropScript is Script {
    // Avalanche Fuji Testnet VRF Configuration
    address constant VRF_COORDINATOR_FUJI = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
    bytes32 constant KEY_HASH_FUJI = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    
    // Avalanche Mainnet VRF Configuration  
    address constant VRF_COORDINATOR_AVALANCHE = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    bytes32 constant KEY_HASH_AVALANCHE = 0x06eb0e2ea7cca202fc7c8258397a36f33d6568941b16b545d7ebd1bce8bd6251;
    
    function setUp() public {}

    function run() public {
        // Get configuration from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address platformTreasury = vm.envAddress("PLATFORM_TREASURY_ADDRESS");
        
        // VRF subscription ID (optional - set to 0 if not using VRF yet)
        uint64 vrfSubscriptionId = 0;
        try vm.envUint("VRF_SUBSCRIPTION_ID") returns (uint256 subId) {
            vrfSubscriptionId = uint64(subId);
        } catch {
            console.log("VRF_SUBSCRIPTION_ID not set, skipping VRF deployment");
        }
        
        // Determine network and VRF settings
        bool isMainnet = block.chainid == 43114;
        address vrfCoordinator = isMainnet ? VRF_COORDINATOR_AVALANCHE : VRF_COORDINATOR_FUJI;
        bytes32 keyHash = isMainnet ? KEY_HASH_AVALANCHE : KEY_HASH_FUJI;
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying HashDrop Platform...");
        console.log("Network:", isMainnet ? "Avalanche Mainnet" : "Avalanche Fuji");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Platform Treasury:", platformTreasury);
        console.log("Block Number:", block.number);
        console.log("Chain ID:", block.chainid);
        
        // 1. Deploy Campaign Contract
        console.log("\n Deploying Campaign Contract...");
        HashDropCampaign campaign = new HashDropCampaign(platformTreasury);
        console.log("Campaign Contract:", address(campaign));
        
        // 2. Deploy NFT Contract
        console.log("\n Deploying NFT Contract...");
        HashDropNFT nftContract = new HashDropNFT();
        console.log("NFT Contract:", address(nftContract));
        
        // 3. Deploy Token Contract
        console.log("\n Deploying Token Contract...");
        HashDropToken tokenContract = new HashDropToken();
        console.log("Token Contract:", address(tokenContract));
        
        // 4. Deploy Rewards Manager
        console.log("\n Deploying Rewards Manager...");
        HashDropRewardsManager rewardsManager = new HashDropRewardsManager(
            address(nftContract),
            address(tokenContract)
        );
        console.log(" Rewards Manager:", address(rewardsManager));
        
        // 5. Deploy Vault Contract
        console.log("\n Deploying Vault Contract...");
        HashDropVault vault = new HashDropVault(
            address(campaign),
            address(rewardsManager)
        );
        console.log("Vault Contract:", address(vault));
        
        // 6. Deploy VRF Contract (if subscription ID provided)
        address vrfContract = address(0);
        if (vrfSubscriptionId > 0) {
            console.log("\n Deploying VRF Contract...");
            HashDropVRF vrf = new HashDropVRF(
                vrfSubscriptionId,
                vrfCoordinator,
                keyHash,
                address(campaign),
                address(rewardsManager)
            );
            vrfContract = address(vrf);
            console.log(" VRF Contract:", vrfContract);
            
            // Set VRF contract in vault
            vault.setVRFContract(vrfContract);
            console.log(" VRF Contract linked to Vault");
        }
        
        // 7. Setup Permissions
        console.log("\n Setting up permissions...");
        
        // Authorize vault to mint rewards through manager
        rewardsManager.setMinterAuthorization(address(vault), true);
        console.log(" Vault authorized to mint rewards");
        
        // If VRF deployed, authorize it too
        if (vrfContract != address(0)) {
            rewardsManager.setMinterAuthorization(vrfContract, true);
            console.log(" VRF contract authorized to mint rewards");
        }
        
        // 8. Verify deployment
        console.log("\n Verifying deployment...");
        
        // Check campaign fees
        uint256 creationFee = campaign.CAMPAIGN_CREATION_FEE();
        uint256 participantFee = campaign.PER_PARTICIPANT_FEE();
        console.log("Creation Fee:", creationFee / 1e18, "AVAX");
        console.log("Participant Fee:", participantFee / 1e18, "AVAX");
        
        // Check vault configuration
        (address vaultCampaign, address vaultRewards) = (vault.campaignContract(), vault.rewardsContract());
        require(vaultCampaign == address(campaign), "Vault campaign mismatch");
        require(vaultRewards == address(rewardsManager), "Vault rewards mismatch");
        console.log(" Vault configuration verified");
        
        // Check rewards authorization
        require(rewardsManager.authorizedMinters(address(vault)), "Vault not authorized");
        console.log(" Rewards authorization verified");
        
        vm.stopBroadcast();
        
        // 9. Deployment Summary
        console.log("\n Deployment Summary:");
        console.log("--------------------------------------------");
        console.log("Campaign Contract:   ", address(campaign));
        console.log("NFT Contract:        ", address(nftContract));
        console.log("Token Contract:      ", address(tokenContract));
        console.log("Rewards Manager:     ", address(rewardsManager));
        console.log("Vault Contract:      ", address(vault));
        if (vrfContract != address(0)) {
            console.log("VRF Contract:        ", vrfContract);
        }
        console.log("Platform Treasury:   ", platformTreasury);
        
        console.log("\n Fee Structure:");
        console.log("----------------------------------------------");
        console.log("Campaign Creation: 0.1 AVAX");
        console.log("Per Participant:   0.01 AVAX");
        console.log("Cross-Chain:       0.3 AVAX per chain");
        console.log("Premium Monitoring: 1 AVAX");
        
        console.log("\n Next Steps:");
        console.log("------------------------------------------------");
        console.log("1. Save contract addresses to .env file");
        console.log("2. Get Neynar API key: https://neynar.com");
        console.log("3. Setup backend monitoring service");
        console.log("4. Deploy frontend application");
        console.log("5. Create test campaign to verify setup");
        
        if (vrfSubscriptionId == 0) {
            console.log("\n  VRF not deployed - limited reward selection unavailable");
            console.log("To enable VRF:");
            console.log("1. Create VRF subscription at https://vrf.chain.link");
            console.log("2. Fund subscription with LINK tokens");
            console.log("3. Set VRF_SUBSCRIPTION_ID in .env and redeploy");
        }
        
        console.log("\n Add these to your .env file:");
        console.log("------------------------------------------------");
        console.log("CAMPAIGN_CONTRACT_ADDRESS=", address(campaign));
        console.log("NFT_CONTRACT_ADDRESS=", address(nftContract));
        console.log("TOKEN_CONTRACT_ADDRESS=", address(tokenContract));
        console.log("REWARDS_MANAGER_ADDRESS=", address(rewardsManager));
        console.log("VAULT_CONTRACT_ADDRESS=", address(vault));
        if (vrfContract != address(0)) {
            console.log("VRF_CONTRACT_ADDRESS=", vrfContract);
        }
    }
}