import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

/// Staking Rewards contract for earning rewards by staking tokens
access(all) contract StakingRewards {
    
    /// Events
    access(all) event StakingPoolCreated(poolId: UInt64, stakingToken: String, rewardToken: String, rewardRate: UFix64)
    access(all) event Staked(user: Address, poolId: UInt64, amount: UFix64)
    access(all) event Unstaked(user: Address, poolId: UInt64, amount: UFix64)
    access(all) event RewardsClaimed(user: Address, poolId: UInt64, amount: UFix64)
    access(all) event RewardRateUpdated(poolId: UInt64, oldRate: UFix64, newRate: UFix64)
    access(all) event EmergencyWithdraw(user: Address, poolId: UInt64, amount: UFix64)
    
    /// Structs
    access(all) struct StakingPool {
        access(all) let poolId: UInt64
        access(all) let stakingToken: String
        access(all) let rewardToken: String
        access(all) var rewardRate: UFix64 // Rewards per second
        access(all) var totalStaked: UFix64
        access(all) var lastUpdateTime: UFix64
        access(all) var rewardPerTokenStored: UFix64
        access(all) var periodFinish: UFix64
        access(all) var rewardsDuration: UFix64
        access(all) var minimumStakeAmount: UFix64
        access(all) var lockupPeriod: UFix64 // Seconds
        access(all) var isActive: Bool
        access(all) var emergencyMode: Bool
        
        init(
            poolId: UInt64,
            stakingToken: String,
            rewardToken: String,
            rewardRate: UFix64,
            rewardsDuration: UFix64,
            minimumStakeAmount: UFix64,
            lockupPeriod: UFix64
        ) {
            self.poolId = poolId
            self.stakingToken = stakingToken
            self.rewardToken = rewardToken
            self.rewardRate = rewardRate
            self.totalStaked = 0.0
            self.lastUpdateTime = getCurrentBlock().timestamp
            self.rewardPerTokenStored = 0.0
            self.periodFinish = getCurrentBlock().timestamp + rewardsDuration
            self.rewardsDuration = rewardsDuration
            self.minimumStakeAmount = minimumStakeAmount
            self.lockupPeriod = lockupPeriod
            self.isActive = true
            self.emergencyMode = false
        }
        
        access(all) fun updateRewardRate(newRate: UFix64) {
            self.rewardRate = newRate
        }
        
        access(all) fun setActive(active: Bool) {
            self.isActive = active
        }
        
        access(all) fun setEmergencyMode(emergency: Bool) {
            self.emergencyMode = emergency
        }
        
        access(all) fun extendRewardsPeriod(extension: UFix64) {
            self.periodFinish = self.periodFinish + extension
        }
        
        access(all) fun isRewardPeriodActive(): Bool {
            return getCurrentBlock().timestamp < self.periodFinish
        }
    }
    
    access(all) struct UserStake {
        access(all) var amount: UFix64
        access(all) var rewardPerTokenPaid: UFix64
        access(all) var rewards: UFix64
        access(all) var stakeTime: UFix64
        access(all) var lastClaimTime: UFix64
        access(all) var totalRewardsClaimed: UFix64
        
        init() {
            self.amount = 0.0
            self.rewardPerTokenPaid = 0.0
            self.rewards = 0.0
            self.stakeTime = getCurrentBlock().timestamp
            self.lastClaimTime = getCurrentBlock().timestamp
            self.totalRewardsClaimed = 0.0
        }
        
        access(all) fun updateStake(amount: UFix64, rewardPerToken: UFix64) {
            if self.amount == 0.0 {
                self.stakeTime = getCurrentBlock().timestamp
            }
            self.amount = amount
            self.rewardPerTokenPaid = rewardPerToken
        }
        
        access(all) fun addRewards(amount: UFix64) {
            self.rewards = self.rewards + amount
        }
        
        access(all) fun claimRewards(): UFix64 {
            let claimAmount = self.rewards
            self.rewards = 0.0
            self.lastClaimTime = getCurrentBlock().timestamp
            self.totalRewardsClaimed = self.totalRewardsClaimed + claimAmount
            return claimAmount
        }
        
        access(all) fun canUnstake(lockupPeriod: UFix64): Bool {
            return getCurrentBlock().timestamp >= self.stakeTime + lockupPeriod
        }
        
        access(all) fun getStakingDuration(): UFix64 {
            return getCurrentBlock().timestamp - self.stakeTime
        }
    }
    
    /// Storage
    access(self) var stakingPools: {UInt64: StakingPool}
    access(self) var userStakes: {Address: {UInt64: UserStake}}
    access(self) var poolCounter: UInt64
    access(self) var admin: Address
    access(self) var totalRewardsDistributed: UFix64
    access(self) var globalEmergencyMode: Bool
    
    /// Create a new staking pool
    access(all) fun createStakingPool(
        stakingToken: String,
        rewardToken: String,
        rewardRate: UFix64,
        rewardsDuration: UFix64,
        minimumStakeAmount: UFix64,
        lockupPeriod: UFix64
    ): UInt64 {
        pre {
            self.admin == self.account.address: "Only admin can create staking pools"
            rewardRate > 0.0: "Reward rate must be positive"
            rewardsDuration > 0.0: "Rewards duration must be positive"
            minimumStakeAmount >= 0.0: "Minimum stake amount must be non-negative"
        }
        
        let poolId = self.poolCounter
        let pool = StakingPool(
            poolId: poolId,
            stakingToken: stakingToken,
            rewardToken: rewardToken,
            rewardRate: rewardRate,
            rewardsDuration: rewardsDuration,
            minimumStakeAmount: minimumStakeAmount,
            lockupPeriod: lockupPeriod
        )
        
        self.stakingPools[poolId] = pool
        self.poolCounter = self.poolCounter + 1
        
        emit StakingPoolCreated(
            poolId: poolId,
            stakingToken: stakingToken,
            rewardToken: rewardToken,
            rewardRate: rewardRate
        )
        return poolId
    }
    
    /// Stake tokens in a pool
    access(all) fun stake(poolId: UInt64, amount: UFix64, user: Address) {
        pre {
            !self.globalEmergencyMode: "Global emergency mode is active"
            amount > 0.0: "Stake amount must be positive"
            self.stakingPools[poolId] != nil: "Staking pool does not exist"
            self.stakingPools[poolId]!.isActive: "Staking pool is not active"
            !self.stakingPools[poolId]!.emergencyMode: "Pool is in emergency mode"
            amount >= self.stakingPools[poolId]!.minimumStakeAmount: "Amount below minimum stake"
        }
        
        self.updateReward(poolId: poolId, user: user)
        
        // Initialize user stake if needed
        if self.userStakes[user] == nil {
            self.userStakes[user] = {}
        }
        if self.userStakes[user]![poolId] == nil {
            self.userStakes[user]![poolId] = UserStake()
        }
        
        let currentStake = self.userStakes[user]![poolId]!.amount
        self.userStakes[user]![poolId]!.updateStake(
            amount: currentStake + amount,
            rewardPerToken: self.stakingPools[poolId]!.rewardPerTokenStored
        )
        
        // Update pool total
        self.stakingPools[poolId]!.totalStaked = self.stakingPools[poolId]!.totalStaked + amount
        
        emit Staked(user: user, poolId: poolId, amount: amount)
    }
    
    /// Unstake tokens from a pool
    access(all) fun unstake(poolId: UInt64, amount: UFix64, user: Address) {
        pre {
            amount > 0.0: "Unstake amount must be positive"
            self.stakingPools[poolId] != nil: "Staking pool does not exist"
            self.userStakes[user] != nil: "User has no stakes"
            self.userStakes[user]![poolId] != nil: "User not staked in this pool"
            self.userStakes[user]![poolId]!.amount >= amount: "Insufficient staked amount"
        }
        
        let pool = self.stakingPools[poolId]!
        let userStake = self.userStakes[user]![poolId]!
        
        // Check lockup period (unless emergency mode)
        if !pool.emergencyMode && !self.globalEmergencyMode {
            if !userStake.canUnstake(lockupPeriod: pool.lockupPeriod) {
                panic("Tokens are still locked. Lockup period not expired.")
            }
        }
        
        self.updateReward(poolId: poolId, user: user)
        
        // Update user stake
        let currentStake = self.userStakes[user]![poolId]!.amount
        self.userStakes[user]![poolId]!.updateStake(
            amount: currentStake - amount,
            rewardPerToken: self.stakingPools[poolId]!.rewardPerTokenStored
        )
        
        // Update pool total
        self.stakingPools[poolId]!.totalStaked = pool.totalStaked - amount
        
        emit Unstaked(user: user, poolId: poolId, amount: amount)
    }
    
    /// Emergency unstake (forfeits rewards)
    access(all) fun emergencyUnstake(poolId: UInt64, user: Address) {
        pre {
            self.stakingPools[poolId] != nil: "Staking pool does not exist"
            self.userStakes[user] != nil: "User has no stakes"
            self.userStakes[user]![poolId] != nil: "User not staked in this pool"
            self.userStakes[user]![poolId]!.amount > 0.0: "No tokens staked"
        }
        
        let amount = self.userStakes[user]![poolId]!.amount
        
        // Reset user stake (forfeit rewards)
        self.userStakes[user]![poolId] = UserStake()
        
        // Update pool total
        self.stakingPools[poolId]!.totalStaked = self.stakingPools[poolId]!.totalStaked - amount
        
        emit EmergencyWithdraw(user: user, poolId: poolId, amount: amount)
    }
    
    /// Claim staking rewards
    access(all) fun claimRewards(poolId: UInt64, user: Address): UFix64 {
        pre {
            self.stakingPools[poolId] != nil: "Staking pool does not exist"
            self.userStakes[user] != nil: "User has no stakes"
            self.userStakes[user]![poolId] != nil: "User not staked in this pool"
        }
        
        self.updateReward(poolId: poolId, user: user)
        
        let rewardAmount = self.userStakes[user]![poolId]!.claimRewards()
        self.totalRewardsDistributed = self.totalRewardsDistributed + rewardAmount
        
        emit RewardsClaimed(user: user, poolId: poolId, amount: rewardAmount)
        return rewardAmount
    }
    
    /// Update reward calculations
    access(self) fun updateReward(poolId: UInt64, user: Address) {
        let pool = self.stakingPools[poolId]!
        let currentTime = getCurrentBlock().timestamp
        let lastTimeRewardApplicable = currentTime < pool.periodFinish ? currentTime : pool.periodFinish
        
        if pool.totalStaked > 0.0 {
            let timeElapsed = lastTimeRewardApplicable - pool.lastUpdateTime
            let rewardPerToken = pool.rewardPerTokenStored + (timeElapsed * pool.rewardRate / pool.totalStaked)
            
            self.stakingPools[poolId]!.rewardPerTokenStored = rewardPerToken
            self.stakingPools[poolId]!.lastUpdateTime = lastTimeRewardApplicable
            
            // Update user rewards
            if self.userStakes[user] != nil && self.userStakes[user]![poolId] != nil {
                let userStake = self.userStakes[user]![poolId]!
                let earnedRewards = userStake.amount * (rewardPerToken - userStake.rewardPerTokenPaid)
                self.userStakes[user]![poolId]!.addRewards(amount: earnedRewards)
                self.userStakes[user]![poolId]!.rewardPerTokenPaid = rewardPerToken
            }
        } else {
            self.stakingPools[poolId]!.lastUpdateTime = lastTimeRewardApplicable
        }
    }
    
    /// Get pending rewards for a user
    access(all) fun getPendingRewards(poolId: UInt64, user: Address): UFix64 {
        if self.stakingPools[poolId] == nil || self.userStakes[user] == nil || self.userStakes[user]![poolId] == nil {
            return 0.0
        }
        
        let pool = self.stakingPools[poolId]!
        let userStake = self.userStakes[user]![poolId]!
        let currentTime = getCurrentBlock().timestamp
        let lastTimeRewardApplicable = currentTime < pool.periodFinish ? currentTime : pool.periodFinish
        
        var rewardPerToken = pool.rewardPerTokenStored
        if pool.totalStaked > 0.0 {
            let timeElapsed = lastTimeRewardApplicable - pool.lastUpdateTime
            rewardPerToken = rewardPerToken + (timeElapsed * pool.rewardRate / pool.totalStaked)
        }
        
        let earnedRewards = userStake.amount * (rewardPerToken - userStake.rewardPerTokenPaid)
        return userStake.rewards + earnedRewards
    }
    
    /// Get staking pool APR (Annual Percentage Rate)
    access(all) fun getPoolAPR(poolId: UInt64): UFix64 {
        if self.stakingPools[poolId] == nil {
            return 0.0
        }
        
        let pool = self.stakingPools[poolId]!
        if pool.totalStaked == 0.0 {
            return 0.0
        }
        
        // Calculate APR: (rewardRate * seconds_per_year) / totalStaked * 100
        let secondsPerYear: UFix64 = 365.0 * 24.0 * 3600.0
        let annualRewards = pool.rewardRate * secondsPerYear
        return (annualRewards / pool.totalStaked) * 100.0
    }
    
    /// Admin functions
    access(all) fun updateRewardRate(poolId: UInt64, newRate: UFix64) {
        pre {
            self.admin == self.account.address: "Only admin can update reward rate"
            self.stakingPools[poolId] != nil: "Staking pool does not exist"
            newRate > 0.0: "Reward rate must be positive"
        }
        
        self.updateReward(poolId: poolId, user: self.admin) // Update with dummy user
        
        let oldRate = self.stakingPools[poolId]!.rewardRate
        self.stakingPools[poolId]!.updateRewardRate(newRate: newRate)
        
        emit RewardRateUpdated(poolId: poolId, oldRate: oldRate, newRate: newRate)
    }
    
    access(all) fun setGlobalEmergencyMode(emergency: Bool) {
        pre {
            self.admin == self.account.address: "Only admin can set emergency mode"
        }
        self.globalEmergencyMode = emergency
    }
    
    access(all) fun setPoolEmergencyMode(poolId: UInt64, emergency: Bool) {
        pre {
            self.admin == self.account.address: "Only admin can set pool emergency mode"
            self.stakingPools[poolId] != nil: "Staking pool does not exist"
        }
        self.stakingPools[poolId]!.setEmergencyMode(emergency: emergency)
    }
    
    /// View functions
    access(all) fun getStakingPool(poolId: UInt64): StakingPool? {
        return self.stakingPools[poolId]
    }
    
    access(all) fun getUserStake(poolId: UInt64, user: Address): UserStake? {
        if self.userStakes[user] == nil {
            return nil
        }
        return self.userStakes[user]![poolId]
    }
    
    access(all) fun getAllStakingPools(): {UInt64: StakingPool} {
        return self.stakingPools
    }
    
    access(all) fun getTotalValueStaked(): UFix64 {
        var total: UFix64 = 0.0
        for poolId in self.stakingPools.keys {
            total = total + self.stakingPools[poolId]!.totalStaked
        }
        return total
    }
    
    init() {
        self.stakingPools = {}
        self.userStakes = {}
        self.poolCounter = 0
        self.admin = self.account.address
        self.totalRewardsDistributed = 0.0
        self.globalEmergencyMode = false
        
        // Create initial FLOW staking pool
        self.createStakingPool(
            stakingToken: "FLOW",
            rewardToken: "FLOW",
            rewardRate: 0.01, // 0.01 FLOW per second
            rewardsDuration: 2592000.0, // 30 days
            minimumStakeAmount: 1.0,
            lockupPeriod: 86400.0 // 1 day lockup
        )
    }
}