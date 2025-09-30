import FungibleToken from 0x9a0766d93b6608b7
import TestXLM from 0x0c0c904844c9a720

transaction() {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    if signer.storage.borrow<&TestXLM.Vault>(from: /storage/testXLMVault) == nil {
      signer.storage.save(<- TestXLM.createEmptyVault(), to: /storage/testXLMVault)
      let recv = signer.capabilities.storage.issue<&TestXLM.Vault>(/storage/testXLMVault)
      signer.capabilities.publish(recv, at: /public/testXLMVault)
    }
  }
}


