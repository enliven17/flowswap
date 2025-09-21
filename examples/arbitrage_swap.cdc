import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7
import MultiTokenSwap from 0xf8d6e0586b0a20c7

/// Arbitrage swap transaction - exploits price differences between pools
transaction(
    tokenA: String,
    tokenB: String,
    amountIn: UFix64,
    minProfitThreshold: UFix64
) {
    
    let pricePool1: UFix64
    let pricePool2: UFix64
    let arbitrageOpportunity: Bool
    let expectedProfit: UFix64
    let arbitrageRoute: [String]
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get prices from different pools/sources
        self.pricePool1 = FlowSwap.getSpotPrice(tokenIn: tokenA, tokenOut: tokenB)
        
        // Simulate getting price from another pool (MultiTokenSwap)
        self.pricePool2 = MultiTokenSwap.calculateSwapOutput(
            tokenIn: tokenA,
            tokenOut: tokenB,
            amountIn: 1.0 // Use 1.0 to get price ratio
        )
        
        // Calculate price difference and potential profit
        let priceDifference = self.pricePool1 > self.pricePool2 ? 
            self.pricePool1 - self.pricePool2 : 
            self.pricePool2 - self.pricePool1
        
        let profitPercentage = priceDifference / (self.pricePool1 < self.pricePool2 ? self.pricePool1 : self.pricePool2)
        
        // Calculate expected profit
        self.expectedProfit = amountIn * profitPercentage
        
        // Determine if arbitrage is profitable
        self.arbitrageOpportunity = self.expectedProfit > minProfitThreshold && profitPercentage > 0.01 // At least 1% profit
        
        // Determine arbitrage route
        if self.pricePool1 > self.pricePool2 {
            // Buy from pool2 (cheaper), sell to pool1 (expensive)
            self.arbitrageRoute = ["MultiTokenSwap", "FlowSwap"]
        } else {
            // Buy from pool1 (cheaper), sell to pool2 (expensive)
            self.arbitrageRoute = ["FlowSwap", "MultiTokenSwap"]
        }
        
        log("Arbitrage Analysis:")
        log("Token Pair: ".concat(tokenA).concat("/").concat(tokenB))
        log("Price Pool 1 (FlowSwap): ".concat(self.pricePool1.toString()))
        log("Price Pool 2 (MultiTokenSwap): ".concat(self.pricePool2.toString()))
        log("Price Difference: ".concat(priceDifference.toString()))
        log("Profit Percentage: ".concat((profitPercentage * 100.0).toString()).concat("%"))
        log("Expected Profit: ".concat(self.expectedProfit.toString()))
        log("Arbitrage Opportunity: ".concat(self.arbitrageOpportunity.toString()))
        log("Route: ".concat(self.arbitrageRoute[0]).concat(" -> ").concat(self.arbitrageRoute[1]))
    }
    
    execute {
        if !self.arbitrageOpportunity {
            log("No profitable arbitrage opportunity found. Transaction aborted.")
            return
        }
        
        var currentAmount = amountIn
        var currentToken = tokenA
        var targetToken = tokenB
        
        // Execute first leg of arbitrage
        if self.arbitrageRoute[0] == "FlowSwap" {
            // Buy from FlowSwap
            let output1 = FlowSwap.calculateSwapOutput(
                amountIn: currentAmount,
                tokenIn: currentToken,
                tokenOut: targetToken
            )
            
            let result1 = FlowSwap.executeSwap(
                tokenIn: currentToken,
                tokenOut: targetToken,
                amountIn: currentAmount,
                minAmountOut: output1 * 0.99, // 1% slippage
                user: self.account.address
            )
            
            currentAmount = result1
            currentToken = targetToken
            targetToken = tokenA
            
            log("First leg (FlowSwap): ".concat(amountIn.toString()).concat(" ").concat(tokenA).concat(" -> ").concat(result1.toString()).concat(" ").concat(tokenB))
        } else {
            // Buy from MultiTokenSwap
            let output1 = MultiTokenSwap.calculateSwapOutput(
                tokenIn: currentToken,
                tokenOut: targetToken,
                amountIn: currentAmount
            )
            
            // Simulate MultiTokenSwap execution
            currentAmount = output1
            currentToken = targetToken
            targetToken = tokenA
            
            log("First leg (MultiTokenSwap): ".concat(amountIn.toString()).concat(" ").concat(tokenA).concat(" -> ").concat(output1.toString()).concat(" ").concat(tokenB))
        }
        
        // Execute second leg of arbitrage
        if self.arbitrageRoute[1] == "FlowSwap" {
            // Sell to FlowSwap
            let output2 = FlowSwap.calculateSwapOutput(
                amountIn: currentAmount,
                tokenIn: currentToken,
                tokenOut: targetToken
            )
            
            let result2 = FlowSwap.executeSwap(
                tokenIn: currentToken,
                tokenOut: targetToken,
                amountIn: currentAmount,
                minAmountOut: output2 * 0.99, // 1% slippage
                user: self.account.address
            )
            
            log("Second leg (FlowSwap): ".concat(currentAmount.toString()).concat(" ").concat(currentToken).concat(" -> ").concat(result2.toString()).concat(" ").concat(targetToken))
            
            // Calculate actual profit
            let actualProfit = result2 > amountIn ? result2 - amountIn : 0.0
            let profitPercentage = actualProfit / amountIn * 100.0
            
            log("Arbitrage Completed!")
            log("Initial Amount: ".concat(amountIn.toString()).concat(" ").concat(tokenA))
            log("Final Amount: ".concat(result2.toString()).concat(" ").concat(tokenA))
            log("Actual Profit: ".concat(actualProfit.toString()).concat(" ").concat(tokenA))
            log("Profit Percentage: ".concat(profitPercentage.toString()).concat("%"))
            
        } else {
            // Sell to MultiTokenSwap
            let output2 = MultiTokenSwap.calculateSwapOutput(
                tokenIn: currentToken,
                tokenOut: targetToken,
                amountIn: currentAmount
            )
            
            log("Second leg (MultiTokenSwap): ".concat(currentAmount.toString()).concat(" ").concat(currentToken).concat(" -> ").concat(output2.toString()).concat(" ").concat(targetToken))
            
            // Calculate actual profit
            let actualProfit = output2 > amountIn ? output2 - amountIn : 0.0
            let profitPercentage = actualProfit / amountIn * 100.0
            
            log("Arbitrage Completed!")
            log("Initial Amount: ".concat(amountIn.toString()).concat(" ").concat(tokenA))
            log("Final Amount: ".concat(output2.toString()).concat(" ").concat(tokenA))
            log("Actual Profit: ".concat(actualProfit.toString()).concat(" ").concat(tokenA))
            log("Profit Percentage: ".concat(profitPercentage.toString()).concat("%"))
        }
    }
    
    post {
        // Verify arbitrage parameters
        amountIn > 0.0: "Amount in must be positive"
        minProfitThreshold >= 0.0: "Minimum profit threshold must be non-negative"
    }
}