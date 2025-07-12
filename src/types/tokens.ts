// Flow token types
export interface FlowToken {
  symbol: "FLOW" | "TEST";
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

// Token pair for swapping
export interface TokenPair {
  tokenA: FlowToken;
  tokenB: FlowToken;
}

// Transaction result interface
export interface TransactionResult {
  id: string;
  status: "pending" | "success" | "failed";
  error?: string;
} 