import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

/// Multi-token swap contract supporting multiple token pairs
access(all) contract MultiTokenSwap {
    
    /// Events
    access(all) event TokenPairAdded(tokenA: String, tokenB: String, poolId: UInt64)
    access(all) event MultiSwapExecuted(user: Address, swaps: [SwapInfo], totalGasUsed: UFix64)
    access(all) event RouteOptimized(tokenIn: String, tokenOut: String, route: [String], expectedOutput: UFix64)
    
    /// Structs
    access(all) struct SwapInfo {
        access(all) let tokenIn: String
        access(all) let tokenOut: String
        access(all) let amountIn: UFix64
        access(all) let amountOut: UFix64
        access(all) let poolId: UInt64
        
        init(tokenIn: String, tokenOut: String, amountIn: UFix64, amountOut: UFix64, poolId: UInt64) {
            self.tokenIn = tokenIn
            self.tokenOut = tokenOut
            self.amountIn = amountIn
            self.amountOut = amountOut
            self.poolId = poolId
        }
    }
    
    access(all) struct TokenPair {
        access(all) let tokenA: String
        access(all) let tokenB: String
        access(all) let reserveA: UFix64
        access(all) let reserveB: UFix64
        access(all) let fee: UFix64
        access(all) let isActive: Bool
        
        init(tokenA: String, tokenB: String, reserveA: UFix64, reserveB: UFix64, fee: UFix64) {
            self.tokenA = tokenA
            self.tokenB = tokenB
            self.reserveA = reserveA
            self.reserveB = reserveB
            self.fee = fee
            self.isActive = true
        }
    }
    
    /// Storage
    access(self) var pools: {UInt64: TokenPair}
    access(self) var poolCounter: UInt64
    access(self) var supportedTokens: {String: Bool}
    access(self) var admin: Address
    
    /// Add a new token pair
    access(all) fun addTokenPair(tokenA: String, tokenB: String, initialReserveA: UFix64, initialReserveB: UFix64, fee: UFix64): UInt64 {
        pre {
            self.admin == self.account.address: "Only admin can add token pairs"
            !self.pairExists(tokenA: tokenA, tokenB: tokenB): "Token pair already exists"
        }
        
        let poolId = self.poolCounter
        let pair = TokenPair(
            tokenA: tokenA,
            tokenB: tokenB,
            reserveA: initialReserveA,
            reserveB: initialReserveB,
            fee: fee
        )
        
        self.pools[poolId] = pair
        self.poolCounter = self.poolCounter + 1
        self.supportedTokens[tokenA] = true
        self.supportedTokens[tokenB] = true
        
        emit TokenPairAdded(tokenA: tokenA, tokenB: tokenB, poolId: poolId)
        return poolId
    }
    
    /// Execute multiple swaps in a single transaction
    access(all) fun executeMultiSwap(swaps: [SwapInfo], user: Address): [UFix64] {
        let results: [UFix64] = []
        var totalGasUsed: UFix64 = 0.0
        
        for swap in swaps {
            let result = self.executeSingleSwap(
                tokenIn: swap.tokenIn,
                tokenOut: swap.tokenOut,
                amountIn: swap.amountIn,
                poolId: swap.poolId,
                user: user
            )
            results.append(result)
            totalGasUsed = totalGasUsed + 1000.0 // Mock gas calculation
        }
        
        emit MultiSwapExecuted(user: user, swaps: swaps, totalGasUsed: totalGasUsed)
        return results
    }
    
    /// Find optimal route between two tokens
    access(all) fun findOptimalRoute(tokenIn: String, tokenOut: String, amountIn: UFix64): [String] {
        // Simple direct route for now - can be enhanced with pathfinding algorithms
        if self.pairExists(tokenA: tokenIn, tokenB: tokenOut) {
            let route = [tokenIn, tokenOut]
            let expectedOutput = self.calculateSwapOutput(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
            
            emit RouteOptimized(tokenIn: tokenIn, tokenOut: tokenOut, route: route, expectedOutput: expectedOutput)
            return route
        }
        
        // Multi-hop routing through FLOW as intermediate token
        if tokenIn != "FLOW" && tokenOut != "FLOW" {
            if self.pairExists(tokenA: tokenIn, tokenB: "FLOW") && self.pairExists(tokenA: "FLOW", tokenB: tokenOut) {
                let route = [tokenIn, "FLOW", tokenOut]
                let intermediateOutput = self.calculateSwapOutput(tokenIn: tokenIn, tokenOut: "FLOW", amountIn: amountIn)
                let finalOutput = self.calculateSwapOutput(tokenIn: "FLOW", tokenOut: tokenOut, amountIn: intermediateOutput)
                
                emit RouteOptimized(tokenIn: tokenIn, tokenOut: tokenOut, route: route, expectedOutput: finalOutput)
                return route
            }
        }
        
        return []
    }
    
    /// Calculate swap output for a token pair
    access(all) fun calculateSwapOutput(tokenIn: String, tokenOut: String, amountIn: UFix64): UFix64 {
        let poolId = self.findPoolId(tokenA: tokenIn, tokenB: tokenOut)
        if poolId == nil {
            return 0.0
        }
        
        let pool = self.pools[poolId!]!
        let (reserveIn, reserveOut) = tokenIn == pool.tokenA ? (pool.reserveA, pool.reserveB) : (pool.reserveB, pool.reserveA)
        
        // AMM formula with fee
        let amountInWithFee = amountIn * (1.0 - pool.fee)
        let numerator = amountInWithFee * reserveOut
        let denominator = reserveIn + amountInWithFee
        
        return numerator / denominator
    }
    
    /// Execute a single swap
    access(self) fun executeSingleSwap(tokenIn: String, tokenOut: String, amountIn: UFix64, poolId: UInt64, user: Address): UFix64 {
        let pool = self.pools[poolId] ?? panic("Pool not found")
        let amountOut = self.calculateSwapOutput(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        
        // Update pool reserves (simplified)
        if tokenIn == pool.tokenA {
            self.pools[poolId] = TokenPair(
                tokenA: pool.tokenA,
                tokenB: pool.tokenB,
                reserveA: pool.reserveA + amountIn,
                reserveB: pool.reserveB - amountOut,
                fee: pool.fee
            )
        } else {
            self.pools[poolId] = TokenPair(
                tokenA: pool.tokenA,
                tokenB: pool.tokenB,
                reserveA: pool.reserveA - amountOut,
                reserveB: pool.reserveB + amountIn,
                fee: pool.fee
            )
        }
        
        return amountOut
    }
    
    /// Check if a token pair exists
    access(all) fun pairExists(tokenA: String, tokenB: String): Bool {
        return self.findPoolId(tokenA: tokenA, tokenB: tokenB) != nil
    }
    
    /// Find pool ID for a token pair
    access(self) fun findPoolId(tokenA: String, tokenB: String): UInt64? {
        for poolId in self.pools.keys {
            let pool = self.pools[poolId]!
            if (pool.tokenA == tokenA && pool.tokenB == tokenB) || (pool.tokenA == tokenB && pool.tokenB == tokenA) {
                return poolId
            }
        }
        return nil
    }
    
    /// Get all pools
    access(all) fun getAllPools(): {UInt64: TokenPair} {
        return self.pools
    }
    
    /// Get supported tokens
    access(all) fun getSupportedTokens(): [String] {
        return self.supportedTokens.keys
    }
    
    init() {
        self.pools = {}
        self.poolCounter = 0
        self.supportedTokens = {}
        self.admin = self.account.address
        
        // Add initial FLOW/TEST pair
        self.addTokenPair(tokenA: "FLOW", tokenB: "TEST", initialReserveA: 1000.0, initialReserveB: 1500.0, fee: 0.003)
    }
}