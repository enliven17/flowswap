import FlowSwap from 0xf8d6e0586b0a20c7

// Script to get user's LP token balance
access(all) fun main(): UFix64 {
  let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
    ?? panic("FlowSwap contract not found")
  
  return FlowSwap.getUserLPBalance(user: 0xf8d6e0586b0a20c7)
}