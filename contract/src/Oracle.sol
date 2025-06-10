// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "chainlink-brownie-contracts/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "chainlink-brownie-contracts/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HashDropCampaign} from "./Campaign.sol";

/**
 * @title HashDropOracle
 * @dev Chainlink Functions integration for monitoring Farcaster campaigns
 */
contract HashDropOracle is FunctionsClient, Ownable, ReentrancyGuard {
    using FunctionsRequest for FunctionsRequest.Request;

    // Chainlink Functions configuration
    bytes32 public donId;
    uint64 public subscriptionId;
    uint32 public gasLimit = 300000;
    
    // Campaign monitoring state
    struct CampaignMonitor {
        uint256 campaignId;
        string hashtag;
        address campaignContract;
        bool active;
        uint256 lastUpdateTime;
        uint256 checkInterval; // seconds between checks
        bytes32 pendingRequestId;
        mapping(address => UserEngagement) userEngagements;
        address[] trackedUsers;
    }
    
    struct UserEngagement {
        uint256 castCount;
        uint256 likeCount;
        uint256 recastCount;
        uint256 replyCount;
        uint256 totalScore;
        uint256 lastUpdateTime;
        bool exists;
    }
    
    // Storage
    mapping(uint256 => CampaignMonitor) public campaignMonitors;
    mapping(bytes32 => uint256) public requestToCampaign;
    mapping(uint256 => bool) public activeCampaigns;
    
    // Events
    event CampaignMonitoringStarted(uint256 indexed campaignId, string hashtag);
    event CampaignMonitoringStopped(uint256 indexed campaignId);
    event EngagementDataReceived(uint256 indexed campaignId, bytes32 requestId);
    event UserEngagementUpdated(uint256 indexed campaignId, address indexed user, uint256 newScore);
    event OracleConfigUpdated(bytes32 donId, uint64 subscriptionId, uint32 gasLimit);
    
    // JavaScript source code for Chainlink Functions
    string private constant FARCASTER_SOURCE = 
        "const campaignId = args[0];"
        "const hashtag = args[1];"
        "const lastUpdateTime = args[2];"
        "const apiUrl = `https://api.farcaster.xyz/v2/casts?q=${hashtag}&limit=100&since=${lastUpdateTime}`;"
        "const response = await Functions.makeHttpRequest({"
        "  url: apiUrl,"
        "  headers: { 'Authorization': `Bearer ${secrets.farcasterApiKey}` }"
        "});"
        "if (response.error) throw new Error('API request failed');"
        "const casts = response.data.result.casts || [];"
        "const userEngagements = {};"
        "for (const cast of casts) {"
        "  const userFid = cast.author.fid;"
        "  const userAddress = cast.author.verified_addresses?.eth_addresses?.[0];"
        "  if (!userAddress) continue;"
        "  if (!userEngagements[userAddress]) {"
        "    userEngagements[userAddress] = { casts: 0, likes: 0, recasts: 0, replies: 0 };"
        "  }"
        "  userEngagements[userAddress].casts += 1;"
        "  userEngagements[userAddress].likes += cast.reactions?.likes?.length || 0;"
        "  userEngagements[userAddress].recasts += cast.reactions?.recasts?.length || 0;"
        "  userEngagements[userAddress].replies += cast.replies?.count || 0;"
        "}"
        "return Functions.encodeString(JSON.stringify(userEngagements));";

    constructor(
        address router,
        bytes32 _donId,
        uint64 _subscriptionId
    ) FunctionsClient(router) Ownable(msg.sender) {
        donId = _donId;
        subscriptionId = _subscriptionId;
    }

    /**
     * @dev Start monitoring a campaign's hashtag on Farcaster
     */
    function startCampaignMonitoring(
        uint256 campaignId,
        string memory hashtag,
        address campaignContract,
        uint256 checkInterval
    ) external onlyOwner {
        require(!activeCampaigns[campaignId], "Campaign already being monitored");
        require(bytes(hashtag).length > 0, "Hashtag cannot be empty");
        require(campaignContract != address(0), "Invalid campaign contract");
        require(checkInterval >= 300, "Check interval must be at least 5 minutes");

        CampaignMonitor storage monitor = campaignMonitors[campaignId];
        monitor.campaignId = campaignId;
        monitor.hashtag = hashtag;
        monitor.campaignContract = campaignContract;
        monitor.active = true;
        monitor.lastUpdateTime = block.timestamp;
        monitor.checkInterval = checkInterval;

        activeCampaigns[campaignId] = true;

        // Start initial monitoring request
        _requestEngagementData(campaignId);

        emit CampaignMonitoringStarted(campaignId, hashtag);
    }

    /**
     * @dev Stop monitoring a campaign
     */
    function stopCampaignMonitoring(uint256 campaignId) external onlyOwner {
        require(activeCampaigns[campaignId], "Campaign not being monitored");

        campaignMonitors[campaignId].active = false;
        activeCampaigns[campaignId] = false;

        emit CampaignMonitoringStopped(campaignId);
    }

    /**
     * @dev Manual trigger for updating campaign engagement data
     */
    function updateCampaignData(uint256 campaignId) external {
        require(activeCampaigns[campaignId], "Campaign not being monitored");
        CampaignMonitor storage monitor = campaignMonitors[campaignId];
        require(
            block.timestamp >= monitor.lastUpdateTime + monitor.checkInterval,
            "Too early for update"
        );

        _requestEngagementData(campaignId);
    }

    /**
     * @dev Internal function to request engagement data from Farcaster
     */
    function _requestEngagementData(uint256 campaignId) internal {
        CampaignMonitor storage monitor = campaignMonitors[campaignId];
        require(monitor.active, "Campaign monitoring not active");
        require(monitor.pendingRequestId == bytes32(0), "Request already pending");

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(FARCASTER_SOURCE);

        // Set up request arguments
        string[] memory args = new string[](3);
        args[0] = _uint2str(campaignId);
        args[1] = monitor.hashtag;
        args[2] = _uint2str(monitor.lastUpdateTime);
        req.setArgs(args);

        // Set secrets reference for Farcaster API key
        req.addSecretsReference("farcasterApiKey");

        // Send request
        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );

        monitor.pendingRequestId = requestId;
        requestToCampaign[requestId] = campaignId;
    }

    /**
     * @dev Chainlink Functions callback
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        uint256 campaignId = requestToCampaign[requestId];
        CampaignMonitor storage monitor = campaignMonitors[campaignId];

        if (err.length > 0) {
            // Handle error - could emit event or implement retry logic
            monitor.pendingRequestId = bytes32(0);
            return;
        }

        // Clear pending request
        monitor.pendingRequestId = bytes32(0);
        monitor.lastUpdateTime = block.timestamp;

        // Process engagement data
        _processEngagementData(campaignId, response);

        emit EngagementDataReceived(campaignId, requestId);

        // Clean up request mapping
        delete requestToCampaign[requestId];
    }

    /**
     * @dev Process engagement data and update user scores
     */
    function _processEngagementData(uint256 campaignId, bytes memory response) internal {
        CampaignMonitor storage monitor = campaignMonitors[campaignId];
        
        // Decode the JSON response
        string memory jsonData = abi.decode(response, (string));
        
        // In a real implementation, you'd need a JSON parser library
        // For now, we'll assume the data is properly formatted
        // This is a simplified version - in production, use a JSON parsing library
        
        // Update campaign contract with new participation data
        HashDropCampaign campaignContract = HashDropCampaign(monitor.campaignContract);
        
        // Note: This is a simplified example. In production, you'd parse the JSON
        // and extract user addresses and their engagement metrics
    }

    /**
     * @dev Calculate engagement score based on activities
     */
    function _calculateEngagementScore(
        uint256 castCount,
        uint256 likeCount,
        uint256 recastCount,
        uint256 replyCount
    ) internal pure returns (uint256) {
        // Weighted scoring algorithm
        uint256 score = 0;
        score += castCount * 25;      // Original casts worth 25 points each
        score += likeCount * 5;       // Likes worth 5 points each
        score += recastCount * 15;    // Recasts worth 15 points each
        score += replyCount * 10;     // Replies worth 10 points each
        
        // Cap at 100
        return score > 100 ? 100 : score;
    }

    /**
     * @dev Get user engagement data for a campaign
     */
    function getUserEngagement(uint256 campaignId, address user) external view returns (
        uint256 castCount,
        uint256 likeCount,
        uint256 recastCount,
        uint256 replyCount,
        uint256 totalScore,
        uint256 lastUpdateTime
    ) {
        UserEngagement storage engagement = campaignMonitors[campaignId].userEngagements[user];
        require(engagement.exists, "User not found in campaign");
        
        return (
            engagement.castCount,
            engagement.likeCount,
            engagement.recastCount,
            engagement.replyCount,
            engagement.totalScore,
            engagement.lastUpdateTime
        );
    }

    /**
     * @dev Get campaign monitoring status
     */
    function getCampaignMonitorStatus(uint256 campaignId) external view returns (
        string memory hashtag,
        address campaignContract,
        bool active,
        uint256 lastUpdateTime,
        uint256 checkInterval,
        bool hasPendingRequest,
        uint256 trackedUserCount
    ) {
        CampaignMonitor storage monitor = campaignMonitors[campaignId];
        return (
            monitor.hashtag,
            monitor.campaignContract,
            monitor.active,
            monitor.lastUpdateTime,
            monitor.checkInterval,
            monitor.pendingRequestId != bytes32(0),
            monitor.trackedUsers.length
        );
    }

    /**
     * @dev Update oracle configuration
     */
    function updateOracleConfig(
        bytes32 _donId,
        uint64 _subscriptionId,
        uint32 _gasLimit
    ) external onlyOwner {
        donId = _donId;
        subscriptionId = _subscriptionId;
        gasLimit = _gasLimit;
        
        emit OracleConfigUpdated(_donId, _subscriptionId, _gasLimit);
    }

    /**
     * @dev Get all tracked users for a campaign
     */
    function getCampaignUsers(uint256 campaignId) external view returns (address[] memory) {
        return campaignMonitors[campaignId].trackedUsers;
    }

    /**
     * @dev Utility function to convert uint to string
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Emergency function to withdraw LINK tokens
     */
    function withdrawLink() external onlyOwner {
        // Implementation depends on your LINK token management
    }
}