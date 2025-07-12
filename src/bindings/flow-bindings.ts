import { query, mutate } from "@onflow/fcl";
import { FLOW_CONFIG, FLOW_TRANSACTIONS } from "@/config/flow";
import type { FlowToken } from "@/types/tokens";

// Flow Client class to handle all Flow blockchain interactions
export class FlowSwapClient {
  private config: typeof FLOW_CONFIG;

  constructor() {
    this.config = FLOW_CONFIG;
  }

  // Get Flow balance for an address
  async getFlowBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_BALANCE,
        args: (arg: any, t: any) => [arg(address, t.Address)]
      });
      return parseFloat(result);
    } catch (error) {
      console.error("Error fetching FLOW balance:", error);
      return 0;
    }
  }

  // Get TestToken balance
  async getTestTokenBalance(address: string): Promise<number> {
    try {
      const result = await query({
        cadence: FLOW_TRANSACTIONS.GET_TEST_TOKEN_BALANCE,
        args: (arg: any, t: any) => [arg(address, t.Address)]
      });
      return parseFloat(result);
    } catch (error) {
      console.error("Error fetching TestToken balance:", error);
      // If the error indicates missing vault, return 0 instead of throwing
      if (error instanceof Error && error.message.includes("Could not borrow Vault reference")) {
        console.log("TestToken vault not set up for user, returning 0 balance");
        return 0;
      }
      return 0;
    }
  }

  // Setup TestToken vault for user
  async setupTestTokenVault(): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SETUP_TEST_TOKEN_VAULT,
        args: (arg: any, t: any) => []
      });
      return result;
    } catch (error) {
      console.error("Error setting up TestToken vault:", error);
      throw error;
    }
  }

  // Check if user has TestToken vault set up
  async hasTestTokenVault(address: string): Promise<boolean> {
    try {
      const result = await query({
        cadence: `
          import FungibleToken from 0x9a0766d93b6608b7
          import TestToken from 0xfbaa55ea2a76ff04
          
          access(all) fun main(address: Address): Bool {
            let account = getAccount(address)
            let vaultCap = account.capabilities.get<&TestToken.Vault>(/public/TestTokenBalance)
            return vaultCap.check()
          }
        `,
        args: (arg: any, t: any) => [arg(address, t.Address)]
      });
      return result === true;
    } catch (error) {
      console.error("Error checking TestToken vault:", error);
      return false;
    }
  }

  // Mint test tokens
  async mintTestTokens(amount: number): Promise<string> {
    try {
      const result = await mutate({
        cadence: `
          import FungibleToken from 0x9a0766d93b6608b7
          import TestToken from 0xfbaa55ea2a76ff04
          
          transaction(amount: UFix64) {
            prepare(signer: auth(Storage, Capabilities) &Account) {
              // Setup vault if it doesn't exist
              if signer.storage.borrow<&TestToken.Vault>(from: /storage/TestTokenVault) == nil {
                signer.storage.save(<- TestToken.createEmptyVault(vaultType: Type<@TestToken.Vault>()), to: /storage/TestTokenVault)
                signer.capabilities.publish(
                  signer.capabilities.storage.issue<&TestToken.Vault>(/storage/TestTokenVault),
                  at: /public/TestTokenReceiver
                )
                signer.capabilities.publish(
                  signer.capabilities.storage.issue<&TestToken.Vault>(/storage/TestTokenVault),
                  at: /public/TestTokenBalance
                )
              }
              
              // Get capability to the vault
              let vaultCap = signer.capabilities.get<&TestToken.Vault>(/public/TestTokenReceiver)
              
              // Mint tokens
              TestToken.mintTokens(amount: amount, recipient: vaultCap)
              
              log("Minted ".concat(amount.toString()).concat(" TestTokens"))
            }
          }
        `,
        args: (arg: any, t: any) => [arg(amount.toFixed(1), t.UFix64)]
      });
      return result;
    } catch (error) {
      console.error("Error minting test tokens:", error);
      throw error;
    }
  }

  // Swap FLOW to TestToken
  async swapFlowToTestToken(amountIn: number, minAmountOut: number): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SWAP_FLOW_TO_TEST,
        args: (arg: any, t: any) => [
          arg(amountIn.toFixed(8), t.UFix64),
          arg(minAmountOut.toFixed(8), t.UFix64),
          arg(this.config.SWAP_CONTRACT, t.Address)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error swapping FLOW to TestToken:", error);
      throw error;
    }
  }

  // Swap TestToken to FLOW
  async swapTestTokenToFlow(amountIn: number, minAmountOut: number): Promise<string> {
    try {
      const result = await mutate({
        cadence: FLOW_TRANSACTIONS.SWAP_TEST_TO_FLOW,
        args: (arg: any, t: any) => [
          arg(amountIn.toFixed(8), t.UFix64),
          arg(minAmountOut.toFixed(8), t.UFix64),
          arg(this.config.SWAP_CONTRACT, t.Address)
        ]
      });
      return result;
    } catch (error) {
      console.error("Error swapping TestToken to FLOW:", error);
      throw error;
    }
  }

  // Generic token transfer
  async transferTokens(
    tokenType: 'FLOW' | 'TEST',
    amount: number,
    recipient: string
  ): Promise<string> {
    try {
      const cadence = tokenType === 'FLOW' 
        ? this.getFlowTransferTransaction()
        : this.getTestTokenTransferTransaction();
      
      const result = await mutate({
        cadence,
        args: (arg: any, t: any) => [
          arg(recipient, t.Address),
          arg(amount.toFixed(8), t.UFix64)
        ]
      });
      return result;
    } catch (error) {
      console.error(`Error transferring ${tokenType} tokens:`, error);
      throw error;
    }
  }

  private getFlowTransferTransaction(): string {
    return `
      import FungibleToken from 0x9a0766d93b6608b7
      import FlowToken from 0x7e60df042a9c0868
      
      transaction(to: Address, amount: UFix64) {
        let sentVault: @FungibleToken.Vault
        
        prepare(signer: auth(Storage) &Account) {
          let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
          
          self.sentVault <- vaultRef.withdraw(amount: amount)
        }
        
        execute {
          let recipient = getAccount(to)
          let receiverRef = recipient.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
            .borrow()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")
          
          receiverRef.deposit(from: <-self.sentVault)
        }
      }
    `;
  }

  private getTestTokenTransferTransaction(): string {
    return `
      import FungibleToken from 0x9a0766d93b6608b7
      import TestToken from 0xfbaa55ea2a76ff04
      
      transaction(to: Address, amount: UFix64) {
        let sentVault: @FungibleToken.Vault
        
        prepare(signer: auth(Storage) &Account) {
          let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TestToken.Vault>(from: /storage/TestTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
          
          self.sentVault <- vaultRef.withdraw(amount: amount)
        }
        
        execute {
          let recipient = getAccount(to)
          let receiverRef = recipient.capabilities.get<&TestToken.Vault>(/public/TestTokenReceiver)
            .borrow()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")
          
          receiverRef.deposit(from: <-self.sentVault)
        }
      }
    `;
  }
}

// Create and export a singleton instance
export const flowSwapClient = new FlowSwapClient();

// Default tokens configuration
export const defaultTokens: FlowToken[] = [
  {
    symbol: "FLOW",
    name: "Flow",
    icon: "/flow.svg",
    address: FLOW_CONFIG.FLOW_TOKEN,
    balance: 0,
    price: 1.5, // Mock price
    decimals: 8
  },
  {
    symbol: "TEST",
    name: "Test Token",
    icon: "/test-token.svg",
    address: FLOW_CONFIG.TEST_TOKEN,
    balance: 0,
    price: 1, // Test token price
    decimals: 8
  }
]; 