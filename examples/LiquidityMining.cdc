import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

/// Liquidity Mining contract for incentivizing liquidity provision
access(all) contract LiquidityMining {
    
    /// Events
    access(all) event MiningPoolCreated(poolId: UInt64, tokenA: String, tokenB: String, miningRate: UFix64)
    access(all) event LiquidityDeposited(user: Address, poolId: UInt64, amountA: UFix64, amountB: UFix64, lpTokens: UFix64)
    access(all) event LiquidityWithdrawn(user: Address, poolId: UInt64, amountA: UFix64, amountB: UFix64, lpTokens: UFix64)
    access(all) event MiningRewardsClaimed(user: Address, poolId: UInt64, amount: UFix64)
    access(all) event BoostActivated(user: Address, poolId: UInt64, multiplier: UFix64, duration: UFix64)
    
    /// Structs
    access(all) struct MiningPool {
        access(all) let poolId: UInt64
        access(all) let tokenA: String
        access(all) let tokenB: String
        access(all) var reserveA: UFix64
        access(all) var reserveB: UFix64
        access(all) var totalLPTokens: UFix64
        access(all) var miningRate: UFix64 // Rewards per second per LP token
        access(all) var lastUpdateTime: UFix64
        access(all) var accRewardPerShare: UFix64
        access(all) var totalRewardsDistributed: UFix64
        access(all) var isActive: Bool
        
        init(poolId: UInt64, tokenA: String, tokenB: String, miningRate: UFix64) {
            self.poolId = poolId
            self.tokenA = tokenA
            self.tokenB = tokenB
            self.reserveA = 0.0
            self.reserveB = 0.0
            self.totalLPTokens = 0.0
            self.miningRate = miningRate
            self.lastUpdateTime = getCurrentBlock().timestamp
            self.accRewardPerShare = 0.0
            self.totalRewardsDistributed = 0.0
            self.isActive = true
        }
        
        access(all) fun updateRewards() {
            let currentTime = getCurrentBlock().timestamp
            if self.totalLPTokens > 0.0 {
                let timeElapsed = currentTime - self.lastUpdateTime
                let rewards = timeElapsed * self.miningRate
                self.accRewardPerShare = self.accRewardPerShare + (rewards / self.totalLPTokens)
            }
            self.lastUpdateTime = currentTime
        }
    }
    
    access(all) struct UserPosition {
        access(all) var lpTokens: UFix64
        access(all) var rewardDebt: UFix64
        access(all) var pendingRewards: UFix64
        access(all) var lastDepositTime: UFix64
        access(all) var boostMultiplier: UFix64
        access(all) var boostEndTime: UFix64
        
        init() {
            self.lpTokens = 0.0
            self.rewardDebt = 0.0
            self.pendingRewards = 0.0
            self.lastDepositTime = getCurrentBlock().timestamp
            self.boostMultiplier = 1.0
            self.boostEndTime = 0.0
        }
        
        access(all) fun updatePosition(lpTokens: UFix64, accRewardPerShare: UFix64) {
            self.lpTokens = lpTokens
            self.rewardDebt = lpTokens * accRewardPerShare
            self.lastDepositTime = getCurrentBlock().timestamp
        }
        
        access(all) fun addPendingRewards(amount: UFix64) {
            self.pendingRewards = self.pendingRewards + amount
        }
        
        access(all) fun claimRewards(): UFix64 {
            let claimAmount = self.pendingRewards
            self.pendingRewards = 0.0
            return claimAmount
        }
        
        access(all) fun activateBoost(multiplier: UFix64, duration: UFix64) {
            self.boostMultiplier = multiplier
            self.boostEndTime = getCurrentBlock().timestamp + duration
        }
        
        access(all) fun getCurrentMultiplier(): UFix64 {
            if getCurrentBlock().timestamp > self.boostEndTime {
                return 1.0
            }
            return self.boostMultiplier
        }
    }
    
    /// Storage
    access(self) var miningPools: {UInt64: MiningPool}
    access(self) var userPositions: {Address: {UInt64: UserPosition}}
    access(self) var poolCounter: UInt64
    access(self) var admin: Address
    access(self) var totalValueLocked: UFix64
    
    /// Create a new mining pool
    access(all) fun createMiningPool(tokenA: String, tokenB: String, miningRate: UFix64): UInt64 {
        pre {
            self.admin == self.account.address: "Only admin can create mining pools"
            miningRate > 0.0: "Mining rate must be positive"
        }
        
        let poolId = self.poolCounter
        let pool = MiningPool(
            poolId: poolId,
            tokenA: tokenA,
            tokenB: tokenB,
            miningRate: miningRate
        )
        
        self.miningPools[poolId] = pool
        self.poolCounter = self.poolCounter + 1
        
        emit MiningPoolCreated(poolId: poolId, tokenA: tokenA, tokenB: tokenB, miningRate: miningRate)
        return poolId
    }
    
    /// Deposit liquidity to earn mining rewards
    access(all) fun depositLiquidity(poolId: UInt64, amountA: UFix64, amountB: UFix64, user: Address): UFix64 {
        pre {
            self.miningPools[poolId] != nil: "Mining pool does not exist"
            self.miningPools[poolId]!.isActive: "Mining pool is not active"
            amountA > 0.0 && amountB > 0.0: "Amounts must be positive"
        }
        
        self.updatePoolRewards(poolId: poolId)
        
        // Calculate LP tokens to mint (simplified)
        let pool = self.miningPools[poolId]!
        var lpTokens: UFix64
        
        if pool.totalLPTokens == 0.0 {
            // First deposit
            lpTokens = self.sqrt(amountA * amountB)
        } else {
            // Subsequent deposits
            let lpFromA = (amountA * pool.totalLPTokens) / pool.reserveA
            let lpFromB = (amountB * pool.totalLPTokens) / pool.reserveB
            lpTokens = lpFromA < lpFromB ? lpFromA : lpFromB
        }
        
        // Update user position
        if self.userPositions[user] == nil {
            self.userPositions[user] = {}
        }
        if self.userPositions[user]![poolId] == nil {
            self.userPositions[user]![poolId] = UserPosition()
        }
        
        let currentPosition = self.userPositions[user]![poolId]!
        let pendingRewards = currentPosition.lpTokens * pool.accRewardPerShare - currentPosition.rewardDebt
        currentPosition.addPendingRewards(amount: pendingRewards * currentPosition.getCurrentMultiplier())
        
        currentPosition.updatePosition(
            lpTokens: currentPosition.lpTokens + lpTokens,
            accRewardPerShare: pool.accRewardPerShare
        )
        
        // Update pool
        self.miningPools[poolId]!.reserveA = pool.reserveA + amountA
        self.miningPools[poolId]!.reserveB = pool.reserveB + amountB
        self.miningPools[poolId]!.totalLPTokens = pool.totalLPTokens + lpTokens
        
        self.totalValueLocked = self.totalValueLocked + amountA + amountB
        
        emit LiquidityDeposited(user: user, poolId: poolId, amountA: amountA, amountB: amountB, lpTokens: lpTokens)
        return lpTokens
    }
    
    /// Withdraw liquidity from mining pool
    access(all) fun withdrawLiquidity(poolId: UInt64, lpTokens: UFix64, user: Address): {String: UFix64} {
        pre {
            self.miningPools[poolId] != nil: "Mining pool does not exist"
            self.userPositions[user] != nil: "User has no positions"
            self.userPositions[user]![poolId] != nil: "User not in this pool"
            self.userPositions[user]![poolId]!.lpTokens >= lpTokens: "Insufficient LP tokens"
        }
        
        self.updatePoolRewards(poolId: poolId)
        
        let pool = self.miningPools[poolId]!
        let currentPosition = self.userPositions[user]![poolId]!
        
        // Calculate pending rewards
        let pendingRewards = currentPosition.lpTokens * pool.accRewardPerShare - currentPosition.rewardDebt
        currentPosition.addPendingRewards(amount: pendingRewards * currentPosition.getCurrentMultiplier())
        
        // Calculate withdrawal amounts
        let amountA = (lpTokens * pool.reserveA) / pool.totalLPTokens
        let amountB = (lpTokens * pool.reserveB) / pool.totalLPTokens
        
        // Update user position
        currentPosition.updatePosition(
            lpTokens: currentPosition.lpTokens - lpTokens,
            accRewardPerShare: pool.accRewardPerShare
        )
        
        // Update pool
        self.miningPools[poolId]!.reserveA = pool.reserveA - amountA
        self.miningPools[poolId]!.reserveB = pool.reserveB - amountB
        self.miningPools[poolId]!.totalLPTokens = pool.totalLPTokens - lpTokens
        
        self.totalValueLocked = self.totalValueLocked - amountA - amountB
        
        emit LiquidityWithdrawn(user: user, poolId: poolId, amountA: amountA, amountB: amountB, lpTokens: lpTokens)
        
        return {
            "amountA": amountA,
            "amountB": amountB
        }
    }
    
    /// Claim mining rewards
    access(all) fun claimMiningRewards(poolId: UInt64, user: Address): UFix64 {
        pre {
            self.miningPools[poolId] != nil: "Mining pool does not exist"
            self.userPositions[user] != nil: "User has no positions"
            self.userPositions[user]![poolId] != nil: "User not in this pool"
        }
        
        self.updatePoolRewards(poolId: poolId)
        
        let pool = self.miningPools[poolId]!
        let currentPosition = self.userPositions[user]![poolId]!
        
        // Calculate and add pending rewards
        let pendingRewards = currentPosition.lpTokens * pool.accRewardPerShare - currentPosition.rewardDebt
        currentPosition.addPendingRewards(amount: pendingRewards * currentPosition.getCurrentMultiplier())
        
        // Update reward debt
        currentPosition.rewardDebt = currentPosition.lpTokens * pool.accRewardPerShare
        
        // Claim rewards
        let rewardAmount = currentPosition.claimRewards()
        self.miningPools[poolId]!.totalRewardsDistributed = pool.totalRewardsDistributed + rewardAmount
        
        emit MiningRewardsClaimed(user: user, poolId: poolId, amount: rewardAmount)
        return rewardAmount
    }
    
    /// Activate boost for enhanced rewards
    access(all) fun activateBoost(poolId: UInt64, user: Address, multiplier: UFix64, duration: UFix64) {
        pre {
            self.userPositions[user] != nil: "User has no positions"
            self.userPositions[user]![poolId] != nil: "User not in this pool"
            multiplier >= 1.0 && multiplier <= 3.0: "Multiplier must be between 1.0 and 3.0"
            duration > 0.0: "Duration must be positive"
        }
        
        self.userPositions[user]![poolId]!.activateBoost(multiplier: multiplier, duration: duration)
        
        emit BoostActivated(user: user, poolId: poolId, multiplier: multiplier, duration: duration)
    }
    
    /// Update pool rewards
    access(self) fun updatePoolRewards(poolId: UInt64) {
        self.miningPools[poolId]!.updateRewards()
    }
    
    /// Get pending rewards for a user
    access(all) fun getPendingRewards(poolId: UInt64, user: Address): UFix64 {
        if self.miningPools[poolId] == nil || self.userPositions[user] == nil || self.userPositions[user]![poolId] == nil {
            return 0.0
        }
        
        let pool = self.miningPools[poolId]!
        let position = self.userPositions[user]![poolId]!
        
        var accRewardPerShare = pool.accRewardPerShare
        if pool.totalLPTokens > 0.0 {
            let timeElapsed = getCurrentBlock().timestamp - pool.lastUpdateTime
            let rewards = timeElapsed * pool.miningRate
            accRewardPerShare = accRewardPerShare + (rewards / pool.totalLPTokens)
        }
        
        let pendingRewards = position.lpTokens * accRewardPerShare - position.rewardDebt
        return position.pendingRewards + (pendingRewards * position.getCurrentMultiplier())
    }
    
    /// Helper function for square root
    access(self) fun sqrt(y: UFix64): UFix64 {
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
    
    /// Get mining pool info
    access(all) fun getMiningPool(poolId: UInt64): MiningPool? {
        return self.miningPools[poolId]
    }
    
    /// Get user position
    access(all) fun getUserPosition(poolId: UInt64, user: Address): UserPosition? {
        if self.userPositions[user] == nil {
            return nil
        }
        return self.userPositions[user]![poolId]
    }
    
    init() {
        self.miningPools = {}
        self.userPositions = {}
        self.poolCounter = 0
        self.admin = self.account.address
        self.totalValueLocked = 0.0
        
        // Create initial FLOW/TEST mining pool
        self.createMiningPool(tokenA: "FLOW", tokenB: "TEST", miningRate: 0.05) // 0.05 rewards per second per LP token
    }
}