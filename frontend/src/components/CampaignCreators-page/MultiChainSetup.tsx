// components/MultiChainSetup.tsx
import { motion } from "framer-motion";

interface MultiChainSetupProps {
  multiChain: boolean;
  setMultiChain: (value: boolean) => void;
  selectedChains: string[];
  setSelectedChains: (chains: string[]) => void;
  nextStep: () => void;
  prevStep: () => void;
}

const chains = [
  { name: "Polygon", icon: "🟣", color: "from-purple-500 to-purple-600" },
  { name: "Arbitrum", icon: "🔵", color: "from-blue-500 to-blue-600" },
  { name: "Optimism", icon: "🔴", color: "from-red-500 to-red-600" },
  { name: "Base", icon: "🟦", color: "from-blue-400 to-blue-500" },
  { name: "Avalanche", icon: "❄️", color: "from-cyan-400 to-cyan-500" }
];

const MultiChainSetup: React.FC<MultiChainSetupProps> = ({
  multiChain,
  setMultiChain,
  selectedChains,
  setSelectedChains,
  nextStep,
  prevStep,
}) => {
  const toggleChain = (chain: string) => {
    if (selectedChains.includes(chain)) {
      setSelectedChains(selectedChains.filter((c) => c !== chain));
    } else {
      setSelectedChains([...selectedChains, chain]);
    }
  };

  return (
      <div className="relative z-10 flex justify-center min-h-screen px-4 py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full max-w-4xl"
        >
          <div className="bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl p-8 shadow-2xl border border-slate-700/50">
            {/* Header */}
            <div className="text-center mb-8">
              <h2 className="text-3xl md:text-4xl font-bold mb-4">
                Multi-Chain <span className="text-teal-400">Setup</span>
              </h2>
              <div className="w-24 h-1 bg-gradient-to-r from-teal-400 to-teal-600 mx-auto rounded-full"></div>
            </div>

            {/* Toggle Switch */}
            <div className="flex items-center justify-center gap-6 mb-8 p-6 bg-slate-700/30 rounded-xl border border-slate-600/30">
              <label className="relative inline-block w-16 h-9 cursor-pointer">
                <input
                  type="checkbox"
                  checked={multiChain}
                  onChange={() => setMultiChain(!multiChain)}
                  className="opacity-0 w-0 h-0"
                />
                <span
                  className={`absolute cursor-pointer top-0 left-0 right-0 bottom-0 rounded-full transition-all duration-300 shadow-lg ${
                    multiChain 
                      ? "bg-gradient-to-r from-teal-500 to-teal-600 shadow-teal-500/25" 
                      : "bg-slate-600 shadow-slate-600/25"
                  }`}
                >
                  <span
                    className={`absolute h-7 w-7 bg-white rounded-full bottom-1 left-1 transition-all duration-300 shadow-lg ${
                      multiChain ? "translate-x-7 shadow-teal-200/50" : "shadow-slate-200/50"
                    }`}
                  />
                </span>
              </label>
              <div className="flex flex-col">
                <span className="text-lg font-semibold text-white">
                  Enable Multi-Chain Distribution
                </span>
                <span className="text-sm text-teal-400 font-medium">
                  +50% cost for maximum reach
                </span>
              </div>
            </div>

            {/* Description */}
            <div className="text-center mb-8">
              <p className="text-lg text-slate-300 leading-relaxed max-w-2xl mx-auto">
                Multi-chain campaigns leverage Chainlink CCIP to reach users across multiple blockchains, 
                maximizing your campaign's impact and engagement potential.
              </p>
            </div>

            {/* Chain Selection */}
            {multiChain && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.3 }}
                className="mb-8"
              >
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold mb-2 text-teal-400">
                    Select Target Chains
                  </h3>
                  <p className="text-sm text-slate-400">
                    Choose which blockchains to deploy your campaign rewards
                  </p>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
                  {chains.map((chain) => (
                    <motion.button
                      key={chain.name}
                      onClick={() => toggleChain(chain.name)}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      className={`group p-6 rounded-xl border-2 transition-all duration-300 transform hover:shadow-xl ${
                        selectedChains.includes(chain.name)
                          ? "border-teal-500 bg-gradient-to-br from-teal-500/10 to-teal-600/5 shadow-teal-500/25"
                          : "border-slate-600 bg-gradient-to-br from-slate-700/50 to-slate-800/30 hover:border-teal-500/50 hover:shadow-teal-500/10"
                      }`}
                    >
                      <div className="flex flex-col items-center">
                        <div className={`w-12 h-12 rounded-xl flex items-center justify-center mb-3 transition-transform group-hover:scale-110 ${
                          selectedChains.includes(chain.name)
                            ? `bg-gradient-to-br ${chain.color}`
                            : "bg-slate-600"
                        }`}>
                          <span className="text-xl">{chain.icon}</span>
                        </div>
                        <span className={`font-semibold ${
                          selectedChains.includes(chain.name) ? "text-teal-400" : "text-white"
                        }`}>
                          {chain.name}
                        </span>
                        {selectedChains.includes(chain.name) && (
                          <div className="w-2 h-2 bg-teal-400 rounded-full mt-2"></div>
                        )}
                      </div>
                    </motion.button>
                  ))}
                </div>
                
                <div className="text-center p-4 bg-teal-900/10 rounded-xl border border-teal-500/20">
                  <p className="text-sm text-teal-300">
                    <svg className="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Default selection optimized for maximum reach and cost efficiency
                  </p>
                </div>
              </motion.div>
            )}

            {/* Navigation Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 mt-8">
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
                  Continue Setup
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

export default MultiChainSetup;