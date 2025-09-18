"use client";

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Fuel, Zap, Clock, TrendingUp } from 'lucide-react';
import { cn } from '@/lib/utils';
import './modern-scrollbar.css';

interface GasFeeOption {
  id: string;
  name: string;
  description: string;
  estimatedTime: string;
  gasPrice: number;
  totalCost: string;
  icon: React.ReactNode;
  recommended?: boolean;
}

interface GasFeeEstimatorProps {
  selectedSpeed: string;
  onSpeedChange: (speedId: string) => void;
  className?: string;
}

export function GasFeeEstimator({ 
  selectedSpeed, 
  onSpeedChange,
  className 
}: GasFeeEstimatorProps) {
  const [gasOptions, setGasOptions] = useState<GasFeeOption[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Simulate gas price fetching
  useEffect(() => {
    const fetchGasPrices = async () => {
      setIsLoading(true);
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const baseGasPrice = 0.001; // Base FLOW price
      const options: GasFeeOption[] = [
        {
          id: 'slow',
          name: 'Slow',
          description: 'Lower cost, longer wait',
          estimatedTime: '~2-5 min',
          gasPrice: baseGasPrice * 0.8,
          totalCost: `${(baseGasPrice * 0.8).toFixed(4)} FLOW`,
          icon: <Clock className="w-4 h-4 text-gray-400" />
        },
        {
          id: 'standard',
          name: 'Standard',
          description: 'Balanced speed and cost',
          estimatedTime: '~1-2 min',
          gasPrice: baseGasPrice,
          totalCost: `${baseGasPrice.toFixed(4)} FLOW`,
          icon: <Zap className="w-4 h-4 text-blue-400" />,
          recommended: true
        },
        {
          id: 'fast',
          name: 'Fast',
          description: 'Higher cost, faster execution',
          estimatedTime: '~30-60 sec',
          gasPrice: baseGasPrice * 1.5,
          totalCost: `${(baseGasPrice * 1.5).toFixed(4)} FLOW`,
          icon: <TrendingUp className="w-4 h-4 text-green-400" />
        }
      ];
      
      setGasOptions(options);
      setIsLoading(false);
    };

    fetchGasPrices();
  }, []);

  const selectedOption = gasOptions.find(option => option.id === selectedSpeed);

  if (isLoading) {
    return (
      <div className={cn("bg-black/60 border border-white/10 rounded-2xl p-4", className)}>
        <div className="flex items-center gap-2 mb-4">
          <Fuel className="w-4 h-4 text-blue-400" />
          <h3 className="text-white font-semibold text-sm">Network Fee</h3>
        </div>
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="animate-pulse">
              <div className="h-12 bg-white/5 rounded-lg"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className={cn("bg-black/60 border border-white/10 rounded-2xl p-4", className)}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Fuel className="w-4 h-4 text-blue-400" />
          <h3 className="text-white font-semibold text-sm">Network Fee</h3>
        </div>
        {selectedOption && (
          <span className="text-xs text-white/60">
            {selectedOption.estimatedTime}
          </span>
        )}
      </div>

      <div className="space-y-2">
        {gasOptions.map((option) => (
          <motion.button
            key={option.id}
            onClick={() => onSpeedChange(option.id)}
            className={cn(
              "w-full flex items-center justify-between p-3 rounded-lg transition-colors text-left",
              selectedSpeed === option.id
                ? "bg-blue-500/20 border border-blue-500/30"
                : "bg-white/5 border border-white/10 hover:bg-white/10"
            )}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <div className="flex items-center gap-3">
              {option.icon}
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-white text-sm font-medium">{option.name}</span>
                  {option.recommended && (
                    <span className="text-xs bg-green-500/20 text-green-400 px-2 py-0.5 rounded-full">
                      Recommended
                    </span>
                  )}
                </div>
                <div className="text-white/60 text-xs">{option.description}</div>
              </div>
            </div>
            
            <div className="text-right">
              <div className="text-white text-sm font-medium">{option.totalCost}</div>
              <div className="text-white/60 text-xs">{option.estimatedTime}</div>
            </div>
          </motion.button>
        ))}
      </div>

      {/* Current Selection Summary */}
      {selectedOption && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-4 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg"
        >
          <div className="flex items-center justify-between">
            <span className="text-blue-300 text-xs">Selected: {selectedOption.name}</span>
            <span className="text-blue-300 text-xs font-medium">{selectedOption.totalCost}</span>
          </div>
          <div className="text-blue-300/80 text-xs mt-1">
            Estimated confirmation: {selectedOption.estimatedTime}
          </div>
        </motion.div>
      )}
    </div>
  );
}