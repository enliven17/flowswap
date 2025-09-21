import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

/// Governance Token contract for DAO voting and protocol governance
access(all) contract GovernanceToken: FungibleToken {
    
    /// Events
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensMinted(amount: UFix64, to: Address?)
    access(all) event TokensBurned(amount: UFix64, from: Address?)
    access(all) event ProposalCreated(proposalId: UInt64, proposer: Address, title: String)
    access(all) event VoteCast(proposalId: UInt64, voter: Address, support: Bool, votes: UFix64)
    access(all) event ProposalExecuted(proposalId: UInt64, result: Bool)
    access(all) event DelegateChanged(delegator: Address, fromDelegate: Address?, toDelegate: Address?)
    
    /// Structs
    access(all) struct Proposal {
        access(all) let proposalId: UInt64
        access(all) let proposer: Address
        access(all) let title: String
        access(all) let description: String
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) var forVotes: UFix64
        access(all) var againstVotes: UFix64
        access(all) var executed: Bool
        access(all) var cancelled: Bool
        
        init(proposalId: UInt64, proposer: Address, title: String, description: String, votingPeriod: UFix64) {
            self.proposalId = proposalId
            self.proposer = proposer
            self.title = title
            self.description = description
            self.startTime = getCurrentBlock().timestamp
            self.endTime = self.startTime + votingPeriod
            self.forVotes = 0.0
            self.againstVotes = 0.0
            self.executed = false
            self.cancelled = false
        }
        
        access(all) fun addVote(support: Bool, votes: UFix64) {
            if support {
                self.forVotes = self.forVotes + votes
            } else {
                self.againstVotes = self.againstVotes + votes
            }
        }
        
        access(all) fun execute() {
            self.executed = true
        }
        
        access(all) fun cancel() {
            self.cancelled = true
        }
        
        access(all) fun isActive(): Bool {
            let currentTime = getCurrentBlock().timestamp
            return currentTime >= self.startTime && currentTime <= self.endTime && !self.executed && !self.cancelled
        }
        
        access(all) fun hasSucceeded(): Bool {
            return self.forVotes > self.againstVotes && self.forVotes > (self.forVotes + self.againstVotes) * 0.5
        }
    }
    
    access(all) struct VoteReceipt {
        access(all) let proposalId: UInt64
        access(all) let voter: Address
        access(all) let support: Bool
        access(all) let votes: UFix64
        access(all) let timestamp: UFix64
        
        init(proposalId: UInt64, voter: Address, support: Bool, votes: UFix64) {
            self.proposalId = proposalId
            self.voter = voter
            self.support = support
            self.votes = votes
            self.timestamp = getCurrentBlock().timestamp
        }
    }
    
    /// Token Implementation
    access(all) var totalSupply: UFix64
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    /// Governance Storage
    access(self) var proposals: {UInt64: Proposal}
    access(self) var proposalCounter: UInt64
    access(self) var votes: {UInt64: {Address: VoteReceipt}} // proposalId -> voter -> receipt
    access(self) var delegates: {Address: Address} // delegator -> delegate
    access(self) var votingPower: {Address: UFix64} // cached voting power including delegations
    access(self) var admin: Address
    access(self) var proposalThreshold: UFix64 // Minimum tokens needed to create proposal
    access(self) var quorumThreshold: UFix64 // Minimum participation for valid vote
    
    /// Vault Resource
    access(all) resource Vault: FungibleToken.Vault {
        access(all) var balance: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
        }
        
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }
        
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @GovernanceToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            destroy vault
        }
        
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance >= amount
        }
        
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
    
    /// Administrator Resource
    access(all) resource Administrator {
        access(all) fun mintTokens(amount: UFix64): @GovernanceToken.Vault {
            GovernanceToken.totalSupply = GovernanceToken.totalSupply + amount
            emit TokensMinted(amount: amount, to: nil)
            return <-create Vault(balance: amount)
        }
        
        access(all) fun burnTokens(from: @GovernanceToken.Vault) {
            let amount = from.balance
            destroy from
            GovernanceToken.totalSupply = GovernanceToken.totalSupply - amount
            emit TokensBurned(amount: amount, from: nil)
        }
        
        access(all) fun updateProposalThreshold(newThreshold: UFix64) {
            GovernanceToken.proposalThreshold = newThreshold
        }
        
        access(all) fun updateQuorumThreshold(newThreshold: UFix64) {
            GovernanceToken.quorumThreshold = newThreshold
        }
    }
    
    /// Create empty vault
    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <-create Vault(balance: 0.0)
    }
    
    /// Create a new governance proposal
    access(all) fun createProposal(
        proposer: Address,
        title: String,
        description: String,
        votingPeriod: UFix64
    ): UInt64 {
        pre {
            self.getVotingPower(address: proposer) >= self.proposalThreshold: "Insufficient tokens to create proposal"
            title.length > 0: "Title cannot be empty"
            description.length > 0: "Description cannot be empty"
            votingPeriod > 0.0: "Voting period must be positive"
        }
        
        let proposalId = self.proposalCounter
        let proposal = Proposal(
            proposalId: proposalId,
            proposer: proposer,
            title: title,
            description: description,
            votingPeriod: votingPeriod
        )
        
        self.proposals[proposalId] = proposal
        self.votes[proposalId] = {}
        self.proposalCounter = self.proposalCounter + 1
        
        emit ProposalCreated(proposalId: proposalId, proposer: proposer, title: title)
        return proposalId
    }
    
    /// Cast a vote on a proposal
    access(all) fun castVote(proposalId: UInt64, voter: Address, support: Bool) {
        pre {
            self.proposals[proposalId] != nil: "Proposal does not exist"
            self.proposals[proposalId]!.isActive(): "Proposal is not active"
            self.votes[proposalId]![voter] == nil: "Already voted on this proposal"
        }
        
        let votingPower = self.getVotingPower(address: voter)
        if votingPower == 0.0 {
            panic("No voting power")
        }
        
        // Record vote
        let receipt = VoteReceipt(
            proposalId: proposalId,
            voter: voter,
            support: support,
            votes: votingPower
        )
        
        self.votes[proposalId]![voter] = receipt
        self.proposals[proposalId]!.addVote(support: support, votes: votingPower)
        
        emit VoteCast(proposalId: proposalId, voter: voter, support: support, votes: votingPower)
    }
    
    /// Execute a proposal if it has succeeded
    access(all) fun executeProposal(proposalId: UInt64) {
        pre {
            self.proposals[proposalId] != nil: "Proposal does not exist"
            !self.proposals[proposalId]!.executed: "Proposal already executed"
            !self.proposals[proposalId]!.cancelled: "Proposal is cancelled"
            getCurrentBlock().timestamp > self.proposals[proposalId]!.endTime: "Voting period not ended"
        }
        
        let proposal = self.proposals[proposalId]!
        let totalVotes = proposal.forVotes + proposal.againstVotes
        let quorumMet = totalVotes >= self.quorumThreshold
        let succeeded = proposal.hasSucceeded()
        
        if quorumMet && succeeded {
            self.proposals[proposalId]!.execute()
            emit ProposalExecuted(proposalId: proposalId, result: true)
        } else {
            emit ProposalExecuted(proposalId: proposalId, result: false)
        }
    }
    
    /// Delegate voting power to another address
    access(all) fun delegate(delegator: Address, delegate: Address) {
        let oldDelegate = self.delegates[delegator]
        self.delegates[delegator] = delegate
        
        // Update voting power cache
        self.updateVotingPowerCache()
        
        emit DelegateChanged(delegator: delegator, fromDelegate: oldDelegate, toDelegate: delegate)
    }
    
    /// Get voting power for an address (including delegations)
    access(all) fun getVotingPower(address: Address): UFix64 {
        return self.votingPower[address] ?? 0.0
    }
    
    /// Update voting power cache
    access(self) fun updateVotingPowerCache() {
        // Reset cache
        self.votingPower = {}
        
        // This is a simplified implementation
        // In practice, you'd need to iterate through all token holders
        // and calculate their voting power including delegations
        
        // For now, we'll use a placeholder implementation
        // that would need to be enhanced with proper token holder tracking
    }
    
    /// Get proposal details
    access(all) fun getProposal(proposalId: UInt64): Proposal? {
        return self.proposals[proposalId]
    }
    
    /// Get vote receipt
    access(all) fun getVoteReceipt(proposalId: UInt64, voter: Address): VoteReceipt? {
        if self.votes[proposalId] == nil {
            return nil
        }
        return self.votes[proposalId]![voter]
    }
    
    /// Get all proposals
    access(all) fun getAllProposals(): {UInt64: Proposal} {
        return self.proposals
    }
    
    /// Get delegate for an address
    access(all) fun getDelegate(delegator: Address): Address? {
        return self.delegates[delegator]
    }
    
    /// Get governance parameters
    access(all) fun getGovernanceParams(): {String: UFix64} {
        return {
            "proposalThreshold": self.proposalThreshold,
            "quorumThreshold": self.quorumThreshold,
            "totalSupply": self.totalSupply
        }
    }
    
    init() {
        self.totalSupply = 1000000.0 // 1M initial supply
        self.VaultStoragePath = /storage/governanceTokenVault
        self.VaultPublicPath = /public/governanceTokenVault
        self.AdminStoragePath = /storage/governanceTokenAdmin
        
        // Governance parameters
        self.proposals = {}
        self.proposalCounter = 0
        self.votes = {}
        self.delegates = {}
        self.votingPower = {}
        self.admin = self.account.address
        self.proposalThreshold = 10000.0 // Need 10k tokens to create proposal
        self.quorumThreshold = 100000.0 // Need 100k votes for quorum
        
        // Create admin vault and administrator
        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)
        
        let vaultCap = self.account.capabilities.storage.issue<&GovernanceToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)
        
        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}