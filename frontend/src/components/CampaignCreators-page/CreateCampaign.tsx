// components/CreateCampaign.tsx
"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import CampaignModeSelector from "../modals/CampaignModeSelector";
import CampaignDetailsForm from "./CampaignDetailsForm";
import MultiChainSetup from "./MultiChainSetup";
import CostBreakdown from "./CostBreakdown";
import LaunchCampaign from "./LaunchCampaign";
import { FormData, CampaignState } from "@/libs/types";
import DeploymentProgress from "./DeploymentProgress";
import CampaignDashboard from "./CampaignDashboard";
import { useAccount } from "wagmi";



const CreateCampaign: React.FC = () => {
    const { address, isConnected } = useAccount();
  const [state, setState] = useState<CampaignState>({
    step: 1,
    mode: "simple",
    formData: {
      hashtag: "#buildwithbase",
      description: "Celebrating builders on Base blockchain",
      duration: 30,
      totalRewards: 1000,
      collectionName: "Base Builder Badge",
      imageUrl: "https://example.com/builder-badge.png",
    },
    multiChain: false,
    selectedChains: ["Polygon", "Arbitrum", "Optimism", "Base"],
    isDeploying: false,
    deploymentProgress: 0,
  });

  const updateFormData = (updates: Partial<FormData>) => {
    setState((prev) => ({
      ...prev,
      formData: { ...prev.formData, ...updates },
    }));
  };

  const nextStep = () => {
    setState((prev) => ({ ...prev, step: prev.step + 1 }));
  };

  const prevStep = () => {
    setState((prev) => ({ ...prev, step: prev.step - 1 }));
  };

  const handleLaunch = () => {
    setState((prev) => ({ ...prev, isDeploying: true, step: 6 }));
    let progress = 0;
    const interval = setInterval(() => {
      progress += 20;
      setState((prev) => ({ ...prev, deploymentProgress: progress }));
      if (progress >= 100) {
        clearInterval(interval);
        setTimeout(() => {
          setState((prev) => ({ ...prev, step: 7, isDeploying: false }));
        }, 1000);
      }
    }, 1500);
  };

  if (!address) {
    return (
      <div className="min-h-screen bg-slate-900 text-white relative overflow-hidden">
      
        <div className="relative z-10 flex items-center justify-center min-h-screen">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center p-8 max-w-md bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl shadow-2xl border border-slate-700/50 hover:border-teal-500/30 transition-all duration-300"
          >
            <div className="w-16 h-16 bg-gradient-to-br from-teal-500 to-teal-600 rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg shadow-teal-500/25">
              <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4 bg-gradient-to-r from-teal-400 to-teal-600 bg-clip-text text-transparent">
              Connect to Create
            </h2>
            <p className="text-lg text-slate-300 leading-relaxed mb-8">
              Connect your wallet to start creating Web3 campaigns with hashtag rewards.
            </p>
            <button
              onClick={connectWallet}
              disabled={isConnecting}
              className="group w-full bg-gradient-to-r from-teal-600 to-teal-500 text-white px-8 py-4 rounded-xl font-semibold hover:from-teal-500 hover:to-teal-400 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-teal-500/25 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none flex items-center justify-center"
            >
              {isConnecting ? (
                <>
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                  Connecting...
                </>
              ) : (
                <span className="flex items-center justify-center gap-2">
                  Connect Wallet
                  <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </span>
              )}
            </button>
          </motion.div>
        </div>
      </div>
    );
  }

  const renderStep = () => {
    switch (state.step) {
      case 1:
        return (
          <CampaignModeSelector
            mode={state.mode}
            setMode={(mode) => setState({ ...state, mode })}
            nextStep={nextStep}
          />
        );
      case 2:
        return (
          <CampaignDetailsForm
            formData={state.formData}
            updateFormData={updateFormData}
            nextStep={nextStep}
            prevStep={prevStep}
          />
        );
      case 3:
        return (
          <MultiChainSetup
            multiChain={state.multiChain}
            setMultiChain={(multiChain) => setState({ ...state, multiChain })}
            selectedChains={state.selectedChains}
            setSelectedChains={(chains) => setState({ ...state, selectedChains: chains })}
            nextStep={nextStep}
            prevStep={prevStep}
          />
        );
      case 4:
        return (
          <CostBreakdown
            formData={state.formData}
            multiChain={state.multiChain}
            nextStep={nextStep}
            prevStep={prevStep}
          />
        );
      case 5:
        return (
          <LaunchCampaign
            formData={state.formData}
            multiChain={state.multiChain}
            launchCampaign={handleLaunch}
            prevStep={prevStep}
          />
        );
      case 6:
        return <DeploymentProgress progress={state.deploymentProgress} />;
      case 7:
        return <CampaignDashboard formData={state.formData} />;
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-white relative overflow-hidden">
      {/* Background gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 opacity-50"></div>
      <div className="absolute inset-0 bg-gradient-to-t from-teal-900/10 via-transparent to-teal-900/5"></div>
      
      {/* Animated background elements */}
      <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-teal-600/5 rounded-full blur-3xl animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-teal-600/3 rounded-full blur-3xl animate-pulse delay-1000"></div>
      
      <div className="relative z-10 pt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
          
          <AnimatePresence mode="wait">
            <motion.div
              key={state.step}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3 }}
            >
              {renderStep()}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
};

export default CreateCampaign;