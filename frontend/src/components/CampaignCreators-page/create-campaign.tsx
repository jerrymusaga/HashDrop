"use client"
import { useState } from 'react';
import { motion } from 'framer-motion';

// Mock Web3 hook for testing
const useMockWeb3 = () => {
  const [address, setAddress] = useState<string | null>(null);
  const [provider, setProvider] = useState<any>(null);
  const [isConnecting, setIsConnecting] = useState(false);

  const connectWallet = async () => {
    setIsConnecting(true);
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

// Mock campaign templates for quick setup
const campaignTemplates = [
  {
    name: "Ocean Cleanup",
    hashtag: "CleanOceans2024",
    description: "Join our mission to clean the oceans! Share your beach cleanup photos and eco-friendly tips.",
    duration: 604800, // 7 days
    totalBudget: 1000,
    totalRewards: 50,
    tierName: "Ocean Guardian",
    baseURI: "https://ipfs.io/ipfs/ocean-cleanup/",
    maxSupply: 100
  },
  {
    name: "Green Tech Innovation",
    hashtag: "GreenTech2024",
    description: "Showcase innovative green technology solutions and sustainable practices.",
    duration: 1209600, // 14 days
    totalBudget: 2000,
    totalRewards: 100,
    tierName: "Tech Pioneer",
    baseURI: "https://ipfs.io/ipfs/green-tech/",
    maxSupply: 200
  },
  {
    name: "Crypto Education",
    hashtag: "CryptoEdu",
    description: "Share educational content about cryptocurrency and blockchain technology.",
    duration: 432000, // 5 days
    totalBudget: 500,
    totalRewards: 25,
    tierName: "Crypto Educator",
    baseURI: "https://ipfs.io/ipfs/crypto-edu/",
    maxSupply: 75
  }
];

interface FormData {
  hashtag: string;
  description: string;
  duration: number;
  totalBudget: number;
  totalRewards: number;
  tierName: string;
  baseURI: string;
  maxSupply: number;
}

const CreateCampaign: React.FC = () => {
  const { address, provider, connectWallet, disconnectWallet, isConnecting } = useMockWeb3();
  const [formData, setFormData] = useState<FormData>({
    hashtag: '',
    description: '',
    duration: 0,
    totalBudget: 0,
    totalRewards: 0,
    tierName: '',
    baseURI: '',
    maxSupply: 0,
  });
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<Partial<FormData>>({});
  const [showPreview, setShowPreview] = useState(false);

  const validateForm = (): boolean => {
    const newErrors: Partial<FormData> = {};
    
    if (!formData.hashtag.trim()) newErrors.hashtag = 'Hashtag is required';
    if (!formData.description.trim()) newErrors.description = 'Description is required';
    if (formData.duration <= 0) newErrors.duration = 'Duration must be greater than 0';
    if (formData.totalBudget <= 0) newErrors.totalBudget = 'Budget must be greater than 0';
    if (formData.totalRewards <= 0) newErrors.totalRewards = 'Rewards must be greater than 0';
    if (!formData.tierName.trim()) newErrors.tierName = 'Tier name is required';
    if (!formData.baseURI.trim()) newErrors.baseURI = 'Base URI is required';
    if (formData.maxSupply <= 0) newErrors.maxSupply = 'Max supply must be greater than 0';
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!address || !provider) return;
    
    if (!validateForm()) return;

    setIsSubmitting(true);
    
    // Simulate contract interaction
    setTimeout(() => {
      // Mock successful creation
      setIsSubmitting(false);
      alert(`Campaign "${formData.hashtag}" created successfully! 🎉\n\nContract Address: 0x${Math.random().toString(16).substr(2, 40)}`);
      
      // Reset form
      setFormData({
        hashtag: '',
        description: '',
        duration: 0,
        totalBudget: 0,
        totalRewards: 0,
        tierName: '',
        baseURI: '',
        maxSupply: 0,
      });
      setShowPreview(false);
    }, 3000);

    // TODO: Replace with actual contract call
    /*
    const contract = new ethers.Contract('FACTORY_CONTRACT_ADDRESS', HashDropCampaignFactory.abi, provider.getSigner());
    try {
      const tx = await contract.quickLaunchSingleTier(
        formData.hashtag,
        formData.description,
        formData.duration,
        formData.tierName,
        formData.baseURI,
        formData.maxSupply,
        formData.totalBudget,
        formData.totalRewards
      );
      await tx.wait();
      alert('Campaign created successfully!');
    } catch (error) {
      console.error(error);
      alert('Failed to create campaign.');
    }
    */
  };

  const loadTemplate = (template: typeof campaignTemplates[0]) => {
    setFormData({
      hashtag: template.hashtag,
      description: template.description,
      duration: template.duration,
      totalBudget: template.totalBudget,
      totalRewards: template.totalRewards,
      tierName: template.tierName,
      baseURI: template.baseURI,
      maxSupply: template.maxSupply
    });
    setErrors({});
  };

  const formatDuration = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    return `${days}d ${hours}h`;
  };

  if (!address) {
    return (
      <div className="min-h-screen bg-slate-900 text-white pt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center py-12"
          >
            <div className="max-w-md mx-auto">
              <div className="mb-8">
                <div className="w-20 h-20 bg-teal-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                </div>
                <h2 className="text-2xl font-bold mb-2">Create Your Campaign</h2>
                <p className="text-slate-300 text-lg mb-6">
                  Connect your wallet to start creating awesome Web3 campaigns with hashtag rewards.
                </p>
              </div>
              
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
                  'Connect Wallet to Create Campaign'
                )}
              </button>
            </div>
          </motion.div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900 text-white pt-20">
      <div className="px-4 sm:px-6 lg:px-8 py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-3xl font-bold">Create Campaign</h1>
          </div>
        
        </motion.div>

        {/* Campaign Templates */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="mb-8"
        >
          <h2 className="text-xl font-semibold mb-4">Quick Start Templates</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {campaignTemplates.map((template, index) => (
              <div key={index} className="bg-slate-800 p-4 rounded-lg border border-slate-700 hover:border-teal-500 transition">
                <h3 className="font-semibold text-teal-400 mb-2">{template.name}</h3>
                <p className="text-sm text-slate-300 mb-3 line-clamp-2">{template.description}</p>
                <div className="flex justify-between items-center text-xs text-slate-400 mb-3">
                  <span>#{template.hashtag}</span>
                  <span>{formatDuration(template.duration)}</span>
                </div>
                <button
                  onClick={() => loadTemplate(template)}
                  className="w-full bg-teal-600 text-white px-3 py-2 rounded text-sm hover:bg-teal-700 transition"
                >
                  Use Template
                </button>
              </div>
            ))}
          </div>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Form Section */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
            className="lg:col-span-2"
          >
            <form onSubmit={handleSubmit} className="bg-slate-800 p-6 rounded-lg">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Hashtag <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.hashtag}
                    onChange={(e) => setFormData({ ...formData, hashtag: e.target.value })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.hashtag ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="CleanOceans2024"
                  />
                  {errors.hashtag && <p className="text-red-400 text-xs mt-1">{errors.hashtag}</p>}
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Tier Name <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.tierName}
                    onChange={(e) => setFormData({ ...formData, tierName: e.target.value })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.tierName ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="Ocean Guardian"
                  />
                  {errors.tierName && <p className="text-red-400 text-xs mt-1">{errors.tierName}</p>}
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Description <span className="text-red-400">*</span>
                  </label>
                  <textarea
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.description ? 'border-red-500' : 'border-slate-700'
                    }`}
                    rows={4}
                    placeholder="Describe your campaign goals and what participants should do..."
                  />
                  {errors.description && <p className="text-red-400 text-xs mt-1">{errors.description}</p>}
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Duration (seconds) <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="number"
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: Number(e.target.value) })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.duration ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="604800"
                  />
                  {formData.duration > 0 && (
                    <p className="text-teal-400 text-xs mt-1">≈ {formatDuration(formData.duration)}</p>
                  )}
                  {errors.duration && <p className="text-red-400 text-xs mt-1">{errors.duration}</p>}
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Max Supply <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="number"
                    value={formData.maxSupply}
                    onChange={(e) => setFormData({ ...formData, maxSupply: Number(e.target.value) })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.maxSupply ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="100"
                  />
                  {errors.maxSupply && <p className="text-red-400 text-xs mt-1">{errors.maxSupply}</p>}
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Total Budget <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="number"
                    value={formData.totalBudget}
                    onChange={(e) => setFormData({ ...formData, totalBudget: Number(e.target.value) })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.totalBudget ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="1000"
                  />
                  {errors.totalBudget && <p className="text-red-400 text-xs mt-1">{errors.totalBudget}</p>}
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Total Rewards <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="number"
                    value={formData.totalRewards}
                    onChange={(e) => setFormData({ ...formData, totalRewards: Number(e.target.value) })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.totalRewards ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="50"
                  />
                  {errors.totalRewards && <p className="text-red-400 text-xs mt-1">{errors.totalRewards}</p>}
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Base URI <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.baseURI}
                    onChange={(e) => setFormData({ ...formData, baseURI: e.target.value })}
                    className={`w-full p-3 bg-slate-900 border rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      errors.baseURI ? 'border-red-500' : 'border-slate-700'
                    }`}
                    placeholder="https://ipfs.io/ipfs/your-nft-metadata/"
                  />
                  {errors.baseURI && <p className="text-red-400 text-xs mt-1">{errors.baseURI}</p>}
                </div>
              </div>

              <div className="flex gap-4 mt-6">
                <button
                  type="button"
                  onClick={() => setShowPreview(!showPreview)}
                  className="flex-1 bg-slate-700 text-white px-6 py-3 rounded-lg hover:bg-slate-600 transition"
                >
                  {showPreview ? 'Hide Preview' : 'Preview Campaign'}
                </button>
                <button
                  type="submit"
                  className="flex-1 bg-teal-600 text-white px-6 py-3 rounded-lg hover:bg-teal-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                  disabled={!address || isSubmitting}
                >
                  {isSubmitting ? (
                    <>
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                      Creating Campaign...
                    </>
                  ) : (
                    'Create Campaign'
                  )}
                </button>
              </div>
            </form>
          </motion.div>

          {/* Preview Section */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
            className="lg:col-span-1"
          >
            <div className="bg-slate-800 p-6 rounded-lg sticky top-24">
              <h3 className="text-lg font-semibold mb-4">Campaign Preview</h3>
              
              {showPreview && formData.hashtag ? (
                <div className="space-y-4">
                  <div className="bg-slate-900 p-4 rounded-lg">
                    <h4 className="font-semibold text-teal-400 mb-2">#{formData.hashtag}</h4>
                    <p className="text-sm text-slate-300 mb-3">{formData.description}</p>
                    
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div>
                        <span className="text-slate-400">Duration:</span>
                        <p className="text-white">{formatDuration(formData.duration)}</p>
                      </div>
                      <div>
                        <span className="text-slate-400">Max Supply:</span>
                        <p className="text-white">{formData.maxSupply}</p>
                      </div>
                      <div>
                        <span className="text-slate-400">Budget:</span>
                        <p className="text-white">{formData.totalBudget}</p>
                      </div>
                      <div>
                        <span className="text-slate-400">Rewards:</span>
                        <p className="text-white">{formData.totalRewards}</p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="bg-slate-900 p-4 rounded-lg">
                    <h5 className="text-sm font-semibold text-slate-300 mb-2">NFT Tier</h5>
                    <p className="text-teal-400">{formData.tierName}</p>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8">
                  <div className="w-16 h-16 bg-slate-700 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg className="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  </div>
                  <p className="text-slate-400 text-sm">
                    Fill in the form and click "Preview Campaign" to see how your campaign will look.
                  </p>
                </div>
              )}
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

export default CreateCampaign;