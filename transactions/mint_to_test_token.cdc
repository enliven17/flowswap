import FungibleToken from 0x9a0766d93b6608b7
import TestToken from 0x0726a2d1884cd909

transaction(recipient: Address, amount: UFix64) {
    prepare(signer: AuthAccount) {
        TestToken.mintTo(recipient: recipient, amount: amount)
    }
} 