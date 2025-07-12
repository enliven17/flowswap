import TestToken from 0x0c0c904844c9a720

transaction {
  prepare(account: auth(Storage, Capabilities) &Account) {
    if account.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) != nil {
      account.storage.remove(/storage/testTokenVault)
    }
    account.storage.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
    let receiverCap = account.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault)
    account.capabilities.publish(receiverCap, at: /public/testTokenVault)
    account.capabilities.publish(receiverCap, at: /public/testTokenBalance)
  }
} 