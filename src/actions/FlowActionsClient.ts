import { query, mutate } from "@onflow/fcl";

// Flow Actions Client for composable DeFi operations
export class FlowActionsClient {
  private static readonly cadenceTypes: { Address?: unknown; UFix64?: unknown; String?: unknown; UInt64?: unknown } = {};
  private static argBuilder(value: unknown, cadenceType: unknown): unknown {
    return { value, cadenceType } as unknown;
  }

  // Create a unique identifier for tracing operations
  async createUniqueIdentifier(): Promise<string> {
    try {
      const result = await query({
        cadence: `
          import DeFiActions from 0xf8d6e0586b0a20c7
          access(all) fun main(): String {
            let id = DeFiActions.createUniqueIdentifier()
            return id.toString()
          }
        `
      });
      return result;
    } catch (error) {
      console.error("Error creating unique identifier:", error);
      throw error;
    }
  }

  // Create a VaultSource for providing tokens
  async createVaultSource(tokenType: string, minAmount: number, userAddress: string): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FungibleToken from 0xee82856bf20e2aa6
          import FlowToken from 0x0ae53cb6e3f42a79
          import TestToken from 0xf8d6e0586b0a20c7
          import FungibleTokenConnectors from 0xf8d6e0586b0a20c7
          import DeFiActions from 0xf8d6e0586b0a20c7

          transaction(tokenType: String, minAmount: UFix64, userAddress: Address) {
            prepare(signer: auth(Storage, Capabilities) &Account) {
              let uniqueID = DeFiActions.createUniqueIdentifier()
              
              let withdrawCap = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(
                tokenType == "FLOW" ? /storage/flowTokenVault : /storage/testTokenVault
              )
              
              let source = FungibleTokenConnectors.VaultSource(
                min: minAmount,
                withdrawVault: withdrawCap,
                uniqueID: uniqueID
              )
              
              log("VaultSource created with ID: ".concat(uniqueID.toString()))
            }
          }
        `,
        args: (arg: typeof FlowActionsClient.argBuilder, t: typeof FlowActionsClient.cadenceTypes) => [
          arg(tokenType, t.String as unknown),
          arg(minAmount.toFixed(8), t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error creating vault source:", error);
      throw error;
    }
  }

  // Create a VaultSink for receiving tokens
  async createVaultSink(tokenType: string, maxAmount: number | null, userAddress: string): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FungibleToken from 0xee82856bf20e2aa6
          import FlowToken from 0x0ae53cb6e3f42a79
          import TestToken from 0xf8d6e0586b0a20c7
          import FungibleTokenConnectors from 0xf8d6e0586b0a20c7
          import DeFiActions from 0xf8d6e0586b0a20c7

          transaction(tokenType: String, maxAmount: UFix64?, userAddress: Address) {
            prepare(signer: auth(Storage, Capabilities) &Account) {
              let uniqueID = DeFiActions.createUniqueIdentifier()
              
              let depositCap = signer.capabilities.get<&{FungibleToken.Vault}>(
                tokenType == "FLOW" ? /public/flowTokenReceiver : /public/testTokenVault
              )
              
              let sink = FungibleTokenConnectors.VaultSink(
                max: maxAmount,
                depositVault: depositCap,
                uniqueID: uniqueID
              )
              
              log("VaultSink created with ID: ".concat(uniqueID.toString()))
            }
          }
        `,
        args: (arg: typeof FlowActionsClient.argBuilder, t: typeof FlowActionsClient.cadenceTypes) => [
          arg(tokenType, t.String as unknown),
          arg(maxAmount ? maxAmount.toFixed(8) : null, t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error creating vault sink:", error);
      throw error;
    }
  }

  // Execute a composable swap using Flow Actions
  async executeComposableSwap(
    tokenIn: string,
    tokenOut: string,
    amountIn: number,
    minAmountOut: number,
    userAddress: string
  ): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FungibleToken from 0xee82856bf20e2aa6
          import FlowToken from 0x0ae53cb6e3f42a79
          import TestToken from 0xf8d6e0586b0a20c7
          import FlowSwap from 0xf8d6e0586b0a20c7
          import FungibleTokenConnectors from 0xf8d6e0586b0a20c7
          import DeFiActions from 0xf8d6e0586b0a20c7

          transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, minAmountOut: UFix64, userAddress: Address) {
            prepare(signer: auth(Storage, Capabilities) &Account) {
              // Create unique identifier for tracing
              let uniqueID = DeFiActions.createUniqueIdentifier()
              
              // Create source for input tokens
              let withdrawCap = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(
                tokenIn == "FLOW" ? /storage/flowTokenVault : /storage/testTokenVault
              )
              
              let source = FungibleTokenConnectors.VaultSource(
                min: 0.0,
                withdrawVault: withdrawCap,
                uniqueID: uniqueID
              )
              
              // Create sink for output tokens
              let depositCap = signer.capabilities.get<&{FungibleToken.Vault}>(
                tokenOut == "FLOW" ? /public/flowTokenReceiver : /public/testTokenVault
              )
              
              let sink = FungibleTokenConnectors.VaultSink(
                max: nil,
                depositVault: depositCap,
                uniqueID: uniqueID
              )
              
              // Execute the composable workflow
              // 1. Withdraw from source
              let tokens <- source.withdrawAvailable(maxAmount: amountIn)
              
              // 2. Execute swap through FlowSwap
              let swapResult = FlowSwap.executeSwap(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: tokens.balance,
                minAmountOut: minAmountOut,
                user: userAddress
              )
              
              // 3. Deposit to sink
              sink.depositCapacity(from: &tokens as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
              
              // 4. Clean up any residual
              if tokens.balance > 0.0 {
                let residualReceiver = signer.capabilities.get<&{FungibleToken.Vault}>(
                  tokenIn == "FLOW" ? /public/flowTokenReceiver : /public/testTokenVault
                ).borrow() ?? panic("Could not borrow residual receiver")
                residualReceiver.deposit(from: <-tokens)
              } else {
                destroy tokens
              }
              
              log("Composable swap completed with unique ID: ".concat(uniqueID.toString()))
              log("Swap result: ".concat(swapResult.toString()))
            }
          }
        `,
        args: (arg: typeof FlowActionsClient.argBuilder, t: typeof FlowActionsClient.cadenceTypes) => [
          arg(tokenIn, t.String as unknown),
          arg(tokenOut, t.String as unknown),
          arg(amountIn.toFixed(8), t.UFix64 as unknown),
          arg(minAmountOut.toFixed(8), t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error executing composable swap:", error);
      throw error;
    }
  }

  // Schedule a recurring swap using callbacks
  async scheduleRecurringSwap(
    tokenIn: string,
    tokenOut: string,
    amountIn: number,
    intervalSeconds: number,
    userAddress: string
  ): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FlowCallbackScheduler from 0xf8d6e0586b0a20c7
          import FlowToken from 0x0ae53cb6e3f42a79
          import FungibleToken from 0xee82856bf20e2aa6

          transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, intervalSeconds: UFix64, userAddress: Address) {
            prepare(signer: auth(Storage, Capabilities) &Account) {
              let future = getCurrentBlock().timestamp + intervalSeconds
              let priority = FlowCallbackScheduler.Priority.Medium
              let executionEffort: UInt64 = 2000
              
              // Create callback data
              let callbackData = {
                "tokenIn": tokenIn,
                "tokenOut": tokenOut,
                "amountIn": amountIn,
                "userAddress": userAddress
              }
              
              // Estimate fees
              let estimate = FlowCallbackScheduler.estimate(
                data: callbackData,
                timestamp: future,
                priority: priority,
                executionEffort: executionEffort
              )
              
              assert(
                estimate.timestamp != nil || priority == FlowCallbackScheduler.Priority.Low,
                message: estimate.error ?? "estimation failed"
              )
              
              // Withdraw fees
              let vaultRef = signer.storage
                .borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
                ?? panic("missing FlowToken vault")
              let fees <- vaultRef.withdraw(amount: estimate.flowFee ?? 0.0) as! @FlowToken.Vault
              
              // Create handler capability (assuming handler is set up)
              let handlerCap = signer.capabilities.storage
                .issue<auth(FlowCallbackScheduler.Execute) &{FlowCallbackScheduler.CallbackHandler}>(/storage/FlowSwapCallbackHandler)
              
              // Schedule the callback
              let receipt = FlowCallbackScheduler.schedule(
                callback: handlerCap,
                data: callbackData,
                timestamp: future,
                priority: priority,
                executionEffort: executionEffort,
                fees: <-fees
              )
              
              log("Scheduled recurring swap with ID: ".concat(receipt.id.toString()))
            }
          }
        `,
        args: (arg: typeof FlowActionsClient.argBuilder, t: typeof FlowActionsClient.cadenceTypes) => [
          arg(tokenIn, t.String as unknown),
          arg(tokenOut, t.String as unknown),
          arg(amountIn.toFixed(8), t.UFix64 as unknown),
          arg(intervalSeconds.toFixed(1), t.UFix64 as unknown),
          arg(userAddress, t.Address as unknown)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error scheduling recurring swap:", error);
      throw error;
    }
  }
}

export const flowActionsClient = new FlowActionsClient();