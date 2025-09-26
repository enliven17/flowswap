import FungibleToken from 0xee82856bf20e2aa6
import TestXRP from 0xf8d6e0586b0a20c7

/// Transaction to set up TestXRP vault for a user
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if TestXRP vault already exists
        if signer.storage.borrow<&TestXRP.Vault>(from: TestXRP.VaultStoragePath) != nil {
            log("TestXRP vault already exists")
            return
        }
        
        // Create new TestXRP vault
        let vault <- TestXRP.createEmptyVault()
        
        // Store the vault in storage
        signer.storage.save(<-vault, to: TestXRP.VaultStoragePath)
        
        // Create and publish public capabilities
        let vaultCap = signer.capabilities.storage.issue<&TestXRP.Vault>(TestXRP.VaultStoragePath)
        signer.capabilities.publish(vaultCap, at: TestXRP.VaultPublicPath)
        signer.capabilities.publish(vaultCap, at: TestXRP.ReceiverPublicPath)
        
        log("TestXRP vault created and capabilities published")
    }
    
    execute {
        log("TestXRP vault setup completed successfully")
    }
}