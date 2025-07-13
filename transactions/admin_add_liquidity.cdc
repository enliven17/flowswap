import FlowSwap from 0x0c0c904844c9a720

transaction(amountFlow: UFix64, amountTestToken: UFix64) {
  execute {
    // Call adminAddLiquidity function
    FlowSwap.adminAddLiquidity(amountA: amountFlow, amountB: amountTestToken, provider: 0x0c0c904844c9a720)
  }
} 