export const SWAP_CONSTANTS = {
  DEFAULT_SLIPPAGE: 0.5,
  MIN_AMOUNT: 0.0001,
  MAX_SLIPPAGE: 50,
  REFRESH_INTERVAL: 2000,
  ANIMATION_DURATION: 0.6,
  DEBOUNCE_DELAY: 300,
} as const;

export const NETWORK_CONFIG = {
  TESTNET: {
    name: 'Flow Testnet',
    chainId: 'flow-testnet',
    rpcUrl: 'https://rest-testnet.onflow.org',
    explorerUrl: 'https://testnet.flowscan.org',
  },
  MAINNET: {
    name: 'Flow Mainnet',
    chainId: 'flow-mainnet',
    rpcUrl: 'https://rest-mainnet.onflow.org',
    explorerUrl: 'https://flowscan.org',
  },
} as const;

export const UI_CONSTANTS = {
  NAVBAR_HEIGHT: 64,
  CARD_BORDER_RADIUS: 24,
  BUTTON_BORDER_RADIUS: 16,
  ANIMATION_SPRING: {
    type: 'spring',
    bounce: 0.2,
    duration: 0.6,
  },
} as const;