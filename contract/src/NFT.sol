// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title HashDropNFT
 * @dev NFT rewards contract for HashDrop campaigns
 */
contract HashDropNFT is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;
    
    uint256 private _tokenIdCounter = 1;
    
    struct RewardTier {
        uint256 minScore;
        uint256 maxSupply;
        uint256 currentSupply;
        string name;
        string imageURI;
        bool active;
    }
    
    struct CampaignRewards {
        RewardTier[] tiers;
        mapping(address => bool) hasClaimed;
        mapping(address => uint256) claimedTier;
        bool configured;
    }
    
    mapping(uint256 => CampaignRewards) public campaignRewards;
    mapping(address => bool) public authorizedMinters;
    mapping(uint256 => uint256) public tokenToCampaign;
    mapping(uint256 => uint256) public tokenToTier;
    
    event CampaignConfigured(uint256 indexed campaignId, uint256 tierCount);
    event NFTRewardMinted(address indexed to, uint256 campaignId, uint256 tierId, uint256 tokenId, string tierName);
    
    modifier onlyAuthorizedMinter() {
        require(authorizedMinters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _;
    }
    
    constructor() ERC721("HashDrop NFT", "HDROP") Ownable(msg.sender) {}
    
    function configureCampaignRewards(
        uint256 campaignId,
        uint256[] memory minScores,
        uint256[] memory maxSupplies,
        string[] memory names,
        string[] memory imageURIs
    ) external onlyOwner {
        require(campaignId > 0, "Invalid campaign ID");
        require(minScores.length > 0, "Must have at least one tier");
        require(
            minScores.length == maxSupplies.length &&
            maxSupplies.length == names.length &&
            names.length == imageURIs.length,
            "Array length mismatch"
        );
        
        CampaignRewards storage rewards = campaignRewards[campaignId];
        
        if (rewards.configured) {
            delete rewards.tiers;
        }
        
        rewards.configured = true;
        
        for (uint256 i = 0; i < minScores.length; i++) {
            require(bytes(names[i]).length > 0, "Tier name cannot be empty");
            require(maxSupplies[i] > 0, "Max supply must be positive");
            require(minScores[i] <= 100, "Score cannot exceed 100");
            
            if (i > 0) {
                require(minScores[i] > minScores[i-1], "Scores must be in ascending order");
            }
            
            rewards.tiers.push(RewardTier({
                minScore: minScores[i],
                maxSupply: maxSupplies[i],
                currentSupply: 0,
                name: names[i],
                imageURI: imageURIs[i],
                active: true
            }));
        }
        
        emit CampaignConfigured(campaignId, minScores.length);
    }
    
    function getQualifiedTier(uint256 campaignId, uint256 score) public view returns (uint256, bool) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(rewards.configured, "Campaign not configured");
        require(score <= 100, "Invalid score");
        
        for (uint256 i = rewards.tiers.length; i > 0; i--) {
            uint256 tierId = i - 1;
            RewardTier storage tier = rewards.tiers[tierId];
            
            if (score >= tier.minScore && tier.active && tier.currentSupply < tier.maxSupply) {
                return (tierId, true);
            }
        }
        
        return (0, false);
    }
    
    function mintReward(
        address to,
        uint256 campaignId,
        uint256 userScore
    ) external onlyAuthorizedMinter returns (bool) {
        require(to != address(0), "Cannot mint to zero address");
        
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(rewards.configured, "Campaign not configured");
        require(!rewards.hasClaimed[to], "User already claimed reward");
        
        (uint256 tierId, bool qualified) = getQualifiedTier(campaignId, userScore);
        require(qualified, "User not qualified for any tier");
        
        RewardTier storage tier = rewards.tiers[tierId];
        tier.currentSupply++;
        rewards.hasClaimed[to] = true;
        rewards.claimedTier[to] = tierId;
        
        uint256 tokenId = _tokenIdCounter++;
        tokenToCampaign[tokenId] = campaignId;
        tokenToTier[tokenId] = tierId;
        
        _safeMint(to, tokenId);
        
        string memory fullURI = string(abi.encodePacked(
            tier.imageURI,
            "/",
            tokenId.toString(),
            ".json"
        ));
        _setTokenURI(tokenId, fullURI);
        
        emit NFTRewardMinted(to, campaignId, tierId, tokenId, tier.name);
        return true;
    }
    
    function batchMintRewards(
        address[] memory users,
        uint256 campaignId,
        uint256[] memory scores
    ) external onlyAuthorizedMinter returns (uint256) {
        require(users.length == scores.length, "Array length mismatch");
        require(users.length > 0, "Empty arrays");
        
        uint256 successCount = 0;
        
        for (uint256 i = 0; i < users.length; i++) {
            try this.mintReward(users[i], campaignId, scores[i]) returns (bool success) {
                if (success) successCount++;
            } catch {
                continue;
            }
        }
        
        return successCount;
    }
    
    function hasUserClaimed(uint256 campaignId, address user) external view returns (bool) {
        return campaignRewards[campaignId].hasClaimed[user];
    }
    
    function getCampaignRewardInfo(uint256 campaignId) external view returns (uint256 tierCount) {
        return campaignRewards[campaignId].tiers.length;
    }
    
    function getTierInfo(uint256 campaignId, uint256 tierId) external view returns (
        uint256 minScore,
        uint256 maxSupply,
        uint256 currentSupply,
        string memory name,
        string memory imageURI,
        bool active
    ) {
        require(tierId < campaignRewards[campaignId].tiers.length, "Invalid tier ID");
        
        RewardTier storage tier = campaignRewards[campaignId].tiers[tierId];
        return (
            tier.minScore,
            tier.maxSupply,
            tier.currentSupply,
            tier.name,
            tier.imageURI,
            tier.active
        );
    }
    
    function setMinterAuthorization(address minter, bool authorized) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinters[minter] = authorized;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
