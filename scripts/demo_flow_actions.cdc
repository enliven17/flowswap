import FlowSwap from 0xf8d6e0586b0a20c7

/// Demo script to showcase FlowSwap capabilities
access(all) fun main(): {String: AnyStruct} {
    let results: {String: AnyStruct} = {}
    
    // 1. Get pool information
    let FlowSwapContract = getAccount(0xf8d6e0586b0a20c7).contracts.borrow<&FlowSwap>(name: "FlowSwap")
        ?? panic("FlowSwap contract not found")
    
    let poolInfo = FlowSwapContract.getPoolInfo()
    results["poolInfo"] = poolInfo
    
    // 2. Calculate swap output for demonstration
    let swapOutput = FlowSwapContract.calculateSwapOutput(
        amountIn: 10.0,
        tokenIn: "FLOW", 
        tokenOut: "TEST"
    )
    results["swapOutput"] = swapOutput
    
    // 3. Get spot price
    let spotPrice = FlowSwapContract.getSpotPrice(tokenIn: "FLOW", tokenOut: "TEST")
    results["spotPrice"] = spotPrice
    
    // 4. Calculate optimal liquidity for 50 FLOW
    let optimalLiquidity = FlowSwapContract.calculateOptimalLiquidity(amountA: 50.0)
    results["optimalLiquidity"] = optimalLiquidity
    
    // 5. Demo information
    results["demoInfo"] = {
        "description": "FlowSwap - Next-Gen DEX with Flow Actions Ready Architecture",
        "features": [
            "AMM with constant product formula",
            "Liquidity pools with LP tokens", 
            "Real-time price calculation",
            "Slippage protection",
            "Flow Actions ready architecture"
        ],
        "currentLiquidity": poolInfo["totalLiquidity"],
        "swapFee": poolInfo["swapFee"],
        "timestamp": getCurrentBlock().timestamp,
        "blockHeight": getCurrentBlock().height
    }
    
    return results
}