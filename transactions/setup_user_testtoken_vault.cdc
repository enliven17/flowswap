import TestToken from 0x0c0c904844c9a720

transaction {
  prepare(signer: AuthAccount) {
    if signer.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
      signer.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
      signer.link<&TestToken.Vault>(
        /public/testTokenVault,
        target: /storage/testTokenVault
      )
      signer.link<&TestToken.Vault>(
        /public/testTokenBalance,
        target: /storage/testTokenVault
      )
    }
  }
} 