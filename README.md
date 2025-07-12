# FlowSwap

A decentralized token swap application built on the Flow blockchain, featuring real-time price feeds and seamless token trading between FLOW and FUSD.

## Features

- **Real-time Price Feeds**: Live price updates via WebSocket connection
- **FUSD Vault Management**: Automatic setup of FUSD vaults for new users
- **Flow Blockchain Integration**: Native support for Flow testnet
- **Modern UI**: Beautiful, responsive interface with animations
- **Error Handling**: Graceful handling of connection issues and missing vaults

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

3. Start the development server with live price feed:
```bash
npm run dev:full
```

This will start both the Vite development server (port 5175) and the WebSocket price server (port 8081).

### Alternative: Run Without Live Prices

If you don't need live price feeds, you can run just the main application:
```bash
npm run dev
```

## Usage

1. **Connect Wallet**: Click "Connect Wallet" to connect your Flow wallet
2. **Setup FUSD Vault**: If you're trading FUSD for the first time, you'll need to set up your FUSD vault (one-time setup)
3. **Select Tokens**: Choose the tokens you want to swap
4. **Enter Amount**: Input the amount you want to swap
5. **Execute Swap**: Click "Swap" to execute the transaction

## Troubleshooting

### FUSD Balance Issues
If you see "Could not borrow Vault reference" errors, this means your account doesn't have the FUSD vault set up. The application will automatically detect this and provide a "Setup FUSD Vault" button.

### WebSocket Connection Issues
If the live price feed isn't working:
- Make sure the price server is running (`npm run price-server`)
- Check that port 8081 is available
- The application will fall back to static prices if the WebSocket connection fails

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

- `src/bindings/flow-bindings.ts` - Flow blockchain interactions
- `src/config/flow.ts` - Flow network configuration
- `src/hooks/useLivePrice.ts` - WebSocket price feed hook
- `scripts/price-server.js` - WebSocket price server

## License

MIT
