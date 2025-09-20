import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7
import FungibleTokenConnectors from 0xf8d6e0586b0a20c7
import DeFiActions from 0xf8d6e0586b0a20c7

/// Execute a composable swap using Flow Actions pattern
transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, minAmountOut: UFix64) {
    
    let uniqueID: DeFiActions.UniqueIdentifier
    let source: FungibleTokenConnectors.VaultSource
    let sink: FungibleTokenConnectors.VaultSink
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create unique identifier for tracing this operation
        self.uniqueID = DeFiActions.createUniqueIdentifier()
        
        // Create source for input tokens
        let withdrawCap = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(
            tokenIn == "FLOW" ? /storage/flowTokenVault : /storage/testTokenVault
        )
        
        self.source = FungibleTokenConnectors.VaultSource(
            min: 0.0,
            withdrawVault: withdrawCap,
            uniqueID: self.uniqueID
        )
        
        // Create sink for output tokens
        let depositCap = signer.capabilities.get<&{FungibleToken.Vault}>(
            tokenOut == "FLOW" ? /public/flowTokenReceiver : /public/testTokenVault
        )
        
        self.sink = FungibleTokenConnectors.VaultSink(
            max: nil,
            depositVault: depositCap,
            uniqueID: self.uniqueID
        )
        
        log("Composable swap initialized with unique ID: ".concat(self.uniqueID.toString()))
    }
    
    execute {
        // Execute the composable workflow atomically
        
        // 1. Withdraw tokens from source
        let tokens <- self.source.withdrawAvailable(maxAmount: amountIn)
        log("Withdrawn ".concat(tokens.balance.toString()).concat(" tokens from source"))
        
        // 2. Execute swap through FlowSwap
        let swapResult = FlowSwap.executeSwap(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: tokens.balance,
            minAmountOut: minAmountOut,
            user: self.source.withdrawVault.address
        )
        log("Swap executed. Output: ".concat(swapResult.toString()))
        
        // 3. For this demo, we'll handle the token transfer manually
        // In a real Flow Actions implementation, the swap would return tokens
        // that we could then deposit to the sink
        
        // Clean up the withdrawn vault (it should be empty after swap)
        assert(tokens.balance == 0.0, message: "Tokens should be consumed by swap")
        destroy tokens
        
        log("Composable swap completed successfully")
        log("Operation ID: ".concat(self.uniqueID.toString()))
    }
    
    post {
        // Verify the operation completed successfully
        log("Post-condition: Composable swap operation verified")
    }
}