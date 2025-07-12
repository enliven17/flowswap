import TestToken from 0x0726a2d1884cd909

transaction(amount: UFix64) {
    prepare(signer: AuthAccount) {
        // Public capability'yi kullanarak vault'a eriş
        let vaultCap = signer.capabilities.get<&TestToken.Vault>(/public/testTokenVault)
        let vault = vaultCap.borrow()
            ?? panic("TestToken vault capability borrow failed")
        // Mint işlemi yap
        let mintedVault <- TestToken.mint(amount: amount)
        // Mint edilen token'ları vault'a deposit et
        vault.deposit(from: <-mintedVault)
    }
} 