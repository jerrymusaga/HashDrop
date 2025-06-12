// components/DeploymentProgress.tsx
import { motion } from "framer-motion";

interface DeploymentProgressProps {
  progress: number;
}

const steps = [
  "Initializing Campaign...",
  "Deploying NFT Contract...",
  "Configuring Multi-Chain...",
  "Starting Monitoring...",
  "Campaign Active!",
];

const DeploymentProgress: React.FC<DeploymentProgressProps> = ({ progress }) => {
  const currentStep = Math.min(Math.floor(progress / 20), steps.length - 1);

  return (
    <div className="relative">
      {/* Background animated elements */}
      <div className="absolute -top-4 -left-4 w-32 h-32 bg-teal-600/5 rounded-full blur-2xl animate-pulse"></div>
      <div className="absolute -bottom-4 -right-4 w-40 h-40 bg-teal-600/3 rounded-full blur-2xl animate-pulse delay-1000"></div>
      
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative z-10 group bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border border-slate-700/50 hover:border-teal-500/30"
      >
        <div className="text-center mb-8">
          <h2 className="text-3xl md:text-4xl font-bold mb-2">
            Deploying Your <span className="text-teal-400">Campaign</span>
          </h2>
          <div className="w-16 h-1 bg-gradient-to-r from-teal-400 to-teal-600 mx-auto rounded-full"></div>
        </div>

        {/* Progress Bar Container */}
        <div className="relative mb-8">
          <div className="bg-slate-700/50 h-3 rounded-full overflow-hidden backdrop-blur-sm border border-slate-600/30">
            <motion.div
              className="bg-gradient-to-r from-teal-500 to-teal-600 h-full rounded-full relative overflow-hidden"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.5, ease: "easeInOut" }}
            >
              {/* Animated shimmer effect */}
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-pulse"></div>
            </motion.div>
          </div>
          
          {/* Progress percentage */}
          <div className="absolute -top-8 right-0">
            <span className="text-sm font-semibold text-teal-400 bg-slate-800/80 px-3 py-1 rounded-full border border-teal-500/30">
              {progress}%
            </span>
          </div>
        </div>

        {/* Current Status */}
        <div className="text-center mb-8">
          <motion.span
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.3 }}
            className={`inline-flex items-center gap-2 px-6 py-3 rounded-xl text-lg font-semibold shadow-lg ${
              progress === 100 
                ? "bg-gradient-to-r from-green-500/20 to-green-600/20 text-green-100 border border-green-500/30" 
                : "bg-gradient-to-r from-teal-500/20 to-teal-600/20 text-teal-100 border border-teal-500/30"
            }`}
          >
            <span className="text-xl">
              {progress === 100 ? "🎉" : "⚡"}
            </span>
            {steps[currentStep]}
          </motion.span>
        </div>

        {/* Steps List */}
        <div className="space-y-4">
          {steps.map((step, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className={`flex items-center gap-4 p-4 rounded-xl transition-all duration-300 ${
                index <= currentStep
                  ? "bg-gradient-to-r from-teal-500/10 to-teal-600/10 border border-teal-500/20"
                  : "bg-slate-700/30 border border-slate-600/30"
              }`}
            >
              <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-all duration-300 ${
                index <= currentStep
                  ? "bg-gradient-to-r from-teal-500 to-teal-600 text-white shadow-lg shadow-teal-500/25"
                  : "bg-slate-600 text-slate-400"
              }`}>
                {index <= currentStep ? (
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  <div className="w-2 h-2 bg-current rounded-full"></div>
                )}
              </div>
              
              <span className={`text-base font-medium transition-colors duration-300 ${
                index <= currentStep ? "text-white" : "text-slate-400"
              }`}>
                {step}
              </span>
              
              {index === currentStep && progress < 100 && (
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                  className="ml-auto"
                >
                  <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                </motion.div>
              )}
            </motion.div>
          ))}
        </div>

        {/* Completion Message */}
        {progress === 100 && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.5 }}
            className="mt-8 p-6 bg-gradient-to-r from-green-500/10 to-green-600/10 rounded-xl border border-green-500/30 text-center"
          >
            <div className="text-4xl mb-2">🚀</div>
            <h3 className="text-2xl font-bold text-green-100 mb-2">Campaign Successfully Deployed!</h3>
            <p className="text-green-200/80 leading-relaxed">
              Your campaign is now live and ready to start rewarding meaningful social engagement.
            </p>
          </motion.div>
        )}
      </motion.div>
    </div>
  );
};

export default DeploymentProgress;