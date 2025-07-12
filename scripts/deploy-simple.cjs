const fs = require('fs');
const path = require('path');

console.log('🚀 Simple TestToken Deployment Guide');
console.log('=====================================');
console.log('');
console.log('Since Flow CLI requires private keys, you can deploy the contract using:');
console.log('');
console.log('1. 📱 Use Blocto Wallet or any Flow wallet');
console.log('2. 📝 Copy the TestToken contract code:');
console.log('');

const testTokenCode = fs.readFileSync('./contracts/TestToken.cdc', 'utf8');
console.log(testTokenCode);

console.log('');
console.log('3. 🔧 Deploy to address: 0xfbaa55ea2a76ff04');
console.log('4. 📋 After deployment, update the frontend with the correct address');
console.log('');
console.log('Alternative: Use Flow Playground (https://play.onflow.org)');
console.log('- Switch to Testnet');
console.log('- Paste the contract code');
console.log('- Deploy to your account');
console.log('- Update the address in src/config/flow.ts'); 