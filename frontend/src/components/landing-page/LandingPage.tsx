import Link from 'next/link';

const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-slate-900 text-white relative overflow-hidden">
      {/* Background gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 opacity-50"></div>
      <div className="absolute inset-0 bg-gradient-to-t from-teal-900/10 via-transparent to-teal-900/5"></div>
      
      {/* Animated background elements */}
      <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-teal-600/5 rounded-full blur-3xl animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-teal-600/3 rounded-full blur-3xl animate-pulse delay-1000"></div>
      
      <div className="relative z-10">
        {/* Hero Section */}
        <section className="pt-20 pb-16 flex flex-col items-center justify-center text-center px-4">
          <div className=" mx-auto pt-5">
            <h1 className="text-4xl md:text-7xl xl:text-7xl font-bold leading-tight mx-auto mb-6">
              Turn
              <span className="text-teal-400 ml-4 inline-block transform hover:scale-105 transition-transform duration-300">
                Hashtags
              </span>
              <br className="md:hidden" />
              <span className="inline"> into Verifiable</span>
              <br />
              <span className="bg-gradient-to-r from-teal-400 to-teal-600 bg-clip-text text-transparent">
                Web3 Rewards
              </span>
            </h1>
            
            <p className="text-lg md:text-2xl xl:text-3xl text-slate-300 leading-relaxed max-w-5xl mx-auto mt-8 mb-12">
              Hashdrop: AI-powered, cross-chain rewards for meaningful social participation, powered by 
              <span className="text-teal-400 font-semibold"> Chainlink</span>.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <Link
                href="/campaigns"
                className="group bg-gradient-to-r from-teal-600 to-teal-500 text-white px-8 py-4 rounded-xl font-semibold hover:from-teal-500 hover:to-teal-400 transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-teal-500/25 min-w-[200px]"
              >
                <span className="flex items-center justify-center gap-2">
                  Explore Campaigns
                  <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </span>
              </Link>
              
              <Link
                href="/create-campaign"
                className="group bg-transparent border-2 border-teal-500 text-teal-400 px-8 py-4 rounded-xl font-semibold hover:bg-teal-500 hover:text-white transition-all duration-300 transform hover:scale-105 hover:shadow-xl hover:shadow-teal-500/25 min-w-[200px]"
              >
                <span className="flex items-center justify-center gap-2">
                  Create Campaign
                  <svg className="w-5 h-5 group-hover:rotate-12 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                </span>
              </Link>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="py- px-4">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-5xl font-bold mb-4">
                Why <span className="text-teal-400">Hashdrop</span>?
              </h2>
              <div className="w-24 h-1 bg-gradient-to-r from-teal-400 to-teal-600 mx-auto rounded-full"></div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="group p-8 bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105 border border-slate-700/50 hover:border-teal-500/30">
                <div className="w-12 h-12 bg-gradient-to-br from-teal-500 to-teal-600 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold mb-3 text-teal-400">AI-Powered Scoring</h3>
                <p className="text-slate-300 leading-relaxed">
                  Our advanced AI agent analyzes social posts to reward high-quality participation and authentic engagement.
                </p>
              </div>
              
              <div className="group p-8 bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105 border border-slate-700/50 hover:border-teal-500/30">
                <div className="w-12 h-12 bg-gradient-to-br from-teal-500 to-teal-600 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold mb-3 text-teal-400">Cross-Chain Rewards</h3>
                <p className="text-slate-300 leading-relaxed">
                  Seamlessly mint NFTs or tokens on any supported blockchain via Chainlink CCIP technology.
                </p>
              </div>
              
              <div className="group p-8 bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-2xl shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105 border border-slate-700/50 hover:border-teal-500/30">
                <div className="w-12 h-12 bg-gradient-to-br from-teal-500 to-teal-600 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold mb-3 text-teal-400">Decentralized Verification</h3>
                <p className="text-slate-300 leading-relaxed">
                  Trustless validation of social engagement using Chainlink Functions for complete transparency.
                </p>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

export default LandingPage;