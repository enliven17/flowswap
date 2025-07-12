import FungibleToken from 0x9a0766d93b6608b7
import TestToken from 0xfbaa55ea2a76ff04

/// Mint test tokens for testing purposes
transaction(amount: UFix64) {
  prepare(signer: AuthAccount) {
    // Ensure user has TestToken vault
    if signer.borrow<&TestToken.Vault>(from: /storage/TestTokenVault) == nil {
      signer.save(<- TestToken.createEmptyVault(), to: /storage/TestTokenVault)
      signer.link<&TestToken.Vault{FungibleToken.Receiver}>(/public/TestTokenReceiver, target: /storage/TestTokenVault)
      signer.link<&TestToken.Vault{FungibleToken.Balance}>(/public/TestTokenBalance, target: /storage/TestTokenVault)
    }
    let receiver = signer.getCapability<&{FungibleToken.Receiver}>(/public/TestTokenReceiver)
      .borrow()
      ?? panic("Could not borrow TestToken receiver")
    TestToken.mintTokens(amount: amount, recipient: receiver)
    log("Minted ".concat(amount.toString()).concat(" TestTokens"))
  }
} 