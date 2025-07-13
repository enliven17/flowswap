import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TestToken from 0x0c0c904844c9a720

transaction(amountIn: UFix64, minAmountOut: UFix64, contractAddr: Address) {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    // Kullanıcıdan FLOW withdraw (Withdraw yetkisiyle)
    let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow user's FlowToken Vault")
    let withdrawnFlow <- flowVault.withdraw(amount: amountIn)

    // Kontratın FlowToken receiver'ına gönder
    let contractAccount = getAccount(contractAddr)
    let contractFlowReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowSwapFlowReceiver)
      .borrow()
      ?? panic("Could not borrow contract's FlowToken receiver")
    contractFlowReceiver.deposit(from: <- withdrawnFlow)

    // Kontratın TestToken vaultundan çek (doğru path kullan)
    let contractTestTokenVault = contractAccount.capabilities.get<&TestToken.Vault>(/public/flowSwapTestReceiver)
      .borrow()
      ?? panic("Could not borrow contract's TestToken Vault")
    let testTokenToSend <- contractTestTokenVault.withdraw(amount: minAmountOut)

    // Kullanıcıda TestToken vault yoksa kur
    if signer.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
      signer.storage.save(<- TestToken.createEmptyVault(), to: /storage/testTokenVault)
      let receiverCap = signer.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault)
      signer.capabilities.publish(receiverCap, at: /public/testTokenVault)
    }

    // Kullanıcının TestToken receiver'ını al
    let userTestTokenReceiver = signer.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
      .borrow()
      ?? panic("Could not borrow user's TestToken receiver")
    userTestTokenReceiver.deposit(from: <- testTokenToSend)
  }
} 