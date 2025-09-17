import { SWAP_CONSTANTS } from '@/constants/swap';

export interface ValidationResult {
  isValid: boolean;
  error?: string;
}

export function validateSwapAmount(
  amount: string,
  balance: string | number,
  tokenSymbol: string
): ValidationResult {
  const numAmount = parseFloat(amount);
  const numBalance = parseFloat(balance.toString());

  if (!amount || amount.trim() === '') {
    return { isValid: false, error: 'Amount is required' };
  }

  if (isNaN(numAmount) || numAmount <= 0) {
    return { isValid: false, error: 'Amount must be greater than 0' };
  }

  if (numAmount < SWAP_CONSTANTS.MIN_AMOUNT) {
    return { 
      isValid: false, 
      error: `Minimum amount is ${SWAP_CONSTANTS.MIN_AMOUNT} ${tokenSymbol}` 
    };
  }

  if (numAmount > numBalance) {
    return { isValid: false, error: 'Insufficient balance' };
  }

  return { isValid: true };
}

export function validateSlippage(slippage: number): ValidationResult {
  if (slippage < 0) {
    return { isValid: false, error: 'Slippage cannot be negative' };
  }

  if (slippage > SWAP_CONSTANTS.MAX_SLIPPAGE) {
    return { 
      isValid: false, 
      error: `Maximum slippage is ${SWAP_CONSTANTS.MAX_SLIPPAGE}%` 
    };
  }

  if (slippage > 10) {
    return { 
      isValid: true, 
      error: 'High slippage warning: You may lose significant value' 
    };
  }

  return { isValid: true };
}

export function isValidAddress(address: string): boolean {
  // Flow address validation - starts with 0x and is 18 characters long
  return /^0x[a-fA-F0-9]{16}$/.test(address);
}