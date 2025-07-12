import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TestToken from 0x0c0c904844c9a720

/// FlowSwap - A simple token swap contract for Flow blockchain
/// This is a basic implementation - you may want to add more features like:
/// - Liquidity pools
/// - Price oracles
/// - Fee collection
/// - Slippage protection

access(all) contract FlowSwap {
    
    // Events
    access(all) event SwapExecuted(
        user: Address,
        tokenIn: String,
        tokenOut: String,
        amountIn: UFix64,
        amountOut: UFix64
    )
    
    access(all) event LiquidityAdded(
        provider: Address,
        tokenA: String,
        tokenB: String,
        amountA: UFix64,
        amountB: UFix64
    )
    
    access(all) event LiquidityRemoved(
        provider: Address,
        tokenA: String,
        tokenB: String,
        amountA: UFix64,
        amountB: UFix64
    )
    
    // Structs for return types
    access(all) struct Reserves {
        access(all) let tokenA: UFix64
        access(all) let tokenB: UFix64
        init(tokenA: UFix64, tokenB: UFix64) {
            self.tokenA = tokenA
            self.tokenB = tokenB
        }
    }

    access(all) struct LiquidityAmounts {
        access(all) let amountA: UFix64
        access(all) let amountB: UFix64
        init(amountA: UFix64, amountB: UFix64) {
            self.amountA = amountA
            self.amountB = amountB
        }
    }
    
    // Storage
    access(self) var totalLiquidity: UFix64
    access(self) var tokenAReserves: UFix64
    access(self) var tokenBReserves: UFix64
    access(self) var tokenASymbol: String
    access(self) var tokenBSymbol: String
    
    // Admin
    access(self) var admin: Address
    
    // Fee (0.3% = 0.003)
    access(self) var swapFee: UFix64
    
    access(self) var flowVault: @FlowToken.Vault
    access(self) var testTokenVault: @TestToken.Vault
    
    init() {
        self.totalLiquidity = 0.0
        self.tokenAReserves = 0.0
        self.tokenBReserves = 0.0
        self.tokenASymbol = "FLOW"
        self.tokenBSymbol = "TEST"
        self.admin = self.account.address
        self.swapFee = 0.003
        self.flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        self.testTokenVault <- TestToken.createEmptyVault()
    }
    
    // Admin functions
    access(all) fun setAdmin(newAdmin: Address) {
        pre {
            self.account.address == self.admin: "Only admin can set new admin"
        }
        self.admin = newAdmin
    }
    
    access(all) fun setSwapFee(newFee: UFix64) {
        pre {
            self.account.address == self.admin: "Only admin can set swap fee"
            newFee < 0.1: "Fee cannot be more than 10%"
        }
        self.swapFee = newFee
    }
    
    // Get current spot price
    access(all) fun getSpotPrice(tokenIn: String, tokenOut: String): UFix64 {
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
    access(all) fun calculateSwapOutput(amountIn: UFix64, tokenIn: String, tokenOut: String): UFix64 {
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
    access(all) fun executeSwap(
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
        
        let amountOut = self.calculateSwapOutput(amountIn: amountIn, tokenIn: tokenIn, tokenOut: tokenOut)
        
        if amountOut < minAmountOut {
            panic("Insufficient output amount")
        }
        
        // Update reserves
        if tokenIn == self.tokenASymbol && tokenOut == self.tokenBSymbol {
            self.tokenAReserves = self.tokenAReserves + amountIn
            self.tokenBReserves = self.tokenBReserves - amountOut
            // FLOW -> TEST: Kullanıcıya TEST gönder
            let tokensToSend <- self.testTokenVault.withdraw(amount: amountOut)
            let userAccount = getAccount(user)
            let userReceiver = userAccount.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
                .borrow()
                ?? panic("User TestToken vault not found")
            userReceiver.deposit(from: <-tokensToSend)
        } else if tokenIn == self.tokenBSymbol && tokenOut == self.tokenASymbol {
            self.tokenBReserves = self.tokenBReserves + amountIn
            self.tokenAReserves = self.tokenAReserves - amountOut
            // TEST -> FLOW: Kullanıcıya FLOW gönder
            let flowToSend <- self.flowVault.withdraw(amount: amountOut)
            let userAccount = getAccount(user)
            let userReceiver = userAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
                .borrow()
                ?? panic("User FlowToken vault not found")
            userReceiver.deposit(from: <-flowToSend)
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
    access(all) fun addLiquidity(
        amountA: UFix64,
        amountB: UFix64,
        provider: Address
    ): UFix64 {
        pre {
            amountA > 0.0: "Amount A must be greater than 0"
            amountB > 0.0: "Amount B must be greater than 0"
        }
        
        var liquidityMinted: UFix64 = 0.0
        if self.totalLiquidity == 0.0 {
            liquidityMinted = self.sqrt(y: amountA * amountB)
        } else {
            let liquidityA = (amountA * self.totalLiquidity) / self.tokenAReserves
            let liquidityB = (amountB * self.totalLiquidity) / self.tokenBReserves
            if liquidityA < liquidityB {
                liquidityMinted = liquidityA
            } else {
                liquidityMinted = liquidityB
            }
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
    access(all) fun removeLiquidity(
        liquidityAmount: UFix64,
        provider: Address
    ): LiquidityAmounts {
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
        
        return LiquidityAmounts(amountA: amountA, amountB: amountB)
    }
    
    // Get reserves
    access(all) fun getReserves(): Reserves {
        return Reserves(tokenA: self.tokenAReserves, tokenB: self.tokenBReserves)
    }
    
    // Get total liquidity
    access(all) fun getTotalLiquidity(): UFix64 {
        return self.totalLiquidity
    }
    
    // Helper function for square root
    access(all) fun sqrt(y: UFix64): UFix64 {
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