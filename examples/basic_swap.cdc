import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7

/// Basic swap transaction with slippage protection
transaction(tokenIn: String, tokenOut: String, amountIn: UFix64, slippageTolerance: UFix64) {
    
    let expectedOutput: UFix64
    let minAmountOut: UFix64
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Calculate expected output
        self.expectedOutput = FlowSwap.calculateSwapOutput(
            amountIn: amountIn,
            tokenIn: tokenIn,
            tokenOut: tokenOut
        )
        
        // Apply slippage tolerance (e.g., 0.05 = 5%)
        self.minAmountOut = self.expectedOutput * (1.0 - slippageTolerance)
        
        log("Expected output: ".concat(self.expectedOutput.toString()))
        log("Minimum output with slippage: ".concat(self.minAmountOut.toString()))
    }
    
    execute {
        let result = FlowSwap.executeSwap(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            minAmountOut: self.minAmountOut,
            user: self.account.address
        )
        
        log("Swap executed successfully!")
        log("Input: ".concat(amountIn.toString()).concat(" ").concat(tokenIn))
        log("Output: ".concat(result.toString()).concat(" ").concat(tokenOut))
        log("Price impact: ".concat(((self.expectedOutput - result) / self.expectedOutput * 100.0).toString()).concat("%"))
    }
    
    post {
        // Verify swap was successful
        self.expectedOutput > 0.0: "Expected output must be positive"
        self.minAmountOut > 0.0: "Minimum output must be positive"
    }
}