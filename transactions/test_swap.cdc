import FlowSwap from 0xf8d6e0586b0a20c7

transaction {
  execute {
    // FLOW -> TEST swap: 10 FLOW için minimum 13 TEST bekle
    let result = FlowSwap.executeSwap(
      tokenIn: "FLOW",
      tokenOut: "TEST", 
      amountIn: 10.0,
      minAmountOut: 13.0,
      user: 0xf8d6e0586b0a20c7
    )
    log("Swap completed. Received: ".concat(result.toString()).concat(" TEST"))
  }
}