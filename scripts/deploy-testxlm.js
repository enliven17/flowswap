#!/usr/bin/env node

import { execSync } from 'node:child_process';

function run(cmd) {
  console.log(`$ ${cmd}`);
  execSync(cmd, { stdio: 'inherit' });
}

try {
  const account = process.env.FLOW_ACCOUNT || 'testnet-account';
  // Deploy TestXLM contract
  run(`flow project deploy --update --network testnet --include contracts/TestXLM.cdc --account ${account}`);

  console.log('✅ TestXLM deployed. If needed, set VITE_TEST_XLM_ADDRESS in .env');
} catch (e) {
  console.error('❌ Failed to deploy TestXLM:', e.message);
  process.exit(1);
}


