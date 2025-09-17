export const ENV = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  VITE_API_URL: process.env.VITE_API_URL,
  VITE_FLOW_NETWORK: process.env.VITE_FLOW_NETWORK || 'testnet',
  VITE_ENABLE_ANALYTICS: process.env.VITE_ENABLE_ANALYTICS === 'true',
  VITE_DEBUG_MODE: process.env.VITE_DEBUG_MODE === 'true',
} as const;

export function isDevelopment(): boolean {
  return ENV.NODE_ENV === 'development';
}

export function isProduction(): boolean {
  return ENV.NODE_ENV === 'production';
}

export function isTestnet(): boolean {
  return ENV.VITE_FLOW_NETWORK === 'testnet';
}

export function isMainnet(): boolean {
  return ENV.VITE_FLOW_NETWORK === 'mainnet';
}

export function getApiUrl(): string {
  return ENV.VITE_API_URL || 'http://localhost:3000';
}

export function isAnalyticsEnabled(): boolean {
  return ENV.VITE_ENABLE_ANALYTICS && isProduction();
}

export function isDebugMode(): boolean {
  return ENV.VITE_DEBUG_MODE || isDevelopment();
}