import FungibleToken from 0xee82856bf20e2aa6
import TestXRP from 0xf8d6e0586b0a20c7

/// Transaction to mint TestXRP tokens to a recipient
transaction(recipient: Address, amount: UFix64) {
    
    let minterRef: &TestXRP.Minter
    let recipientVault: &TestXRP.Vault
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get reference to minter resource
        self.minterRef = signer.storage.borrow<&TestXRP.Minter>(from: TestXRP.MinterStoragePath)
            ?? panic("Could not borrow TestXRP Minter reference")
        
        // Check minter allowance
        if self.minterRef.allowedAmount < amount {
            panic("Insufficient minting allowance. Allowed: ".concat(self.minterRef.allowedAmount.toString()).concat(", Requested: ").concat(amount.toString()))
        }
        
        // Get recipient's TestXRP vault
        let recipientAccount = getAccount(recipient)
        self.recipientVault = recipientAccount.capabilities.get<&TestXRP.Vault>(TestXRP.VaultPublicPath)
            .borrow()
            ?? panic("Recipient does not have TestXRP vault set up")
        
        log("Minting TestXRP:")
        log("Amount: ".concat(amount.toString()))
        log("Recipient: ".concat(recipient.toString()))
        log("Minter Allowance: ".concat(self.minterRef.allowedAmount.toString()))
    }
    
    execute {
        // Mint TestXRP tokens
        let mintedTokens <- self.minterRef.mintTokens(amount: amount)
        
        // Deposit minted tokens to recipient's vault
        self.recipientVault.deposit(from: <-mintedTokens)
        
        log("Successfully minted ".concat(amount.toString()).concat(" TestXRP to ").concat(recipient.toString()))
        log("Remaining minter allowance: ".concat(self.minterRef.allowedAmount.toString()))
    }
    
    post {
        // Verify minting parameters
        amount > 0.0: "Mint amount must be positive"
    }
}