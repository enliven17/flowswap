/**
 * Format number with appropriate decimal places
 */
export function formatNumber(value: string | number, decimals: number = 4): string {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '0';
  if (num <= 0) return '0';
  if (num < 0.0001) return '< 0.0001';
  return num.toFixed(decimals);
}

/**
 * Format USD value
 */
export function formatUSD(value: string | number): string {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num) || num <= 0) return '$0.00';
  return `$${num.toFixed(2)}`;
}

/**
 * Format short number (K, M, B)
 */
export function formatShortNumber(value: string | number): string {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '';
  if (num >= 1e9) return (num / 1e9).toFixed(2) + 'B';
  if (num >= 1e6) return (num / 1e6).toFixed(2) + 'M';
  if (num >= 1e3) return (num / 1e3).toFixed(2) + 'K';
  return num.toFixed(2);
}