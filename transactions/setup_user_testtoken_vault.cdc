import TestToken from 0x0c0c904844c9a720

transaction {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    if signer.storage.borrow<&TestToken.Vault>(from: /storage/flowSwapTestVault) == nil {
      signer.storage.save(<- TestToken.createEmptyVault(), to: /storage/flowSwapTestVault)
      let receiverCap = signer.capabilities.storage.issue<&TestToken.Vault>(/storage/flowSwapTestVault)
      signer.capabilities.publish(receiverCap, at: /public/flowSwapTestReceiver)
      signer.capabilities.publish(receiverCap, at: /public/flowSwapTestBalance)
    }
  }
} 