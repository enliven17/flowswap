import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import USDC from 0x64adf39cbc354fcb

/// FlowSwap - A simple token swap contract for Flow blockchain
/// This is a basic implementation - you may want to add more features like:
/// - Liquidity pools
/// - Price oracles
/// - Fee collection
/// - Slippage protection

pub contract FlowSwap {
    
    // Events
    pub event SwapExecuted(
        user: Address,
        tokenIn: String,
        tokenOut: String,
        amountIn: UFix64,
        amountOut: UFix64
    )
    
    pub event LiquidityAdded(
        provider: Address,
        tokenA: String,
        tokenB: String,
        amountA: UFix64,
        amountB: UFix64
    )
    
    pub event LiquidityRemoved(
        provider: Address,
        tokenA: String,
        tokenB: String,
        amountA: UFix64,
        amountB: UFix64
    )
    
    // Storage
    pub var totalLiquidity: UFix64
    pub var tokenAReserves: UFix64
    pub var tokenBReserves: UFix64
    pub var tokenASymbol: String
    pub var tokenBSymbol: String
    
    // Admin
    pub var admin: Address
    
    // Fee (0.3% = 0.003)
    pub var swapFee: UFix64
    
    init() {
        self.totalLiquidity = 0.0
        self.tokenAReserves = 0.0
        self.tokenBReserves = 0.0
        self.tokenASymbol = "FLOW"
        self.tokenBSymbol = "USDC"
        self.admin = self.account.address
        self.swapFee = 0.003
    }
    
    // Admin functions
    pub fun setAdmin(newAdmin: Address) {
        pre {
            self.account.address == self.admin: "Only admin can set new admin"
        }
        self.admin = newAdmin
    }
    
    pub fun setSwapFee(newFee: UFix64) {
        pre {
            self.account.address == self.admin: "Only admin can set swap fee"
            newFee < 0.1: "Fee cannot be more than 10%"
        }
        self.swapFee = newFee
    }
    
    // Get current spot price
    pub fun getSpotPrice(tokenIn: String, tokenOut: String): UFix64 {
        if tokenIn == self.tokenASymbol && tokenOut == self.tokenBSymbol {
            if self.tokenAReserves == 0.0 {
                return 0.0
            }
            return self.tokenBReserves / self.tokenAReserves
        } else if tokenIn == self.tokenBSymbol && tokenOut == self.tokenASymbol {
            if self.tokenBReserves == 0.0 {
                return 0.0
            }
            return self.tokenAReserves / self.tokenBReserves
        }
        return 0.0
    }
    
    // Calculate swap output amount
    pub fun calculateSwapOutput(amountIn: UFix64, tokenIn: String, tokenOut: String): UFix64 {
        if tokenIn == self.tokenASymbol && tokenOut == self.tokenBSymbol {
            let amountInWithFee = amountIn * (1.0 - self.swapFee)
            let numerator = amountInWithFee * self.tokenBReserves
            let denominator = self.tokenAReserves + amountInWithFee
            return numerator / denominator
        } else if tokenIn == self.tokenBSymbol && tokenOut == self.tokenASymbol {
            let amountInWithFee = amountIn * (1.0 - self.swapFee)
            let numerator = amountInWithFee * self.tokenAReserves
            let denominator = self.tokenBReserves + amountInWithFee
            return numerator / denominator
        }
        return 0.0
    }
    
    // Execute swap
    pub fun executeSwap(
        tokenIn: String,
        tokenOut: String,
        amountIn: UFix64,
        minAmountOut: UFix64,
        user: Address
    ): UFix64 {
        pre {
            amountIn > 0.0: "Amount must be greater than 0"
            minAmountOut > 0.0: "Minimum output must be greater than 0"
        }
        
        let amountOut = self.calculateSwapOutput(amountIn, tokenIn, tokenOut)
        
        pre {
            amountOut >= minAmountOut: "Insufficient output amount"
        }
        
        // Update reserves
        if tokenIn == self.tokenASymbol && tokenOut == self.tokenBSymbol {
            self.tokenAReserves = self.tokenAReserves + amountIn
            self.tokenBReserves = self.tokenBReserves - amountOut
        } else if tokenIn == self.tokenBSymbol && tokenOut == self.tokenASymbol {
            self.tokenBReserves = self.tokenBReserves + amountIn
            self.tokenAReserves = self.tokenAReserves - amountOut
        }
        
        emit SwapExecuted(
            user: user,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            amountOut: amountOut
        )
        
        return amountOut
    }
    
    // Add liquidity (simplified - assumes equal value)
    pub fun addLiquidity(
        amountA: UFix64,
        amountB: UFix64,
        provider: Address
    ): UFix64 {
        pre {
            amountA > 0.0: "Amount A must be greater than 0"
            amountB > 0.0: "Amount B must be greater than 0"
        }
        
        let liquidityMinted: UFix64
        
        if self.totalLiquidity == 0.0 {
            // First liquidity provider
            liquidityMinted = sqrt(amountA * amountB)
        } else {
            // Calculate based on existing reserves
            let liquidityA = (amountA * self.totalLiquidity) / self.tokenAReserves
            let liquidityB = (amountB * self.totalLiquidity) / self.tokenBReserves
            liquidityMinted = min(liquidityA, liquidityB)
        }
        
        self.tokenAReserves = self.tokenAReserves + amountA
        self.tokenBReserves = self.tokenBReserves + amountB
        self.totalLiquidity = self.totalLiquidity + liquidityMinted
        
        emit LiquidityAdded(
            provider: provider,
            tokenA: self.tokenASymbol,
            tokenB: self.tokenBSymbol,
            amountA: amountA,
            amountB: amountB
        )
        
        return liquidityMinted
    }
    
    // Remove liquidity
    pub fun removeLiquidity(
        liquidityAmount: UFix64,
        provider: Address
    ): {amountA: UFix64, amountB: UFix64} {
        pre {
            liquidityAmount > 0.0: "Liquidity amount must be greater than 0"
            liquidityAmount <= self.totalLiquidity: "Insufficient liquidity"
        }
        
        let amountA = (liquidityAmount * self.tokenAReserves) / self.totalLiquidity
        let amountB = (liquidityAmount * self.tokenBReserves) / self.totalLiquidity
        
        self.tokenAReserves = self.tokenAReserves - amountA
        self.tokenBReserves = self.tokenBReserves - amountB
        self.totalLiquidity = self.totalLiquidity - liquidityAmount
        
        emit LiquidityRemoved(
            provider: provider,
            tokenA: self.tokenASymbol,
            tokenB: self.tokenBSymbol,
            amountA: amountA,
            amountB: amountB
        )
        
        return {amountA: amountA, amountB: amountB}
    }
    
    // Get reserves
    pub fun getReserves(): {tokenA: UFix64, tokenB: UFix64} {
        return {tokenA: self.tokenAReserves, tokenB: self.tokenBReserves}
    }
    
    // Get total liquidity
    pub fun getTotalLiquidity(): UFix64 {
        return self.totalLiquidity
    }
    
    // Helper function for square root
    pub fun sqrt(y: UFix64): UFix64 {
        var z: UFix64 = 0.0
        if y > 3.0 {
            z = y
            var x: UFix64 = y / 2.0 + 1.0
            while x < z {
                z = x
                x = (y / x + x) / 2.0
            }
        } else if y != 0.0 {
            z = 1.0
        }
        return z
    }
} 