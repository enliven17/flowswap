import { query, mutate } from "@onflow/fcl";
import { FLOW_CONFIG, FLOW_TRANSACTIONS } from "@/config/flow";
import type { FlowToken } from "@/types/tokens";

// Flow Client class to handle all Flow blockchain interactions
export class FlowSwapClient {
  private config: typeof FLOW_CONFIG;

  // Helper types to avoid `any` when building Cadence args with FCL
  private static readonly cadenceTypes: { Address?: unknown; UFix64?: unknown; String?: unknown } = {};
  private static argBuilder(value: unknown, cadenceType: unknown): unknown {
    // This function exists purely for typing clarity when passed into FCL's args callback
    return { value, cadenceType } as unknown;
  }

  constructor() {
    this.config = FLOW_CONFIG;
  }

  async setupPoolFlowReceiver(): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SETUP_POOL_FLOW_RECEIVER,
        args: (_arg: typeof FlowSwapClient.argBuilder, _t: typeof FlowSwapClient.cadenceTypes) => [],
      });
      return result;
    } catch (error) {
      console.error("Error setting up pool flow receiver:", error);
      throw error;
    }
  }

  async hasFlowVault(address: string): Promise<boolean> {
    try {
      const result = await query({
        cadence: `
          import FungibleToken from 0x9a0766d93b6608b7
          import FlowToken from 0x7e60df042a9c0868
          access(all) fun main(address: Address): Bool {
            let account = getAccount(address)
            return account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance).check()
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(address, t.Address as unknown)
        ]
      });
      return result === true;
    } catch {
      return false;
    }
  }

  async setupFlowVault(): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SETUP_FLOW_VAULT,
        args: (_arg: typeof FlowSwapClient.argBuilder, _t: typeof FlowSwapClient.cadenceTypes) => [],
      });
      return result;
    } catch (error) {
      console.error("Error setting up Flow vault:", error);
      throw error;
    }
  }

  // Get Flow balance for an address
  async getFlowBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_BALANCE,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(address, t.Address as unknown)
        ]
      });
      return parseFloat(result);
    } catch (error) {
      console.error("Error fetching FLOW balance:", error);
      return 0;
    }
  }

  // Get TestToken balance
  async getTestTokenBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_TEST_TOKEN_BALANCE,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(address, t.Address as unknown)
        ]
      });
      return parseFloat(result);
    } catch (error) {
      console.error("Error fetching TestToken balance:", error);
      // If the error indicates missing vault, return 0 instead of throwing
      if (error instanceof Error && error.message.includes("Could not borrow Vault reference")) {
        console.log("TestToken vault not set up for user, returning 0 balance");
        return 0;
      }
      return 0;
    }
  }

  // Setup TestToken vault for user
  async setupTestTokenVault(): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SETUP_TEST_TOKEN_VAULT,
        args: (_arg: typeof FlowSwapClient.argBuilder, _t: typeof FlowSwapClient.cadenceTypes) => []
      });
      return result;
    } catch (error) {
      console.error("Error setting up TestToken vault:", error);
      throw error;
    }
  }

  // Check if user has TestToken vault set up
  async hasTestTokenVault(address: string): Promise<boolean> {
    try {
      const result = await query({
        cadence: `
          import FungibleToken from 0x9a0766d93b6608b7
          import TestToken from 0x0c0c904844c9a720
          access(all) fun main(address: Address): Bool {
            let account = getAccount(address)
            let vaultCap = account.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
            return vaultCap.check()
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(address, t.Address as unknown)
        ]
      });
      return result === true;
    } catch (error) {
      console.error("Error checking TestToken vault:", error);
      return false;
    }
  }

  // Refresh all balances for a user
  async refreshBalances(address: string): Promise<{ flow: number; test: number }> {
    try {
      const [flowBalance, testBalance] = await Promise.all([
        this.getFlowBalance(address),
        this.getTestTokenBalance(address)
      ]);
      
      return {
        flow: flowBalance,
        test: testBalance
      };
    } catch (error) {
      console.error("Error refreshing balances:", error);
      return { flow: 0, test: 0 };
    }
  }

  // Swap FLOW to TestToken
  async swapFlowToTestToken(amountIn: number, minAmountOut: number): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SWAP_FLOW_TO_TEST,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(amountIn.toFixed(8), t.UFix64 as unknown),
          arg(minAmountOut.toFixed(8), t.UFix64 as unknown),
          arg(this.config.SWAP_CONTRACT, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error swapping FLOW to TestToken:", error);
      throw error;
    }
  }

  // Swap TestToken to FLOW
  async swapTestTokenToFlow(amountIn: number, minAmountOut: number): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SWAP_TEST_TO_FLOW,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(amountIn.toFixed(8), t.UFix64 as unknown),
          arg(minAmountOut.toFixed(8), t.UFix64 as unknown),
          arg(this.config.SWAP_CONTRACT, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error swapping TestToken to FLOW:", error);
      throw error;
    }
  }

  async addFlowLiquidity(amount: number, poolAddress: string): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.ADD_FLOW_LIQUIDITY,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(amount.toFixed(8), t.UFix64 as unknown),
          arg(poolAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error adding FLOW liquidity:", error);
      throw error;
    }
  }

  // Generic token transfer
  async transferTokens(
    tokenType: 'FLOW' | 'TEST',
    amount: number,
    recipient: string
  ): Promise<string> {
    try {
      const cadence = tokenType === 'FLOW' 
        ? this.getFlowTransferTransaction()
        : this.getTestTokenTransferTransaction();
      
      const result = await mutate({
        cadence,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(recipient, t.Address as unknown),
          arg(amount.toFixed(8), t.UFix64 as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error(`Error transferring ${tokenType} tokens:`, error);
      throw error;
    }
  }

  private getFlowTransferTransaction(): string {
    return `
      import FungibleToken from 0xee82856bf20e2aa6
      import FlowToken from 0x0ae53cb6e3f42a79
      
      transaction(to: Address, amount: UFix64) {
        let sentVault: @FungibleToken.Vault
        
        prepare(signer: auth(Storage) &Account) {
          let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
          
          self.sentVault <- vaultRef.withdraw(amount: amount)
        }
        
        execute {
          let recipient = getAccount(to)
          let receiverRef = recipient.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
            .borrow()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")
          
          receiverRef.deposit(from: <-self.sentVault)
        }
      }
    `;
  }

  private getTestTokenTransferTransaction(): string {
    return `
      import FungibleToken from 0xee82856bf20e2aa6
      import TestToken from 0xf8d6e0586b0a20c7
      transaction(to: Address, amount: UFix64) {
        let sentVault: @FungibleToken.Vault
        prepare(signer: auth(Storage) &Account) {
          let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/testTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
          self.sentVault <- vaultRef.withdraw(amount: amount)
        }
        execute {
          let recipient = getAccount(to)
          let receiverRef = recipient.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
            .borrow()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")
          receiverRef.deposit(from: <-self.sentVault)
        }
      }
    `;
  }

  // Pool and Liquidity Functions

  // Get pool information
  async getPoolInfo(): Promise<{
    tokenA: string;
    tokenB: string;
    reserveA: number;
    reserveB: number;
    totalLiquidity: number;
    swapFee: number;
    spotPrice: number;
  }> {
    try {
      const result = await query({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          access(all) fun main(): {String: AnyStruct} {
            let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
              ?? panic("FlowSwap contract not found")
            return FlowSwap.getPoolInfo()
          }
        `
      });

      return {
        tokenA: result.tokenA || "FLOW",
        tokenB: result.tokenB || "TEST",
        reserveA: parseFloat(result.reserveA || "0"),
        reserveB: parseFloat(result.reserveB || "0"),
        totalLiquidity: parseFloat(result.totalLiquidity || "0"),
        swapFee: parseFloat(result.swapFee || "0"),
        spotPrice: parseFloat(result.spotPrice || "0")
      };
    } catch (error) {
      console.error("Error getting pool info:", error);
      throw error;
    }
  }

  // Get user's LP token balance
  async getLPBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          access(all) fun main(userAddress: Address): UFix64 {
            let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
              ?? panic("FlowSwap contract not found")
            return FlowSwap.getUserLPBalance(user: userAddress)
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(address, t.Address as unknown)
        ]
      });
      return parseFloat(result || "0");
    } catch (error) {
      console.error("Error getting LP balance:", error);
      return 0;
    }
  }

  // Calculate swap output
  async calculateSwapOutput(amountIn: number, tokenIn: string, tokenOut: string): Promise<number> {
    try {
      const result = await query({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          access(all) fun main(amountIn: UFix64, tokenIn: String, tokenOut: String): UFix64 {
            let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
              ?? panic("FlowSwap contract not found")
            return FlowSwap.calculateSwapOutput(amountIn: amountIn, tokenIn: tokenIn, tokenOut: tokenOut)
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(amountIn.toFixed(8), t.UFix64 as unknown),
          arg(tokenIn, t.String as unknown),
          arg(tokenOut, t.String as unknown)
        ]
      });
      return parseFloat(result || "0");
    } catch (error) {
      console.error("Error calculating swap output:", error);
      return 0;
    }
  }

  // Execute swap
  async executeSwap(tokenIn: string, tokenOut: string, amountIn: number, minAmountOut: number, userAddress: string): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, minAmountOut: UFix64, userAddress: Address) {
            execute {
              let result = FlowSwap.executeSwap(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                minAmountOut: minAmountOut,
                user: userAddress
              )
              log("Swap completed. Output: ".concat(result.toString()))
            }
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(tokenIn, t.String as unknown),
          arg(tokenOut, t.String as unknown),
          arg(amountIn.toFixed(8), t.UFix64 as unknown),
          arg(minAmountOut.toFixed(8), t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error executing swap:", error);
      throw error;
    }
  }

  // Add liquidity
  async addLiquidity(amountA: number, amountB: number, userAddress: string): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          transaction(amountA: UFix64, amountB: UFix64, userAddress: Address) {
            execute {
              let result = FlowSwap.addLiquidity(
                amountA: amountA,
                amountB: amountB,
                provider: userAddress
              )
              log("Liquidity added. LP tokens minted: ".concat(result.toString()))
            }
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(amountA.toFixed(8), t.UFix64 as unknown),
          arg(amountB.toFixed(8), t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error adding liquidity:", error);
      throw error;
    }
  }

  // Remove liquidity
  async removeLiquidity(liquidityAmount: number, userAddress: string): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          transaction(liquidityAmount: UFix64, userAddress: Address) {
            execute {
              let result = FlowSwap.removeLiquidity(
                liquidityAmount: liquidityAmount,
                provider: userAddress
              )
              log("Liquidity removed. Returned: ".concat(result.amountA.toString()).concat(" FLOW, ").concat(result.amountB.toString()).concat(" TEST"))
            }
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(liquidityAmount.toFixed(8), t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error removing liquidity:", error);
      throw error;
    }
  }

  // Calculate optimal liquidity amounts
  async calculateOptimalLiquidity(amountA: number): Promise<{
    amountA: number;
    amountB: number;
    liquidity: number;
  }> {
    try {
      const result = await query({
        cadence: `
          import FlowSwap from 0xf8d6e0586b0a20c7
          access(all) fun main(amountA: UFix64): {String: UFix64} {
            let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
              ?? panic("FlowSwap contract not found")
            return FlowSwap.calculateOptimalLiquidity(amountA: amountA)
          }
        `,
        args: (arg: typeof FlowSwapClient.argBuilder, t: typeof FlowSwapClient.cadenceTypes) => [
          arg(amountA.toFixed(8), t.UFix64 as unknown)
        ]
      });

      return {
        amountA: parseFloat(result.amountA || "0"),
        amountB: parseFloat(result.amountB || "0"),
        liquidity: parseFloat(result.liquidity || "0")
      };
    } catch (error) {
      console.error("Error calculating optimal liquidity:", error);
      return { amountA: 0, amountB: 0, liquidity: 0 };
    }
  }
}

// Create and export a singleton instance
export const flowSwapClient = new FlowSwapClient();

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
    symbol: "TEST",
    name: "Test Token",
    icon: "/test-token.svg",
    address: FLOW_CONFIG.TEST_TOKEN,
    balance: 0,
    price: 1, // Test token price
    decimals: 8
  }
]; 