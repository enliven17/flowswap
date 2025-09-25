#!/usr/bin/env node

import { execSync } from 'node:child_process';

function run(cmd) {
  console.log(`$ ${cmd}`);
  execSync(cmd, { stdio: 'inherit' });
}

try {
  const account = process.env.FLOW_ACCOUNT || 'testnet-account';
  // Deploy TestETH contract
  run(`flow project deploy --update --network testnet --include contracts/TestETH.cdc --account ${account}`);

  console.log('✅ TestETH deployed. If needed, set VITE_TEST_ETH_ADDRESS in .env');
} catch (e) {
  console.error('❌ Failed to deploy TestETH:', e.message);
  process.exit(1);
}


