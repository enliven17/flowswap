import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

/// Yield Farming contract for earning rewards by providing liquidity
access(all) contract YieldFarming {
    
    /// Events
    access(all) event FarmCreated(farmId: UInt64, lpToken: String, rewardToken: String, rewardRate: UFix64)
    access(all) event Staked(user: Address, farmId: UInt64, amount: UFix64)
    access(all) event Unstaked(user: Address, farmId: UInt64, amount: UFix64)
    access(all) event RewardsClaimed(user: Address, farmId: UInt64, amount: UFix64)
    access(all) event RewardRateUpdated(farmId: UInt64, oldRate: UFix64, newRate: UFix64)
    
    /// Structs
    access(all) struct Farm {
        access(all) let farmId: UInt64
        access(all) let lpToken: String
        access(all) let rewardToken: String
        access(all) var rewardRate: UFix64 // Rewards per second
        access(all) var totalStaked: UFix64
        access(all) var lastUpdateTime: UFix64
        access(all) var rewardPerTokenStored: UFix64
        access(all) var isActive: Bool
        
        init(farmId: UInt64, lpToken: String, rewardToken: String, rewardRate: UFix64) {
            self.farmId = farmId
            self.lpToken = lpToken
            self.rewardToken = rewardToken
            self.rewardRate = rewardRate
            self.totalStaked = 0.0
            self.lastUpdateTime = getCurrentBlock().timestamp
            self.rewardPerTokenStored = 0.0
            self.isActive = true
        }
        
        access(all) fun updateRewardRate(newRate: UFix64) {
            self.rewardRate = newRate
        }
        
        access(all) fun setActive(active: Bool) {
            self.isActive = active
        }
    }
    
    access(all) struct UserStake {
        access(all) var amount: UFix64
        access(all) var rewardPerTokenPaid: UFix64
        access(all) var rewards: UFix64
        access(all) var lastStakeTime: UFix64
        
        init() {
            self.amount = 0.0
            self.rewardPerTokenPaid = 0.0
            self.rewards = 0.0
            self.lastStakeTime = getCurrentBlock().timestamp
        }
        
        access(all) fun updateStake(amount: UFix64, rewardPerToken: UFix64) {
            self.amount = amount
            self.rewardPerTokenPaid = rewardPerToken
            self.lastStakeTime = getCurrentBlock().timestamp
        }
        
        access(all) fun addRewards(amount: UFix64) {
            self.rewards = self.rewards + amount
        }
        
        access(all) fun claimRewards(): UFix64 {
            let claimAmount = self.rewards
            self.rewards = 0.0
            return claimAmount
        }
    }
    
    /// Storage
    access(self) var farms: {UInt64: Farm}
    access(self) var userStakes: {Address: {UInt64: UserStake}}
    access(self) var farmCounter: UInt64
    access(self) var admin: Address
    access(self) var totalRewardsDistributed: UFix64
    
    /// Create a new farm
    access(all) fun createFarm(lpToken: String, rewardToken: String, rewardRate: UFix64): UInt64 {
        pre {
            self.admin == self.account.address: "Only admin can create farms"
            rewardRate > 0.0: "Reward rate must be positive"
        }
        
        let farmId = self.farmCounter
        let farm = Farm(
            farmId: farmId,
            lpToken: lpToken,
            rewardToken: rewardToken,
            rewardRate: rewardRate
        )
        
        self.farms[farmId] = farm
        self.farmCounter = self.farmCounter + 1
        
        emit FarmCreated(farmId: farmId, lpToken: lpToken, rewardToken: rewardToken, rewardRate: rewardRate)
        return farmId
    }
    
    /// Stake LP tokens in a farm
    access(all) fun stake(farmId: UInt64, amount: UFix64, user: Address) {
        pre {
            amount > 0.0: "Stake amount must be positive"
            self.farms[farmId] != nil: "Farm does not exist"
            self.farms[farmId]!.isActive: "Farm is not active"
        }
        
        self.updateReward(farmId: farmId, user: user)
        
        // Update user stake
        if self.userStakes[user] == nil {
            self.userStakes[user] = {}
        }
        if self.userStakes[user]![farmId] == nil {
            self.userStakes[user]![farmId] = UserStake()
        }
        
        let currentStake = self.userStakes[user]![farmId]!.amount
        self.userStakes[user]![farmId]!.updateStake(
            amount: currentStake + amount,
            rewardPerToken: self.farms[farmId]!.rewardPerTokenStored
        )
        
        // Update farm total
        self.farms[farmId]!.totalStaked = self.farms[farmId]!.totalStaked + amount
        
        emit Staked(user: user, farmId: farmId, amount: amount)
    }
    
    /// Unstake LP tokens from a farm
    access(all) fun unstake(farmId: UInt64, amount: UFix64, user: Address) {
        pre {
            amount > 0.0: "Unstake amount must be positive"
            self.farms[farmId] != nil: "Farm does not exist"
            self.userStakes[user] != nil: "User has no stakes"
            self.userStakes[user]![farmId] != nil: "User not staked in this farm"
            self.userStakes[user]![farmId]!.amount >= amount: "Insufficient staked amount"
        }
        
        self.updateReward(farmId: farmId, user: user)
        
        // Update user stake
        let currentStake = self.userStakes[user]![farmId]!.amount
        self.userStakes[user]![farmId]!.updateStake(
            amount: currentStake - amount,
            rewardPerToken: self.farms[farmId]!.rewardPerTokenStored
        )
        
        // Update farm total
        self.farms[farmId]!.totalStaked = self.farms[farmId]!.totalStaked - amount
        
        emit Unstaked(user: user, farmId: farmId, amount: amount)
    }
    
    /// Claim rewards from a farm
    access(all) fun claimRewards(farmId: UInt64, user: Address): UFix64 {
        pre {
            self.farms[farmId] != nil: "Farm does not exist"
            self.userStakes[user] != nil: "User has no stakes"
            self.userStakes[user]![farmId] != nil: "User not staked in this farm"
        }
        
        self.updateReward(farmId: farmId, user: user)
        
        let rewardAmount = self.userStakes[user]![farmId]!.claimRewards()
        self.totalRewardsDistributed = self.totalRewardsDistributed + rewardAmount
        
        emit RewardsClaimed(user: user, farmId: farmId, amount: rewardAmount)
        return rewardAmount
    }
    
    /// Update reward calculations
    access(self) fun updateReward(farmId: UInt64, user: Address) {
        let farm = self.farms[farmId]!
        let currentTime = getCurrentBlock().timestamp
        
        if farm.totalStaked > 0.0 {
            let timeElapsed = currentTime - farm.lastUpdateTime
            let rewardPerToken = farm.rewardPerTokenStored + (timeElapsed * farm.rewardRate / farm.totalStaked)
            
            self.farms[farmId]!.rewardPerTokenStored = rewardPerToken
            self.farms[farmId]!.lastUpdateTime = currentTime
            
            // Update user rewards
            if self.userStakes[user] != nil && self.userStakes[user]![farmId] != nil {
                let userStake = self.userStakes[user]![farmId]!
                let earnedRewards = userStake.amount * (rewardPerToken - userStake.rewardPerTokenPaid)
                self.userStakes[user]![farmId]!.addRewards(amount: earnedRewards)
                self.userStakes[user]![farmId]!.rewardPerTokenPaid = rewardPerToken
            }
        } else {
            self.farms[farmId]!.lastUpdateTime = currentTime
        }
    }
    
    /// Get user's pending rewards
    access(all) fun getPendingRewards(farmId: UInt64, user: Address): UFix64 {
        if self.farms[farmId] == nil || self.userStakes[user] == nil || self.userStakes[user]![farmId] == nil {
            return 0.0
        }
        
        let farm = self.farms[farmId]!
        let userStake = self.userStakes[user]![farmId]!
        
        var rewardPerToken = farm.rewardPerTokenStored
        if farm.totalStaked > 0.0 {
            let timeElapsed = getCurrentBlock().timestamp - farm.lastUpdateTime
            rewardPerToken = rewardPerToken + (timeElapsed * farm.rewardRate / farm.totalStaked)
        }
        
        let earnedRewards = userStake.amount * (rewardPerToken - userStake.rewardPerTokenPaid)
        return userStake.rewards + earnedRewards
    }
    
    /// Get farm info
    access(all) fun getFarm(farmId: UInt64): Farm? {
        return self.farms[farmId]
    }
    
    /// Get user stake info
    access(all) fun getUserStake(farmId: UInt64, user: Address): UserStake? {
        if self.userStakes[user] == nil {
            return nil
        }
        return self.userStakes[user]![farmId]
    }
    
    /// Get all farms
    access(all) fun getAllFarms(): {UInt64: Farm} {
        return self.farms
    }
    
    /// Update reward rate (admin only)
    access(all) fun updateRewardRate(farmId: UInt64, newRate: UFix64) {
        pre {
            self.admin == self.account.address: "Only admin can update reward rate"
            self.farms[farmId] != nil: "Farm does not exist"
            newRate > 0.0: "Reward rate must be positive"
        }
        
        let oldRate = self.farms[farmId]!.rewardRate
        self.farms[farmId]!.updateRewardRate(newRate: newRate)
        
        emit RewardRateUpdated(farmId: farmId, oldRate: oldRate, newRate: newRate)
    }
    
    init() {
        self.farms = {}
        self.userStakes = {}
        self.farmCounter = 0
        self.admin = self.account.address
        self.totalRewardsDistributed = 0.0
        
        // Create initial FLOW/TEST LP farm
        self.createFarm(lpToken: "FLOW_TEST_LP", rewardToken: "FLOW", rewardRate: 0.1) // 0.1 FLOW per second
    }
}