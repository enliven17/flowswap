import FungibleToken from 0x9a0766d93b6608b7
import TestETH from 0x0c0c904844c9a720

transaction() {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    if signer.storage.borrow<&TestETH.Vault>(from: /storage/testETHVault) == nil {
      signer.storage.save(<- TestETH.createEmptyVault(), to: /storage/testETHVault)
      let recv = signer.capabilities.storage.issue<&TestETH.Vault>(/storage/testETHVault)
      signer.capabilities.publish(recv, at: /public/testETHVault)
    }
  }
}


