// Deployed Contract Addresses
export const DEPLOYED_CONTRACTS = {
  testnet: {
    TestToken: "0xfbaa55ea2a76ff04", // Gerçek testnet hesabı
    FungibleToken: "0xf233dcee88fe0abe", // Testnet FungibleToken
  },
  mainnet: {
    TestToken: "", // Mainnet'e deploy edilecek
    FungibleToken: "0xf233dcee88fe0abe",
  },
};

// Contract Import Templates
export const CONTRACT_IMPORTS = {
  testnet: {
    TestToken: `import TestToken from 0xfbaa55ea2a76ff04`,
    FungibleToken: `import FungibleToken from 0xf233dcee88fe0abe`,
  },
};

// Contract Interaction Functions
export const TestTokenConfig = {
  contractAddress: "0xfbaa55ea2a76ff04",
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

export default DEPLOYED_CONTRACTS; 