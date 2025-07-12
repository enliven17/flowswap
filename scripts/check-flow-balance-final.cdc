import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868

access(all) fun main(): UFix64 {
  let account = getAccount(0x0c0c904844c9a720)
  let vaultRef = account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance)
    .borrow()
    ?? panic("Could not borrow Vault reference")
  return vaultRef.balance
} 