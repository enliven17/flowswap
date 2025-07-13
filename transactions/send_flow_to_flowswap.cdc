import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868

transaction(recipient: Address, amount: UFix64) {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    let vaultRef = signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow FlowToken vault")
    let recipientAccount = getAccount(recipient)
    let receiverRef = recipientAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
      .borrow()
      ?? panic("Could not borrow receiver reference to the recipient's FlowToken Vault")
    let sentVault <- vaultRef.withdraw(amount: amount)
    receiverRef.deposit(from: <-sentVault)
  }
} 