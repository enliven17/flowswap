import FlowCallbackScheduler from 0xf8d6e0586b0a20c7
import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import FlowSwap from 0xf8d6e0586b0a20c7

/// Schedule a recurring swap using Flow Callbacks
transaction(
    tokenIn: String,
    tokenOut: String, 
    amountIn: UFix64,
    intervalSeconds: UFix64,
    maxRecurrences: UInt64
) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let future = getCurrentBlock().timestamp + intervalSeconds
        let priority = FlowCallbackScheduler.Priority.Medium
        let executionEffort: UInt64 = 2000
        
        // Create callback data with recurring information
        let callbackData: {String: AnyStruct} = {
            "tokenIn": tokenIn,
            "tokenOut": tokenOut,
            "amountIn": amountIn,
            "userAddress": signer.address,
            "isRecurring": true,
            "intervalSeconds": intervalSeconds,
            "maxRecurrences": maxRecurrences,
            "currentRecurrence": UInt64(1)
        }
        
        // Estimate fees for the callback
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
        
        // Calculate total fees needed for all recurrences
        let totalFees = (estimate.flowFee ?? 0.0) * UFix64(maxRecurrences)
        
        // Withdraw fees
        let vaultRef = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("missing FlowToken vault")
        
        // Check if user has enough FLOW for fees
        if vaultRef.balance < totalFees {
            panic("Insufficient FLOW balance for recurring swap fees. Need: ".concat(totalFees.toString()).concat(", Have: ").concat(vaultRef.balance.toString()))
        }
        
        let fees <- vaultRef.withdraw(amount: estimate.flowFee ?? 0.0) as! @FlowToken.Vault
        
        // Create handler capability
        let handlerCap = signer.capabilities.storage
            .issue<auth(FlowCallbackScheduler.Execute) &{FlowCallbackScheduler.CallbackHandler}>(/storage/FlowSwapCallbackHandler)
        
        // Verify handler capability
        if !handlerCap.check() {
            panic("FlowSwap callback handler not properly set up. Run setup_flow_actions.cdc first.")
        }
        
        // Schedule the first callback
        let receipt = FlowCallbackScheduler.schedule(
            callback: handlerCap,
            data: callbackData,
            timestamp: future,
            priority: priority,
            executionEffort: executionEffort,
            fees: <-fees
        )
        
        log("Scheduled recurring swap:")
        log("- Callback ID: ".concat(receipt.id.toString()))
        log("- Token pair: ".concat(tokenIn).concat(" -> ").concat(tokenOut))
        log("- Amount: ".concat(amountIn.toString()))
        log("- Interval: ".concat(intervalSeconds.toString()).concat(" seconds"))
        log("- Max recurrences: ".concat(maxRecurrences.toString()))
        log("- Next execution: ".concat(receipt.timestamp.toString()))
    }
    
    execute {
        log("Recurring swap scheduled successfully")
    }
}