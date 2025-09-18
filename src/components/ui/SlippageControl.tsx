import * as React from 'react';
import { clamp, parseDecimal } from '@/utils/number';
import { cn } from '@/lib/utils';

type Props = {
  value: number;
  onChange: (next: number) => void;
  className?: string;
  presets?: number[];
  max?: number;
  min?: number;
};

export function SlippageControl({
  value,
  onChange,
  className,
  presets = [0.1, 0.5, 1],
  max = 50,
  min = 0.01,
}: Props) {
  const [custom, setCustom] = React.useState('');

  const apply = (v: number) => onChange(clamp(Number(v), min, max));

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <div className="flex items-center gap-2">
        {presets.map((p) => {
          const isActive = Math.abs(value - p) < 1e-9;
          return (
            <button
              key={p}
              type="button"
              aria-pressed={isActive}
              onClick={() => apply(p)}
              className={cn(
                'px-3 py-1 rounded-md border text-sm transition-colors',
                isActive
                  ? 'bg-white text-black border-white'
                  : 'bg-transparent text-white/80 border-white/40 hover:bg-white/10'
              )}
            >
              {p}%
            </button>
          );
        })}
        <div className="flex items-center gap-2">
          <input
            type="text"
            inputMode="decimal"
            placeholder="Custom"
            aria-label="Custom slippage"
            value={custom}
            onChange={(e) => setCustom(parseDecimal(e.target.value, 2))}
            className="w-20 bg-transparent border border-white/40 text-white/90 rounded-md px-2 py-1 text-sm placeholder:text-white/40"
          />
          <button
            type="button"
            className="px-2 py-1 text-sm border border-white/40 text-white/90 rounded-md hover:bg-white/10"
            onClick={() => {
              const n = Number(custom);
              if (Number.isFinite(n)) apply(n);
            }}
          >
            Set
          </button>
        </div>
      </div>
      <div className="text-xs text-white/70">Current slippage: {value}%</div>
    </div>
  );
}
