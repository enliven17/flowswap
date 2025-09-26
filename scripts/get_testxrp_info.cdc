import TestXRP from 0xf8d6e0586b0a20c7

/// Script to get comprehensive TestXRP token information
access(all) fun main(userAddress: Address?): {String: AnyStruct} {
    let results: {String: AnyStruct} = {}
    
    // Get basic token information
    let tokenInfo = TestXRP.getTokenInfo()
    results["tokenInfo"] = tokenInfo
    
    // Get user-specific information if address provided
    if let address = userAddress {
        let account = getAccount(address)
        
        // Check if user has TestXRP vault
        let hasVault = account.capabilities.get<&TestXRP.Vault>(TestXRP.VaultPublicPath).check()
        results["hasVault"] = hasVault
        
        if hasVault {
            // Get user balance
            let vaultRef = account.capabilities.get<&TestXRP.Vault>(TestXRP.VaultPublicPath)
                .borrow()
            
            if vaultRef != nil {
                results["balance"] = vaultRef!.getBalance()
                results["canWithdrawAll"] = vaultRef!.isAvailableToWithdraw(amount: vaultRef!.getBalance())
                results["availableToWithdraw"] = vaultRef!.getBalance() - TestXRP.getMinimumReserve()
            }
        } else {
            results["balance"] = 0.0
            results["canWithdrawAll"] = false
            results["availableToWithdraw"] = 0.0
        }
        
        // Get user's escrows
        let userEscrows = TestXRP.getEscrowsForAddress(address: address)
        results["escrows"] = userEscrows
        results["escrowCount"] = userEscrows.length
        
        // Calculate total escrowed amount
        var totalEscrowed: UFix64 = 0.0
        for escrow in userEscrows {
            if !escrow.isReleased {
                totalEscrowed = totalEscrowed + escrow.amount
            }
        }
        results["totalEscrowed"] = totalEscrowed
    }
    
    // Get bridge status
    results["bridgeEnabled"] = TestXRP.isBridgeEnabled()
    results["minimumReserve"] = TestXRP.getMinimumReserve()
    
    // Get network information
    results["networkInfo"] = {
        "blockHeight": getCurrentBlock().height,
        "timestamp": getCurrentBlock().timestamp,
        "contractAddress": TestXRP.account.address.toString()
    }
    
    return results
}