import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7

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
    
    // LP Token Resource
    access(all) resource LPToken: FungibleToken.Vault {
        access(all) var balance: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
        }
        
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            self.balance = self.balance - amount
            return <-create LPToken(balance: amount)
        }
        
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @LPToken
            self.balance = self.balance + vault.balance
            destroy vault
        }
        
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance >= amount
        }
        
        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <-create LPToken(balance: 0.0)
        }
        
        access(all) view fun getViews(): [Type] {
            return []
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
    }
    
    // Storage
    access(self) var totalLiquidity: UFix64
    access(self) var tokenAReserves: UFix64
    access(self) var tokenBReserves: UFix64
    access(self) var tokenASymbol: String
    access(self) var tokenBSymbol: String
    
    // LP Token tracking
    access(self) var userLPBalances: {Address: UFix64}
    
    // Admin
    access(self) var admin: Address
    
    // Fee (0.3% = 0.003)
    access(self) var swapFee: UFix64
    
    init() {
        self.totalLiquidity = 0.0
        self.tokenAReserves = 0.0
        self.tokenBReserves = 0.0
        self.tokenASymbol = "FLOW"
        self.tokenBSymbol = "TEST"
        self.userLPBalances = {}
        self.admin = self.account.address
        self.swapFee = 0.003
        
        // Create and store vaults in account storage
        let flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        let testTokenVault <- TestToken.createEmptyVault()
        
        self.account.storage.save(<-flowVault, to: /storage/flowSwapFlowVault)
        self.account.storage.save(<-testTokenVault, to: /storage/flowSwapTestVault)
        
        // Publish receiver capabilities for liquidity provision
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&FlowToken.Vault>(/storage/flowSwapFlowVault),
            at: /public/flowSwapFlowReceiver
        )
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&TestToken.Vault>(/storage/flowSwapTestVault),
            at: /public/flowSwapTestReceiver
        )
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
    
    // Admin function to add liquidity directly
    access(all) fun adminAddLiquidity(
        amountA: UFix64,
        amountB: UFix64,
        provider: Address
    ) : UFix64 {
        pre {
            self.account.address == self.admin: "Only admin can add liquidity"
            amountA > 0.0: "Amount A must be greater than 0"
            amountB > 0.0: "Amount B must be greater than 0"
        }
        // Transfer FLOW from admin vault to FlowSwap vault
        let adminFlowVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Admin Flow vault not found")
        let flowToTransfer <- adminFlowVault.withdraw(amount: amountA)
        let flowSwapVault = self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowSwapFlowVault)
            ?? panic("FlowSwap Flow vault not found")
        flowSwapVault.deposit(from: <- flowToTransfer)
        
        // Transfer TestToken from admin vault to FlowSwap vault
        let adminTestVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/testTokenVault)
            ?? panic("Admin TestToken vault not found")
        let testToTransfer <- adminTestVault.withdraw(amount: amountB)
        let testSwapVault = self.account.storage.borrow<&TestToken.Vault>(from: /storage/flowSwapTestVault)
            ?? panic("FlowSwap Test vault not found")
        testSwapVault.deposit(from: <- testToTransfer)
        
        // Calculate and add liquidity
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
            let testVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/flowSwapTestVault)
                ?? panic("FlowSwap Test vault not found")
            let tokensToSend <- testVault.withdraw(amount: amountOut)
            let userAccount = getAccount(user)
            let userReceiver = userAccount.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
                .borrow()
                ?? panic("User TestToken vault not found")
            userReceiver.deposit(from: <-tokensToSend)
        } else if tokenIn == self.tokenBSymbol && tokenOut == self.tokenASymbol {
            self.tokenBReserves = self.tokenBReserves + amountIn
            self.tokenAReserves = self.tokenAReserves - amountOut
            // TEST -> FLOW: Kullanıcıya FLOW gönder
            let flowVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowSwapFlowVault)
                ?? panic("FlowSwap Flow vault not found")
            let flowToSend <- flowVault.withdraw(amount: amountOut)
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
        
        // Update user LP balance
        let currentBalance = self.userLPBalances[provider] ?? 0.0
        self.userLPBalances[provider] = currentBalance + liquidityMinted
        
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
        
        let userBalance = self.userLPBalances[provider] ?? 0.0
        if liquidityAmount > userBalance {
            panic("Insufficient LP token balance")
        }
        
        let amountA = (liquidityAmount * self.tokenAReserves) / self.totalLiquidity
        let amountB = (liquidityAmount * self.tokenBReserves) / self.totalLiquidity
        
        self.tokenAReserves = self.tokenAReserves - amountA
        self.tokenBReserves = self.tokenBReserves - amountB
        self.totalLiquidity = self.totalLiquidity - liquidityAmount
        
        // Update user LP balance
        self.userLPBalances[provider] = userBalance - liquidityAmount
        
        // Transfer tokens back to user
        let userAccount = getAccount(provider)
        
        // Transfer FLOW
        let flowVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowSwapFlowVault)
            ?? panic("FlowSwap Flow vault not found")
        let flowToSend <- flowVault.withdraw(amount: amountA)
        let userFlowReceiver = userAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
            .borrow()
            ?? panic("User Flow receiver not found")
        userFlowReceiver.deposit(from: <-flowToSend)
        
        // Transfer TEST
        let testVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/flowSwapTestVault)
            ?? panic("FlowSwap Test vault not found")
        let testToSend <- testVault.withdraw(amount: amountB)
        let userTestReceiver = userAccount.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
            .borrow()
            ?? panic("User Test receiver not found")
        userTestReceiver.deposit(from: <-testToSend)
        
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
    
    // Create LP Token vault for user
    access(all) fun createLPTokenVault(): @LPToken {
        return <-create LPToken(balance: 0.0)
    }
    
    // Get user LP balance
    access(all) fun getUserLPBalance(user: Address): UFix64 {
        return self.userLPBalances[user] ?? 0.0
    }
    
    // Setup user LP vault (called by setup transaction)
    access(all) fun setupUserLPVault(user: Address) {
        // Initialize user LP balance if not exists
        if self.userLPBalances[user] == nil {
            self.userLPBalances[user] = 0.0
        }
    }
    
    // Get pool information
    access(all) fun getPoolInfo(): {String: AnyStruct} {
        return {
            "tokenA": self.tokenASymbol,
            "tokenB": self.tokenBSymbol,
            "reserveA": self.tokenAReserves,
            "reserveB": self.tokenBReserves,
            "totalLiquidity": self.totalLiquidity,
            "swapFee": self.swapFee,
            "spotPrice": self.getSpotPrice(tokenIn: self.tokenASymbol, tokenOut: self.tokenBSymbol)
        }
    }
    
    // Calculate optimal liquidity amounts
    access(all) fun calculateOptimalLiquidity(amountA: UFix64): {String: UFix64} {
        if self.totalLiquidity == 0.0 {
            // First liquidity provision - any ratio is acceptable
            return {
                "amountA": amountA,
                "amountB": amountA, // 1:1 ratio for initial liquidity
                "liquidity": self.sqrt(y: amountA * amountA)
            }
        } else {
            // Calculate required amountB based on current ratio
            let amountB = (amountA * self.tokenBReserves) / self.tokenAReserves
            let liquidity = (amountA * self.totalLiquidity) / self.tokenAReserves
            
            return {
                "amountA": amountA,
                "amountB": amountB,
                "liquidity": liquidity
            }
        }
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