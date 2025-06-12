// components/CampaignModeSelector.tsx
import { motion } from "framer-motion";

interface CampaignModeSelectorProps {
  mode: "simple" | "advanced";
  setMode: (mode: "simple" | "advanced") => void;
  nextStep: () => void;
}

const CampaignModeSelector: React.FC<CampaignModeSelectorProps> = ({
  mode,
  setMode,
  nextStep,
}) => {
  const features = {
    simple: [
      {
        icon: "⚡",
        title: "One-Click Launch",
        description: "Just hashtag, image, and go!",
      },
      {
        icon: "🌐",
        title: "Auto Multi-Chain",
        description: "Deploy across popular L2s",
      },
      {
        icon: "🎨",
        title: "Single NFT Tier",
        description: "Everyone gets the same reward",
      },
    ],
    advanced: [
      {
        icon: "🏆",
        title: "Custom Tiers",
        description: "Bronze, Silver, Gold rewards",
      },
      {
        icon: "⛓️",
        title: "Chain Selection",
        description: "Pick specific networks",
      },
      {
        icon: "📊",
        title: "Custom Monitoring",
        description: "Set your own intervals",
      },
    ],
  };

  return (
    <div>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center mb-6"
      >
        <h1 className="text-4xl md:text-5xl xl:text-6xl font-bold leading-tight mb-3">
          <span className="bg-gradient-to-r from-teal-400 to-teal-600 bg-clip-text text-transparent">
            Campaign Factory
          </span>
        </h1>
        <p className="text-lg md:text-2xl xl:text-3xl text-slate-300 leading-relaxed max-w-4xl mx-auto">
          Turn Your Hashtag Into a Cross-Chain NFT Campaign
        </p>
      </motion.div>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-slate-800 rounded-xl p-8 shadow-2xl"
      >
        <h2 className="text-2xl font-semibold mb-6">
          Choose Your Campaign Style
        </h2>
        <div className="flex bg-slate-700 rounded-lg p-1 mb-6">
          <button
            className={`flex-1 py-3 rounded-lg text-sm font-semibold transition ${
              mode === "simple"
                ? "bg-white text-teal-500 shadow-md"
                : "text-slate-300"
            }`}
            onClick={() => setMode("simple")}
          >
            🚀 Simple Mode
          </button>
          <button
            className={`flex-1 py-3 rounded-lg text-sm font-semibold transition ${
              mode === "advanced"
                ? "bg-white text-teal-500 shadow-md"
                : "text-slate-300"
            }`}
            onClick={() => setMode("advanced")}
          >
            ⚙️ Advanced Mode
          </button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {features[mode].map((feature, index) => (
            <div
              key={index}
              className="bg-slate-900 p-4 rounded-lg border border-slate-700 hover:border-teal-500 transition"
            >
              <div className="text-2xl mb-2">{feature.icon}</div>
              <h3 className="font-semibold text-teal-400">{feature.title}</h3>
              <p className="text-sm text-slate-300">{feature.description}</p>
            </div>
          ))}
        </div>
        <p className="text-sm text-slate-400 mt-4">
          {mode === "simple"
            ? "Perfect for first-time users or quick campaigns"
            : "For power users who want full control"}
        </p>
        <button
          className="mt-6 w-full bg-teal-500 text-white py-3 rounded-lg hover:bg-teal-600 transition"
          onClick={nextStep}
        >
          Next
        </button>
      </motion.div>
    </div>
  );
};

export default CampaignModeSelector;
