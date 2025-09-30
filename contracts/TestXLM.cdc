import FungibleToken from 0xee82856bf20e2aa6

access(all) contract TestXLM {
    access(all) var totalSupply: UFix64
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)
    access(all) event TokensMinted(amount: UFix64)
    access(all) event TokensBurned(amount: UFix64)

    access(all) resource Vault {
        access(all) var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        access(all) fun withdraw(amount: UFix64): @TestXLM.Vault {
            pre { self.balance >= amount: "Insufficient balance" }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        access(all) fun deposit(from: @TestXLM.Vault) {
            self.balance = self.balance + from.balance
            emit TokensDeposited(amount: from.balance, to: self.owner?.address)
            destroy from
        }

        access(all) fun getBalance(): UFix64 { return self.balance }
    }

    access(all) fun createEmptyVault(): @TestXLM.Vault { return <-create Vault(balance: 0.0) }

    access(all) resource Administrator {
        access(all) fun mintTokens(amount: UFix64): @TestXLM.Vault {
            TestXLM.totalSupply = TestXLM.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }
        access(all) fun burnTokens(from: @TestXLM.Vault) {
            let amount = from.balance
            destroy from
            emit TokensBurned(amount: amount)
        }
    }

    access(all) fun mint(amount: UFix64): @Vault {
        let adminRef = self.account.storage.borrow<&Administrator>(from: self.AdminStoragePath)
            ?? panic("Admin resource not found")
        return <-adminRef.mintTokens(amount: amount)
    }

    access(all) fun mintTo(recipient: Address, amount: UFix64): @Vault {
        let adminRef = self.account.storage.borrow<&Administrator>(from: self.AdminStoragePath)
            ?? panic("Admin resource not found")
        let mintedVault <- adminRef.mintTokens(amount: amount)
        let recipientAccount = getAccount(recipient)
        let receiverRef = recipientAccount.capabilities.get<&TestXLM.Vault>(/public/testXLMVault)
            .borrow()
            ?? panic("Recipient vault not found")
        receiverRef.deposit(from: <-mintedVault)
        return <-self.createEmptyVault()
    }

    init() {
        self.totalSupply = 1000000.0
        self.VaultStoragePath = /storage/testXLMVault
        self.VaultPublicPath = /public/testXLMVault
        self.AdminStoragePath = /storage/testXLMAdmin

        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        let vaultCap = self.account.capabilities.storage.issue<&TestXLM.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)

        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}


