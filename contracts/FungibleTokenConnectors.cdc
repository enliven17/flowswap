import FungibleToken from 0xee82856bf20e2aa6
import DeFiActions from 0xf8d6e0586b0a20c7

/// Fungible Token Connectors for Flow Actions
/// Provides Source and Sink implementations for token operations
access(all) contract FungibleTokenConnectors {

    /// Event emitted when tokens are withdrawn from a source
    access(all) event SourceWithdraw(
        uniqueID: String,
        tokenType: String,
        amount: UFix64,
        userAddress: Address
    )

    /// Event emitted when tokens are deposited to a sink
    access(all) event SinkDeposit(
        uniqueID: String,
        tokenType: String,
        amount: UFix64,
        userAddress: Address
    )

    /// Source interface for providing tokens
    access(all) struct interface Source {
        access(all) view fun getSourceType(): Type
        access(all) fun minimumAvailable(): UFix64
        access(all) fun withdrawAvailable(maxAmount: UFix64): @{FungibleToken.Vault}
    }

    /// Sink interface for receiving tokens
    access(all) struct interface Sink {
        access(all) view fun getSinkType(): Type
        access(all) fun minimumCapacity(): UFix64
        access(all) fun depositCapacity(from: @{FungibleToken.Vault}): UFix64
    }

    /// VaultSource implementation
    access(all) struct VaultSource: Source {
        access(all) let min: UFix64
        access(all) let withdrawVault: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>
        access(all) let uniqueID: DeFiActions.UniqueIdentifier

        init(
            min: UFix64,
            withdrawVault: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
            uniqueID: DeFiActions.UniqueIdentifier
        ) {
            self.min = min
            self.withdrawVault = withdrawVault
            self.uniqueID = uniqueID
        }

        access(all) view fun getSourceType(): Type {
            return self.withdrawVault.getType()
        }

        access(all) fun minimumAvailable(): UFix64 {
            if let vault = self.withdrawVault.borrow() {
                let available = vault.balance
                return available >= self.min ? available : 0.0
            }
            return 0.0
        }

        access(all) fun withdrawAvailable(maxAmount: UFix64): @{FungibleToken.Vault} {
            let vault = self.withdrawVault.borrow()
                ?? panic("Could not borrow withdraw vault")
            
            let available = vault.balance
            let withdrawAmount = maxAmount > available ? available : maxAmount
            
            if withdrawAmount < self.min {
                panic("Insufficient tokens available. Need: ".concat(self.min.toString()).concat(", Available: ").concat(available.toString()))
            }

            let tokens <- vault.withdraw(amount: withdrawAmount)

            emit SourceWithdraw(
                uniqueID: self.uniqueID.toString(),
                tokenType: self.getSourceType().identifier,
                amount: withdrawAmount,
                userAddress: self.withdrawVault.address
            )

            return <-tokens
        }
    }

    /// VaultSink implementation
    access(all) struct VaultSink: Sink {
        access(all) let max: UFix64?
        access(all) let depositVault: Capability<&{FungibleToken.Vault}>
        access(all) let uniqueID: DeFiActions.UniqueIdentifier

        init(
            max: UFix64?,
            depositVault: Capability<&{FungibleToken.Vault}>,
            uniqueID: DeFiActions.UniqueIdentifier
        ) {
            self.max = max
            self.depositVault = depositVault
            self.uniqueID = uniqueID
        }

        access(all) view fun getSinkType(): Type {
            return self.depositVault.getType()
        }

        access(all) fun minimumCapacity(): UFix64 {
            return self.max ?? 1000000.0 // Large default capacity
        }

        access(all) fun depositCapacity(from: @{FungibleToken.Vault}): UFix64 {
            let vault = self.depositVault.borrow()
                ?? panic("Could not borrow deposit vault")
            
            let depositAmount = from.balance
            let maxCapacity = self.max ?? depositAmount
            
            if depositAmount > maxCapacity {
                panic("Deposit amount exceeds maximum capacity")
            }

            vault.deposit(from: <-from)

            emit SinkDeposit(
                uniqueID: self.uniqueID.toString(),
                tokenType: self.getSinkType().identifier,
                amount: depositAmount,
                userAddress: self.depositVault.address
            )

            return depositAmount
        }
    }
}