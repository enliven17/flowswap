import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import MultiTokenSwap from 0xf8d6e0586b0a20c7

/// Batch swap transaction for executing multiple swaps atomically
transaction(swapData: [{String: AnyStruct}], maxSlippage: UFix64) {
    
    let swaps: [MultiTokenSwap.SwapInfo]
    let expectedOutputs: [UFix64]
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.swaps = []
        self.expectedOutputs = []
        
        // Parse swap data and calculate expected outputs
        for data in swapData {
            let tokenIn = data["tokenIn"] as! String
            let tokenOut = data["tokenOut"] as! String
            let amountIn = data["amountIn"] as! UFix64
            let poolId = data["poolId"] as! UInt64
            
            // Calculate expected output
            let expectedOutput = MultiTokenSwap.calculateSwapOutput(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn
            )
            
            self.expectedOutputs.append(expectedOutput)
            
            let swapInfo = MultiTokenSwap.SwapInfo(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: expectedOutput * (1.0 - maxSlippage), // Apply slippage
                poolId: poolId
            )
            
            self.swaps.append(swapInfo)
        }
        
        log("Prepared ".concat(self.swaps.length.toString()).concat(" swaps for batch execution"))
    }
    
    execute {
        // Execute all swaps atomically
        let results = MultiTokenSwap.executeMultiSwap(swaps: self.swaps, user: self.account.address)
        
        // Verify all swaps met minimum output requirements
        var i = 0
        while i < results.length {
            let actualOutput = results[i]
            let expectedOutput = self.expectedOutputs[i]
            let swap = self.swaps[i]
            
            assert(actualOutput >= swap.amountOut, message: "Swap ".concat(i.toString()).concat(" failed slippage check"))
            
            log("Swap ".concat(i.toString()).concat(": ").concat(swap.amountIn.toString()).concat(" ").concat(swap.tokenIn).concat(" -> ").concat(actualOutput.toString()).concat(" ").concat(swap.tokenOut))
            
            i = i + 1
        }
        
        log("Batch swap completed successfully!")
    }
    
    post {
        self.swaps.length > 0: "Must have at least one swap"
        self.swaps.length == self.expectedOutputs.length: "Swaps and outputs length mismatch"
    }
}