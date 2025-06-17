// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract HashDropRewards is ERC721, ERC721URIStorage, ERC20, Ownable {
    using Strings for uint256;
    
    uint256 private _tokenIdCounter = 1; // Start NFT IDs from 1
    
    struct RewardTier {
        uint256 minScore; // Minimum AI score required (0-100)
        uint256 maxSupply; // Maximum rewards for this tier
        uint256 currentSupply; // Current minted count
        string name; // Tier name (e.g., "Gold", "Silver", "Bronze")
        string imageURI; // Base URI for NFT metadata
        uint256 tokenAmount; // ERC20 token amount (if token rewards)
        bool active; // Is this tier active?
    }
    
    struct CampaignRewards {
        bool isNFT; // true = NFT rewards, false = Token rewards
        RewardTier[] tiers; // Array of reward tiers
        mapping(address => bool) hasClaimed; // User claim status
        mapping(address => uint256) claimedTier; // Which tier user claimed
        bool configured; // Has this campaign been configured?
    }
    
    // Storage
    mapping(uint256 => CampaignRewards) public campaignRewards;
    mapping(address => bool) public authorizedMinters;
    mapping(uint256 => uint256) public tokenToCampaign; // NFT tokenId => campaignId
    mapping(uint256 => uint256) public tokenToTier; // NFT tokenId => tierId
    
    // Events
    event CampaignConfigured(uint256 indexed campaignId, bool isNFT, uint256 tierCount);
    event RewardTierAdded(
        uint256 indexed campaignId, 
        uint256 tierId, 
        string name, 
        uint256 minScore,
        uint256 maxSupply
    );
    event NFTRewardMinted(
        address indexed to, 
        uint256 campaignId, 
        uint256 tierId, 
        uint256 tokenId,
        string tierName
    );
    event TokenRewardMinted(
        address indexed to, 
        uint256 campaignId, 
        uint256 tierId, 
        uint256 amount,
        string tierName
    );
    event MinterAuthorized(address indexed minter, bool authorized);
    
    modifier onlyAuthorizedMinter() {
        require(
            authorizedMinters[msg.sender] || msg.sender == owner(), 
            "Not authorized to mint"
        );
        _;
    }
    
    /**
     * @dev Constructor sets up dual NFT/Token contract
     */
    constructor() 
        ERC721("HashDrop NFT", "HDROP") 
        ERC20("HashDrop Token", "HDROP")
        Ownable(msg.sender) 
    {}
    
    /**
     * @dev Configure reward tiers for a campaign
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
        require(campaignId > 0, "Invalid campaign ID");
        require(minScores.length > 0, "Must have at least one tier");
        require(minScores.length <= 10, "Maximum 10 tiers allowed");
        require(
            minScores.length == maxSupplies.length &&
            maxSupplies.length == names.length &&
            names.length == imageURIs.length &&
            imageURIs.length == tokenAmounts.length,
            "Array length mismatch"
        );
        
        CampaignRewards storage rewards = campaignRewards[campaignId];
        
        // Clear existing tiers if reconfiguring
        if (rewards.configured) {
            delete rewards.tiers;
        }
        
        rewards.isNFT = isNFT;
        rewards.configured = true;
        
        // Validate and add tiers
        for (uint256 i = 0; i < minScores.length; i++) {
            require(bytes(names[i]).length > 0, "Tier name cannot be empty");
            require(maxSupplies[i] > 0, "Max supply must be positive");
            require(minScores[i] <= 100, "Score cannot exceed 100");
            
            // For multi-tier, ensure scores are in ascending order
            if (i > 0) {
                require(minScores[i] > minScores[i-1], "Scores must be in ascending order");
            }
            
            rewards.tiers.push(RewardTier({
                minScore: minScores[i],
                maxSupply: maxSupplies[i],
                currentSupply: 0,
                name: names[i],
                imageURI: imageURIs[i],
                tokenAmount: tokenAmounts[i],
                active: true
            }));
            
            emit RewardTierAdded(campaignId, i, names[i], minScores[i], maxSupplies[i]);
        }
        
        emit CampaignConfigured(campaignId, isNFT, minScores.length);
    }
    
    /**
     * @dev Determine which tier a user qualifies for based on their AI score
     */
    function getQualifiedTier(uint256 campaignId, uint256 score) public view returns (uint256, bool) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(rewards.configured, "Campaign not configured");
        require(score <= 100, "Invalid score");
        
        // Find the highest tier the user qualifies for (reverse order)
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
     * @dev Mint reward to user based on their AI score
     */
    function mintReward(
        address to,
        uint256 campaignId,
        uint256 userScore
    ) external onlyAuthorizedMinter returns (bool) {
        require(to != address(0), "Cannot mint to zero address");
        
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(rewards.configured, "Campaign not configured");
        require(!rewards.hasClaimed[to], "User already claimed reward");
        
        // Determine which tier user qualifies for
        (uint256 tierId, bool qualified) = getQualifiedTier(campaignId, userScore);
        require(qualified, "User not qualified for any tier");
        
        RewardTier storage tier = rewards.tiers[tierId];
        
        // Update state before minting (reentrancy protection)
        tier.currentSupply++;
        rewards.hasClaimed[to] = true;
        rewards.claimedTier[to] = tierId;
        
        if (rewards.isNFT) {
            // Mint NFT
            uint256 tokenId = _tokenIdCounter++;
            
            tokenToCampaign[tokenId] = campaignId;
            tokenToTier[tokenId] = tierId;
            
            _safeMint(to, tokenId);
            
            // Set metadata URI
            string memory fullURI = string(abi.encodePacked(
                tier.imageURI,
                "/",
                tokenId.toString(),
                ".json"
            ));
            _setTokenURI(tokenId, fullURI);
            
            emit NFTRewardMinted(to, campaignId, tierId, tokenId, tier.name);
        } else {
            // Mint ERC20 tokens
            _mint(to, tier.tokenAmount);
            
            emit TokenRewardMinted(to, campaignId, tierId, tier.tokenAmount, tier.name);
        }
        
        return true;
    }
    
    /**
     * @dev Batch mint rewards for multiple users (gas efficient)
     */
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
                if (success) {
                    successCount++;
                }
            } catch {
                // Continue with next user if one fails
                continue;
            }
        }
        
        return successCount;
    }
    
    // ===============================================
    // OVERRIDE FUNCTIONS TO RESOLVE CONFLICTS
    // ===============================================
    
    /**
     * @dev Override transferFrom to handle both NFT and Token transfers
     * This resolves the conflict between ERC721 and ERC20 transferFrom functions
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenIdOrAmount
    ) public override(ERC721, ERC20) {
        // Check if this is an NFT transfer (tokenId exists)
        if (_ownerOf(tokenIdOrAmount) != address(0)) {
            // This is an NFT transfer
            ERC721.transferFrom(from, to, tokenIdOrAmount);
        } else {
            // This is an ERC20 token transfer
            ERC20.transferFrom(from, to, tokenIdOrAmount);
        }
    }
    
    /**
     * @dev Override approve to handle both NFT and Token approvals
     */
    function approve(address to, uint256 tokenIdOrAmount) public override(ERC721, ERC20) {
        // Check if this is an NFT approval (tokenId exists)
        if (tokenIdOrAmount < _tokenIdCounter && _ownerOf(tokenIdOrAmount) != address(0)) {
            // This is an NFT approval
            ERC721.approve(to, tokenIdOrAmount);
        } else {
            // This is an ERC20 token approval
            ERC20.approve(to, tokenIdOrAmount);
        }
    }
    
    /**
     * @dev Separate function for NFT transfers to avoid confusion
     */
    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) public {
        ERC721.transferFrom(from, to, tokenId);
    }
    
    /**
     * @dev Separate function for Token transfers to avoid confusion
     */
    function transferTokens(
        address from,
        address to,
        uint256 amount
    ) public {
        ERC20.transferFrom(from, to, amount);
    }
    
    /**
     * @dev Separate function for NFT approvals
     */
    function approveNFT(address to, uint256 tokenId) public {
        ERC721.approve(to, tokenId);
    }
    
    /**
     * @dev Separate function for Token approvals  
     */
    function approveTokens(address spender, uint256 amount) public {
        ERC20.approve(spender, amount);
    }
    
    // ===============================================
    // VIEW FUNCTIONS
    // ===============================================
    
    /**
     * @dev Check if user has claimed reward for a campaign
     */
    function hasUserClaimed(uint256 campaignId, address user) external view returns (bool) {
        return campaignRewards[campaignId].hasClaimed[user];
    }
    
    /**
     * @dev Get campaign reward configuration
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
        require(tierId < campaignRewards[campaignId].tiers.length, "Invalid tier ID");
        
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
     * @dev Get all tier thresholds for a campaign
     */
    function getCampaignThresholds(uint256 campaignId) external view returns (uint256[] memory) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(rewards.configured, "Campaign not configured");
        
        uint256 tierCount = rewards.tiers.length;
        uint256[] memory thresholds = new uint256[](tierCount);
        
        for (uint256 i = 0; i < tierCount; i++) {
            thresholds[i] = rewards.tiers[i].minScore;
        }
        
        return thresholds;
    }
    
    /**
     * @dev Get NFT token information
     */
    function getTokenInfo(uint256 tokenId) external view returns (
        uint256 campaignId,
        uint256 tierId,
        string memory tierName
    ) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        uint256 campId = tokenToCampaign[tokenId];
        uint256 tId = tokenToTier[tokenId];
        string memory tName = campaignRewards[campId].tiers[tId].name;
        
        return (campId, tId, tName);
    }
    
    /**
     * @dev Check if tier is available for minting
     */
    function tierAvailable(uint256 campaignId, uint256 tierId) external view returns (bool) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        
        if (!rewards.configured || tierId >= rewards.tiers.length) {
            return false;
        }
        
        RewardTier storage tier = rewards.tiers[tierId];
        return tier.active && tier.currentSupply < tier.maxSupply;
    }
    
    /**
     * @dev Get total supply stats for a campaign
     */
    function getCampaignSupplyStats(uint256 campaignId) external view returns (
        uint256 totalSupply,
        uint256 totalMinted
    ) {
        CampaignRewards storage rewards = campaignRewards[campaignId];
        require(rewards.configured, "Campaign not configured");
        
        for (uint256 i = 0; i < rewards.tiers.length; i++) {
            totalSupply += rewards.tiers[i].maxSupply;
            totalMinted += rewards.tiers[i].currentSupply;
        }
        
        return (totalSupply, totalMinted);
    }
    
    /**
     * @dev Check if campaign is single-tier
     */
    function isSingleTier(uint256 campaignId) external view returns (bool) {
        return campaignRewards[campaignId].tiers.length == 1;
    }
    
    /**
     * @dev Check if campaign is multi-tier
     */
    function isMultiTier(uint256 campaignId) external view returns (bool) {
        return campaignRewards[campaignId].tiers.length > 1;
    }
    
    // ===============================================
    // ADMIN FUNCTIONS
    // ===============================================
    
    /**
     * @dev Update tier configuration (owner only)
     */
    function updateTierConfig(
        uint256 campaignId,
        uint256 tierId,
        uint256 newMaxSupply,
        string memory newImageURI,
        bool active
    ) external onlyOwner {
        require(tierId < campaignRewards[campaignId].tiers.length, "Invalid tier ID");
        
        RewardTier storage tier = campaignRewards[campaignId].tiers[tierId];
        require(newMaxSupply >= tier.currentSupply, "Cannot reduce below current supply");
        
        tier.maxSupply = newMaxSupply;
        if (bytes(newImageURI).length > 0) {
            tier.imageURI = newImageURI;
        }
        tier.active = active;
    }
    
    /**
     * @dev Set minter authorization
     */
    function setMinterAuthorization(address minter, bool authorized) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinters[minter] = authorized;
        emit MinterAuthorized(minter, authorized);
    }
    
    /**
     * @dev Emergency function to mint tokens for testing
     */
    function emergencyMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    // ===============================================
    // REQUIRED OVERRIDES
    // ===============================================
    
    /**
     * @dev Override tokenURI for ERC721URIStorage
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @dev Override supportsInterface for multiple inheritance
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}