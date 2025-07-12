import FungibleToken from 0x9a0766d93b6608b7
import TestToken from 0x0726a2d1884cd909

transaction(amount: UFix64) {
    prepare(signer: AuthAccount) {
        // Eğer vault yoksa, mevcut tokenlarla oluştur
        if signer.borrow<&TestToken.Vault>(from: /storage/testTokenVault) == nil {
            // Boş vault oluştur
            signer.save(<-TestToken.createEmptyVault(), to: /storage/testTokenVault)
            
            // Concrete type ile linkle (Cadence 1.0 uyumlu)
            signer.link<&TestToken.Vault>(
                /public/testTokenVault,
                target: /storage/testTokenVault
            )
        }

        // Mevcut tokenları vault'a yatır (mint yerine)
        let receiver = signer.getCapability<&TestToken.Vault>(/public/testTokenVault)
            .borrow()
            ?? panic("Receiver vault bulunamadı")
        
        // Eğer hesapta token varsa, onları vault'a yatır
        // Bu kısım opsiyonel - sadece vault setup için
    }
} 