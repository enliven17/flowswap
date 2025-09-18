"use client";

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronDown, Route, Zap, TrendingUp } from 'lucide-react';
import { cn } from '@/lib/utils';
import './modern-scrollbar.css';

interface RouteOption {
  id: string;
  name: string;
  description: string;
  gasEstimate: string;
  priceImpact: number;
  hops: number;
  icon: React.ReactNode;
  recommended?: boolean;
}

interface RouteSelectorProps {
  selectedRoute: string;
  onRouteChange: (routeId: string) => void;
  routes: RouteOption[];
  className?: string;
}

export function RouteSelector({ 
  selectedRoute, 
  onRouteChange, 
  routes,
  className 
}: RouteSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  
  const selectedRouteData = routes.find(route => route.id === selectedRoute);

  return (
    <div className={cn("relative", className)}>
      <div className="flex items-center justify-between mb-2">
        <label className="text-white/80 text-sm">Route</label>
        <span className="text-xs text-white/60">
          {selectedRouteData?.hops === 1 ? 'Direct' : `${selectedRouteData?.hops} hops`}
        </span>
      </div>
      
      <div className="relative">
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="w-full flex items-center justify-between p-3 bg-black/40 border border-white/10 rounded-xl text-white hover:bg-white/5 transition-colors"
        >
          <div className="flex items-center gap-3">
            {selectedRouteData?.icon}
            <div className="text-left">
              <div className="text-sm font-medium">{selectedRouteData?.name}</div>
              <div className="text-xs text-white/60">{selectedRouteData?.description}</div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {selectedRouteData?.recommended && (
              <span className="text-xs bg-green-500/20 text-green-400 px-2 py-1 rounded-full">
                Best
              </span>
            )}
            <ChevronDown className={cn(
              "h-4 w-4 transition-transform",
              isOpen && "rotate-180"
            )} />
          </div>
        </button>

        <AnimatePresence>
          {isOpen && (
            <motion.div
              initial={{ opacity: 0, y: -10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.95 }}
              transition={{ duration: 0.2 }}
              className="absolute top-full left-0 right-0 mt-2 bg-black/90 backdrop-blur-xl border border-white/10 rounded-xl shadow-2xl z-50 overflow-hidden"
            >
              {routes.map((route) => (
                <button
                  key={route.id}
                  onClick={() => {
                    onRouteChange(route.id);
                    setIsOpen(false);
                  }}
                  className={cn(
                    "w-full flex items-center justify-between p-3 text-left hover:bg-white/5 transition-colors border-b border-white/5 last:border-b-0",
                    selectedRoute === route.id && "bg-cyan-500/10"
                  )}
                >
                  <div className="flex items-center gap-3">
                    {route.icon}
                    <div>
                      <div className="text-sm font-medium text-white">{route.name}</div>
                      <div className="text-xs text-white/60">{route.description}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    {route.recommended && (
                      <span className="text-xs bg-green-500/20 text-green-400 px-2 py-1 rounded-full mb-1 block">
                        Recommended
                      </span>
                    )}
                    <div className="text-xs text-white/60">
                      Gas: {route.gasEstimate}
                    </div>
                    <div className="text-xs text-white/60">
                      Impact: {route.priceImpact.toFixed(2)}%
                    </div>
                  </div>
                </button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

// Default route options
export const defaultRoutes: RouteOption[] = [
  {
    id: 'direct',
    name: 'Direct Swap',
    description: 'Single hop through main pool',
    gasEstimate: '~0.001 FLOW',
    priceImpact: 0.12,
    hops: 1,
    icon: <Zap className="w-4 h-4 text-cyan-400" />,
    recommended: true
  },
  {
    id: 'multi-hop',
    name: 'Multi-hop Route',
    description: 'Better price through multiple pools',
    gasEstimate: '~0.003 FLOW',
    priceImpact: 0.08,
    hops: 2,
    icon: <Route className="w-4 h-4 text-blue-400" />
  },
  {
    id: 'twap',
    name: 'TWAP Route',
    description: 'Time-weighted for large trades',
    gasEstimate: '~0.005 FLOW',
    priceImpact: 0.05,
    hops: 1,
    icon: <TrendingUp className="w-4 h-4 text-purple-400" />
  }
];