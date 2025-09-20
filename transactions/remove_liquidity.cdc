import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwap from 0xf8d6e0586b0a20c7

transaction(lpTokenAmount: UFix64) {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    // Get LP token vault reference
    let lpVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowSwap.LPTokenVault>(from: /storage/lpTokenVault)
      ?? panic("No LP token vault found")
    
    // Withdraw LP tokens
    let withdrawnLP <- lpVault.withdraw(amount: lpTokenAmount)
    
    // Get receiver capabilities for returned tokens
    let flowReceiver = signer.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
      .borrow()
      ?? panic("Flow receiver not found")
    
    let testReceiver = signer.capabilities.get<&{FungibleToken.Receiver}>(/public/testTokenReceiver)
      .borrow()
      ?? panic("TestToken receiver not found")
    
    // Remove liquidity and get returned tokens
    let returnedTokens <- FlowSwap.removeLiquidity(lpTokens: <- withdrawnLP)
    
    // Deposit returned FLOW tokens
    flowReceiver.deposit(from: <- returnedTokens.flowTokens)
    
    // Deposit returned TestTokens
    testReceiver.deposit(from: <- returnedTokens.testTokens)
  }

  execute {
    log("Liquidity removed successfully")
  }
}