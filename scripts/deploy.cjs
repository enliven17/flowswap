#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Flow CLI deployment script for FlowSwap contract
console.log('🚀 Deploying FlowSwap contract to Flow testnet...\n');

// Configuration
const CONTRACT_NAME = 'FlowSwap';
const CONTRACT_PATH = path.join(__dirname, '../contracts/FlowSwap.cdc');
const NETWORK = 'testnet';

// Check if Flow CLI is installed
try {
  execSync('flow version', { stdio: 'pipe' });
  console.log('✅ Flow CLI is installed');
} catch (error) {
  console.error('❌ Flow CLI is not installed. Please install it first:');
  console.error('   https://docs.onflow.org/flow-cli/install/');
  process.exit(1);
}

// Check if contract file exists
if (!fs.existsSync(CONTRACT_PATH)) {
  console.error(`❌ Contract file not found: ${CONTRACT_PATH}`);
  process.exit(1);
}

// Initialize Flow project if not already done
try {
  if (!fs.existsSync('flow.json')) {
    console.log('📁 Initializing Flow project...');
    execSync('flow init', { stdio: 'inherit' });
  }
} catch (error) {
  console.error('❌ Failed to initialize Flow project:', error.message);
  process.exit(1);
}

// Deploy contract
try {
  console.log(`📦 Deploying ${CONTRACT_NAME} contract...`);
  
  const deployCommand = `flow deploy ${CONTRACT_PATH} --network=${NETWORK}`;
  console.log(`Running: ${deployCommand}`);
  
  const result = execSync(deployCommand, { 
    encoding: 'utf8',
    stdio: 'inherit'
  });
  
  console.log('\n✅ Contract deployed successfully!');
  console.log('\n📋 Next steps:');
  console.log('1. Update the SWAP_CONTRACT address in src/config/flow.ts');
  console.log('2. Test the contract with sample transactions');
  console.log('3. Add liquidity to the pool');
  
} catch (error) {
  console.error('❌ Deployment failed:', error.message);
  process.exit(1);
}

// Helper function to extract contract address from deployment output
function extractContractAddress(output) {
  const match = output.match(/Deployed Contract To: (0x[a-fA-F0-9]+)/);
  return match ? match[1] : null;
}

console.log('\n🎉 FlowSwap deployment script completed!'); 