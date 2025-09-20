import FlowSwap from 0xf8d6e0586b0a20c7

// Script to calculate swap output for 10 FLOW -> TEST
access(all) fun main(): UFix64 {
  let FlowSwap = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
    ?? panic("FlowSwap contract not found")
  
  return FlowSwap.calculateSwapOutput(amountIn: 10.0, tokenIn: "FLOW", tokenOut: "TEST")
}