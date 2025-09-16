# FlowSwap

A decentralized token swap application **built on the Flow blockchain**, featuring real-time price feeds and seamless token trading between FLOW and TestToken (a custom fungible token for demo purposes).

## 🌊 Built on Flow Blockchain

This project is built on the **Flow blockchain** using:
- **Cadence smart contracts** for secure token swapping
- **@onflow/fcl** for blockchain interactions
- **Flow testnet** for deployment and testing
- **Flow wallet integration** for user authentication

### Deployed Contract Addresses on Flow Testnet:
- **FlowSwap Contract**: `0x0c0c904844c9a720`
- **TestToken Contract**: `0x0c0c904844c9a720`
- **FLOW Token Contract**: `0x9a0766d93b6608b7`

[![ReWTF](https://img.shields.io/badge/ReWTF-Participant-blue?style=for-the-badge&logo=flow&logoColor=white)](https://github.com/onflow/rewtf-registry)
[![Flow](https://img.shields.io/badge/Built%20on-Flow-00EF8B?style=for-the-badge&logo=flow&logoColor=white)](https://flow.com)

## Features

- **Real-time Price Feeds**: Live price updates via WebSocket connection
- **TestToken Vault Management**: Automatic setup of TestToken vaults for new users
- **Flow Blockchain Integration**: Native support for Flow testnet
- **Modern UI**: Beautiful, responsive interface with animations
- **Error Handling**: Graceful handling of connection issues and missing vaults

## Live Price System

The application includes a real-time price feed system that provides live USD values for token balances:

- **WebSocket Connection**: Connects to `ws://localhost:8081` for live price updates
- **Price Integration**: Automatically calculates USD values for FLOW and TestToken balances
- **Fallback Handling**: Uses default prices when WebSocket connection is unavailable
- **Real-time Updates**: Token balances display current USD values based on live market data

## Smart Contracts

### `contracts/FlowSwap.cdc`
**Purpose:**
A decentralized swap contract that allows users to swap between FLOW and TestToken. It manages liquidity pools, swap fees, and emits events for swaps and liquidity changes.

**Key Features:**
- Users can swap FLOW <-> TestToken with slippage protection
- Liquidity providers can add/remove liquidity
- Admin can set swap fees and manage the contract
- All balances and reserves are managed on-chain

### `contracts/TestToken.cdc`
**Purpose:**
A simple fungible token contract (Cadence) for demo and testing. Implements the Flow FungibleToken standard.

**Key Features:**
- Mintable and burnable by the contract admin
- Users can create their own vaults to hold TestToken
- Standard deposit/withdraw interface

## Cadence Transaction & Script Files

- `transactions/swap_flow_to_test.cdc`: Swaps FLOW for TestToken using the FlowSwap contract.
- `transactions/add_liquidity_deployer.cdc`: Adds liquidity to the FlowSwap contract (admin or deployer only).
- `transactions/setup_user_testtoken_vault.cdc`: Sets up a TestToken vault for a user if not already present.
- `scripts/check-flow-balance-final.cdc`: Checks a user's FLOW token balance.
- `scripts/check-testtoken-balance-final.cdc`: Checks a user's TestToken balance.

**All other Cadence files in `transactions/` and `scripts/` are deprecated and have been removed for clarity.**

## Quick Start

### Prerequisites

- Node.js 18+ 
- Flow CLI (for contract deployment)
- A Flow wallet (Blocto, Dapper, etc.)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flowswap
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev -- --port 5190
```

This will start the Vite development server (port 5190).

## Usage

1. **Connect Wallet**: Click "Connect Wallet" to connect your Flow wallet
2. **Setup TestToken Vault**: If you're trading TestToken for the first time, you'll need to set up your TestToken vault (one-time setup)
3. **Select Tokens**: Choose the tokens you want to swap
4. **Enter Amount**: Input the amount you want to swap
5. **Execute Swap**: Click "Swap" to execute the transaction

## Troubleshooting

### TestToken Balance Issues
If you see "Could not borrow Vault reference" errors, this means your account doesn't have the TestToken vault set up. The application will automatically detect this and provide a "Setup TestToken Vault" button.

### Flow Network Issues
- Ensure you're connected to Flow testnet
- Check that your wallet has sufficient FLOW tokens for gas fees
- Verify that the contract addresses in `src/config/flow.ts` are correct for your network

## Development

### Project Structure

```
src/
├── api/             # API clients and calls
├── assets/          # Images, fonts, animations
├── components/      # Reusable UI components
├── config/          # Environment variables and configuration
├── constants/       # App-wide constants
├── hooks/           # Custom React hooks
├── navigation/      # React Navigation logic
├── screens/         # Screen components
├── store/           # Redux Toolkit state management
├── theme/           # Styling and theme
├── types/           # Global TypeScript types
└── utils/           # Helper functions
```

### Key Files

https://github.com/onflow/rewtf-registry

- `src/bindings/flow-bindings.ts` - Flow blockchain interactions
- `src/config/flow.ts` - Flow network configuration
- `src/hooks/useLivePrice.ts` - WebSocket price feed hook

## License

MIT

## Addresses & Vault Mechanism

### Project Addresses

- **FLOW Token Contract:** `0x9a0766d93b6608b7`
- **TestToken Contract & FlowSwap Contract:** `0x0c0c904844c9a720`
- **Swap Contract Address (Testnet):** `0x0c0c904844c9a720`

### Vault Storage Paths

- **FLOW Vault Storage Path:** `/storage/flowTokenVault`
- **FLOW Vault Public Paths:** `/public/flowTokenReceiver`, `/public/flowTokenBalance`
- **TestToken Vault Storage Path:** `/storage/testTokenVault`
- **TestToken Vault Public Paths:** `/public/testTokenVault`, `/public/testTokenBalance`
- **FlowSwap Contract Vaults:**
  - **FLOW:** `/storage/flowSwapFlowVault` (public: `/public/flowSwapFlowReceiver`)
  - **TestToken:** `/storage/flowSwapTestVault` (public: `/public/flowSwapTestReceiver`)

---

## How Vaults and Liquidity Work

### Vaults

- **Vaults** are secure storage resources for tokens in Flow. Each user must have a vault for each token they want to hold or trade.
- When a user interacts with the dApp for the first time, the app checks if the user has a vault for TestToken. If not, it automatically creates one using the `setup_user_testtoken_vault.cdc` transaction.
- Vaults expose public capabilities for deposit and balance queries, allowing contracts and other users to send tokens to your account.

### Liquidity

- **Liquidity** in FlowSwap is managed by the smart contract. The contract holds its own vaults for both FLOW and TestToken.
- Liquidity providers (usually the admin or deployer) can add tokens to the contract's vaults using the `add_liquidity_deployer.cdc` transaction.
- When a user swaps tokens, the contract withdraws from its own vaults to fulfill the swap, and updates its internal reserves.
- The contract emits events for every liquidity addition, removal, and swap, making it easy to track on-chain activity.

---

## Example: Swap Flow

1. **User wants to swap FLOW for TestToken:**
   - User must have a FLOW vault (`/storage/flowTokenVault`) and a TestToken vault (`/storage/testTokenVault`).
   - User calls the swap transaction, which:
     - Withdraws FLOW from the user's vault.
     - Deposits FLOW into the FlowSwap contract's vault.
     - Withdraws TestToken from the contract's vault.
     - Deposits TestToken into the user's vault.

2. **Liquidity Provider adds liquidity:**
   - Admin calls the add liquidity transaction.
   - FLOW and TestToken are deposited into the contract's vaults.
   - The contract's reserves are updated.

---

## User Vault Setup

To use FlowSwap, users need to set up their token vaults. Here's how to do it:

### Prerequisites
- A Flow account with FLOW tokens
- Flow CLI installed and configured

### Setting up FLOW Token Vault
```bash
# Deploy FLOW token vault to your account
flow transactions send cadence/transactions/setup_flow_vault.cdc

# Verify vault setup
flow scripts execute cadence/scripts/get_flow_balance.cdc 0xYOUR_ACCOUNT_ADDRESS
```

### Setting up TestToken Vault
```bash
# Deploy TestToken vault to your account
flow transactions send cadence/transactions/setup_testtoken_vault.cdc

# Verify vault setup
flow scripts execute cadence/scripts/get_testtoken_balance.cdc 0xYOUR_ACCOUNT_ADDRESS
```

### Verifying Vault Setup
After setting up both vaults, you can verify they're working correctly:
```bash
# Check FLOW balance
flow scripts execute cadence/scripts/get_flow_balance.cdc 0xYOUR_ACCOUNT_ADDRESS

# Check TestToken balance
flow scripts execute cadence/scripts/get_testtoken_balance.cdc 0xYOUR_ACCOUNT_ADDRESS
```

### Important Notes
- Make sure your account has sufficient FLOW tokens for transaction fees
- The vault setup transactions only need to be run once per account
- If you encounter any errors, ensure your account has the necessary capabilities and storage paths

---

## 🏆 ReWTF Program

This project is participating in the **ReWTF (Reward The Flow)** program! 

ReWTF rewards developers building on Flow with:
- 10k+ $FLOW rewards for active builders
- Points redeemable for MacBook Pros, AirPods, and digital collectibles
- Recognition for building in public

Learn more about ReWTF: [https://github.com/onflow/rewtf-registry](https://github.com/onflow/rewtf-registry)

---

💚 Built with love for the Flow ecosystem. ⭐💧✨ #ReWTF #FlowBlockchain
