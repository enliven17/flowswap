import { config } from "@onflow/fcl";

// Flow Testnet Configuration
export const FLOW_CONFIG = {
  // Testnet RPC endpoints
  ACCESS_NODE: import.meta.env.VITE_FLOW_ACCESS_NODE || "https://rest-testnet.onflow.org",
  WALLET_DISCOVERY: import.meta.env.VITE_FLOW_WALLET_DISCOVERY || "https://fcl-discovery.onflow.org/testnet/authn",
  
  // Testnet contract addresses
  FLOW_TOKEN: import.meta.env.VITE_FLOW_TOKEN_ADDRESS || "0x9a0766d93b6608b7",
  TEST_TOKEN: import.meta.env.VITE_TEST_TOKEN_ADDRESS || "0x0c0c904844c9a720",  // Latest TestToken address
  
  // Testnet token configurations
  TOKENS: {
    FLOW: {
      name: "Flow",
      symbol: "FLOW",
      decimals: 8,
      address: import.meta.env.VITE_FLOW_TOKEN_ADDRESS || "0x9a0766d93b6608b7",
      logo: "/flow.svg",
      description: "Native Flow token"
    },
    TEST: {
      name: "Test Token", 
      symbol: "TEST", 
      decimals: 8, 
      address: import.meta.env.VITE_TEST_TOKEN_ADDRESS || "0x0c0c904844c9a720", 
      logo: "/test-token.svg", 
      description: "Test token for FlowSwap" 
    }
  },
  
  // Swap contract (placeholder - you'll need to deploy your own)
  SWAP_CONTRACT: import.meta.env.VITE_FLOW_SWAP_ADDRESS || "0x0c0c904844c9a720", // Latest contract address
  
  // Network configuration
  NETWORK: "testnet",
  CHAIN_ID: "testnet"
};

// Initialize Flow configuration
config({
  "accessNode.api": FLOW_CONFIG.ACCESS_NODE,
  "discovery.wallet": FLOW_CONFIG.WALLET_DISCOVERY,
  "0x9a0766d93b6608b7": FLOW_CONFIG.FLOW_TOKEN,
  "0x0c0c904844c9a720": FLOW_CONFIG.TEST_TOKEN,
});

// Flow transaction templates
export const FLOW_TRANSACTIONS = {
  GET_BALANCE: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from 0x7e60df042a9c0868
    access(all) fun main(address: Address): UFix64 {
      let account = getAccount(address)
      let vaultRef = account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance)
        .borrow()
        ?? panic("Could not borrow Vault reference")
      return vaultRef.balance
    }
  `,
  
  GET_TEST_TOKEN_BALANCE: `
    import FungibleToken from 0x9a0766d93b6608b7
    import TestToken from 0x0c0c904844c9a720
    
    access(all) fun main(address: Address): UFix64 {
      let account = getAccount(address)
      let vaultRef = account.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
        .borrow()
        ?? panic("Could not borrow Vault reference")
      return vaultRef.balance
    }
  `,
  SWAP_FLOW_TO_TEST: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from 0x7e60df042a9c0868
    import TestToken from 0x0c0c904844c9a720
    
    transaction(amountIn: UFix64, minAmountOut: UFix64, contractAddr: Address) {
      prepare(signer: auth(Storage, Capabilities) &Account) {
        let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
          ?? panic("Could not borrow user's FlowToken Vault")
        let withdrawnFlow <- flowVault.withdraw(amount: amountIn)
        let contractAccount = getAccount(contractAddr)
        let contractFlowReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowSwapFlowReceiver)
          .borrow()
          ?? panic("Could not borrow contract's FlowToken receiver")
        contractFlowReceiver.deposit(from: <- withdrawnFlow)
        let contractTestTokenVault = contractAccount.capabilities.get<&TestToken.Vault>(/public/flowSwapTestReceiver)
          .borrow()
          ?? panic("Could not borrow contract's TestToken Vault")
        let testTokenToSend <- contractTestTokenVault.withdraw(amount: minAmountOut)
        if signer.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
          signer.storage.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
          let receiverCap = signer.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault)
          signer.capabilities.publish(receiverCap, at: /public/testTokenVault)
        }
        let userTestTokenReceiver = signer.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
          .borrow()
          ?? panic("Could not borrow user's TestToken receiver")
        userTestTokenReceiver.deposit(from: <- testTokenToSend)
      }
    }
  `,
  SWAP_TEST_TO_FLOW: `
    import FungibleToken from 0x9a0766d93b6608b7
    import FlowToken from 0x7e60df042a9c0868
    import TestToken from 0x0c0c904844c9a720
    
    transaction(amountIn: UFix64, minAmountOut: UFix64, contractAddr: Address) {
      prepare(signer: auth(Storage, Capabilities) &Account) {
        let testTokenVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/testTokenVault)
          ?? panic("Could not borrow user's TestToken Vault")
        let withdrawnTestToken <- testTokenVault.withdraw(amount: amountIn)
        let contractAccount = getAccount(contractAddr)
        let contractTestTokenReceiver = contractAccount.capabilities.get<&TestToken.Vault>(/public/flowSwapTestReceiver)
          .borrow()
          ?? panic("Could not borrow contract's TestToken receiver")
        contractTestTokenReceiver.deposit(from: <- withdrawnTestToken)
        let contractFlowVault = contractAccount.capabilities.get<auth(FungibleToken.Withdraw) &FlowToken.Vault>(/public/flowSwapFlowReceiver)
          .borrow()
          ?? panic("Could not borrow contract's FlowToken Vault")
        let flowToSend <- contractFlowVault.withdraw(amount: minAmountOut)
        if signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {
          signer.storage.save(<- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()), to: /storage/flowTokenVault)
          let receiverCap = signer.capabilities.storage.issue<&FlowToken.Vault>(/storage/flowTokenVault)
          signer.capabilities.publish(receiverCap, at: /public/flowTokenReceiver)
        }
        let userFlowReceiver = signer.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
          .borrow()
          ?? panic("Could not borrow user's Flow receiver")
        userFlowReceiver.deposit(from: <- flowToSend)
      }
    }
  `,
  SETUP_TEST_TOKEN_VAULT: `
    import FungibleToken from 0x9a0766d93b6608b7
    import TestToken from 0x0c0c904844c9a720
    
    transaction() {
      prepare(signer: auth(Storage, Capabilities) &Account) {
        if signer.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
          signer.storage.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
          signer.capabilities.publish(
            signer.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault),
            at: /public/testTokenVault
          )
          signer.capabilities.publish(
            signer.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault),
            at: /public/testTokenBalance
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
    import FlowSwap from 0x0c0c904844c9a720
    
    pub fun main(tokenIn: String, tokenOut: String): UFix64 {
      return FlowSwap.getSpotPrice(tokenIn: tokenIn, tokenOut: tokenOut)
    }
  `
}; 