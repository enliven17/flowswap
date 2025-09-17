export const appConfig = {
  name: 'FlowSwap',
  version: '1.0.0',
  description: 'Decentralized token swap on Flow blockchain',
  
  api: {
    baseUrl: process.env.VITE_API_BASE_URL || '',
    timeout: 10000,
  },
  
  flow: {
    network: process.env.VITE_FLOW_NETWORK || 'testnet',
    accessNode: process.env.VITE_FLOW_ACCESS_NODE || 'https://rest-testnet.onflow.org',
    walletDiscovery: process.env.VITE_WALLET_DISCOVERY || 'https://fcl-discovery.onflow.org/testnet/authn',
  },
  
  features: {
    enableAnalytics: process.env.VITE_ENABLE_ANALYTICS === 'true',
    enableErrorReporting: process.env.VITE_ENABLE_ERROR_REPORTING === 'true',
    enablePerformanceMonitoring: process.env.NODE_ENV === 'development',
  },
  
  ui: {
    theme: 'dark',
    animations: {
      enabled: true,
      duration: 300,
    },
    notifications: {
      position: 'top-right' as const,
      duration: 5000,
    },
  },
} as const;

export type AppConfig = typeof appConfig;