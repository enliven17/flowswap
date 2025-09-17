export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export function lerp(start: number, end: number, factor: number): number {
  return start + (end - start) * factor;
}

export function roundTo(value: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
}

export function percentage(value: number, total: number): number {
  if (total === 0) return 0;
  return (value / total) * 100;
}

export function calculatePriceImpact(
  inputAmount: number,
  outputAmount: number,
  expectedOutput: number
): number {
  if (expectedOutput === 0) return 0;
  return ((expectedOutput - outputAmount) / expectedOutput) * 100;
}

export function calculateSlippage(
  expectedAmount: number,
  actualAmount: number
): number {
  if (expectedAmount === 0) return 0;
  return Math.abs((expectedAmount - actualAmount) / expectedAmount) * 100;
}

export function formatPercentage(value: number, decimals: number = 2): string {
  return `${roundTo(value, decimals)}%`;
}

export function isValidNumber(value: unknown): value is number {
  return typeof value === 'number' && !isNaN(value) && isFinite(value);
}

export function safeParseFloat(value: string): number {
  const parsed = parseFloat(value);
  return isValidNumber(parsed) ? parsed : 0;
}