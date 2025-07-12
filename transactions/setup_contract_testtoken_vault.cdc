import TestToken from 0x0c0c904844c9a720

transaction {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    if signer.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
      signer.storage.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
      let receiverCap = signer.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault)
      signer.capabilities.publish(receiverCap, at: /public/testTokenVault)
      signer.capabilities.publish(receiverCap, at: /public/testTokenBalance)
    }
  }
} 