import FlowSwap from 0xf8d6e0586b0a20c7

transaction {
  execute {
    let result = FlowSwap.adminAddLiquidity(
      amountA: 100.0, 
      amountB: 150.0, 
      provider: 0xf8d6e0586b0a20c7
    )
    log("Liquidity added: ".concat(result.toString()))
  }
}