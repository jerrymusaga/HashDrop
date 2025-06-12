// components/CostBreakdown.tsx
import { motion } from "framer-motion";
import { CostBreakdownProps } from "@/libs/types";

const CostBreakdown: React.FC<CostBreakdownProps> = ({
  formData,
  multiChain,
  nextStep,
  prevStep,
}) => {
  const baseCost = formData.totalRewards * 0.001;
  const multiChainPremium = multiChain ? baseCost * 0.5 : 0;
  const monitoringCost = formData.duration * 0.01;
  const totalCost = baseCost + multiChainPremium + monitoringCost;

  const costItems = [
    {
      label: `Base NFT Cost (${formData.totalRewards} × $0.001)`,
      amount: baseCost,
      icon: "💎",
      description: "Core reward minting cost"
    },
    ...(multiChain ? [{
      label: "Multi-Chain Premium (50%)",
      amount: multiChainPremium,
      icon: "🔗",
      description: "Cross-chain deployment via Chainlink CCIP"
    }] : []),
    {
      label: `Monitoring Cost (${formData.duration} days × $0.01)`,
      amount: monitoringCost,
      icon: "📊",
      description: "AI-powered social engagement tracking"
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
              <h2 className="text-3xl md:text-4xl font-bold mb-4">
                Campaign <span className="text-teal-400">Cost Breakdown</span>
              </h2>
              <div className="w-24 h-1 bg-gradient-to-r from-teal-400 to-teal-600 mx-auto rounded-full"></div>
              <p className="text-lg text-slate-300 mt-4">
                Transparent pricing for your Web3 rewards campaign
              </p>
            </div>

            {/* Cost Breakdown Card */}
            <div className="bg-gradient-to-br from-slate-700/50 to-slate-800/30 rounded-2xl p-8 border border-slate-600/30 mb-8">
              {/* Individual Cost Items */}
              <div className="space-y-6 mb-8">
                {costItems.map((item, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-center justify-between p-4 bg-slate-800/50 rounded-xl border border-slate-700/30 hover:border-teal-500/30 transition-all duration-300"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-gradient-to-br from-teal-500/20 to-teal-600/10 rounded-xl flex items-center justify-center border border-teal-500/20">
                        <span className="text-xl">{item.icon}</span>
                      </div>
                      <div>
                        <div className="font-semibold text-white">{item.label}</div>
                        <div className="text-sm text-slate-400">{item.description}</div>
                      </div>
                    </div>
                    <div className="text-xl font-bold text-teal-400">
                      ${item.amount.toFixed(2)}
                    </div>
                  </motion.div>
                ))}
              </div>

              {/* Total Cost */}
              <div className="border-t border-slate-600/50 pt-6">
                <motion.div
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.4 }}
                  className="bg-gradient-to-r from-teal-600/20 to-teal-500/10 rounded-xl p-6 border border-teal-500/30"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-16 h-16 bg-gradient-to-br from-teal-500 to-teal-600 rounded-xl flex items-center justify-center shadow-lg shadow-teal-500/25">
                        <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                        </svg>
                      </div>
                      <div>
                        <div className="text-2xl font-bold text-white">Total Campaign Cost</div>
                        <div className="text-sm text-teal-300">All fees included, no hidden costs</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-4xl font-bold bg-gradient-to-r from-teal-400 to-teal-600 bg-clip-text text-transparent">
                        ${totalCost.toFixed(2)}
                      </div>
                      <div className="text-sm text-slate-400 mt-1">
                        ≈ ${(totalCost / formData.totalRewards).toFixed(4)} per reward
                      </div>
                    </div>
                  </div>
                </motion.div>
              </div>
            </div>

            {/* Smart Pricing Info */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="bg-gradient-to-r from-teal-900/20 to-teal-800/10 border border-teal-500/30 rounded-xl p-6 mb-8"
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-gradient-to-br from-teal-500 to-teal-600 rounded-xl flex items-center justify-center shadow-lg shadow-teal-500/25 flex-shrink-0">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-teal-400 mb-2">💡 Smart Pricing Model</h3>
                  <p className="text-slate-300 leading-relaxed">
                    Our costs scale efficiently with campaign size. Larger campaigns benefit from better per-NFT rates, 
                    while our AI-powered monitoring ensures every reward goes to genuine, high-quality engagement.
                  </p>
                  <div className="flex flex-wrap gap-2 mt-4">
                    <span className="px-3 py-1 bg-teal-500/20 text-teal-300 rounded-full text-sm border border-teal-500/30">
                      Volume Discounts
                    </span>
                    <span className="px-3 py-1 bg-teal-500/20 text-teal-300 rounded-full text-sm border border-teal-500/30">
                      Gas Optimized
                    </span>
                    <span className="px-3 py-1 bg-teal-500/20 text-teal-300 rounded-full text-sm border border-teal-500/30">
                      No Hidden Fees
                    </span>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Navigation Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <button
                type="button"
                onClick={prevStep}
                className="group flex-1 bg-transparent border-2 border-slate-600 text-slate-300 px-8 py-4 rounded-xl font-semibold hover:bg-slate-600 hover:text-white hover:border-slate-500 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-slate-500/25"
              >
                <span className="flex items-center justify-center gap-2">
                  <svg className="w-5 h-5 group-hover:-translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 17l-5-5m0 0l5-5m-5 5h12" />
                  </svg>
                  Back
                </span>
              </button>
              
              <button
                type="button"
                onClick={nextStep}
                className="group flex-1 bg-gradient-to-r from-teal-600 to-teal-500 text-white px-8 py-4 rounded-xl font-semibold hover:from-teal-500 hover:to-teal-400 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-teal-500/25"
              >
                <span className="flex items-center justify-center gap-2">
                  Proceed to Payment
                  <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </span>
              </button>
            </div>
          </div>
        </motion.div>
      </div>
  
  );
};

export default CostBreakdown;