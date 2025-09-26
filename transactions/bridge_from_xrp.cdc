import FungibleToken from 0xee82856bf20e2aa6
import TestXRP from 0xf8d6e0586b0a20c7

/// Transaction to bridge XRP to TestXRP (simulate XRP deposit)
transaction(amount: UFix64, xrpAddress: String) {
    
    let receiverRef: &TestXRP.Vault
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Ensure user has TestXRP vault set up
        if signer.storage.borrow<&TestXRP.Vault>(from: TestXRP.VaultStoragePath) == nil {
            // Create vault if it doesn't exist
            let vault <- TestXRP.createEmptyVault()
            signer.storage.save(<-vault, to: TestXRP.VaultStoragePath)
            
            let vaultCap = signer.capabilities.storage.issue<&TestXRP.Vault>(TestXRP.VaultStoragePath)
            signer.capabilities.publish(vaultCap, at: TestXRP.VaultPublicPath)
            signer.capabilities.publish(vaultCap, at: TestXRP.ReceiverPublicPath)
        }
        
        // Get reference to user's TestXRP vault
        self.receiverRef = signer.storage.borrow<&TestXRP.Vault>(from: TestXRP.VaultStoragePath)
            ?? panic("Could not borrow TestXRP vault reference")
    }
    
    execute {
        // Bridge XRP to TestXRP
        let bridgedTokens <- TestXRP.bridgeFromXRP(
            amount: amount,
            xrpAddress: xrpAddress,
            flowAddress: self.receiverRef.owner!.address
        )
        
        // Deposit bridged tokens to user's vault
        self.receiverRef.deposit(from: <-bridgedTokens)
        
        log("Successfully bridged ".concat(amount.toString()).concat(" XRP to TestXRP"))
        log("XRP Address: ".concat(xrpAddress))
        log("Flow Address: ".concat(self.receiverRef.owner!.address.toString()))
    }
    
    post {
        // Verify the bridge operation
        amount > 0.0: "Bridge amount must be positive"
        xrpAddress.length > 0: "XRP address cannot be empty"
    }
}