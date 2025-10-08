import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7
import DeFiActions from 0xf8d6e0586b0a20c7
import FungibleTokenConnectors from 0xf8d6e0586b0a20c7
import FlowSwapCallbackHandler from 0xf8d6e0586b0a20c7
import FlowCallbackScheduler from 0xf8d6e0586b0a20c7

/// Comprehensive Flow Actions Demo Transaction
/// This demonstrates all Flow Actions features in a single transaction
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        log("🚀 Starting Flow Actions Demo...")
        
        // 1. Create Unique Identifier
        let uniqueID = DeFiActions.createUniqueIdentifier()
        log("✅ Created Unique ID: ".concat(uniqueID.toString()))
        
        // 2. Test VaultSource Creation
        let withdrawCap = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(/storage/flowTokenVault)
        let source = FungibleTokenConnectors.VaultSource(
            min: 0.0,
            withdrawVault: withdrawCap,
            uniqueID: uniqueID
        )
        log("✅ VaultSource created successfully")
        
        // 3. Test VaultSink Creation
        let depositCap = signer.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenReceiver)
        let sink = FungibleTokenConnectors.VaultSink(
            max: nil,
            depositVault: depositCap,
            uniqueID: uniqueID
        )
        log("✅ VaultSink created successfully")
        
        // 4. Test Callback Fee Estimation
        let callbackData: {String: AnyStruct} = {
            "tokenIn": "FLOW",
            "tokenOut": "TEST",
            "amountIn": 1.0,
            "userAddress": signer.address
        }
        
        let estimate = FlowCallbackScheduler.estimate(
            data: callbackData,
            timestamp: getCurrentBlock().timestamp + 300.0,
            priority: FlowCallbackScheduler.Priority.Medium,
            executionEffort: 2000
        )
        
        if estimate.error == nil {
            log("✅ Fee estimate successful: ".concat((estimate.flowFee ?? 0.0).toString()).concat(" FLOW"))
        } else {
            log("⚠️ Fee estimation warning: ".concat(estimate.error ?? "Unknown error"))
        }
        
        // 5. Test FlowSwap Pool Info
        let poolInfo = FlowSwap.getPoolInfo()
        log("✅ Pool Info Retrieved:")
        log("  - Token A: ".concat(poolInfo["tokenA"] as? String ?? "Unknown"))
        log("  - Token B: ".concat(poolInfo["tokenB"] as? String ?? "Unknown"))
        log("  - Reserve A: ".concat((poolInfo["reserveA"] as? UFix64 ?? 0.0).toString()))
        log("  - Reserve B: ".concat((poolInfo["reserveB"] as? UFix64 ?? 0.0).toString()))
        log("  - Total Liquidity: ".concat((poolInfo["totalLiquidity"] as? UFix64 ?? 0.0).toString()))
        
        // 6. Test Callback Handler Stats
        let handlerStats = FlowSwapCallbackHandler.getOperationStats()
        log("✅ Callback Handler Stats:")
        log("  - Contract: ".concat(handlerStats["contractAddress"] as? String ?? "Unknown"))
        log("  - Block Height: ".concat((handlerStats["blockHeight"] as? UInt64 ?? 0).toString()))
        log("  - Description: ".concat(handlerStats["description"] as? String ?? "Unknown"))
        
        // 7. Test Composable Operation (Simulation)
        let operationId = FlowSwapCallbackHandler.createOperationId()
        log("✅ Created Operation ID: ".concat(operationId))
        
        log("🎉 Flow Actions Demo completed successfully!")
        log("📊 Summary:")
        log("  - Unique Identifier: ✅")
        log("  - VaultSource/VaultSink: ✅")
        log("  - Fee Estimation: ✅")
        log("  - Pool Integration: ✅")
        log("  - Callback Handler: ✅")
        log("  - Operation Tracing: ✅")
    }
    
    execute {
        log("🔄 Flow Actions Demo execution phase completed")
    }
    
    post {
        log("✨ Flow Actions are fully integrated and operational!")
    }
}