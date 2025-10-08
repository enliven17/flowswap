const fcl = require("@onflow/fcl");

// Configure FCL for emulator
fcl.config({
  "accessNode.api": "http://localhost:8888",
  "discovery.wallet": "http://localhost:8701/fcl/authn"
});

async function testFlowActions() {
  console.log("🚀 Testing Flow Actions Integration...\n");

  try {
    // Test 1: Create Unique Identifier
    console.log("1️⃣ Testing Unique Identifier Creation...");
    const uniqueIdResult = await fcl.query({
      cadence: `
        import DeFiActions from 0xf8d6e0586b0a20c7
        
        access(all) fun main(): String {
          let uniqueID = DeFiActions.createUniqueIdentifier()
          return uniqueID.toString()
        }
      `
    });
    console.log("✅ Unique ID created:", uniqueIdResult);

    // Test 2: Get Operation Stats
    console.log("\n2️⃣ Testing FlowSwap Callback Handler Stats...");
    const statsResult = await fcl.query({
      cadence: `
        import FlowSwapCallbackHandler from 0xf8d6e0586b0a20c7
        
        access(all) fun main(): {String: AnyStruct} {
          return FlowSwapCallbackHandler.getOperationStats()
        }
      `
    });
    console.log("✅ Operation stats:", statsResult);

    // Test 3: Test Fee Estimation
    console.log("\n3️⃣ Testing Callback Fee Estimation...");
    const feeEstimate = await fcl.query({
      cadence: `
        import FlowCallbackScheduler from 0xf8d6e0586b0a20c7
        
        access(all) fun main(): FlowCallbackScheduler.FeeEstimate {
          let data: {String: AnyStruct} = {
            "tokenIn": "FLOW",
            "tokenOut": "TEST",
            "amountIn": 1.0,
            "userAddress": 0xf8d6e0586b0a20c7
          }
          
          return FlowCallbackScheduler.estimate(
            data: data,
            timestamp: getCurrentBlock().timestamp + 300.0,
            priority: FlowCallbackScheduler.Priority.Medium,
            executionEffort: 2000
          )
        }
      `
    });
    console.log("✅ Fee estimate:", feeEstimate);

    // Test 4: Test Pool Info
    console.log("\n4️⃣ Testing FlowSwap Pool Info...");
    const poolInfo = await fcl.query({
      cadence: `
        import FlowSwap from 0xf8d6e0586b0a20c7
        
        access(all) fun main(): {String: AnyStruct} {
          return FlowSwap.getPoolInfo()
        }
      `
    });
    console.log("✅ Pool info:", poolInfo);

    console.log("\n🎉 All Flow Actions tests completed successfully!");

  } catch (error) {
    console.error("❌ Test failed:", error);
    process.exit(1);
  }
}

// Run tests
testFlowActions();