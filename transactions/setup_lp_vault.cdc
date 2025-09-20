import FungibleToken from 0xee82856bf20e2aa6
import FlowSwap from 0xf8d6e0586b0a20c7

// Transaction to set up LP token vault for user
transaction {
  prepare(signer: auth(Storage, Capabilities) &Account) {
    // Check if LP vault already exists
    if signer.storage.borrow<&FlowSwap.LPTokenVault>(from: /storage/lpTokenVault) != nil {
      log("LP token vault already exists")
      return
    }
    
    // Create new LP token vault
    let lpVault <- FlowSwap.createEmptyLPVault()
    
    // Store the vault in storage
    signer.storage.save(<- lpVault, to: /storage/lpTokenVault)
    
    // Create public capability for balance checking
    let lpBalanceCap = signer.capabilities.storage.issue<&FlowSwap.LPTokenVault>(/storage/lpTokenVault)
    signer.capabilities.publish(lpBalanceCap, at: /public/lpTokenBalance)
    
    // Create public capability for receiving LP tokens
    let lpReceiverCap = signer.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/lpTokenVault)
    signer.capabilities.publish(lpReceiverCap, at: /public/lpTokenReceiver)
    
    log("LP token vault set up successfully")
  }

  execute {
    log("LP vault setup transaction completed")
  }
}