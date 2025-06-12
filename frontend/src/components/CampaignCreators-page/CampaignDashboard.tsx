// components/CampaignDashboard.tsx
import { motion } from "framer-motion";
import { FormData } from "@/libs/types";

interface CampaignDashboardProps {
  formData: FormData;
}

const CampaignDashboard: React.FC<CampaignDashboardProps> = ({ formData }) => {
  const metrics = [
    { 
      value: 247, 
      label: "Total Participants",
      icon: "👥",
      trend: "+12%",
      trendUp: true
    },
    { 
      value: 89, 
      label: "NFTs Claimed",
      icon: "🏆",
      trend: "+8%",
      trendUp: true
    },
    { 
      value: "4.2k", 
      label: "Total Engagement",
      icon: "❤️",
      trend: "+24%",
      trendUp: true
    },
    { 
      value: formData.duration - 7, 
      label: "Days Remaining",
      icon: "⏰",
      trend: null,
      trendUp: null
    },
  ];

  return (
    <div className="relative">
      {/* Background animated elements */}
      <div className="absolute -top-6 -left-6 w-40 h-40 bg-teal-600/5 rounded-full blur-3xl animate-pulse"></div>
      <div className="absolute -bottom-6 -right-6 w-48 h-48 bg-teal-600/3 rounded-full blur-3xl animate-pulse delay-1000"></div>
      
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative z-10 group bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border border-slate-700/50 hover:border-teal-500/30"
      >
        {/* Header Section */}
        <div className="text-center mb-8">
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2 }}
          >
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              <span className="text-teal-400">#</span>{formData.hashtag} 
              <span className="text-slate-300 ml-2">Campaign</span>
            </h2>
            <div className="w-20 h-1 bg-gradient-to-r from-teal-400 to-teal-600 mx-auto rounded-full mb-4"></div>
          </motion.div>
          
          <motion.span
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-gradient-to-r from-green-500/20 to-green-600/20 text-green-100 text-lg font-semibold border border-green-500/30 shadow-lg shadow-green-500/10"
          >
            <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
            ACTIVE
          </motion.span>
        </div>

        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {metrics.map((metric, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 * index }}
              className="group bg-gradient-to-br from-slate-700/50 to-slate-800/50 p-6 rounded-xl border border-slate-600/30 hover:border-teal-500/30 transition-all duration-300 hover:shadow-xl hover:shadow-teal-500/10 transform hover:scale-105"
            >
              {/* Icon */}
              <div className="flex items-center justify-between mb-4">
                <div className="text-2xl group-hover:scale-110 transition-transform duration-300">
                  {metric.icon}
                </div>
                {metric.trend && (
                  <span className={`text-xs font-semibold px-2 py-1 rounded-full ${
                    metric.trendUp 
                      ? "bg-green-500/20 text-green-300 border border-green-500/30" 
                      : "bg-red-500/20 text-red-300 border border-red-500/30"
                  }`}>
                    {metric.trend}
                  </span>
                )}
              </div>
              
              {/* Value */}
              <div className="text-3xl font-bold text-white mb-2 group-hover:text-teal-400 transition-colors duration-300">
                {metric.value}
              </div>
              
              {/* Label */}
              <div className="text-sm text-slate-400 font-medium">
                {metric.label}
              </div>
            </motion.div>
          ))}
        </div>

        {/* Action Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="flex flex-col sm:flex-row gap-4"
        >
          <button className="group flex-1 bg-gradient-to-r from-teal-600 to-teal-500 text-white px-8 py-4 rounded-xl font-semibold hover:from-teal-500 hover:to-teal-400 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-teal-500/25">
            <span className="flex items-center justify-center gap-3">
              <span className="text-xl group-hover:scale-110 transition-transform">📊</span>
              <span>View Full Analytics</span>
              <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
              </svg>
            </span>
          </button>
          
          <button className="group flex-1 bg-transparent border-2 border-slate-600 text-slate-300 px-8 py-4 rounded-xl font-semibold hover:bg-slate-700 hover:border-slate-500 hover:text-white transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-slate-500/25">
            <span className="flex items-center justify-center gap-3">
              <span className="text-xl group-hover:scale-110 transition-transform">⚙️</span>
              <span>Campaign Settings</span>
              <svg className="w-5 h-5 group-hover:rotate-90 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </span>
          </button>
        </motion.div>

        {/* Additional Campaign Info */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="mt-8 p-4 bg-gradient-to-r from-teal-500/10 to-teal-600/10 rounded-xl border border-teal-500/20"
        >
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-300">
              Campaign Performance: <span className="text-teal-400 font-semibold">Excellent</span>
            </span>
            <span className="text-slate-400">
              Last updated: <span className="text-white">2 minutes ago</span>
            </span>
          </div>
        </motion.div>
      </motion.div>
    </div>
  );
};

export default CampaignDashboard;