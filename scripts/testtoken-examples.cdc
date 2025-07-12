// TestToken Contract Examples
// Deploy edilen contract adresi: 0xfbaa55ea2a76ff04

// ========================================
// 1. GET TOTAL SUPPLY (Script)
// ========================================
import TestToken from 0xfbaa55ea2a76ff04

access(all) fun main(): UFix64 {
    return TestToken.totalSupply
}

// ========================================
// 2. GET BALANCE (Script)
// ========================================
import TestToken from 0xfbaa55ea2a76ff04

access(all) fun main(account: Address): UFix64? {
    let vaultRef = getAccount(account)
        .capabilities.borrow<&TestToken.Vault>(
            TestToken.VaultPublicPath
        )
    return vaultRef?.getBalance()
}

// ========================================
// 3. SETUP ACCOUNT (Transaction)
// ========================================
import TestToken from 0xfbaa55ea2a76ff04

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if vault already exists
        if signer.storage.borrow<&TestToken.Vault>(from: TestToken.VaultStoragePath) == nil {
            // Create new vault
            let vault <- TestToken.createEmptyVault()
            signer.storage.save(<-vault, to: TestToken.VaultStoragePath)
            
            // Create public capability
            let vaultCap = signer.capabilities.storage.issue<&TestToken.Vault>(
                TestToken.VaultStoragePath
            )
            signer.capabilities.publish(vaultCap, at: TestToken.VaultPublicPath)
        }
    }
}

// ========================================
// 4. MINT TOKENS (Transaction) - Admin Only
// ========================================
import TestToken from 0xfbaa55ea2a76ff04

transaction(amount: UFix64) {
    let adminRef: &TestToken.Administrator
    let receiverRef: &TestToken.Vault
    
    prepare(signer: auth(Storage) &Account) {
        // Get admin resource
        self.adminRef = signer.storage.borrow<&TestToken.Administrator>(
            from: TestToken.AdminStoragePath
        ) ?? panic("Admin resource not found")
        
        // Get receiver vault
        self.receiverRef = signer.storage.borrow<&TestToken.Vault>(
            from: TestToken.VaultStoragePath
        ) ?? panic("Vault not found")
    }
    
    execute {
        let mintedTokens <- self.adminRef.mintTokens(amount: amount)
        self.receiverRef.deposit(from: <-mintedTokens)
    }
}

// ========================================
// 5. TRANSFER TOKENS (Transaction)
// ========================================
import TestToken from 0xfbaa55ea2a76ff04

transaction(amount: UFix64, recipient: Address) {
    let senderVault: &TestToken.Vault
    let receiverVault: &TestToken.Vault
    
    prepare(signer: auth(Storage) &Account) {
        // Get sender vault
        self.senderVault = signer.storage.borrow<&TestToken.Vault>(
            from: TestToken.VaultStoragePath
        ) ?? panic("Sender vault not found")
        
        // Get receiver vault
        self.receiverVault = getAccount(recipient)
            .capabilities.borrow<&TestToken.Vault>(TestToken.VaultPublicPath)
            ?? panic("Receiver vault not found")
    }
    
    execute {
        let tokens <- self.senderVault.withdraw(amount: amount)
        self.receiverVault.deposit(from: <-tokens)
    }
}

// ========================================
// 6. BURN TOKENS (Transaction) - Admin Only
// ========================================
import TestToken from 0xfbaa55ea2a76ff04

transaction(amount: UFix64) {
    let adminRef: &TestToken.Administrator
    let senderVault: &TestToken.Vault
    
    prepare(signer: auth(Storage) &Account) {
        self.adminRef = signer.storage.borrow<&TestToken.Administrator>(
            from: TestToken.AdminStoragePath
        ) ?? panic("Admin resource not found")
        
        self.senderVault = signer.storage.borrow<&TestToken.Vault>(
            from: TestToken.VaultStoragePath
        ) ?? panic("Vault not found")
    }
    
    execute {
        let tokens <- self.senderVault.withdraw(amount: amount)
        self.adminRef.burnTokens(from: <-tokens)
    }
} 