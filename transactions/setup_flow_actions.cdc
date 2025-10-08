import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
import TestToken from 0xf8d6e0586b0a20c7
import FlowSwapCallbackHandler from 0xf8d6e0586b0a20c7
import FlowCallbackScheduler from 0xf8d6e0586b0a20c7
import DeFiActions from 0xf8d6e0586b0a20c7
import FungibleTokenConnectors from 0xf8d6e0586b0a20c7

/// Setup Flow Actions and Scheduled Callbacks for FlowSwap
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Setup FlowSwap callback handler if not exists
        if signer.storage.borrow<&AnyResource>(from: /storage/FlowSwapCallbackHandler) == nil {
            let handler <- FlowSwapCallbackHandler.createHandler()
            signer.storage.save(<-handler, to: /storage/FlowSwapCallbackHandler)
            log("FlowSwap callback handler created and saved")
        }
        
        // Create and test handler capability
        let handlerCap = signer.capabilities.storage
            .issue<auth(FlowCallbackScheduler.Execute) &{FlowCallbackScheduler.CallbackHandler}>(/storage/FlowSwapCallbackHandler)
        
        // Verify capability works
        if handlerCap.check() {
            log("FlowSwap callback handler capability verified")
        } else {
            log("Warning: FlowSwap callback handler capability failed verification")
        }
        
        // Ensure user has proper token vaults setup
        // FLOW vault should already exist, but let's verify
        if signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {
            log("Warning: FLOW vault not found")
        }
        
        // Setup TestToken vault if not exists
        if signer.storage.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
            signer.storage.save(<-TestToken.createEmptyVault(), to: /storage/testTokenVault)
            
            let receiverCap = signer.capabilities.storage.issue<&TestToken.Vault>(/storage/testTokenVault)
            signer.capabilities.publish(receiverCap, at: /public/testTokenVault)
            
            log("TestToken vault created and capability published")
        }
        
        // Test DeFi Actions functionality
        let uniqueID = DeFiActions.createUniqueIdentifier()
        log("Created unique identifier: ".concat(uniqueID.toString()))
        
        // Test FungibleTokenConnectors
        let withdrawCap = signer.capabilities.storage.issue<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(/storage/flowTokenVault)
        let source = FungibleTokenConnectors.VaultSource(
            min: 0.0,
            withdrawVault: withdrawCap,
            uniqueID: uniqueID
        )
        log("VaultSource created successfully")
        
        let depositCap = signer.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenReceiver)
        let sink = FungibleTokenConnectors.VaultSink(
            max: nil,
            depositVault: depositCap,
            uniqueID: uniqueID
        )
        log("VaultSink created successfully")
        
        log("Flow Actions setup completed successfully")
    }
    
    execute {
        log("Flow Actions and Scheduled Callbacks are ready for FlowSwap")
    }
}