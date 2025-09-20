"use client";
import React from 'react';
import { motion } from 'framer-motion';
import { 
  Wallet, 
  ArrowLeftRight, 
  Droplets, 
  ArrowRightLeft, 
  Info,
  Zap
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { NavItem, NavItemId } from '@/types/navigation';

interface GlassNavbarProps {
  activeItem?: NavItemId;
  onItemClick?: (itemId: NavItemId) => void;
  className?: string;
}

const GlassNavbar: React.FC<GlassNavbarProps> = ({ 
  activeItem = 'swap', 
  onItemClick,
  className 
}) => {
  const navItems: NavItem[] = [
    {
      id: 'balance',
      label: 'Balance',
      icon: <Wallet className="w-5 h-5" />
    },
    {
      id: 'swap',
      label: 'Swap',
      icon: <ArrowLeftRight className="w-5 h-5" />
    },
    {
      id: 'pools',
      label: 'Pools',
      icon: <Droplets className="w-5 h-5" />
    },
    {
      id: 'bridge',
      label: 'Bridge',
      icon: <ArrowRightLeft className="w-5 h-5" />
    },
    {
      id: 'info',
      label: 'Info',
      icon: <Info className="w-5 h-5" />
    },
    {
      id: 'actions',
      label: 'Actions',
      icon: <Zap className="w-5 h-5" />
    }
  ];

  const handleItemClick = (itemId: string) => {
    if (onItemClick) {
      onItemClick(itemId);
    }
  };

  return (
    <motion.div
      className={cn(
        "flex items-center justify-center gap-1 p-2 rounded-2xl",
        "bg-black/60 backdrop-blur-2xl border border-white/20",
        "shadow-2xl shadow-black/40",
        "ring-1 ring-white/10",
        className
      )}
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      {navItems.map((item) => {
        const isActive = item.id === activeItem;
        
        return (
          <motion.button
            key={item.id}
            onClick={() => handleItemClick(item.id)}
            className={cn(
              "relative flex flex-col items-center justify-center gap-1 px-4 py-3 rounded-xl",
              "transition-all duration-300 ease-out",
              "hover:bg-white/15 hover:backdrop-blur-sm",
              "hover:shadow-lg hover:shadow-white/10",
              isActive 
                ? "bg-gradient-to-br from-purple-500/90 to-blue-500/90 text-white shadow-xl shadow-purple-500/30 ring-1 ring-purple-400/50" 
                : "text-white/70 hover:text-white hover:scale-105"
            )}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            {/* Active background glow */}
            {isActive && (
              <motion.div
                className="absolute -inset-1 bg-gradient-to-br from-purple-500/30 to-blue-500/30 rounded-xl blur-md"
                layoutId="activeBackground"
                transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
              />
            )}
            
            {/* Icon */}
            <div className="relative z-10">
              {item.icon}
            </div>
            
            {/* Label */}
            <span className="relative z-10 text-xs font-medium">
              {item.label}
            </span>
          </motion.button>
        );
      })}
    </motion.div>
  );
};

export default GlassNavbar;