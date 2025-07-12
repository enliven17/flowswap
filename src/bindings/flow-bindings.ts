import { query, mutate, tx } from "@onflow/fcl";
import { FLOW_CONFIG, FLOW_TRANSACTIONS, FLOW_SCRIPTS } from "@/config/flow";

// Flow token types
export interface FlowToken {
  symbol: "FLOW" | "USDC";
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

  // Get USDC balance
  async getUSDCBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_USDC_BALANCE,
        args: (arg: any, t: any) => [arg(address, t.Address)]
      });
      return parseFloat(result);
    } catch (error) {
      console.error("Error fetching USDC balance:", error);
      return 0;
    }
  }

  // Get FUSD balance
  async getFUSDBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_USDC_BALANCE.replace(/FiatToken/g, 'FUSD').replace(FLOW_CONFIG.USDC_TOKEN, '0xe223d8a629e49c68'),
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
      if (tokenIn === "FLOW" && tokenOut === "USDC") {
        return 1.5; // Mock price: 1 FLOW = 1.5 USDC
      } else if (tokenIn === "USDC" && tokenOut === "FLOW") {
        return 0.67; // Mock price: 1 USDC = 0.67 FLOW
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
      let cadence;
      let args;
      const contractAddr = FLOW_CONFIG.SWAP_CONTRACT;
      if (tokenIn === "FLOW" && tokenOut === "USDC") {
        cadence = FLOW_TRANSACTIONS.SWAP_FLOW_TO_USDC;
        args = (arg: any, t: any) => [
          arg(amountIn.toFixed(1), t.UFix64),
          arg(minAmountOut.toFixed(1), t.UFix64),
          arg(contractAddr, t.Address)
        ];
      } else if (tokenIn === "USDC" && tokenOut === "FLOW") {
        cadence = FLOW_TRANSACTIONS.SWAP_USDC_TO_FLOW;
        args = (arg: any, t: any) => [
          arg(amountIn.toFixed(1), t.UFix64),
          arg(minAmountOut.toFixed(1), t.UFix64),
          arg(contractAddr, t.Address)
        ];
      } else {
        throw new Error("Unsupported swap direction");
      }
      const result = await mutate({
        cadence,
        args
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
      symbol: symbol as "FLOW" | "USDC",
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
      symbol: token.symbol as "FLOW" | "USDC",
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
    symbol: "USDC",
    name: "USD Coin",
    icon: "/usdc.svg",
    address: "0x64adf39cbc354fcb", // USDC contract address on Flow testnet
    balance: 0,
    price: 1, // Stablecoin price
    decimals: 8
  }
]; 