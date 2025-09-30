import FungibleToken from 0x9a0766d93b6608b7
import TestMETU from 0x0c0c904844c9a720

transaction() {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    if signer.storage.borrow<&TestMETU.Vault>(from: /storage/testMETUVault) == nil {
      signer.storage.save(<- TestMETU.createEmptyVault(), to: /storage/testMETUVault)
      let recv = signer.capabilities.storage.issue<&TestMETU.Vault>(/storage/testMETUVault)
      signer.capabilities.publish(recv, at: /public/testMETUVault)
    }
  }
}

