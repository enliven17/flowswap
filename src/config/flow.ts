import { config } from "@onflow/fcl";

// Flow Testnet Configuration
export const FLOW_CONFIG = {
  // Testnet RPC endpoints
  ACCESS_NODE: "https://rest-testnet.onflow.org",
  WALLET_DISCOVERY: "https://fcl-discovery.onflow.org/testnet/authn",
  
  // Testnet contract addresses
  FLOW_TOKEN: "0x7e60df042a9c0868",
  USDC_TOKEN: "0x64adf39cbc354fcb",
  
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
    USDC: {
      name: "USD Coin",
      symbol: "USDC",
      decimals: 8,
      address: "0x64adf39cbc354fcb",
      logo: "/usdc.svg",
      description: "USD Coin stablecoin"
    }
  },
  
  // Swap contract (placeholder - you'll need to deploy your own)
  SWAP_CONTRACT: "0xfbaa55ea2a76ff04", // Yeni deploy edilen kontrat adresi
  
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
  
  GET_USDC_BALANCE: `
    import FungibleToken from 0x9a0766d93b6608b7
    import USDC from ${FLOW_CONFIG.TOKENS.USDC.address}
    
    access(all) fun main(address: Address): UFix64 {
      let account = getAccount(address)
      let vaultRef = account.capabilities.get<&USDC.Vault>(/public/USDCBalance).borrow() ?? panic("Could not borrow Vault reference")
      return vaultRef.balance
    }
  `,
  SWAP_FLOW_TO_USDC: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from 0x7e60df042a9c0868
    import USDC from 0x64adf39cbc354fcb
    
    transaction(amountIn: UFix64, minAmountOut: UFix64, contractAddr: Address) {
      prepare(signer: AuthAccount) {
        // 1. Withdraw FLOW from user
        let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
          ?? panic("Could not borrow user's FlowToken Vault")
        let withdrawnFlow <- flowVault.withdraw(amount: amountIn)

        // 2. Deposit FLOW to contract
        let contractAccount = getAccount(contractAddr)
        let contractFlowReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
          .borrow()
          ?? panic("Could not borrow contract's FlowToken receiver")
        contractFlowReceiver.deposit(from: <- withdrawnFlow)

        // 3. Withdraw USDC from contract and send to user
        let contractUSDCVault = contractAccount.capabilities.get<&USDC.Vault>(/public/USDCVault)
          .borrow()
          ?? panic("Could not borrow contract's USDC Vault")
        let usdcToSend <- contractUSDCVault.withdraw(amount: minAmountOut)

        // 4. Create USDC vault for user if needed
        if signer.borrow<&USDC.Vault>(from: /storage/USDCVault) == nil {
          signer.save(<- USDC.createEmptyVault(), to: /storage/USDCVault)
          signer.link<&USDC.Vault>(
            /public/USDCReceiver,
            target: /storage/USDCVault
          )
        }
        let userUSDCReceiver = signer.getCapability(/public/USDCReceiver)
          .borrow<&{FungibleToken.Receiver}>()
          ?? panic("Could not borrow user's USDC receiver")
        userUSDCReceiver.deposit(from: <- usdcToSend)
      }
    }
  `,
  SWAP_USDC_TO_FLOW: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from 0x7e60df042a9c0868
    import USDC from 0x64adf39cbc354fcb
    
    transaction(amountIn: UFix64, minAmountOut: UFix64, contractAddr: Address) {
      prepare(signer: AuthAccount) {
        // 1. Withdraw USDC from user
        let usdcVault = signer.borrow<&USDC.Vault>(from: /storage/USDCVault)
          ?? panic("Could not borrow user's USDC Vault")
        let withdrawnUSDC <- usdcVault.withdraw(amount: amountIn)

        // 2. Deposit USDC to contract
        let contractAccount = getAccount(contractAddr)
        let contractUSDCReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/USDCReceiver)
          .borrow()
          ?? panic("Could not borrow contract's USDC receiver")
        contractUSDCReceiver.deposit(from: <- withdrawnUSDC)

        // 3. Withdraw FLOW from contract and send to user
        let contractFlowVault = contractAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenVault)
          .borrow()
          ?? panic("Could not borrow contract's FlowToken Vault")
        let flowToSend <- contractFlowVault.withdraw(amount: minAmountOut)

        // 4. Create FLOW vault for user if needed
        if signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {
          signer.save(<- FlowToken.createEmptyVault(), to: /storage/flowTokenVault)
          signer.link<&FlowToken.Vault>(
            /public/flowTokenReceiver,
            target: /storage/flowTokenVault
          )
        }
        let userFlowReceiver = signer.getCapability(/public/flowTokenReceiver)
          .borrow<&{FungibleToken.Receiver}>()
          ?? panic("Could not borrow user's Flow receiver")
        userFlowReceiver.deposit(from: <- flowToSend)
      }
    }
  `,
  SETUP_USDC_VAULT: `
    import FungibleToken from 0x9a0766d93b6608b7
    import USDC from 0x64adf39cbc354fcb
    
    transaction {
      prepare(signer: AuthAccount) {
        // USDC Vault yoksa oluştur
        if signer.borrow<&USDC.Vault>(from: /storage/USDCVault) == nil {
          signer.save(<- USDC.createEmptyVault(), to: /storage/USDCVault)
          signer.link<&USDC.Vault{FungibleToken.Receiver}>(
            /public/USDCReceiver,
            target: /storage/USDCVault
          )
          signer.link<&USDC.Vault{FungibleToken.Balance}>(
            /public/USDCBalance,
            target: /storage/USDCVault
          )
        }
      }
    }
  `,
  SETUP_FLOW_VAULT: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from 0x7e60df042a9c0868
    
    transaction {
      prepare(signer: AuthAccount) {
        // FlowToken Vault yoksa oluştur
        if signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {
          signer.save(<- FlowToken.createEmptyVault(), to: /storage/flowTokenVault)
          signer.link<&FlowToken.Vault{FungibleToken.Receiver}>(
            /public/flowTokenReceiver,
            target: /storage/flowTokenVault
          )
          signer.link<&FlowToken.Vault{FungibleToken.Balance}>(
            /public/flowTokenBalance,
            target: /storage/flowTokenVault
          )
        }
      }
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