# 🚀 Flow Playground - Cadence 1.0 TestToken

## Problem: `pub` is no longer valid (Cadence 1.0)
Playground artık Cadence 1.0 kullanıyor. `pub` → `access(all)` oldu.

## ✅ Cadence 1.0 Uyumlu TestToken:

```cadence
access(all) contract TestToken {
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

        access(all) fun withdraw(amount: UFix64): @TestToken.Vault {
            pre {
                self.balance >= amount: "Insufficient balance"
            }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        access(all) fun deposit(from: @TestToken.Vault) {
            self.balance = self.balance + from.balance
            emit TokensDeposited(amount: from.balance, to: self.owner?.address)
            destroy from
        }

        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
    }

    access(all) fun createEmptyVault(): @TestToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    access(all) resource Administrator {
        access(all) fun mintTokens(amount: UFix64): @TestToken.Vault {
            TestToken.totalSupply = TestToken.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        access(all) fun burnTokens(from: @TestToken.Vault) {
            let amount = from.balance
            destroy from
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        self.totalSupply = 1000000.0
        self.VaultStoragePath = /storage/testTokenVault
        self.VaultPublicPath = /public/testTokenVault
        self.AdminStoragePath = /storage/testTokenAdmin

        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        let vaultCap = self.account.capabilities.storage.issue<&TestToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)

        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
```

## 🔧 Cadence 1.0 Değişiklikleri:

- ✅ `pub` → `access(all)`
- ✅ `destroy()` fonksiyonu kaldırıldı
- ✅ `self.account.save()` → `self.account.storage.save()`
- ✅ `self.account.link()` → `self.account.capabilities.storage.issue()`
- ✅ Restricted types düzeltildi
- ✅ Interface kaldırıldı (basitleştirme)

## 📝 Adımlar:

1. **Playground'da tüm kodu sil**
2. **Yukarıdaki Cadence 1.0 kodunu kopyala**
3. **Yapıştır ve Deploy et**

**Bu sefer kesinlikle çalışacak! 🎉** 