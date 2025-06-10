"use client"
import { WagmiProvider, createConfig, http } from 'wagmi';
import { mainnet, polygon, sepolia } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ConnectKitProvider, getDefaultConfig } from 'connectkit';
import { ReactNode } from 'react';



// Configure wagmi with ConnectKit
const config = createConfig(
  getDefaultConfig({
     chains: [mainnet, polygon, sepolia],
    transports: {
      [mainnet.id]: http(`https://eth-mainnet.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_ID}`),
      [polygon.id]: http(`https://polygon-mainnet.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_ID}`),
      [sepolia.id]: http(`https://eth-sepolia.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_ID}`),
    },
    walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '4f69838bdcf91d4345a82e1c8be0c78e',
    appName: 'Hashdrop',
    appDescription: 'AI-powered, cross-chain rewards for meaningful social participation',
    appUrl: 'https://hashdrop.app',
    appIcon: 'https://hashdrop.app/logo.png',
  })
);

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 2, // Retry failed queries twice
      staleTime: 60 * 1000, // Cache queries for 1 minute
    },
  },
});

interface Web3ProviderProps {
  children: ReactNode;
}

export const Web3Provider: React.FC<Web3ProviderProps> = ({ children }) => {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider
          theme="midnight"
          customTheme={{
            '--ck-connectbutton-background': '#10B981', // Teal for buttons
            '--ck-connectbutton-hover-background': '#059669', // Hover teal
            '--ck-modal-background': '#1E293B', // Dark slate background
            '--ck-font-family': 'Inter, sans-serif', // Hashdrop’s font
            '--ck-border-radius': '8px', // Rounded corners
            '--ck-overlay-background': 'rgba(0, 0, 0, 0.5)', // Modal overlay
          }}
          options={{
            disclaimer: (
              <span>
                By connecting, you agree to Hashdrop’s{' '}
                <a href="/terms" className="text-teal-400 hover:underline">
                  Terms of Service
                </a>
              </span>
            ),
          }}
        >
          {children}
        </ConnectKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
};