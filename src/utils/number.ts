export function parseDecimal(input: string, maxDecimals = 8): string {
  const sanitized = input.replace(/[^0-9.]/g, '');
  if (!sanitized) return '';
  const parts = sanitized.split('.');
  if (parts.length === 1) return parts[0].replace(/^0+(?=\d)/, '0');
  const intPart = parts[0] || '0';
  const fracPart = (parts[1] || '').slice(0, maxDecimals);
  return `${intPart}.${fracPart}`.replace(/^0+(?=\d)/, '0');
}

export function clamp(value: number, min: number, max: number): number {
  if (Number.isNaN(value)) return min;
  return Math.min(max, Math.max(min, value));
}

export function formatWithMaxDigits(value: number | string, maxDigits = 8): string {
  const num = typeof value === 'string' ? Number(value) : value;
  if (!Number.isFinite(num)) return '0';
  return num.toLocaleString(undefined, { maximumFractionDigits: maxDigits });
}
