// components/CampaignDetailsForm.tsx
import { motion } from "framer-motion";
import { CampaignDetailsFormProps, FormData } from "@/libs/types";
import React, { useState } from "react";

const CampaignDetailsForm: React.FC<CampaignDetailsFormProps> = ({
  formData,
  updateFormData,
  nextStep,
  prevStep,
}) => {
  const [errors, setErrors] = useState<Partial<FormData>>({});

  const validateForm = (): boolean => {
    const newErrors: Partial<FormData> = {};
    if (!formData.hashtag.trim() || !formData.hashtag.startsWith("#"))
      newErrors.hashtag = "Hashtag must start with #";
    if (!formData.description.trim()) newErrors.description = "Description is required";
    if (formData.duration <= 0) newErrors.duration = "Duration must be greater than 0";
    if (formData.totalRewards <= 0) newErrors.totalRewards = "Rewards must be greater than 0";
    if (!formData.collectionName.trim()) newErrors.collectionName = "Collection name is required";
    if (!formData.imageUrl.trim()) newErrors.imageUrl = "Image URL is required";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm()) nextStep();
  };

  return (
    <div className="max-w-4xl mx-auto">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center mb-6"
      >
        <h2 className="text-3xl md:text-4xl font-bold mb-4">
          Campaign <span className="text-teal-400">Details</span>
        </h2>

        <p className="text-lg text-slate-300 mt-2 max-w-2xl mx-auto">
          Configure your hashtag campaign with NFT rewards and cross-chain distribution
        </p>
      </motion.div>

      <motion.form
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        onSubmit={handleSubmit}
        className="bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl p-8 shadow-2xl border border-slate-700/50 hover:border-teal-500/30 transition-all duration-300"
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Campaign Hashtag */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
            className="group"
          >
            <label className="block text-lg font-semibold text-slate-300 mb-3">
              Campaign Hashtag <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <input
                type="text"
                value={formData.hashtag}
                onChange={(e) => updateFormData({ hashtag: e.target.value })}
                className={`w-full p-4 bg-slate-900 border-2 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-300 ${
                  errors.hashtag ? "border-red-500" : "border-slate-700 group-hover:border-slate-600"
                }`}
                placeholder="#buildwithbase"
              />
              <div className="absolute top-4 right-4">
                <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
                </svg>
              </div>
            </div>
            {errors.hashtag && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-sm mt-2 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {errors.hashtag}
              </motion.p>
            )}
            <p className="text-sm text-slate-400 mt-2">
              Must start with # and contain only letters, numbers, and underscores
            </p>
          </motion.div>

          {/* NFT Collection Name */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
            className="group"
          >
            <label className="block text-lg font-semibold text-slate-300 mb-3">
              NFT Collection Name <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <input
                type="text"
                value={formData.collectionName}
                onChange={(e) => updateFormData({ collectionName: e.target.value })}
                className={`w-full p-4 bg-slate-900 border-2 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-300 ${
                  errors.collectionName ? "border-red-500" : "border-slate-700 group-hover:border-slate-600"
                }`}
                placeholder="Base Builder Badge"
              />
              <div className="absolute top-4 right-4">
                <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
              </div>
            </div>
            {errors.collectionName && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-sm mt-2 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {errors.collectionName}
              </motion.p>
            )}
          </motion.div>

          {/* Campaign Description */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="md:col-span-2 group"
          >
            <label className="block text-lg font-semibold text-slate-300 mb-3">
              Campaign Description <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <textarea
                value={formData.description}
                onChange={(e) => updateFormData({ description: e.target.value })}
                className={`w-full p-4 bg-slate-900 border-2 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-300 resize-none ${
                  errors.description ? "border-red-500" : "border-slate-700 group-hover:border-slate-600"
                }`}
                rows={4}
                placeholder="Celebrating builders on Base blockchain - share your projects, tutorials, and insights to earn exclusive NFT rewards!"
              />
              <div className="absolute top-4 right-4">
                <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </div>
            </div>
            {errors.description && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-sm mt-2 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {errors.description}
              </motion.p>
            )}
          </motion.div>

          {/* Duration */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.5 }}
            className="group"
          >
            <label className="block text-lg font-semibold text-slate-300 mb-3">
              Duration (Days) <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <input
                type="number"
                value={formData.duration}
                onChange={(e) => updateFormData({ duration: Number(e.target.value) })}
                className={`w-full p-4 bg-slate-900 border-2 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-300 ${
                  errors.duration ? "border-red-500" : "border-slate-700 group-hover:border-slate-600"
                }`}
                min="1"
                max="365"
                placeholder="30"
              />
              <div className="absolute top-4 right-4">
                <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
            </div>
            {errors.duration && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-sm mt-2 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {errors.duration}
              </motion.p>
            )}
          </motion.div>

          {/* Total NFT Rewards */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.6 }}
            className="group"
          >
            <label className="block text-lg font-semibold text-slate-300 mb-3">
              Total NFT Rewards <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <input
                type="number"
                value={formData.totalRewards}
                onChange={(e) => updateFormData({ totalRewards: Number(e.target.value) })}
                className={`w-full p-4 bg-slate-900 border-2 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-300 ${
                  errors.totalRewards ? "border-red-500" : "border-slate-700 group-hover:border-slate-600"
                }`}
                min="1"
                max="10000"
                placeholder="1000"
              />
              <div className="absolute top-4 right-4">
                <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                </svg>
              </div>
            </div>
            {errors.totalRewards && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-sm mt-2 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {errors.totalRewards}
              </motion.p>
            )}
          </motion.div>

          {/* NFT Image URL */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="md:col-span-2 group"
          >
            <label className="block text-lg font-semibold text-slate-300 mb-3">
              NFT Image URL <span className="text-red-400">*</span>
            </label>
            <div className="relative">
              <input
                type="url"
                value={formData.imageUrl}
                onChange={(e) => updateFormData({ imageUrl: e.target.value })}
                className={`w-full p-4 bg-slate-900 border-2 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-300 ${
                  errors.imageUrl ? "border-red-500" : "border-slate-700 group-hover:border-slate-600"
                }`}
                placeholder="https://your-image.com/builder-badge.png"
              />
              <div className="absolute top-4 right-4">
                <svg className="w-5 h-5 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
            </div>
            {errors.imageUrl && (
              <motion.p
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-sm mt-2 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {errors.imageUrl}
              </motion.p>
            )}
            <p className="text-sm text-slate-400 mt-2">
              High-quality image recommended (512x512 or larger) for best NFT display quality
            </p>
          </motion.div>
        </div>

        {/* Action Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="flex flex-col sm:flex-row gap-4 mt-12"
        >
          <button
            type="button"
            onClick={prevStep}
            className="group flex-1 bg-transparent border-2 border-slate-600 text-slate-300 px-8 py-4 rounded-xl font-semibold hover:bg-slate-700 hover:border-slate-500 hover:text-white transition-all duration-300 transform hover:scale-105"
          >
            <span className="flex items-center justify-center gap-2">
              <svg className="w-5 h-5 group-hover:-translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 17l-5-5m0 0l5-5m-5 5h12" />
              </svg>
              Back
            </span>
          </button>
          <button
            type="submit"
            className="group flex-1 bg-gradient-to-r from-teal-600 to-teal-500 text-white px-8 py-4 rounded-xl font-semibold hover:from-teal-500 hover:to-teal-400 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-teal-500/25"
          >
            <span className="flex items-center justify-center gap-2">
              Continue Setup
              <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
              </svg>
            </span>
          </button>
        </motion.div>
      </motion.form>
    </div>
  );
};

export default CampaignDetailsForm;