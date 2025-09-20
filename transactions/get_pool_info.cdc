import FlowSwap from 0xf8d6e0586b0a20c7

// Script to get pool information
access(all) fun main(): {String: AnyStruct} {
  // Get contract reference
  let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
    ?? panic("FlowSwap contract not found")
  
  return FlowSwap.getPoolInfo()
}