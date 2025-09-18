"use client";

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Clock, Target, AlertCircle, CheckCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import './modern-scrollbar.css';

interface LimitOrderPanelProps {
  currentPrice: number;
  onLimitOrderCreate: (targetPrice: number, expiryHours: number) => void;
  className?: string;
}

export function LimitOrderPanel({ 
  currentPrice, 
  onLimitOrderCreate,
  className 
}: LimitOrderPanelProps) {
  const [targetPrice, setTargetPrice] = useState('');
  const [expiryHours, setExpiryHours] = useState('24');
  const [isActive, setIsActive] = useState(false);

  const targetPriceNum = parseFloat(targetPrice);
  const priceChange = targetPriceNum ? ((targetPriceNum - currentPrice) / currentPrice) * 100 : 0;
  const isValidPrice = targetPriceNum > 0;

  const handleCreateOrder = () => {
    if (isValidPrice && expiryHours) {
      onLimitOrderCreate(targetPriceNum, parseInt(expiryHours));
      setIsActive(true);
    }
  };

  return (
    <div className={cn("bg-black/60 border border-white/10 rounded-2xl p-4", className)}>
      <div className="flex items-center gap-2 mb-4">
        <Target className="w-4 h-4 text-orange-400" />
        <h3 className="text-white font-semibold text-sm">Limit Order</h3>
        {isActive && (
          <span className="text-xs bg-orange-500/20 text-orange-400 px-2 py-1 rounded-full">
            Active
          </span>
        )}
      </div>

      <div className="space-y-4">
        {/* Current Price Display */}
        <div className="flex items-center justify-between p-2 bg-white/5 rounded-lg">
          <span className="text-white/70 text-xs">Current Price</span>
          <span className="text-white text-sm font-medium">${currentPrice.toFixed(4)}</span>
        </div>

        {/* Target Price Input */}
        <div>
          <Label className="text-white/80 text-xs mb-2 block">Target Price</Label>
          <div className="relative">
            <Input
              type="number"
              step="0.0001"
              placeholder="0.0000"
              value={targetPrice}
              onChange={(e) => setTargetPrice(e.target.value)}
              className="bg-black/40 border-white/10 text-white placeholder:text-white/30 text-sm pr-12"
            />
            <span className="absolute right-3 top-1/2 -translate-y-1/2 text-white/60 text-xs">
              USD
            </span>
          </div>
          
          {/* Price Change Indicator */}
          {isValidPrice && (
            <div className="flex items-center gap-2 mt-2">
              <div className={cn(
                "text-xs px-2 py-1 rounded-full",
                priceChange > 0 
                  ? "bg-green-500/20 text-green-400" 
                  : "bg-red-500/20 text-red-400"
              )}>
                {priceChange > 0 ? '+' : ''}{priceChange.toFixed(2)}%
              </div>
              <span className="text-xs text-white/60">
                {priceChange > 0 ? 'Above' : 'Below'} current price
              </span>
            </div>
          )}
        </div>

        {/* Expiry Time */}
        <div>
          <Label className="text-white/80 text-xs mb-2 block">Expires In</Label>
          <div className="grid grid-cols-3 gap-2">
            {['1', '24', '168'].map((hours) => (
              <button
                key={hours}
                onClick={() => setExpiryHours(hours)}
                className={cn(
                  "py-2 px-3 rounded-lg text-xs font-medium transition-colors",
                  expiryHours === hours
                    ? "bg-orange-500/20 text-orange-400 border border-orange-500/30"
                    : "bg-white/5 text-white/70 border border-white/10 hover:bg-white/10"
                )}
              >
                {hours === '1' ? '1h' : hours === '24' ? '1d' : '1w'}
              </button>
            ))}
          </div>
        </div>

        {/* Order Status */}
        {isActive ? (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center gap-2 p-3 bg-orange-500/10 border border-orange-500/20 rounded-lg"
          >
            <Clock className="w-4 h-4 text-orange-400" />
            <div className="flex-1">
              <div className="text-orange-400 text-xs font-medium">Order Active</div>
              <div className="text-orange-300/80 text-xs">
                Waiting for price to reach ${targetPriceNum.toFixed(4)}
              </div>
            </div>
            <button
              onClick={() => setIsActive(false)}
              className="text-xs text-orange-400 hover:text-orange-300 underline"
            >
              Cancel
            </button>
          </motion.div>
        ) : (
          <button
            onClick={handleCreateOrder}
            disabled={!isValidPrice || !expiryHours}
            className={cn(
              "w-full py-3 rounded-lg font-medium text-sm transition-colors",
              isValidPrice && expiryHours
                ? "bg-orange-500/20 text-orange-400 hover:bg-orange-500/30 border border-orange-500/30"
                : "bg-gray-500/20 text-gray-400 cursor-not-allowed border border-gray-500/20"
            )}
          >
            Create Limit Order
          </button>
        )}

        {/* Info */}
        <div className="flex items-start gap-2 p-2 bg-blue-500/10 border border-blue-500/20 rounded-lg">
          <AlertCircle className="w-3 h-3 text-blue-400 mt-0.5 flex-shrink-0" />
          <div className="text-xs text-blue-300/80">
            Limit orders are executed automatically when the target price is reached. 
            Gas fees apply when the order is filled.
          </div>
        </div>
      </div>
    </div>
  );
}