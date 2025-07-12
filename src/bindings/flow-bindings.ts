import { query, mutate, tx } from "@onflow/fcl";
import { FLOW_CONFIG, FLOW_TRANSACTIONS, FLOW_SCRIPTS } from "@/config/flow";

// Flow token types
export interface FlowToken {
  symbol: "FLOW" | "FUSD";
  name: string;
  icon: string;
  address: string;
  balance: string | number;
  price: number;
  decimals: number;
}

// Swap state interface
export interface SwapState {
  fromToken: FlowToken;
  toToken: FlowToken;
  fromAmount: string;
  toAmount: string;
  slippage: number;
  isLoading: boolean;
  status: "idle" | "loading" | "success" | "error";
  error?: string;
}

// Flow client class for contract interactions
export class FlowSwapClient {
  private userAddress: string | null = null;

  constructor(userAddress?: string) {
    this.userAddress = userAddress || null;
  }

  // Get user's FLOW balance
  async getFlowBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_BALANCE,
        args: (arg: any, t: any) => [arg(address, t.Address)]
      });
      return Math.max(0, parseFloat(result));
    } catch (error) {
      console.error("Error fetching FLOW balance:", error);
      return 0;
    }
  }

  // Get FUSD balance
  async getFUSDBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_FUSD_BALANCE,
        args: (arg: any, t: any) => [arg(address, t.Address)]
      });
      return parseFloat(result);
    } catch (error) {
      console.error("Error fetching FUSD balance:", error);
      return 0;
    }
  }

  // Get spot price from swap contract (placeholder)
  async getSpotPrice(tokenIn: string, tokenOut: string): Promise<number> {
    try {
      // For now, return a mock price - you'll need to implement this with your actual swap contract
      if (tokenIn === "FLOW" && tokenOut === "FUSD") {
        return 1.5; // Mock price: 1 FLOW = 1.5 FUSD
      } else if (tokenIn === "FUSD" && tokenOut === "FLOW") {
        return 0.67; // Mock price: 1 FUSD = 0.67 FLOW
      }
      return 1;
    } catch (error) {
      console.error("Error fetching spot price:", error);
      return 1;
    }
  }

  // Execute swap transaction (placeholder)
  async executeSwap(
    tokenIn: string,
    tokenOut: string,
    amountIn: number,
    minAmountOut: number
  ): Promise<string> {
    try {
      // This is a placeholder transaction - you'll need to implement the actual swap logic
      const transaction = `
        import FlowSwap from ${FLOW_CONFIG.SWAP_CONTRACT}
        import FungibleToken from 0x9a0766d93b6608b7
        import FlowToken from ${FLOW_CONFIG.FLOW_TOKEN}
        import FUSD from ${FLOW_CONFIG.TOKENS.FUSD.address}
        
        transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, minAmountOut: UFix64) {
          prepare(signer: AuthAccount) {
            // Add your swap logic here
          }
          
          execute {
            // Execute the swap
          }
        }
      `;

      const result = await mutate({
        cadence: transaction,
        args: (arg: any, t: any) => [
          arg(tokenIn, t.String),
          arg(tokenOut, t.String),
          arg(amountIn.toFixed(1), t.UFix64),
          arg(minAmountOut.toFixed(1), t.UFix64)
        ]
      });

      return result;
    } catch (error) {
      console.error("Error executing swap:", error);
      throw error;
    }
  }

  // Get token metadata
  getTokenMetadata(symbol: string): FlowToken | null {
    const token = FLOW_CONFIG.TOKENS[symbol as keyof typeof FLOW_CONFIG.TOKENS];
    if (!token) return null;

    return {
      symbol: symbol as "FLOW" | "FUSD",
      name: token.name,
      icon: token.logo,
      address: token.address,
      balance: 0,
      price: 0,
      decimals: token.decimals
    };
  }

  // Get all available tokens
  getAllTokens(): FlowToken[] {
    return Object.values(FLOW_CONFIG.TOKENS).map(token => ({
      symbol: token.symbol as "FLOW" | "FUSD",
      name: token.name,
      icon: token.logo,
      address: token.address,
      balance: 0,
      price: 0,
      decimals: token.decimals
    }));
  }
}

// Default tokens configuration
export const defaultTokens: FlowToken[] = [
  {
    symbol: "FLOW",
    name: "Flow",
    icon: "/flow.svg",
    address: FLOW_CONFIG.FLOW_TOKEN,
    balance: 0,
    price: 1.5, // Mock price
    decimals: 8
  },
  {
    symbol: "FUSD",
    name: "FUSD Coin",
    icon: "/fusd.svg",
    address: "0xFUSDADDRESS", // Update with actual FUSD contract address on Flow
    balance: 0,
    price: 1, // Stablecoin price
    decimals: 8
  }
]; 