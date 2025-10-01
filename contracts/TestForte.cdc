import FungibleToken from 0xee82856bf20e2aa6

access(all) contract TestForte {
    access(all) var totalSupply: UFix64
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // Flow Actions için özel event'ler
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)
    access(all) event TokensMinted(amount: UFix64, recipient: Address?)
    access(all) event TokensBurned(amount: UFix64, from: Address?)
    access(all) event ActionExecuted(actionType: String, amount: UFix64, user: Address?)

    access(all) resource Vault {
        access(all) var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        access(all) fun withdraw(amount: UFix64): @TestForte.Vault {
            pre {
                self.balance >= amount: "Insufficient balance in TestForte vault"
            }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        access(all) fun deposit(from: @TestForte.Vault) {
            let depositAmount = from.balance
            self.balance = self.balance + depositAmount
            emit TokensDeposited(amount: depositAmount, to: self.owner?.address)
            destroy from
        }

        access(all) fun getBalance(): UFix64 {
            return self.balance
        }

        // Flow Actions için özel fonksiyon
        access(all) fun executeAction(actionType: String, amount: UFix64) {
            emit ActionExecuted(actionType: actionType, amount: amount, user: self.owner?.address)
        }
    }

    access(all) fun createEmptyVault(): @TestForte.Vault {
        return <-create Vault(balance: 0.0)
    }

    access(all) resource Administrator {
        access(all) fun mintTokens(amount: UFix64): @TestForte.Vault {
            TestForte.totalSupply = TestForte.totalSupply + amount
            emit TokensMinted(amount: amount, recipient: nil)
            return <-create Vault(balance: amount)
        }

        access(all) fun burnTokens(from: @TestForte.Vault) {
            let amount = from.balance
            TestForte.totalSupply = TestForte.totalSupply - amount
            emit TokensBurned(amount: amount, from: nil)
            destroy from
        }

        // Flow Actions için gelişmiş mint fonksiyonu
        access(all) fun mintToAddress(recipient: Address, amount: UFix64) {
            let mintedVault <- self.mintTokens(amount: amount)
            let recipientAccount = getAccount(recipient)
            
            // Recipient'in vault'unu kontrol et
            if let receiverRef = recipientAccount.capabilities.get<&TestForte.Vault>(/public/testForteVault).borrow() {
                receiverRef.deposit(from: <-mintedVault)
                emit TokensMinted(amount: amount, recipient: recipient)
            } else {
                // Eğer vault yoksa, token'ları geri yak
                self.burnTokens(from: <-mintedVault)
                panic("Recipient does not have TestForte vault set up")
            }
        }
    }

    // Flow Actions için public mint fonksiyonu
    access(all) fun mint(amount: UFix64): @Vault {
        let adminRef = self.account.storage.borrow<&Administrator>(from: self.AdminStoragePath)
            ?? panic("TestForte Admin resource not found")
        return <-adminRef.mintTokens(amount: amount)
    }

    // Flow Actions için gelişmiş mint fonksiyonu
    access(all) fun mintTo(recipient: Address, amount: UFix64) {
        let adminRef = self.account.storage.borrow<&Administrator>(from: self.AdminStoragePath)
            ?? panic("TestForte Admin resource not found")
        adminRef.mintToAddress(recipient: recipient, amount: amount)
    }

    // Flow Actions için batch mint fonksiyonu
    access(all) fun batchMint(recipients: [Address], amounts: [UFix64]) {
        pre {
            recipients.length == amounts.length: "Recipients and amounts arrays must have same length"
        }
        
        let adminRef = self.account.storage.borrow<&Administrator>(from: self.AdminStoragePath)
            ?? panic("TestForte Admin resource not found")
        
        var i = 0
        while i < recipients.length {
            adminRef.mintToAddress(recipient: recipients[i], amount: amounts[i])
            i = i + 1
        }
    }

    // Flow Actions için utility fonksiyonlar
    access(all) fun getTotalSupply(): UFix64 {
        return self.totalSupply
    }

    access(all) fun getBalance(address: Address): UFix64 {
        let account = getAccount(address)
        if let vaultRef = account.capabilities.get<&TestForte.Vault>(/public/testForteVault).borrow() {
            return vaultRef.getBalance()
        }
        return 0.0
    }

    // Flow Actions için transfer fonksiyonu
    access(all) fun transfer(from: Address, to: Address, amount: UFix64) {
        let fromAccount = getAccount(from)
        let toAccount = getAccount(to)
        
        let fromVaultRef = fromAccount.capabilities.get<&TestForte.Vault>(/public/testForteVault).borrow()
            ?? panic("From address does not have TestForte vault")
        
        let toVaultRef = toAccount.capabilities.get<&TestForte.Vault>(/public/testForteVault).borrow()
            ?? panic("To address does not have TestForte vault")
        
        let transferVault <- fromVaultRef.withdraw(amount: amount)
        toVaultRef.deposit(from: <-transferVault)
        
        emit ActionExecuted(actionType: "transfer", amount: amount, user: from)
    }

    init() {
        self.totalSupply = 1000000.0
        self.VaultStoragePath = /storage/testForteVault
        self.VaultPublicPath = /public/testForteVault
        self.AdminStoragePath = /storage/testForteAdmin

        // Initial vault oluştur
        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        // Public capability yayınla
        let vaultCap = self.account.capabilities.storage.issue<&TestForte.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)

        // Admin resource oluştur
        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}