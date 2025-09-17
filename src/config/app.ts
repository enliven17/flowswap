export const APP_CONFIG = {
  name: 'FlowSwap',
  version: '1.0.0',
  description: 'Decentralized token swap on Flow blockchain',
  author: 'FlowSwap Team',
  
  // Network configuration
  network: {
    testnet: {
      name: 'Flow Testnet',
      rpcUrl: 'https://rest-testnet.onflow.org',
      explorerUrl: 'https://testnet.flowscan.org',
      chainId: 'flow-testnet',
    },
    mainnet: {
      name: 'Flow Mainnet', 
      rpcUrl: 'https://rest-mainnet.onflow.org',
      explorerUrl: 'https://flowscan.org',
      chainId: 'flow-mainnet',
    },
  },

  // API endpoints
  api: {
    priceWebSocket: 'ws://localhost:8081',
    baseUrl: process.env.VITE_API_URL || 'http://localhost:3000',
  },

  // UI configuration
  ui: {
    theme: 'dark',
    animations: {
      enabled: true,
      duration: 300,
    },
    navbar: {
      height: 64,
      borderRadius: 24,
    },
  },

  // Feature flags
  features: {
    enableAnimations: true,
    enableNotifications: true,
    enableAnalytics: false,
    enableDebugMode: process.env.NODE_ENV === 'development',
  },

  // Swap configuration
  swap: {
    defaultSlippage: 0.5,
    maxSlippage: 50,
    minAmount: 0.0001,
    refreshInterval: 2000,
  },
} as const;

export type AppConfig = typeof APP_CONFIG;