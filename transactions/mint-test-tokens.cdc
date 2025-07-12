import FungibleToken from 0x9a0766d93b6608b7
import TestToken from 0x0c0c904844c9a720

/// Mint test tokens for testing purposes
transaction(amount: UFix64) {
  prepare(account: auth(Storage, Capabilities) &Account) {
    // Ensure user has TestToken vault
    if account.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
      account.storage.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
      let receiverCap = account.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault)
      account.capabilities.publish(receiverCap, at: /public/testTokenVault)
      account.capabilities.publish(receiverCap, at: /public/testTokenBalance)
    }
    let vaultRef = account.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault)
      ?? panic("Could not borrow TestToken vault")
    let mintedVault <- TestToken.mintTo(recipient: account.address, amount: amount)
    vaultRef.deposit(from: <-mintedVault)
    log("Minted ".concat(amount.toString()).concat(" TestTokens to address: ").concat(account.address.toString()))
  }
} 