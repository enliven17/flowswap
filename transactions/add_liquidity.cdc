import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TestToken from 0x0726a2d1884cd909
import FlowSwap from 0x0726a2d1884cd909

transaction(amountFlow: UFix64, amountTestToken: UFix64) {
  prepare(signer: AuthAccount) {
    let contractAddr = 0x0726a2d1884cd909
    let contractAccount = getAccount(contractAddr)

    // Withdraw FLOW
    let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("No Flow vault")
    let withdrawnFlow <- flowVault.withdraw(amount: amountFlow)
    let flowReceiver = contractAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowSwapFlowReceiver).borrow() ?? panic("No receiver")
    flowReceiver.deposit(from: <-withdrawnFlow)

    // Withdraw TestToken
    let testTokenVault = signer.borrow<&TestToken.Vault>(from: /storage/testTokenVault) ?? panic("No TestToken vault")
    let withdrawnTestToken <- testTokenVault.withdraw(amount: amountTestToken)
    let testTokenReceiver = contractAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowSwapTestReceiver).borrow() ?? panic("No receiver")
    testTokenReceiver.deposit(from: <-withdrawnTestToken)

    // Call addLiquidity
    FlowSwap.addLiquidity(amountA: amountFlow, amountB: amountTestToken, provider: signer.address)
  }
} 