import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TestToken from 0x0c0c904844c9a720
import FlowSwap from 0x0c0c904844c9a720

transaction(amountFlow: UFix64, amountTestToken: UFix64) {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    // Withdraw FLOW from signer's vault using capability
    let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("No Flow vault")
    let withdrawnFlow <- flowVault.withdraw(amount: amountFlow)

    // Withdraw TestToken from signer's vault using capability
    let testTokenVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/testTokenVault)
      ?? panic("No TestToken vault")
    let withdrawnTestToken <- testTokenVault.withdraw(amount: amountTestToken)

    let contractAccount = getAccount(0x0c0c904844c9a720)

    // Deposit FLOW to FlowSwap contract using receiver capability
    let flowReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowSwapFlowReceiver)
      .borrow()
      ?? panic("FlowSwap FLOW receiver not found")
    flowReceiver.deposit(from: <- withdrawnFlow)

    // Deposit TestToken to FlowSwap contract using receiver capability
    let testReceiver = contractAccount.capabilities.get<&TestToken.Vault>(/public/flowSwapTestReceiver)
      .borrow()
      ?? panic("FlowSwap TestToken receiver not found")
    testReceiver.deposit(from: <- withdrawnTestToken)
  }

  execute {
    // Call addLiquidity function
    FlowSwap.addLiquidity(amountA: amountFlow, amountB: amountTestToken, provider: 0x0c0c904844c9a720)
  }
} 