import FungibleToken from 0xee82856bf20e2aa6
import TestXRP from 0xf8d6e0586b0a20c7

/// Transaction to bridge TestXRP back to XRP (simulate XRP withdrawal)
transaction(amount: UFix64, xrpAddress: String) {
    
    let vaultRef: auth(FungibleToken.Withdraw) &TestXRP.Vault
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get reference to user's TestXRP vault
        self.vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TestXRP.Vault>(from: TestXRP.VaultStoragePath)
            ?? panic("Could not borrow TestXRP vault reference")
        
        // Check if user has sufficient balance
        if self.vaultRef.balance < amount {
            panic("Insufficient TestXRP balance. Have: ".concat(self.vaultRef.balance.toString()).concat(", Need: ").concat(amount.toString()))
        }
        
        // Check minimum reserve requirement
        let minReserve = TestXRP.getMinimumReserve()
        if self.vaultRef.balance - amount < minReserve {
            panic("Cannot withdraw below minimum reserve of ".concat(minReserve.toString()).concat(" TestXRP"))
        }
    }
    
    execute {
        // Withdraw TestXRP tokens to bridge
        let tokensTobridge <- self.vaultRef.withdraw(amount: amount)
        
        // Bridge TestXRP to XRP
        TestXRP.bridgeToXRP(from: <-tokensTobridge, xrpAddress: xrpAddress)
        
        log("Successfully bridged ".concat(amount.toString()).concat(" TestXRP to XRP"))
        log("XRP Address: ".concat(xrpAddress))
        log("Flow Address: ".concat(self.vaultRef.owner!.address.toString()))
    }
    
    post {
        // Verify the bridge operation
        amount > 0.0: "Bridge amount must be positive"
        xrpAddress.length > 0: "XRP address cannot be empty"
    }
}