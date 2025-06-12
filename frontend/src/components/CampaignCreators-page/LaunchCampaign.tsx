// components/LaunchCampaign.tsx
import { motion } from "framer-motion";
import { FormData } from "@/libs/types";

interface LaunchCampaignProps {
  formData: FormData;
  multiChain: boolean;
  launchCampaign: () => void;
  prevStep: () => void;
}

const LaunchCampaign: React.FC<LaunchCampaignProps> = ({
  formData,
  multiChain,
  launchCampaign,
  prevStep,
}) => {
  const baseCost = formData.totalRewards * 0.001;
  const multiChainPremium = multiChain ? baseCost * 0.5 : 0;
  const monitoringCost = formData.duration * 0.01;
  const totalCost = baseCost + multiChainPremium + monitoringCost;

  const checklist = [
    {
      icon: "🏷️",
      title: "Hashtag Uniqueness",
      description: "Make sure your hashtag is unique and brandable"
    },
    {
      icon: "🎨",
      title: "NFT Quality",
      description: "Your NFT image should be high-quality and appealing"
    },
    {
      icon: "⛽",
      title: "Gas & Fees",
      description: "Have enough ETH for campaign cost plus gas fees"
    },
    {
      icon: "⏰",
      title: "Immediate Start",
      description: "Campaign monitoring begins immediately after launch"
    }
  ];

  return (
      <div className="relative z-10 flex items-center justify-center min-h-screen px-4 py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full max-w-4xl"
        >
          <div className="bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl p-8 shadow-2xl border border-slate-700/50">
            {/* Header */}
            <div className="text-center mb-8">
              <motion.div
                initial={{ scale: 0.9 }}
                animate={{ scale: 1 }}
                transition={{ duration: 0.5 }}
              >
                <h2 className="text-3xl md:text-4xl font-bold mb-4">
                  🚀 Launch Your <span className="text-teal-400">Campaign</span>
                </h2>
                <div className="w-24 h-1 bg-gradient-to-r from-teal-400 to-teal-600 mx-auto rounded-full"></div>
                <p className="text-lg text-slate-300 mt-4">
                  You're ready to deploy your Web3 rewards campaign!
                </p>
              </motion.div>
            </div>

            {/* Pre-Launch Checklist */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="mb-8"
            >
              <div className="bg-gradient-to-r from-amber-900/20 to-orange-900/10 border border-amber-500/30 rounded-xl p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-br from-amber-500 to-orange-600 rounded-xl flex items-center justify-center shadow-lg shadow-amber-500/25">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-amber-400">Pre-Launch Checklist</h3>
                    <p className="text-amber-200/80 text-sm">Ensure everything is ready before deployment</p>
                  </div>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {checklist.map((item, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.3 + index * 0.1 }}
                      className="flex items-start gap-3 p-4 bg-slate-800/30 rounded-lg border border-slate-600/30"
                    >
                      <div className="w-8 h-8 bg-amber-500/20 rounded-lg flex items-center justify-center flex-shrink-0 mt-1">
                        <span className="text-lg">{item.icon}</span>
                      </div>
                      <div>
                        <h4 className="font-semibold text-amber-300 text-sm">{item.title}</h4>
                        <p className="text-amber-200/70 text-xs mt-1">{item.description}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>
            </motion.div>

            {/* Campaign Summary */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="bg-gradient-to-br from-slate-700/50 to-slate-800/30 rounded-xl p-6 border border-slate-600/30 mb-8"
            >
              <h3 className="text-lg font-semibold mb-4 text-teal-400">Campaign Summary</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Hashtag:</span>
                    <span className="text-teal-400 font-mono">#{formData.hashtag}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Total Rewards:</span>
                    <span className="text-white font-semibold">{formData.totalRewards}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Duration:</span>
                    <span className="text-white font-semibold">{formData.duration} days</span>
                  </div>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Multi-Chain:</span>
                    <span className={`font-semibold ${multiChain ? 'text-teal-400' : 'text-slate-500'}`}>
                      {multiChain ? 'Enabled' : 'Disabled'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Total Cost:</span>
                    <span className="text-2xl font-bold text-teal-400">${totalCost.toFixed(2)}</span>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Action Buttons */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
              className="space-y-4 mb-6"
            >
              {/* Primary Launch Button */}
              <button
                onClick={launchCampaign}
                className="group w-full bg-gradient-to-r from-teal-600 to-teal-500 text-white px-8 py-6 rounded-xl font-bold text-lg hover:from-teal-500 hover:to-teal-400 transition-all duration-300 transform hover:scale-105 hover:shadow-2xl hover:shadow-teal-500/25"
              >
                <span className="flex items-center justify-center gap-3">
                  <span className="text-2xl group-hover:animate-bounce">🚀</span>
                  <span>Launch Campaign</span>
                  <span className="bg-teal-400/20 px-3 py-1 rounded-full text-sm font-semibold">
                    ${totalCost.toFixed(2)}
                  </span>
                </span>
              </button>

              {/* Save as Draft Button */}
              <button
                className="group w-full bg-gradient-to-r from-slate-700 to-slate-600 text-white px-8 py-4 rounded-xl font-semibold hover:from-slate-600 hover:to-slate-500 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-slate-500/25"
              >
                <span className="flex items-center justify-center gap-2">
                  <svg className="w-5 h-5 group-hover:scale-110 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                  Save as Draft
                </span>
              </button>
            </motion.div>

            {/* Back Button */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.8 }}
            >
              <button
                type="button"
                onClick={prevStep}
                className="group w-full bg-transparent border-2 border-slate-600 text-slate-300 px-8 py-4 rounded-xl font-semibold hover:bg-slate-600 hover:text-white hover:border-slate-500 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-slate-500/25"
              >
                <span className="flex items-center justify-center gap-2">
                  <svg className="w-5 h-5 group-hover:-translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 17l-5-5m0 0l5-5m-5 5h12" />
                  </svg>
                  Back to Review
                </span>
              </button>
            </motion.div>

            {/* Success Indicators */}
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 1 }}
              className="flex justify-center mt-6"
            >
              <div className="flex items-center gap-2 text-teal-400 text-sm">
                <div className="w-2 h-2 bg-teal-400 rounded-full animate-pulse"></div>
                <span>Chainlink Functions Ready</span>
                <div className="w-2 h-2 bg-teal-400 rounded-full animate-pulse delay-500"></div>
                <span>CCIP Enabled</span>
                <div className="w-2 h-2 bg-teal-400 rounded-full animate-pulse delay-1000"></div>
                <span>AI Agent Active</span>
              </div>
            </motion.div>
          </div>
        </motion.div>
      </div>
  );
};

export default LaunchCampaign;