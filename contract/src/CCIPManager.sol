// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IHashDropCampaign {
    function recordParticipation(uint256 campaignId, address participant, uint256 score) external;
    function hasUserParticipated(uint256 campaignId, address user) external view returns (bool);
    function getUserScore(uint256 campaignId, address user) external view returns (uint256);
    function getCampaignChains(uint256 campaignId) external view returns (uint256[] memory, bool);
}

interface IHashDropVault {
    function processRewardClaim(uint256 campaignId, address user, uint256 score) external;
}

contract HashDropCCIPManager is CCIPReceiver, OwnerIsCreator, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum MessageType { PARTICIPATION, CLAIM_REWARD, SYNC_DATA }

    struct CrossChainMessage {
        MessageType msgType;
        uint256 campaignId;
        address user;
        uint256 score;
        uint64 sourceChainSelector;
    }

    // Chain selector mappings
    mapping(uint256 => uint64) public chainIdToSelector;
    mapping(uint64 => uint256) public selectorToChainId;
    mapping(uint64 => bool) public allowlistedSourceChains;
    mapping(address => bool) public allowlistedSenders;

    // Contract references
    IHashDropCampaign public campaignContract;
    IHashDropVault public vaultContract;

    // Fee management
    IERC20 public linkToken;
    address public feeToken; // Can be LINK or native token

    // Events
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        MessageType msgType,
        uint256 campaignId,
        address user,
        uint256 score,
        address feeToken,
        uint256 fees
    );

    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        MessageType msgType,
        uint256 campaignId,
        address user,
        uint256 score
    );

    event ChainConfigured(uint256 indexed chainId, uint64 chainSelector);
    event ContractReferencesUpdated(address campaignContract, address vaultContract);

    modifier onlyAllowlistedSender(uint64 _sourceChainSelector, address _sender) {
        require(allowlistedSourceChains[_sourceChainSelector], "Source chain not allowlisted");
        require(allowlistedSenders[_sender], "Sender not allowlisted");
        _;
    }

    constructor(
        address _router,
        address _linkToken,
        address _campaignContract,
        address _vaultContract
    ) CCIPReceiver(_router) {
        linkToken = IERC20(_linkToken);
        feeToken = _linkToken; // Default to LINK
        campaignContract = IHashDropCampaign(_campaignContract);
        vaultContract = IHashDropVault(_vaultContract);
    }

    /**
     * @dev Configure chain selector mappings
     */
    function configureChain(uint256 chainId, uint64 chainSelector) external onlyOwner {
        chainIdToSelector[chainId] = chainSelector;
        selectorToChainId[chainSelector] = chainId;
        emit ChainConfigured(chainId, chainSelector);
    }

    /**
     * @dev Configure multiple chains at once
     */
    function configureChains(
        uint256[] calldata chainIds,
        uint64[] calldata chainSelectors
    ) external onlyOwner {
        require(chainIds.length == chainSelectors.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < chainIds.length; i++) {
            chainIdToSelector[chainIds[i]] = chainSelectors[i];
            selectorToChainId[chainSelectors[i]] = chainIds[i];
            emit ChainConfigured(chainIds[i], chainSelectors[i]);
        }
    }

    /**
     * @dev Allowlist source chains and senders
     */
    function allowlistSourceChain(uint64 _sourceChainSelector, bool allowed) external onlyOwner {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    /**
     * @dev Update contract references
     */
    function updateContractReferences(
        address _campaignContract,
        address _vaultContract
    ) external onlyOwner {
        campaignContract = IHashDropCampaign(_campaignContract);
        vaultContract = IHashDropVault(_vaultContract);
        emit ContractReferencesUpdated(_campaignContract, _vaultContract);
    }

    /**
     * @dev Set fee token (LINK or address(0) for native)
     */
    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = _feeToken;
    }

    /**
     * @dev Send participation data to all supported chains for a campaign
     */
    function broadcastParticipation(
        uint256 campaignId,
        address participant,
        uint256 score
    ) external onlyOwner nonReentrant {
        (uint256[] memory supportedChains, bool crossChainEnabled) = campaignContract.getCampaignChains(campaignId);
        require(crossChainEnabled, "Campaign not cross-chain enabled");

        CrossChainMessage memory message = CrossChainMessage({
            msgType: MessageType.PARTICIPATION,
            campaignId: campaignId,
            user: participant,
            score: score,
            sourceChainSelector: chainIdToSelector[block.chainid]
        });

        for (uint256 i = 0; i < supportedChains.length; i++) {
            uint256 chainId = supportedChains[i];
            if (chainId != block.chainid) {
                uint64 destinationChainSelector = chainIdToSelector[chainId];
                require(destinationChainSelector != 0, "Chain selector not configured");
                
                _sendMessage(destinationChainSelector, message);
            }
        }
    }

    /**
     * @dev Send reward claim request to destination chain
     */
    function sendRewardClaim(
        uint256 destinationChainId,
        uint256 campaignId,
        address user,
        uint256 score
    ) external onlyOwner nonReentrant {
        uint64 destinationChainSelector = chainIdToSelector[destinationChainId];
        require(destinationChainSelector != 0, "Chain selector not configured");

        CrossChainMessage memory message = CrossChainMessage({
            msgType: MessageType.CLAIM_REWARD,
            campaignId: campaignId,
            user: user,
            score: score,
            sourceChainSelector: chainIdToSelector[block.chainid]
        });

        _sendMessage(destinationChainSelector, message);
    }

    /**
     * @dev Internal function to send CCIP message
     */
    function _sendMessage(
        uint64 destinationChainSelector,
        CrossChainMessage memory message
    ) internal {
        // Create message payload
        bytes memory messageData = abi.encode(message);
        
        // Build CCIP message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)), // Receiver is this contract on destination chain
            data: messageData,
            tokenAmounts: new Client.EVMTokenAmount[](0), // No tokens being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 300_000}) // Gas limit for execution
            ),
            feeToken: feeToken
        });

        // Get fee
        uint256 fees = IRouterClient(getRouter()).getFee(destinationChainSelector, evm2AnyMessage);

        // Pay fees
        if (feeToken == address(0)) {
            require(address(this).balance >= fees, "Insufficient native token for fees");
        } else {
            linkToken.safeTransferFrom(msg.sender, address(this), fees);
            linkToken.safeApprove(getRouter(), fees);
        }

        // Send message
        bytes32 messageId = IRouterClient(getRouter()).ccipSend{value: feeToken == address(0) ? fees : 0}(
            destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            destinationChainSelector,
            address(this),
            message.msgType,
            message.campaignId,
            message.user,
            message.score,
            feeToken,
            fees
        );
    }

    /**
     * @dev Receive and process CCIP messages
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override onlyAllowlistedSender(
        any2EvmMessage.sourceChainSelector,
        abi.decode(any2EvmMessage.sender, (address))
    ) {
        CrossChainMessage memory message = abi.decode(any2EvmMessage.data, (CrossChainMessage));

        if (message.msgType == MessageType.PARTICIPATION) {
            _handleParticipationMessage(message);
        } else if (message.msgType == MessageType.CLAIM_REWARD) {
            _handleRewardClaimMessage(message);
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            message.msgType,
            message.campaignId,
            message.user,
            message.score
        );
    }

    /**
     * @dev Handle participation message from another chain
     */
    function _handleParticipationMessage(CrossChainMessage memory message) internal {
        try campaignContract.recordParticipation(
            message.campaignId,
            message.user,
            message.score
        ) {} catch {
            // Silently handle cases where participation already exists
        }
    }

    /**
     * @dev Handle reward claim message from another chain
     */
    function _handleRewardClaimMessage(CrossChainMessage memory message) internal {
        try vaultContract.processRewardClaim(
            message.campaignId,
            message.user,
            message.score
        ) {} catch {
            // Handle claim failures gracefully
        }
    }

    /**
     * @dev Get estimated fee for sending message
     */
    function getEstimatedFee(
        uint256 destinationChainId,
        MessageType msgType,
        uint256 campaignId,
        address user,
        uint256 score
    ) external view returns (uint256) {
        uint64 destinationChainSelector = chainIdToSelector[destinationChainId];
        require(destinationChainSelector != 0, "Chain selector not configured");

        CrossChainMessage memory message = CrossChainMessage({
            msgType: msgType,
            campaignId: campaignId,
            user: user,
            score: score,
            sourceChainSelector: chainIdToSelector[block.chainid]
        });

        bytes memory messageData = abi.encode(message);
        
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: messageData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 300_000})
            ),
            feeToken: feeToken
        });

        return IRouterClient(getRouter()).getFee(destinationChainSelector, evm2AnyMessage);
    }

    /**
     * @dev Withdraw accumulated fees/tokens
     */
    function withdraw(address _beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            (bool sent, ) = _beneficiary.call{value: amount}("");
            require(sent, "Failed to send Ether");
        }
    }

    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0) {
            IERC20(_token).safeTransfer(_beneficiary, amount);
        }
    }

    receive() external payable {}
}