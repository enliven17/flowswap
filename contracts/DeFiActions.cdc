import FungibleToken from 0xee82856bf20e2aa6

/// DeFi Actions - Core contract for composable DeFi operations
/// Provides unique identifiers and basic structures for Flow Actions
access(all) contract DeFiActions {

    /// Event emitted when a unique identifier is created
    access(all) event UniqueIdentifierCreated(id: UInt64, timestamp: UFix64, blockHeight: UInt64)

    /// Unique identifier for tracing operations
    access(all) struct UniqueIdentifier {
        access(all) let id: UInt64
        access(all) let timestamp: UFix64
        access(all) let blockHeight: UInt64
        access(all) let nonce: UInt64

        init(id: UInt64, timestamp: UFix64, blockHeight: UInt64, nonce: UInt64) {
            self.id = id
            self.timestamp = timestamp
            self.blockHeight = blockHeight
            self.nonce = nonce
        }

        access(all) fun toString(): String {
            return self.id.toString()
                .concat("_")
                .concat(self.timestamp.toString())
                .concat("_")
                .concat(self.blockHeight.toString())
                .concat("_")
                .concat(self.nonce.toString())
        }
    }

    /// Counter for unique identifiers
    access(self) var identifierCounter: UInt64

    init() {
        self.identifierCounter = 0
    }

    /// Create a unique identifier for operations
    access(all) fun createUniqueIdentifier(): UniqueIdentifier {
        self.identifierCounter = self.identifierCounter + 1
        
        let identifier = UniqueIdentifier(
            id: self.identifierCounter,
            timestamp: getCurrentBlock().timestamp,
            blockHeight: getCurrentBlock().height,
            nonce: revertibleRandom<UInt64>()
        )

        emit UniqueIdentifierCreated(
            id: identifier.id,
            timestamp: identifier.timestamp,
            blockHeight: identifier.blockHeight
        )

        return identifier
    }

    /// Get the current identifier counter
    access(all) view fun getIdentifierCounter(): UInt64 {
        return self.identifierCounter
    }
}