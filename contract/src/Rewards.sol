// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Unified contract that handles both NFT and Token rewards
 */
contract HashDropRewards is ERC721, ERC721URIStorage, ERC20, Ownable {
    uint256 private _tokenIdCounter;
    
    struct RewardTier {
        uint256 minScore;
        uint256 maxSupply;
        uint256 currentSupply;
        string name;
        string imageURI;
        uint256 tokenAmount; // For ERC20 rewards
        bool active;
    }
    
    struct CampaignRewards {
        bool isNFT;
        RewardTier[] tiers;
        mapping(address => bool) hasClaimed;
        mapping(address => uint256) claimedTier;
    }
    
    mapping(uint256 => CampaignRewards) public campaignRewards;
    mapping(address => bool) public authorizedMinters;
    
    event RewardTierAdded(uint256 indexed campaignId, uint256 tierId, string name, uint256 minScore);
    event NFTRewardMinted(address indexed to, uint256 campaignId, uint256 tierId, uint256 tokenId);
    event TokenRewardMinted(address indexed to, uint256 campaignId, uint256 tierId, uint256 amount);
    
    constructor() 
        ERC721("HashDrop NFT", "HDROP") 
        ERC20("HashDrop Token", "HDROP")
        Ownable(msg.sender) 
    {}
    
    /**
     * @dev Configure campaign rewards - supports both single and multiple tiers
     */
    function configureCampaignRewards(
        uint256 campaignId,
        bool isNFT,
        uint256[] memory minScores,
        uint256[] memory maxSupplies,
        string[] memory names,
        string[] memory imageURIs,
        uint256[] memory tokenAmounts
    ) external onlyOwner {
        require(minScores.length > 0, "Must have at least one tier");
        require(
            minScores.length == maxSupplies.length &&
            maxSupplies.length == names.length &&
            names.length == imageURIs.length &&
            imageURIs.length == tokenAmounts.length,
            "Array length mismatch"
        );
        
        CampaignRewards storage rewards = campaignRewards[campaignId];
        rewards.isNFT = isNFT;
        
        // Clear existing tiers
        delete rewards.tiers;
        
        for (uint256 i = 0; i < minScores.length; i++) {
            rewards.tiers.push(RewardTier({
                minScore: minScores[i],
                maxSupply: maxSupplies[i],
                currentSupply: 0,
                name: names[i],
                imageURI: imageURIs[i],
                tokenAmount: tokenAmounts[i],
                active: true
            }));
            
            emit RewardTierAdded(campaignId, i, names[i], minScores[i]);
        }
    }
    
    /**
     * @dev Determine which tier a user qualifies for based on score
     */
    function getQualifiedTier(uint256 campaignId, uint256 score) public view returns (uint256, bool) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        
        // Find highest tier user qualifies for
        for (uint256 i = rewards.tiers.length; i > 0; i--) {
            uint256 tierId = i - 1;
            RewardTier storage tier = rewards.tiers[tierId];
            
            if (score >= tier.minScore && tier.active && tier.currentSupply < tier.maxSupply) {
                return (tierId, true);
            }
        }
        
        return (0, false);
    }
    
    /**
     * @dev Mint reward to user based on their score
     */
    function mintReward(
        address to,
        uint256 campaignId,
        uint256 userScore
    ) external returns (bool) {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Unauthorized");
        
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(!rewards.hasClaimed[to], "Already claimed");
        
        (uint256 tierId, bool qualified) = getQualifiedTier(campaignId, userScore);
        require(qualified, "Not qualified for any tier");
        
        RewardTier storage tier = rewards.tiers[tierId];
        tier.currentSupply++;
        rewards.hasClaimed[to] = true;
        rewards.claimedTier[to] = tierId;
        
        if (rewards.isNFT) {
            uint256 tokenId = _tokenIdCounter++;
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, string(abi.encodePacked(tier.imageURI, "/", _toString(tokenId))));
            emit NFTRewardMinted(to, campaignId, tierId, tokenId);
        } else {
            _mint(to, tier.tokenAmount);
            emit TokenRewardMinted(to, campaignId, tierId, tier.tokenAmount);
        }
        
        return true;
    }
    
    /**
     * @dev Batch mint rewards for multiple users
     */
    function batchMintRewards(
        address[] memory users,
        uint256 campaignId,
        uint256[] memory scores
    ) external returns (uint256) {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Unauthorized");
        require(users.length == scores.length, "Array length mismatch");
        
        uint256 successCount = 0;
        
        for (uint256 i = 0; i < users.length; i++) {
            try this.mintReward(users[i], campaignId, scores[i]) returns (bool success) {
                if (success) successCount++;
            } catch {
                // Continue with next user
            }
        }
        
        return successCount;
    }
    
    /**
     * @dev Check if user has claimed reward
     */
    function hasUserClaimed(uint256 campaignId, address user) external view returns (bool) {
        return campaignRewards[campaignId].hasClaimed[user];
    }
    
    /**
     * @dev Get campaign reward info
     */
    function getCampaignRewardInfo(uint256 campaignId) external view returns (
        bool isNFT,
        uint256 tierCount
    ) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        return (rewards.isNFT, rewards.tiers.length);
    }
    
    /**
     * @dev Get tier information
     */
    function getTierInfo(uint256 campaignId, uint256 tierId) external view returns (
        uint256 minScore,
        uint256 maxSupply,
        uint256 currentSupply,
        string memory name,
        string memory imageURI,
        uint256 tokenAmount,
        bool active
    ) {
        RewardTier storage tier = campaignRewards[campaignId].tiers[tierId];
        return (
            tier.minScore,
            tier.maxSupply,
            tier.currentSupply,
            tier.name,
            tier.imageURI,
            tier.tokenAmount,
            tier.active
        );
    }
    
    /**
     * @dev Set minter authorization
     */
    function setMinterAuthorization(address minter, bool authorized) external onlyOwner {
        authorizedMinters[minter] = authorized;
    }
    
    // Override required functions
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}