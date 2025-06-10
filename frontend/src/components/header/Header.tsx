"use client"
import { Hash } from 'lucide-react';
import { useState } from 'react';
import Link from 'next/link';
import { Menu, X, Wallet } from 'lucide-react';
import { ConnectKitButton } from "connectkit";
import { useAccount } from 'wagmi';

const Header: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { address, isConnected } = useAccount();

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-slate-900/90 backdrop-blur-md border-b border-slate-800">
      <div className="mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
        {/* Logo */}
        <Link href="/" className="text-2xl font-bold text-white">
          <div className="flex items-center">
            <div className="flex-shrink-0 flex items-center">
              <Hash className="h-8 w-8 text-teal-600"/>
              <span className="ml-2 text-3xl font-bold">HashDrop</span>
            </div>
          </div>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex space-x-6">
          <Link href="/" className="text-slate-300 hover:text-teal-400 transition">Home</Link>
          <Link href="/campaigns" className="text-slate-300 hover:text-teal-400 transition">Campaigns</Link>
          <Link href="/create-campaign" className="text-slate-300 hover:text-teal-400 transition">Create Campaign</Link>
          <Link href="/participantsDashboard" className="text-slate-300 hover:text-teal-400 transition">Dashboard</Link>
          <Link href="/docs" className="text-slate-300 hover:text-teal-400 transition">Docs</Link>
        </nav>

        {/* Wallet Button */}
        <div className="flex items-center space-x-4">
          {/* ConnectKit Button with Custom Styling */}
          <ConnectKitButton.Custom>
            {({ isConnected, isConnecting, show, hide, address, ensName, chain }) => (
              <button
                onClick={show}
                className="group bg-teal-600 text-white px-4 py-2 rounded-lg hover:bg-teal-700 transition-all duration-200 flex items-center space-x-2 font-medium"
              >
                <Wallet className="w-4 h-4" />
                <span>
                  {isConnecting && "Connecting..."}
                  {isConnected && address && (
                    `${address.slice(0, 6)}...${address.slice(-4)}`
                  )}
                  {!isConnected && !isConnecting && "Connect Wallet"}
                </span>
              </button>
            )}
          </ConnectKitButton.Custom>

          {/* Mobile Menu Toggle */}
          <button 
            className="md:hidden text-white" 
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMenuOpen && (
        <div className="md:hidden bg-slate-900 border-t border-slate-800">
          <nav className="flex flex-col space-y-4 px-4 py-6">
            <Link href="/" className="text-slate-300 hover:text-teal-400 transition">Home</Link>
            <Link href="/campaigns" className="text-slate-300 hover:text-teal-400 transition">Campaigns</Link>
            <Link href="/create-campaign" className="text-slate-300 hover:text-teal-400 transition">Create Campaign</Link>
            <Link href="/dashboard" className="text-slate-300 hover:text-teal-400 transition">Dashboard</Link>
            <Link href="/docs" className="text-slate-300 hover:text-teal-400 transition">Docs</Link>
            
            {/* Mobile Wallet Button */}
            <div className="pt-4 border-t border-slate-700">
              <ConnectKitButton.Custom>
                {({ isConnected, isConnecting, show, hide, address, ensName }) => (
                  <button
                    onClick={show}
                    className="w-full bg-teal-600 text-white px-4 py-3 rounded-lg hover:bg-teal-700 transition-all duration-200 flex items-center justify-center space-x-2 font-medium"
                  >
                    <Wallet className="w-4 h-4" />
                    <span>
                      {isConnecting && "Connecting..."}
                      {isConnected && address && (
                        `${address.slice(0, 6)}...${address.slice(-4)}`
                      )}
                      {!isConnected && !isConnecting && "Connect Wallet"}
                    </span>
                  </button>
                )}
              </ConnectKitButton.Custom>
            </div>
          </nav>
        </div>
      )}
    </header>
  );
};

export default Header;