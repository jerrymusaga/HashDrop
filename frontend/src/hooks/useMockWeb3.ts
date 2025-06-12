// hooks/useMockWeb3.ts
import { useState } from "react";

export const useMockWeb3 = () => {
  const [address, setAddress] = useState<string | null>(null);
  const [provider, setProvider] = useState<any>(null);
  const [isConnecting, setIsConnecting] = useState(false);

  const connectWallet = async () => {
    setIsConnecting(true);
    setTimeout(() => {
      setAddress("0x742d35Cc6634C0532925a3b8D23b7C42BFcb7730");
      setProvider({ mock: true });
      setIsConnecting(false);
    }, 2000);
  };

  const disconnectWallet = () => {
    setAddress(null);
    setProvider(null);
  };

  return { address, provider, connectWallet, disconnectWallet, isConnecting };
};