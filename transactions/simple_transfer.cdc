import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TestToken from 0x0c0c904844c9a720

transaction(amountFlow: UFix64, amountTestToken: UFix64) {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    let contractAccount = getAccount(0x0c0c904844c9a720)

    // Get FlowToken provider capability from signer
    let flowProvider = signer.capabilities.get<&{FungibleToken.Provider}>(/public/flowTokenProvider)
      .borrow()
      ?? panic("FlowToken provider capability not found")
    let withdrawnFlow <- flowProvider.withdraw(amount: amountFlow)

    // Get TestToken provider capability from signer
    let testProvider = signer.capabilities.get<&{FungibleToken.Provider}>(/public/testTokenProvider)
      .borrow()
      ?? panic("TestToken provider capability not found")
    let withdrawnTestToken <- testProvider.withdraw(amount: amountTestToken)

    // Deposit FLOW to FlowSwap contract
    let flowReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowSwapFlowReceiver)
      .borrow()
      ?? panic("FlowSwap FLOW receiver not found")
    flowReceiver.deposit(from: <- withdrawnFlow)

    // Deposit TestToken to FlowSwap contract
    let testReceiver = contractAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowSwapTestReceiver)
      .borrow()
      ?? panic("FlowSwap TestToken receiver not found")
    testReceiver.deposit(from: <- withdrawnTestToken)
  }
} 