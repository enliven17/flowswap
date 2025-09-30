#!/usr/bin/env node

import { execSync } from 'node:child_process';

function run(cmd) {
  console.log(`$ ${cmd}`);
  execSync(cmd, { stdio: 'inherit' });
}

try {
  const account = process.env.FLOW_ACCOUNT || 'testnet-account';
  // Deploy TestMETU contract
  run(`flow project deploy --update --network testnet --include contracts/TestMETU.cdc --account ${account}`);

  console.log('✅ TestMETU deployed. If needed, set VITE_TEST_METU_ADDRESS in .env');
} catch (e) {
  console.error('❌ Failed to deploy TestMETU:', e.message);
  process.exit(1);
}

