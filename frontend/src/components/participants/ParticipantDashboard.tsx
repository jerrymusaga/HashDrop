"use client"
// import { useWeb3 } from '@/hooks/useWeb3';
import { useEffect, useState } from 'react';
// import { ethers } from 'ethers';
// import { HashDropCampaign } from '@/contracts/HashDropCampaign'; // ABI and contract address
import { motion } from 'framer-motion';

// Mock Web3 hook for testing
const useMockWeb3 = () => {
  const [address, setAddress] = useState<string | null>(null);
  const [provider, setProvider] = useState<any>(null);
  const [isConnecting, setIsConnecting] = useState(false);

  const connectWallet = async () => {
    setIsConnecting(true);
    // Simulate connection delay
    setTimeout(() => {
      setAddress('0x742d35Cc6634C0532925a3b8D23b7C42BFcb7730');
      setProvider({ mock: true });
      setIsConnecting(false);
    }, 2000);
  };

  const disconnectWallet = () => {
    setAddress(null);
    setProvider(null);
  };

  return { address, provider, connectWallet, disconnectWallet, isConnecting };
};

interface Campaign {
  id: number;
  hashtag: string;
  score: number;
  rewardClaimed: boolean;
  campaignName: string;
  participationDate: string;
  rewardType: 'NFT' | 'Token';
  rewardAmount?: number;
}

interface NFTReward {
  id: number;
  name: string;
  image: string;
  tier: 'Bronze' | 'Silver' | 'Gold' | 'Diamond';
  campaignHashtag: string;
  claimedDate: string;
}

// Mock data
const mockCampaigns: Campaign[] = [
  {
    id: 1,
    hashtag: 'CleanOceans2024',
    score: 85,
    rewardClaimed: true,
    campaignName: 'Ocean Cleanup Initiative',
    participationDate: '2024-12-15',
    rewardType: 'NFT',
  },
  {
    id: 2,
    hashtag: 'GreenTech',
    score: 92,
    rewardClaimed: false,
    campaignName: 'Green Technology Awareness',
    participationDate: '2024-12-20',
    rewardType: 'Token',
    rewardAmount: 50,
  },
  {
    id: 3,
    hashtag: 'SustainableFuture',
    score: 76,
    rewardClaimed: true,
    campaignName: 'Sustainable Future Campaign',
    participationDate: '2024-12-10',
    rewardType: 'NFT',
  },
  {
    id: 4,
    hashtag: 'CryptoEducation',
    score: 88,
    rewardClaimed: false,
    campaignName: 'Crypto Education Week',
    participationDate: '2024-12-22',
    rewardType: 'Token',
    rewardAmount: 25,
  },
];

const mockNFTs: NFTReward[] = [
  {
    id: 1,
    name: 'Ocean Guardian',
    image: '/api/placeholder/200/200',
    tier: 'Gold',
    campaignHashtag: 'CleanOceans2024',
    claimedDate: '2024-12-16',
  },
  {
    id: 2,
    name: 'Eco Warrior',
    image: '/api/placeholder/200/200',
    tier: 'Silver',
    campaignHashtag: 'SustainableFuture',
    claimedDate: '2024-12-11',
  },
];

const ParticipantDashboard: React.FC = () => {
  const { address, provider, connectWallet, disconnectWallet, isConnecting } = useMockWeb3();
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [nftRewards, setNftRewards] = useState<NFTReward[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (address && provider) {
      fetchUserCampaigns();
    }
  }, [address, provider]);

  const fetchUserCampaigns = async () => {
    setIsLoading(true);
    
    // Simulate API call delay
    setTimeout(() => {
      // Use mock data for now
      setCampaigns(mockCampaigns);
      setNftRewards(mockNFTs);
      setIsLoading(false);
    }, 1000);

    // TODO: Replace with actual contract calls
    /*
    const contract = new ethers.Contract('CAMPAIGN_CONTRACT_ADDRESS', HashDropCampaign.abi, provider);
    const userCampaigns = await contract.getUserCampaigns(address);
    setCampaigns(userCampaigns);
    */
  };

  const claimReward = async (campaignId: number) => {
    setIsLoading(true);
    
    // Simulate claiming process
    setTimeout(() => {
      setCampaigns(prev => 
        prev.map(campaign => 
          campaign.id === campaignId 
            ? { ...campaign, rewardClaimed: true }
            : campaign
        )
      );
      setIsLoading(false);
      
      // Show success message (you can add toast notification here)
      alert('Reward claimed successfully!');
    }, 2000);

    // TODO: Replace with actual contract call
    /*
    const contract = new ethers.Contract('CAMPAIGN_CONTRACT_ADDRESS', HashDropCampaign.abi, provider.getSigner());
    await contract.claimReward(campaignId);
    */
  };

  const getScoreColor = (score: number) => {
    if (score >= 90) return 'text-green-400';
    if (score >= 70) return 'text-yellow-400';
    return 'text-red-400';
  };

  const getTierColor = (tier: string) => {
    switch (tier) {
      case 'Diamond': return 'text-purple-400';
      case 'Gold': return 'text-yellow-400';
      case 'Silver': return 'text-gray-300';
      case 'Bronze': return 'text-orange-400';
      default: return 'text-white';
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-slate-900 text-white pt-20 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-500 mx-auto"></div>
          <p className="mt-4 text-slate-300">Loading your dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900 text-white pt-20">
      <div className="px-4 sm:px-6 lg:px-8 py-8">
        <motion.h1 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-3xl font-bold mb-2"
        >
          Participant Dashboard
        </motion.h1>
        
      
        {!address ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center py-12"
          >
            <div className="max-w-md mx-auto">
              <div className="mb-8">
                <div className="w-20 h-20 bg-teal-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                </div>
                <h2 className="text-2xl font-bold mb-2">Connect Your Wallet</h2>
                <p className="text-slate-300 text-lg mb-6">
                  Connect your wallet to view your campaigns, rewards, and NFT collection.
                </p>
              </div>
              
              <div className="space-y-4">
                <button 
                  onClick={connectWallet}
                  disabled={isConnecting}
                  className="w-full bg-teal-600 text-white px-6 py-3 rounded-lg hover:bg-teal-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                >
                  {isConnecting ? (
                    <>
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                      Connecting...
                    </>
                  ) : (
                    'Connect Wallet'
                  )}
                </button>
                
                <div className="text-xs text-slate-400 space-y-1">
                  <p>🔐 Mock wallet connection for testing</p>
                  <p>📝 No real wallet needed</p>
                  <p>⚡ Instant demo data loading</p>
                </div>
              </div>
            </div>
          </motion.div>
        ) : (
          <div className="space-y-8">
            {/* Stats Overview */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="grid grid-cols-1 md:grid-cols-4 gap-4"
            >
              <div className="bg-slate-800 rounded-lg p-4 text-center">
                <h3 className="text-2xl font-bold text-teal-400">{campaigns.length}</h3>
                <p className="text-slate-300">Total Campaigns</p>
              </div>
              <div className="bg-slate-800 rounded-lg p-4 text-center">
                <h3 className="text-2xl font-bold text-green-400">
                  {campaigns.filter(c => c.rewardClaimed).length}
                </h3>
                <p className="text-slate-300">Rewards Claimed</p>
              </div>
              <div className="bg-slate-800 rounded-lg p-4 text-center">
                <h3 className="text-2xl font-bold text-yellow-400">
                  {Math.round(campaigns.reduce((acc, c) => acc + c.score, 0) / campaigns.length) || 0}
                </h3>
                <p className="text-slate-300">Avg Score</p>
              </div>
              <div className="bg-slate-800 rounded-lg p-4 text-center">
                <h3 className="text-2xl font-bold text-purple-400">{nftRewards.length}</h3>
                <p className="text-slate-300">NFTs Earned</p>
              </div>
            </motion.div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Campaigns List */}
              <motion.div 
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.2 }}
                className="bg-slate-800 rounded-lg p-6"
              >
                <h2 className="text-xl font-semibold mb-4">Your Campaigns</h2>
                {campaigns.length === 0 ? (
                  <p className="text-slate-300">No campaigns participated yet.</p>
                ) : (
                  <div className="space-y-4 max-h-96 overflow-y-auto">
                    {campaigns.map((campaign, index) => (
                      <motion.div
                        key={campaign.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.3 + index * 0.1 }}
                        className="p-4 bg-slate-900 rounded-lg border border-slate-700"
                      >
                        <div className="flex justify-between items-start mb-2">
                          <h3 className="font-semibold text-teal-400">#{campaign.hashtag}</h3>
                          <span className={`text-lg font-bold ${getScoreColor(campaign.score)}`}>
                            {campaign.score}/100
                          </span>
                        </div>
                        <p className="text-slate-300 text-sm mb-2">{campaign.campaignName}</p>
                        <p className="text-slate-400 text-xs mb-3">
                          Participated: {new Date(campaign.participationDate).toLocaleDateString()}
                        </p>
                        
                        <div className="flex justify-between items-center">
                          <div className="flex items-center space-x-2">
                            <span className={`px-2 py-1 rounded text-xs ${
                              campaign.rewardClaimed 
                                ? 'bg-green-900 text-green-300' 
                                : 'bg-yellow-900 text-yellow-300'
                            }`}>
                              {campaign.rewardClaimed ? 'Claimed' : 'Pending'}
                            </span>
                            <span className="text-xs text-slate-400">
                              {campaign.rewardType} {campaign.rewardAmount ? `(${campaign.rewardAmount})` : ''}
                            </span>
                          </div>
                          
                          {!campaign.rewardClaimed && (
                            <button 
                              onClick={() => claimReward(campaign.id)}
                              disabled={isLoading}
                              className="bg-teal-600 text-white px-3 py-1 rounded text-sm hover:bg-teal-700 transition disabled:opacity-50"
                            >
                              {isLoading ? 'Claiming...' : 'Claim Reward'}
                            </button>
                          )}
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </motion.div>

              {/* NFT Showcase */}
              <motion.div 
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
                className="bg-slate-800 rounded-lg p-6"
              >
                <h2 className="text-xl font-semibold mb-4">Your NFT Rewards</h2>
                {nftRewards.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-slate-300 mb-4">No NFTs earned yet.</p>
                    <p className="text-slate-400 text-sm">Complete campaigns and claim rewards to earn NFTs!</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-2 gap-4">
                    {nftRewards.map((nft, index) => (
                      <motion.div
                        key={nft.id}
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.4 + index * 0.1 }}
                        className="bg-slate-900 p-4 rounded-lg text-center border border-slate-700 hover:border-teal-500 transition"
                      >
                        <div className="w-full h-32 bg-gradient-to-br from-teal-500 to-purple-600 rounded mb-3 flex items-center justify-center">
                          <span className="text-white font-bold">NFT</span>
                        </div>
                        <p className="font-semibold text-sm mb-1">{nft.name}</p>
                        <p className={`text-xs mb-1 ${getTierColor(nft.tier)}`}>
                          {nft.tier} Tier
                        </p>
                        <p className="text-xs text-slate-400">#{nft.campaignHashtag}</p>
                        <p className="text-xs text-slate-500">
                          {new Date(nft.claimedDate).toLocaleDateString()}
                        </p>
                      </motion.div>
                    ))}
                  </div>
                )}
              </motion.div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ParticipantDashboard;