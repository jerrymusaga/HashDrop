"use client"
import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { ethers } from 'ethers';
// import { HashDropCampaign } from '../contracts/HashDropCampaign'; // Uncomment when ready

interface Campaign {
  id: string;
  hashtag: string;
  description: string;
  rewardType: string;
  supportedChains: string[];
  totalReward?: string;
  participantCount?: number;
  endDate?: string;
  status?: 'active' | 'completed' | 'upcoming';
}

const CampaignsPage: React.FC = () => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCampaigns();
  }, []);

  const fetchCampaigns = async () => {
    try {
      // TODO: Replace with actual blockchain calls when ready
      // const provider = new ethers.JsonRpcProvider('YOUR_PROVIDER_URL');
      // const contract = new ethers.Contract('CAMPAIGN_CONTRACT_ADDRESS', HashDropCampaign.abi, provider);
      
      // Mock data for development
      const mockCampaigns: Campaign[] = [
        {
          id: '1',
          hashtag: '#BuildOnEthereum',
          description: 'Share your Ethereum development journey and earn rewards for inspiring others to build on the platform.',
          rewardType: 'ETH + NFT Badge',
          supportedChains: ['Ethereum', 'Polygon'],
          totalReward: '5 ETH',
          participantCount: 1247,
          endDate: '2025-07-01',
          status: 'active'
        },
        {
          id: '2',
          hashtag: '#DeFiEducation',
          description: 'Create educational content about DeFi protocols and help newcomers understand decentralized finance.',
          rewardType: 'USDC Rewards',
          supportedChains: ['Ethereum', 'Arbitrum', 'Optimism'],
          totalReward: '10,000 USDC',
          participantCount: 892,
          endDate: '2025-06-25',
          status: 'active'
        },
        {
          id: '3',
          hashtag: '#NFTArtShowcase',
          description: 'Showcase your NFT artwork and connect with collectors. Winners receive platform promotion and rewards.',
          rewardType: 'Platform Tokens + Promotion',
          supportedChains: ['Ethereum', 'Polygon', 'Base'],
          totalReward: '50,000 HDROP',
          participantCount: 2156,
          endDate: '2025-06-30',
          status: 'active'
        },
        {
          id: '4',
          hashtag: '#Layer2Solutions',
          description: 'Discuss the benefits and innovations of Layer 2 scaling solutions for Ethereum.',
          rewardType: 'L2 Native Tokens',
          supportedChains: ['Arbitrum', 'Optimism', 'Polygon'],
          totalReward: 'Mixed L2 Tokens',
          participantCount: 445,
          endDate: '2025-07-15',
          status: 'active'
        },
        {
          id: '5',
          hashtag: '#CryptoForGood',
          description: 'Share stories about how cryptocurrency is making a positive impact in your community.',
          rewardType: 'Charity Donation Match',
          supportedChains: ['Ethereum', 'Polygon'],
          totalReward: '25 ETH Charity Match',
          participantCount: 678,
          endDate: '2025-08-01',
          status: 'active'
        },
        {
          id: '6',
          hashtag: '#ZKProofExplained',
          description: 'Help others understand Zero-Knowledge proofs through simple explanations and examples.',
          rewardType: 'ZK Ecosystem Tokens',
          supportedChains: ['Ethereum', 'Polygon zkEVM'],
          totalReward: 'Various ZK Tokens',
          participantCount: 234,
          endDate: '2025-07-20',
          status: 'upcoming'
        }
      ];

      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setCampaigns(mockCampaigns);
    } catch (error) {
      console.error('Error fetching campaigns:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-400';
      case 'completed': return 'text-gray-400';
      case 'upcoming': return 'text-yellow-400';
      default: return 'text-slate-300';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active': return 'Active';
      case 'completed': return 'Completed';
      case 'upcoming': return 'Starting Soon';
      default: return 'Unknown';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 text-white pt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-500"></div>
            <span className="ml-3 text-lg">Loading campaigns...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900 text-white pt-20">
      <div className=" px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold">Active Campaigns</h1>
          <div className="text-slate-400">
            {campaigns.filter(c => c.status === 'active').length} active campaigns
          </div>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {campaigns.map((campaign) => (
            <div key={campaign.id} className="bg-slate-800 p-6 rounded-lg shadow-lg hover:bg-slate-750 transition-colors border border-slate-700">
              <div className="flex justify-between items-start mb-4">
                <h2 className="text-xl font-semibold text-teal-400">#{campaign.hashtag.replace('#', '')}</h2>
                <span className={`text-sm font-medium ${getStatusColor(campaign.status || 'active')}`}>
                  {getStatusText(campaign.status || 'active')}
                </span>
              </div>
              
              <p className="text-slate-300 mb-4 text-sm leading-relaxed">
                {campaign.description}
              </p>
              
              <div className="space-y-2 mb-4">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">Reward:</span>
                  <span className="text-white font-medium">{campaign.rewardType}</span>
                </div>
                
                {campaign.totalReward && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-400">Total Pool:</span>
                    <span className="text-green-400 font-medium">{campaign.totalReward}</span>
                  </div>
                )}
                
                {campaign.participantCount && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-400">Participants:</span>
                    <span className="text-white">{campaign.participantCount.toLocaleString()}</span>
                  </div>
                )}
                
                {campaign.endDate && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-400">Ends:</span>
                    <span className="text-white">{new Date(campaign.endDate).toLocaleDateString()}</span>
                  </div>
                )}
              </div>
              
              <div className="mb-4">
                <span className="text-slate-400 text-sm">Supported chains:</span>
                <div className="flex flex-wrap gap-1 mt-1">
                  {campaign.supportedChains.map((chain, index) => (
                    <span 
                      key={index} 
                      className="bg-slate-700 text-xs px-2 py-1 rounded-full text-slate-300"
                    >
                      {chain}
                    </span>
                  ))}
                </div>
              </div>
              
              <Link 
                href={`/campaigns/${campaign.id}`} 
                className="block w-full text-center bg-teal-600 text-white px-4 py-2 rounded-lg hover:bg-teal-700 transition-colors font-medium"
              >
                {campaign.status === 'upcoming' ? 'View Details' : 'Participate'}
              </Link>
            </div>
          ))}
        </div>
        
        {campaigns.length === 0 && !loading && (
          <div className="text-center py-12">
            <div className="text-slate-400 text-lg mb-4">No campaigns available</div>
            <p className="text-slate-500">Check back later for new campaigns!</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default CampaignsPage;