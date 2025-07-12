import { config } from "@onflow/fcl";

// Flow Testnet Configuration
export const FLOW_CONFIG = {
  // Testnet RPC endpoints
  ACCESS_NODE: "https://rest-testnet.onflow.org",
  WALLET_DISCOVERY: "https://fcl-discovery.onflow.org/testnet/authn",
  
  // Testnet contract addresses
  FLOW_TOKEN: "0x7e60df042a9c0868",
  FUSD_TOKEN: "0xe223d8a629e49c68",
  
  // Testnet token configurations
  TOKENS: {
    FLOW: {
      name: "Flow",
      symbol: "FLOW",
      decimals: 8,
      address: "0x7e60df042a9c0868",
      logo: "/flow.svg",
      description: "Native Flow token"
    },
    FUSD: {
      name: "Flow USD",
      symbol: "FUSD",
      decimals: 8,
      address: "0xe223d8a629e49c68",
      logo: "/fusd.svg",
      description: "Flow USD stablecoin"
    }
  },
  
  // Swap contract (placeholder - you'll need to deploy your own)
  SWAP_CONTRACT: "0x1234567890abcdef", // Replace with your deployed contract address
  
  // Network configuration
  NETWORK: "testnet",
  CHAIN_ID: "testnet"
};

// Initialize FCL configuration
export function initializeFlow() {
  config({
    "accessNode.api": FLOW_CONFIG.ACCESS_NODE,
    "discovery.wallet": FLOW_CONFIG.WALLET_DISCOVERY,
    "fcl.network": FLOW_CONFIG.NETWORK,
    "app.detail.title": "FlowSwap",
    "app.detail.icon": "/flowswap-logo.png"
  });
}

// Flow transaction templates
export const FLOW_TRANSACTIONS = {
  GET_BALANCE: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from ${FLOW_CONFIG.FLOW_TOKEN}
    
    access(all) fun main(address: Address): UFix64 {
      let account = getAccount(address)
      let vaultRef = account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance).borrow() ?? panic("Could not borrow Vault reference")
      return vaultRef.balance
    }
  `,
  
  GET_FUSD_BALANCE: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FUSD from ${FLOW_CONFIG.TOKENS.FUSD.address}
    
    access(all) fun main(address: Address): UFix64 {
      let account = getAccount(address)
      let vaultRef = account.capabilities.get<&FUSD.Vault>(/public/fusdBalance).borrow() ?? panic("Could not borrow Vault reference")
      return vaultRef.balance
    }
  `
};

// Flow scripts for price fetching (placeholder)
export const FLOW_SCRIPTS = {
  GET_SPOT_PRICE: `
    import FlowSwap from ${FLOW_CONFIG.SWAP_CONTRACT}
    
    pub fun main(tokenIn: String, tokenOut: String): UFix64 {
      return FlowSwap.getSpotPrice(tokenIn: tokenIn, tokenOut: tokenOut)
    }
  `
}; 