import FungibleToken from 0x9a0766d93b6608b7
import TestToken from 0x0c0c904844c9a720

access(all) fun main(address: Address): UFix64 {
  let account = getAccount(address)
  let vaultRef = account.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
    .borrow()
    ?? panic("Could not borrow Vault reference")
  return vaultRef.balance
} 