import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7

/// Limit order swap transaction - executes only if price conditions are met
transaction(
    tokenIn: String, 
    tokenOut: String, 
    amountIn: UFix64, 
    limitPrice: UFix64, 
    orderType: String, // "BUY" or "SELL"
    expirationTime: UFix64
) {
    
    let currentPrice: UFix64
    let shouldExecute: Bool
    let orderId: String
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get current spot price
        self.currentPrice = FlowSwap.getSpotPrice(tokenIn: tokenIn, tokenOut: tokenOut)
        
        // Generate order ID
        self.orderId = getCurrentBlock().timestamp.toString()
            .concat("_")
            .concat(signer.address.toString())
            .concat("_")
            .concat(getCurrentBlock().height.toString())
        
        // Check if order should execute based on limit price
        if orderType == "BUY" {
            // Buy order: execute if current price <= limit price
            self.shouldExecute = self.currentPrice <= limitPrice
        } else if orderType == "SELL" {
            // Sell order: execute if current price >= limit price
            self.shouldExecute = self.currentPrice >= limitPrice
        } else {
            panic("Invalid order type. Must be 'BUY' or 'SELL'")
        }
        
        // Check expiration
        if getCurrentBlock().timestamp > expirationTime {
            self.shouldExecute = false
            log("Order expired. Current time: ".concat(getCurrentBlock().timestamp.toString()).concat(", Expiration: ").concat(expirationTime.toString()))
        }
        
        log("Limit Order Analysis:")
        log("Order ID: ".concat(self.orderId))
        log("Type: ".concat(orderType))
        log("Current Price: ".concat(self.currentPrice.toString()))
        log("Limit Price: ".concat(limitPrice.toString()))
        log("Should Execute: ".concat(self.shouldExecute.toString()))
    }
    
    execute {
        if !self.shouldExecute {
            log("Limit order conditions not met. Order not executed.")
            return
        }
        
        // Calculate expected output with current price
        let expectedOutput = FlowSwap.calculateSwapOutput(
            amountIn: amountIn,
            tokenIn: tokenIn,
            tokenOut: tokenOut
        )
        
        // Apply minimal slippage for limit orders (0.1%)
        let minAmountOut = expectedOutput * 0.999
        
        // Execute the swap
        let result = FlowSwap.executeSwap(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            minAmountOut: minAmountOut,
            user: self.account.address
        )
        
        // Calculate actual execution price
        let executionPrice = result / amountIn
        
        log("Limit Order Executed Successfully!")
        log("Order ID: ".concat(self.orderId))
        log("Input: ".concat(amountIn.toString()).concat(" ").concat(tokenIn))
        log("Output: ".concat(result.toString()).concat(" ").concat(tokenOut))
        log("Execution Price: ".concat(executionPrice.toString()))
        log("Price Improvement: ".concat(((executionPrice - self.currentPrice) / self.currentPrice * 100.0).toString()).concat("%"))
    }
    
    post {
        // Verify order parameters
        amountIn > 0.0: "Amount in must be positive"
        limitPrice > 0.0: "Limit price must be positive"
        expirationTime > getCurrentBlock().timestamp: "Expiration time must be in the future"
    }
}