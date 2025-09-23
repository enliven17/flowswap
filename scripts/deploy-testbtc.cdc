import FungibleToken from 0x9a0766d93b6608b7
import TestBTC from 0x0c0c904844c9a720

transaction() {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    if signer.storage.borrow<&TestBTC.Vault>(from: /storage/testBTCVault) == nil {
      signer.storage.save(<- TestBTC.createEmptyVault(), to: /storage/testBTCVault)
      let recv = signer.capabilities.storage.issue<&TestBTC.Vault>(/storage/testBTCVault)
      signer.capabilities.publish(recv, at: /public/testBTCVault)
    }
  }
}

