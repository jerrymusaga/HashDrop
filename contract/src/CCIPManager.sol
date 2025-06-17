// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HashDropCCIP is CCIPReceiver, Ownable {
    
    struct CrossChainReward {
        uint256 campaignId;
        address user;
        uint256 score;
        uint64 sourceChain;
    }
    
    mapping(uint64 => bool) public allowedChains;
    mapping(address => bool) public allowedSenders;
    address public vaultContract;
    
    event CrossChainRewardReceived(uint256 campaignId, address user, uint256 score);
    event CrossChainRewardSent(uint256 campaignId, address user, uint64 destinationChain);
    
    constructor(address router) CCIPReceiver(router) Ownable(msg.sender) {}
    
    /**
     * @dev Send cross-chain reward request
     */
    function sendCrossChainReward(
        uint64 destinationChain,
        address destinationContract,
        uint256 campaignId,
        address user,
        uint256 score
    ) external payable {
        require(allowedChains[destinationChain], "Chain not allowed");
        require(msg.sender == vaultContract || msg.sender == owner(), "Unauthorized");
        
        CrossChainReward memory reward = CrossChainReward({
            campaignId: campaignId,
            user: user,
            score: score,
            sourceChain: uint64(block.chainid)
        });
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationContract),
            data: abi.encode(reward),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200000})),
            feeToken: address(0) // Use native token for fees
        });
        
        uint256 fee = IRouterClient(getRouter()).getFee(destinationChain, message);
        require(msg.value >= fee, "Insufficient fee");
        
        IRouterClient(getRouter()).ccipSend{value: fee}(destinationChain, message);
        
        emit CrossChainRewardSent(campaignId, user, destinationChain);
    }
    
    /**
     * @dev Receive cross-chain reward request
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        require(allowedChains[message.sourceChainSelector], "Chain not allowed");
        require(allowedSenders[abi.decode(message.sender, (address))], "Sender not allowed");
        
        CrossChainReward memory reward = abi.decode(message.data, (CrossChainReward));
        
        // Process reward through vault
        if (vaultContract != address(0)) {
            (bool success,) = vaultContract.call(
                abi.encodeWithSignature(
                    "processIndividualReward(uint256,address,uint256)",
                    reward.campaignId,
                    reward.user,
                    reward.score
                )
            );
            require(success, "Reward processing failed");
        }
        
        emit CrossChainRewardReceived(reward.campaignId, reward.user, reward.score);
    }
    
    /**
     * @dev Configure allowed chains and senders
     */
    function configureAccess(
        uint64[] memory chains,
        address[] memory senders,
        bool[] memory allowed
    ) external onlyOwner {
        require(chains.length == allowed.length, "Chain array mismatch");
        require(senders.length == allowed.length, "Sender array mismatch");
        
        for (uint256 i = 0; i < chains.length; i++) {
            allowedChains[chains[i]] = allowed[i];
        }
        
        for (uint256 i = 0; i < senders.length; i++) {
            allowedSenders[senders[i]] = allowed[i];
        }
    }
    
    function setVaultContract(address _vaultContract) external onlyOwner {
        vaultContract = _vaultContract;
    }
}