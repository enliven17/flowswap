import FungibleToken from 0xee82856bf20e2aa6
import TestXRP from 0xf8d6e0586b0a20c7

/// Transaction to create an escrow (time-locked payment)
transaction(amount: UFix64, receiver: Address, lockDurationHours: UFix64) {
    
    let vaultRef: auth(FungibleToken.Withdraw) &TestXRP.Vault
    let lockDuration: UFix64
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get reference to user's TestXRP vault
        self.vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TestXRP.Vault>(from: TestXRP.VaultStoragePath)
            ?? panic("Could not borrow TestXRP vault reference")
        
        // Check if user has sufficient balance
        if self.vaultRef.balance < amount {
            panic("Insufficient TestXRP balance. Have: ".concat(self.vaultRef.balance.toString()).concat(", Need: ").concat(amount.toString()))
        }
        
        // Convert hours to seconds
        self.lockDuration = lockDurationHours * 3600.0
        
        log("Creating escrow:")
        log("Amount: ".concat(amount.toString()).concat(" TestXRP"))
        log("Receiver: ".concat(receiver.toString()))
        log("Lock Duration: ".concat(lockDurationHours.toString()).concat(" hours"))
    }
    
    execute {
        // Withdraw tokens for escrow
        let tokensToEscrow <- self.vaultRef.withdraw(amount: amount)
        
        // Create escrow
        let escrowId = TestXRP.createEscrow(
            from: <-tokensToEscrow,
            receiver: receiver,
            lockDuration: self.lockDuration
        )
        
        log("Escrow created successfully!")
        log("Escrow ID: ".concat(escrowId.toString()))
        log("Release Time: ".concat((getCurrentBlock().timestamp + self.lockDuration).toString()))
    }
    
    post {
        // Verify escrow parameters
        amount > 0.0: "Escrow amount must be positive"
        lockDurationHours > 0.0: "Lock duration must be positive"
    }
}