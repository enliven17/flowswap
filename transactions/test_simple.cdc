transaction() {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    // Just a simple transaction to test signing
  }
  
  execute {
    log("Test transaction executed successfully")
  }
} 