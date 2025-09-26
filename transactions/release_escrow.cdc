import FungibleToken from 0xee82856bf20e2aa6
import TestXRP from 0xf8d6e0586b0a20c7

/// Transaction to release escrowed TestXRP tokens
transaction(escrowId: UInt64) {
    
    let receiverRef: &TestXRP.Vault
    let escrowInfo: TestXRP.EscrowInfo
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get escrow information
        self.escrowInfo = TestXRP.getEscrowInfo(escrowId: escrowId)
            ?? panic("Escrow with ID ".concat(escrowId.toString()).concat(" does not exist"))
        
        // Verify signer is the receiver
        if signer.address != self.escrowInfo.receiver {
            panic("Only the escrow receiver can release the escrow")
        }
        
        // Check if escrow can be released
        if !self.escrowInfo.canRelease() {
            let currentTime = getCurrentBlock().timestamp
            let releaseTime = self.escrowInfo.releaseTime
            let remainingTime = releaseTime - currentTime
            
            if self.escrowInfo.isReleased {
                panic("Escrow has already been released")
            } else {
                panic("Escrow cannot be released yet. Remaining time: ".concat(remainingTime.toString()).concat(" seconds"))
            }
        }
        
        // Ensure user has TestXRP vault set up
        if signer.storage.borrow<&TestXRP.Vault>(from: TestXRP.VaultStoragePath) == nil {
            // Create vault if it doesn't exist
            let vault <- TestXRP.createEmptyVault()
            signer.storage.save(<-vault, to: TestXRP.VaultStoragePath)
            
            let vaultCap = signer.capabilities.storage.issue<&TestXRP.Vault>(TestXRP.VaultStoragePath)
            signer.capabilities.publish(vaultCap, at: TestXRP.VaultPublicPath)
            signer.capabilities.publish(vaultCap, at: TestXRP.ReceiverPublicPath)
        }
        
        // Get reference to receiver's TestXRP vault
        self.receiverRef = signer.storage.borrow<&TestXRP.Vault>(from: TestXRP.VaultStoragePath)
            ?? panic("Could not borrow TestXRP vault reference")
        
        log("Releasing escrow:")
        log("Escrow ID: ".concat(escrowId.toString()))
        log("Amount: ".concat(self.escrowInfo.amount.toString()).concat(" TestXRP"))
        log("Sender: ".concat(self.escrowInfo.sender.toString()))
        log("Receiver: ".concat(self.escrowInfo.receiver.toString()))
    }
    
    execute {
        // Release escrow tokens
        let releasedTokens <- TestXRP.releaseEscrow(escrowId: escrowId)
        
        // Deposit released tokens to receiver's vault
        self.receiverRef.deposit(from: <-releasedTokens)
        
        log("Escrow released successfully!")
        log("Released ".concat(self.escrowInfo.amount.toString()).concat(" TestXRP to ").concat(self.escrowInfo.receiver.toString()))
    }
    
    post {
        // Verify escrow release
        escrowId >= 0: "Escrow ID must be valid"
    }
}