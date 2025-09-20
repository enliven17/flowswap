// Test script for Cadence contracts
import { FlowSwapClient } from './src/bindings/flow-bindings.ts';

async function testContracts() {
  console.log('🧪 Testing Cadence Contracts...\n');
  
  const client = new FlowSwapClient();
  
  try {
    // Test 1: Get Pool Info
    console.log('📊 Testing Pool Info...');
    const poolInfo = await client.getPoolInfo();
    console.log('Pool Info:', poolInfo);
    console.log('✅ Pool info test passed\n');
    
    // Test 2: Get LP Balance (with test address)
    console.log('💰 Testing LP Balance...');
    const testAddress = '0x0c0c904844c9a720'; // Contract address for testing
    const lpBalance = await client.getLPBalance(testAddress);
    console.log('LP Balance:', lpBalance);
    console.log('✅ LP balance test passed\n');
    
    console.log('🎉 All contract tests passed!');
    
  } catch (error) {
    console.error('❌ Contract test failed:', error);
    
    // Detailed error analysis
    if (error.message.includes('FlowSwap')) {
      console.log('💡 Suggestion: Make sure FlowSwap contract is deployed');
    }
    if (error.message.includes('getFlowReserve')) {
      console.log('💡 Suggestion: Check if pool functions exist in contract');
    }
    if (error.message.includes('capabilities')) {
      console.log('💡 Suggestion: Check capability setup in contract');
    }
  }
}

// Run tests
testContracts();