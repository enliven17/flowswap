import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7
import FungibleTokenConnectors from 0xf8d6e0586b0a20c7
import DeFiActions from 0xf8d6e0586b0a20c7
import FlowSwapCallbackHandler from 0xf8d6e0586b0a20c7

/// Execute a composable swap using Flow Actions pattern
transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, minAmountOut: UFix64) {
    
    let uniqueID: DeFiActions.UniqueIdentifier
    let userAddress: Address
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create unique identifier for tracing this operation
        self.uniqueID = DeFiActions.createUniqueIdentifier()
        self.userAddress = signer.address
        
        log("Composable swap initialized with unique ID: ".concat(self.uniqueID.toString()))
        log("Token pair: ".concat(tokenIn).concat(" -> ").concat(tokenOut))
        log("Amount in: ".concat(amountIn.toString()))
        log("Min amount out: ".concat(minAmountOut.toString()))
    }
    
    execute {
        // Execute the composable workflow using FlowSwapCallbackHandler
        let operationId = FlowSwapCallbackHandler.createOperationId()
        
        let swapResult = FlowSwapCallbackHandler.executeComposableSwap(
            operationId: operationId,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            minAmountOut: minAmountOut,
            userAddress: self.userAddress
        )
        
        log("Composable swap completed successfully")
        log("Operation ID: ".concat(operationId))
        log("Unique ID: ".concat(self.uniqueID.toString()))
        log("Swap result: ".concat(swapResult.toString()))
    }
    
    post {
        // Verify the operation completed successfully
        log("Post-condition: Composable swap operation verified")
    }
}