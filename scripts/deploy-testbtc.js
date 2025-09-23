#!/usr/bin/env node

import { execSync } from 'node:child_process';

function run(cmd) {
  console.log(`$ ${cmd}`);
  execSync(cmd, { stdio: 'inherit' });
}

try {
  // Assumes flow.json has a contract named TestBTC and an account alias (e.g., emulator-account or testnet-account)
  const account = process.env.FLOW_ACCOUNT || 'testnet-account';
  // Deploy TestBTC contract
  run(`flow project deploy --update --network testnet --include contracts/TestBTC.cdc --account ${account}`);

  console.log('✅ TestBTC deployed. If needed, set VITE_TESTBTC_ADDRESS in .env');
} catch (e) {
  console.error('❌ Failed to deploy TestBTC:', e.message);
  process.exit(1);
}
