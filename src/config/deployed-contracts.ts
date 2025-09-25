// Deployed Contract Addresses
export const DEPLOYED_CONTRACTS = {
  testnet: {
    TestToken: import.meta.env.VITE_TEST_TOKEN_ADDRESS || "0x0c0c904844c9a720", // Latest TestToken address
    TestETH: import.meta.env.VITE_TEST_ETH_ADDRESS || "0x0c0c904844c9a720", // Latest TestETH address
    FlowSwap: import.meta.env.VITE_FLOW_SWAP_ADDRESS || "0x0c0c904844c9a720", // Latest FlowSwap contract address
    FungibleToken: import.meta.env.VITE_FUNGIBLE_TOKEN_ADDRESS || "0xf233dcee88fe0abe", // Testnet FungibleToken
  },
  mainnet: {
    TestToken: "", // Mainnet'e deploy edilecek
    TestETH: "", // Mainnet'e deploy edilecek
    FungibleToken: "0xf233dcee88fe0abe",
  },
};

// Contract Import Templates
export const CONTRACT_IMPORTS = {
  testnet: {
    TestToken: `import TestToken from 0x0c0c904844c9a720`,
    TestETH: `import TestETH from 0x0c0c904844c9a720`,
    FlowSwap: `import FlowSwap from 0x0c0c904844c9a720`,
    FungibleToken: `import FungibleToken from 0xf233dcee88fe0abe`,
  },
};

// Contract Interaction Functions
export const TestTokenConfig = {
  contractAddress: import.meta.env.VITE_TEST_TOKEN_ADDRESS || "0x0c0c904844c9a720",
  contractName: "TestToken",
  
  // Storage Paths
  VaultStoragePath: "/storage/testTokenVault",
  VaultPublicPath: "/public/testTokenVault",
  AdminStoragePath: "/storage/testTokenAdmin",
  
  // Token Info
  name: "TestToken",
  symbol: "TEST",
  decimals: 8,
  totalSupply: "1000000.0",
};

export const TestETHConfig = {
  contractAddress: import.meta.env.VITE_TEST_ETH_ADDRESS || "0x0c0c904844c9a720",
  contractName: "TestETH",

  // Storage Paths
  VaultStoragePath: "/storage/testETHVault",
  VaultPublicPath: "/public/testETHVault",
  AdminStoragePath: "/storage/testETHAdmin",

  // Token Info
  name: "TestETH",
  symbol: "TETH",
  decimals: 8,
  totalSupply: "1000000.0",
};

export default DEPLOYED_CONTRACTS; 