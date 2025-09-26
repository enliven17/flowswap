import FungibleToken from 0xee82856bf20e2aa6

/// TestXRP - A test token representing XRP for FlowSwap demo purposes
/// This token mimics XRP characteristics with additional DeFi features
access(all) contract TestXRP: FungibleToken {
    
    /// Total supply of TestXRP tokens
    access(all) var totalSupply: UFix64
    
    /// Storage and Public Paths
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let ReceiverPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    access(all) let MinterStoragePath: StoragePath
    
    /// Events
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)
    access(all) event TokensMinted(amount: UFix64, to: Address?)
    access(all) event TokensBurned(amount: UFix64, from: Address?)
    access(all) event MinterCreated(allowedAmount: UFix64)
    access(all) event BurnCapabilityCreated()
    
    /// XRP-specific events
    access(all) event XRPBridgeDeposit(amount: UFix64, xrpAddress: String, flowAddress: Address)
    access(all) event XRPBridgeWithdraw(amount: UFix64, flowAddress: Address, xrpAddress: String)
    access(all) event EscrowCreated(escrowId: UInt64, amount: UFix64, sender: Address, receiver: Address)
    access(all) event EscrowReleased(escrowId: UInt64, amount: UFix64, receiver: Address)
    
    /// XRP-like features
    access(self) var bridgeEnabled: Bool
    access(self) var escrows: {UInt64: EscrowInfo}
    access(self) var escrowCounter: UInt64
    access(self) var minimumReserve: UFix64 // XRP-like reserve requirement
    
    /// Structs
    access(all) struct EscrowInfo {
        access(all) let escrowId: UInt64
        access(all) let amount: UFix64
        access(all) let sender: Address
        access(all) let receiver: Address
        access(all) let createdAt: UFix64
        access(all) let releaseTime: UFix64
        access(all) var isReleased: Bool
        
        init(escrowId: UInt64, amount: UFix64, sender: Address, receiver: Address, lockDuration: UFix64) {
            self.escrowId = escrowId
            self.amount = amount
            self.sender = sender
            self.receiver = receiver
            self.createdAt = getCurrentBlock().timestamp
            self.releaseTime = self.createdAt + lockDuration
            self.isReleased = false
        }
        
        access(all) fun release() {
            self.isReleased = true
        }
        
        access(all) fun canRelease(): Bool {
            return getCurrentBlock().timestamp >= self.releaseTime && !self.isReleased
        }
    }
    
    /// Vault Resource
    access(all) resource Vault: FungibleToken.Vault {
        /// The total balance of this vault
        access(all) var balance: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
        }
        
        /// Withdraw tokens from the vault
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            pre {
                self.balance >= amount: "Insufficient balance to withdraw"
                self.balance - amount >= TestXRP.minimumReserve: "Cannot withdraw below minimum reserve"
            }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }
        
        /// Deposit tokens into the vault
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @TestXRP.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            destroy vault
        }
        
        /// Get the balance of the vault
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        /// Check if amount is available to withdraw
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance >= amount && (self.balance - amount) >= TestXRP.minimumReserve
        }
        
        /// Create an empty vault
        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <-create Vault(balance: 0.0)
        }
        
        access(all) view fun getViews(): [Type] {
            return []
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
    }
    
    /// Minter Resource - allows minting new tokens
    access(all) resource Minter {
        access(all) var allowedAmount: UFix64
        
        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
        
        /// Mint new TestXRP tokens
        access(all) fun mintTokens(amount: UFix64): @TestXRP.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount exceeds allowed minting amount"
            }
            
            TestXRP.totalSupply = TestXRP.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            
            emit TokensMinted(amount: amount, to: nil)
            return <-create Vault(balance: amount)
        }
        
        /// Mint tokens directly to a recipient
        access(all) fun mintTo(recipient: Address, amount: UFix64): @TestXRP.Vault {
            let mintedVault <- self.mintTokens(amount: amount)
            emit TokensMinted(amount: amount, to: recipient)
            return <-mintedVault
        }
    }
    
    /// Burner Resource - allows burning tokens
    access(all) resource Burner {
        /// Burn tokens by destroying a vault
        access(all) fun burnTokens(from: @TestXRP.Vault) {
            let amount = from.balance
            destroy from
            TestXRP.totalSupply = TestXRP.totalSupply - amount
            emit TokensBurned(amount: amount, from: nil)
        }
    }
    
    /// Administrator Resource
    access(all) resource Administrator {
        /// Create a new minter with specified allowed amount
        access(all) fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }
        
        /// Create a new burner
        access(all) fun createNewBurner(): @Burner {
            emit BurnCapabilityCreated()
            return <-create Burner()
        }
        
        /// Update minimum reserve requirement
        access(all) fun updateMinimumReserve(newReserve: UFix64) {
            TestXRP.minimumReserve = newReserve
        }
        
        /// Enable/disable bridge functionality
        access(all) fun setBridgeEnabled(enabled: Bool) {
            TestXRP.bridgeEnabled = enabled
        }
        
        /// Emergency mint (only for admin)
        access(all) fun emergencyMint(amount: UFix64): @TestXRP.Vault {
            TestXRP.totalSupply = TestXRP.totalSupply + amount
            emit TokensMinted(amount: amount, to: TestXRP.account.address)
            return <-create Vault(balance: amount)
        }
    }
    
    /// Create an empty TestXRP Vault
    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <-create Vault(balance: 0.0)
    }
    
    /// Create an empty TestXRP Vault (convenience function)
    access(all) fun createEmptyVault(): @TestXRP.Vault {
        return <-create Vault(balance: 0.0)
    }
    
    /// XRP-like Bridge Functions
    
    /// Simulate bridging XRP to TestXRP
    access(all) fun bridgeFromXRP(amount: UFix64, xrpAddress: String, flowAddress: Address): @TestXRP.Vault {
        pre {
            self.bridgeEnabled: "Bridge is not enabled"
            amount > 0.0: "Amount must be greater than zero"
            xrpAddress.length > 0: "XRP address cannot be empty"
        }
        
        // In a real implementation, this would verify XRP deposit on XRP Ledger
        // For demo purposes, we'll mint equivalent TestXRP
        self.totalSupply = self.totalSupply + amount
        
        emit XRPBridgeDeposit(amount: amount, xrpAddress: xrpAddress, flowAddress: flowAddress)
        emit TokensMinted(amount: amount, to: flowAddress)
        
        return <-create Vault(balance: amount)
    }
    
    /// Simulate bridging TestXRP back to XRP
    access(all) fun bridgeToXRP(from: @TestXRP.Vault, xrpAddress: String) {
        pre {
            self.bridgeEnabled: "Bridge is not enabled"
            from.balance > 0.0: "Cannot bridge zero amount"
            xrpAddress.length > 0: "XRP address cannot be empty"
        }
        
        let amount = from.balance
        let flowAddress = from.owner?.address
        
        // Burn the TestXRP tokens
        self.totalSupply = self.totalSupply - amount
        destroy from
        
        emit XRPBridgeWithdraw(amount: amount, flowAddress: flowAddress!, xrpAddress: xrpAddress)
        emit TokensBurned(amount: amount, from: flowAddress)
        
        // In a real implementation, this would trigger XRP release on XRP Ledger
    }
    
    /// XRP-like Escrow Functions
    
    /// Create an escrow (time-locked payment)
    access(all) fun createEscrow(
        from: @TestXRP.Vault,
        receiver: Address,
        lockDuration: UFix64
    ): UInt64 {
        pre {
            from.balance > 0.0: "Cannot escrow zero amount"
            lockDuration > 0.0: "Lock duration must be positive"
        }
        
        let amount = from.balance
        let sender = from.owner?.address ?? panic("Cannot determine sender")
        let escrowId = self.escrowCounter
        
        let escrowInfo = EscrowInfo(
            escrowId: escrowId,
            amount: amount,
            sender: sender,
            receiver: receiver,
            lockDuration: lockDuration
        )
        
        self.escrows[escrowId] = escrowInfo
        self.escrowCounter = self.escrowCounter + 1
        
        // Store the escrowed tokens in contract
        destroy from
        
        emit EscrowCreated(
            escrowId: escrowId,
            amount: amount,
            sender: sender,
            receiver: receiver
        )
        
        return escrowId
    }
    
    /// Release escrowed tokens
    access(all) fun releaseEscrow(escrowId: UInt64): @TestXRP.Vault {
        pre {
            self.escrows[escrowId] != nil: "Escrow does not exist"
            self.escrows[escrowId]!.canRelease(): "Escrow cannot be released yet"
        }
        
        let escrowInfo = self.escrows[escrowId]!
        self.escrows[escrowId]!.release()
        
        emit EscrowReleased(escrowId: escrowId, amount: escrowInfo.amount, receiver: escrowInfo.receiver)
        
        return <-create Vault(balance: escrowInfo.amount)
    }
    
    /// Get escrow information
    access(all) fun getEscrowInfo(escrowId: UInt64): EscrowInfo? {
        return self.escrows[escrowId]
    }
    
    /// Get all escrows for an address
    access(all) fun getEscrowsForAddress(address: Address): [EscrowInfo] {
        let result: [EscrowInfo] = []
        for escrowId in self.escrows.keys {
            let escrow = self.escrows[escrowId]!
            if escrow.sender == address || escrow.receiver == address {
                result.append(escrow)
            }
        }
        return result
    }
    
    /// Utility Functions
    
    /// Get token information
    access(all) fun getTokenInfo(): {String: AnyStruct} {
        return {
            "name": "TestXRP",
            "symbol": "TXRP",
            "decimals": 6, // XRP uses 6 decimal places
            "totalSupply": self.totalSupply,
            "minimumReserve": self.minimumReserve,
            "bridgeEnabled": self.bridgeEnabled,
            "escrowCount": self.escrowCounter,
            "contractAddress": self.account.address.toString()
        }
    }
    
    /// Check if bridge is enabled
    access(all) fun isBridgeEnabled(): Bool {
        return self.bridgeEnabled
    }
    
    /// Get minimum reserve requirement
    access(all) fun getMinimumReserve(): UFix64 {
        return self.minimumReserve
    }
    
    /// Get total supply
    access(all) fun getTotalSupply(): UFix64 {
        return self.totalSupply
    }
    
    init() {
        // Initialize supply and paths
        self.totalSupply = 100000000.0 // 100M TestXRP initial supply
        self.VaultStoragePath = /storage/testXRPVault
        self.VaultPublicPath = /public/testXRPVault
        self.ReceiverPublicPath = /public/testXRPReceiver
        self.AdminStoragePath = /storage/testXRPAdmin
        self.MinterStoragePath = /storage/testXRPMinter
        
        // Initialize XRP-like features
        self.bridgeEnabled = true
        self.escrows = {}
        self.escrowCounter = 0
        self.minimumReserve = 20.0 // XRP-like reserve requirement (20 XRP equivalent)
        
        // Create the admin vault with total supply
        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)
        
        // Create public capabilities
        let vaultCap = self.account.capabilities.storage.issue<&TestXRP.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)
        self.account.capabilities.publish(vaultCap, at: self.ReceiverPublicPath)
        
        // Create and store Administrator resource
        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        // Create and store initial Minter
        let minter <- create Minter(allowedAmount: 50000000.0) // 50M additional minting capacity
        self.account.storage.save(<-minter, to: self.MinterStoragePath)
        
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}