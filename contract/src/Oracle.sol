// // HashDropOracle.sol - Enhanced with proper Chainlink integration
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
// import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./Campaign.sol";

// contract HashDropOracle is FunctionsClient, Ownable {
//     using FunctionsRequest for FunctionsRequest.Request;

//     // Chainlink Functions Configuration
//     bytes32 public donId;
//     uint64 public subscriptionId;
//     uint32 public gasLimit = 300000;
    
//     // Campaign monitoring
//     struct CampaignMonitor {
//         uint256 campaignId;
//         string hashtag;
//         bool active;
//         uint256 lastCheck;
//         bytes32 pendingRequestId;
//     }
    
//     mapping(uint256 => CampaignMonitor) public monitors;
//     mapping(bytes32 => uint256) public requestToCampaign;
//     HashDropCampaign public campaignContract;
    
//     // Neynar API monitoring JavaScript code for Chainlink Functions
//     string private constant FARCASTER_SOURCE = 
//         "const hashtag = args[0];"
//         "const lastCheck = args[1];"
//         "const apiUrl = `https://api.neynar.com/v2/farcaster/cast/search?q=${hashtag}&limit=50&cursor=`;"
//         "try {"
//         "  const response = await Functions.makeHttpRequest({"
//         "    url: apiUrl,"
//         "    headers: { 'api_key': secrets.neynarKey, 'accept': 'application/json' }"
//         "  });"
//         "  if (response.error) throw new Error('Neynar API failed');"
//         "  const casts = response.data.result?.casts || [];"
//         "  const users = [];"
//         "  const scores = [];"
//         "  for (const cast of casts) {"
//         "    if (new Date(cast.timestamp) < new Date(lastCheck * 1000)) continue;"
//         "    const userAddr = cast.author.verified_addresses?.eth_addresses?.[0];"
//         "    if (userAddr && cast.text.toLowerCase().includes(hashtag.toLowerCase())) {"
//         "      const reactions = cast.reactions || {};"
//         "      const replies = cast.replies?.count || 0;"
//         "      const recasts = reactions.recasts?.length || 0;"
//         "      const likes = reactions.likes?.length || 0;"
//         "      const score = Math.min(100, Math.max(10, "
//         "        likes * 3 + recasts * 8 + replies * 5 + "
//         "        (cast.text.length > 100 ? 25 : cast.text.length > 50 ? 15 : 10) + "
//         "        (cast.embeds?.length > 0 ? 10 : 0)"
//         "      ));"
//         "      users.push(userAddr);"
//         "      scores.push(score);"
//         "    }"
//         "  }"
//         "  return Functions.encodeString(JSON.stringify({users, scores, count: users.length}));"
//         "} catch (error) {"
//         "  throw new Error(`Neynar request failed: ${error.message}`);"
//         "}";

//     event MonitoringStarted(uint256 indexed campaignId, string hashtag);
//     event DataReceived(uint256 indexed campaignId, uint256 userCount);
    
//     constructor(
//         address router,
//         bytes32 _donId,
//         uint64 _subscriptionId,
//         address _campaignContract
//     ) FunctionsClient(router) Ownable(msg.sender) {
//         donId = _donId;
//         subscriptionId = _subscriptionId;
//         campaignContract = HashDropCampaign(_campaignContract);
//     }
    
//     /**
//      * @dev Start monitoring a campaign hashtag
//      */
//     function startMonitoring(uint256 campaignId, string memory hashtag) external onlyOwner {
//         require(!monitors[campaignId].active, "Already monitoring");
        
//         monitors[campaignId] = CampaignMonitor({
//             campaignId: campaignId,
//             hashtag: hashtag,
//             active: true,
//             lastCheck: block.timestamp,
//             pendingRequestId: bytes32(0)
//         });
        
//         // Start first check
//         _requestFarcasterData(campaignId);
        
//         emit MonitoringStarted(campaignId, hashtag);
//     }
    
//     /**
//      * @dev Manual trigger for checking (also called by Automation)
//      */
//     function checkCampaign(uint256 campaignId) external {
//         CampaignMonitor storage monitor = monitors[campaignId];
//         require(monitor.active, "Not monitoring");
//         require(monitor.pendingRequestId == bytes32(0), "Request pending");
        
//         _requestFarcasterData(campaignId);
//     }
    
//     function _requestFarcasterData(uint256 campaignId) internal {
//         CampaignMonitor storage monitor = monitors[campaignId];
        
//         FunctionsRequest.Request memory req;
//         req.initializeRequestForInlineJavaScript(FARCASTER_SOURCE);
        
//         string[] memory args = new string[](2);
//         args[0] = monitor.hashtag;
//         args[1] = _toString(monitor.lastCheck);
//         req.setArgs(args);
        
//         req.addSecretsReference("neynarKey");
        
//         bytes32 requestId = _sendRequest(
//             req.encodeCBOR(),
//             subscriptionId,
//             gasLimit,
//             donId
//         );
        
//         monitor.pendingRequestId = requestId;
//         requestToCampaign[requestId] = campaignId;
//     }
    
//     /**
//      * @dev Chainlink Functions callback
//      */
//     function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
//         uint256 campaignId = requestToCampaign[requestId];
//         CampaignMonitor storage monitor = monitors[campaignId];
        
//         monitor.pendingRequestId = bytes32(0);
//         monitor.lastCheck = block.timestamp;
        
//         if (err.length > 0) return; // Handle error silently
        
//         try this.processResponse(campaignId, response) {} catch {}
//         delete requestToCampaign[requestId];
//     }
    
//     function processResponse(uint256 campaignId, bytes memory response) external {
//         require(msg.sender == address(this), "Internal only");
        
//         string memory jsonData = abi.decode(response, (string));
//         // In production, use a JSON parser library like Chainlink's
//         // For now, we'll assume the off-chain system handles this
        
//         emit DataReceived(campaignId, 0); // Placeholder
//     }
    
//     function updateConfig(bytes32 _donId, uint64 _subscriptionId, uint32 _gasLimit) external onlyOwner {
//         donId = _donId;
//         subscriptionId = _subscriptionId;
//         gasLimit = _gasLimit;
//     }
    
//     function _toString(uint256 value) internal pure returns (string memory) {
//         if (value == 0) return "0";
//         uint256 temp = value;
//         uint256 digits;
//         while (temp != 0) {
//             digits++;
//             temp /= 10;
//         }
//         bytes memory buffer = new bytes(digits);
//         while (value != 0) {
//             digits -= 1;
//             buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
//             value /= 10;
//         }
//         return string(buffer);
//     }
// }