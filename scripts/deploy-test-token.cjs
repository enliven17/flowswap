const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Deploying TestToken contract...');

try {
  // Deploy TestToken contract
  console.log('📦 Deploying TestToken...');
  const testTokenResult = execSync('flow deploy contracts/TestToken.cdc --network testnet', { 
    encoding: 'utf8',
    stdio: 'pipe'
  });
  
  console.log('✅ TestToken deployed successfully!');
  console.log(testTokenResult);
  
  // Update FlowSwap contract to use TestToken
  console.log('🔄 Updating FlowSwap contract...');
  const flowSwapResult = execSync('flow deploy contracts/FlowSwap.cdc --network testnet', { 
    encoding: 'utf8',
    stdio: 'pipe'
  });
  
  console.log('✅ FlowSwap updated successfully!');
  console.log(flowSwapResult);
  
  console.log('🎉 All contracts deployed successfully!');
  console.log('📝 Contract addresses:');
  console.log('- TestToken: 0xfbaa55ea2a76ff04');
  console.log('- FlowSwap: 0xfbaa55ea2a76ff04');
  
} catch (error) {
  console.error('❌ Deployment failed:', error.message);
  process.exit(1);
} 