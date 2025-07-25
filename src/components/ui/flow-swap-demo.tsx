"use client";
import React, { useState, useRef, useEffect, useMemo } from 'react';
import { motion, AnimatePresence, useReducedMotion } from 'framer-motion';
import {
  ArrowUpDown,
  Settings,
  ChevronDown,
  Zap,
  CheckCircle,
  AlertCircle,
  Loader2,
  ArrowUp,
  ArrowDown
} from 'lucide-react';
import { cn } from '@/lib/utils';


// Flow imports
import { authenticate, unauthenticate, currentUser } from "@onflow/fcl";
import { 
  FlowSwapClient, 
  defaultTokens 
} from "@/bindings/flow-bindings";
import { FlowToken, SwapState } from "@/types/tokens";
import { useLivePrice } from "@/hooks/useLivePrice";

// UI Components
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import "@/components/ui/hide-number-spin.css";

// Initialize Flow configuration


// Global error handler for browser extension errors
window.addEventListener('error', (event) => {
  if (event.message.includes('Receiving end does not exist')) {
    // This is typically from browser extensions, we can safely ignore it
    event.preventDefault();
    return false;
  }
});

// Global unhandled promise rejection handler
window.addEventListener('unhandledrejection', (event) => {
  if (event.reason && event.reason.message && event.reason.message.includes('Receiving end does not exist')) {
    // This is typically from browser extensions, we can safely ignore it
    event.preventDefault();
    return false;
  }
});

// --- Flickering Grid Background Effect ---
import { FlickeringGrid } from "@/components/ui/flickering-grid-hero";

export const CanvasRevealEffect = ({
  animationSpeed = 10,
  opacities = [0.3, 0.3, 0.3, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8, 1],
  colors = [[0, 255, 255]],
  containerClassName,
  dotSize = 3,
  showGradient = true,
  reverse = false,
}: {
  animationSpeed?: number;
  opacities?: number[];
  colors?: number[][];
  containerClassName?: string;
  dotSize?: number;
  showGradient?: boolean;
  reverse?: boolean;
}) => {
  const primaryColor = colors[0];
  const colorString = `rgb(${primaryColor[0]}, ${primaryColor[1]}, ${primaryColor[2]})`;

  // Calculate flicker chance based on animation speed
  const flickerChance = Math.max(0.05, 0.3 - (animationSpeed * 0.02));

  return (
    <div className={cn("h-full relative w-full overflow-hidden", containerClassName)}>
      {/* Flickering Grid Background */}
      <FlickeringGrid
        color={colorString}
        maxOpacity={0.2}
        flickerChance={flickerChance}
        squareSize={dotSize}
        gridGap={dotSize + 2}
        className="absolute inset-0 z-0"
      />
      
      {/* Additional subtle grid layer */}
      <FlickeringGrid
        color={colorString}
        maxOpacity={0.1}
        flickerChance={flickerChance * 0.5}
        squareSize={dotSize * 2}
        gridGap={dotSize * 3}
        className="absolute inset-0 z-0 opacity-50"
      />
      
      {/* Gradient overlay */}
      {showGradient && (
        <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent z-10" />
      )}
    </div>
  );
};

function useClickOutside<T extends HTMLElement = HTMLElement>(
  ref: React.RefObject<T>,
  handler: (event: MouseEvent | TouchEvent) => void,
  mouseEvent: 'mousedown' | 'mouseup' = 'mousedown'
): void {
  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      if (!ref.current || ref.current.contains(event.target as Node)) {
        return;
      }
      handler(event);
    };

    document.addEventListener(mouseEvent, listener);
    return () => {
      document.removeEventListener(mouseEvent, listener);
    };
  }, [ref, handler, mouseEvent]);
}

function FlowSwapBox() {
  const [user, setUser] = useState<any>(null);
  const [lastEdited, setLastEdited] = useState<"from" | "to">("from");
  const [showTokenSelector, setShowTokenSelector] = useState(false);
  const [selectedTokenType, setSelectedTokenType] = useState<"from" | "to">("from");
  const tokenSelectorRef = useRef<HTMLDivElement>(null);
  const fromInputRef = useRef<HTMLInputElement>(null);
  const toInputRef = useRef<HTMLInputElement>(null);

  // Flow client instance
  const flowClient = useMemo(() => {
    return new FlowSwapClient();
  }, [user?.addr]);

  // State management
  const [tokensLive, setTokensLive] = useState<FlowToken[]>(defaultTokens);
  const [swapState, setSwapState] = useState<SwapState>({
    fromToken: defaultTokens[0],
    toToken: defaultTokens[1],
    fromAmount: '',
    toAmount: '',
    slippage: 0.5,
    isLoading: false,
    status: 'idle'
  });
  // Remove needsTestTokenVault state - user already has tokens
  // const [needsTestTokenVault, setNeedsTestTokenVault] = useState(false);

  // Fiyatı canlı olarak al
  const { price: livePrice, isConnected: priceConnected } = useLivePrice("ws://localhost:8081");

  // Flow wallet connection
  async function connect() {
    try {
      await authenticate();
    } catch (error) {
      console.error("Authentication error:", error);
    }
  }

  async function disconnect() {
    try {
      await unauthenticate();
    } catch (error) {
      console.error("Disconnect error:", error);
    }
  }

  // Listen for user changes
  useEffect(() => {
    const unsubscribe = currentUser.subscribe((user) => {
      setUser(user);
    });
    return () => { unsubscribe(); };
  }, []);

  // Fetch balances when user connects
  useEffect(() => {
    if (!user?.addr) return;

    const fetchBalances = async () => {
      try {
        console.log('Connected user address:', user.addr);
        const flowBalance = await flowClient.getFlowBalance(user.addr);
        console.log('Fetched FLOW balance:', flowBalance);
        
        // Check if user has TestToken vault set up and get TestToken balance
        const hasTestTokenVault = await flowClient.hasTestTokenVault(user.addr);
        console.log('TestToken vault check result:', hasTestTokenVault);
        
        const testTokenBalance = hasTestTokenVault ? await flowClient.getTestTokenBalance(user.addr) : 0;
        console.log('TestToken balance:', testTokenBalance);
        
        // Remove vault setup check - user already has tokens
        // setNeedsTestTokenVault(!hasTestTokenVault);
        // if (!hasTestTokenVault) {
        //   console.log('User does not have TestToken vault set up');
        // }

        setTokensLive([
          {
            ...defaultTokens[0],
            balance: flowBalance.toFixed(4)
          },
          {
            ...defaultTokens[1],
            balance: testTokenBalance.toFixed(4)
          }
        ]);

        setSwapState(prev => ({
          ...prev,
          fromToken: { ...defaultTokens[0], balance: flowBalance.toFixed(4) },
          toToken: { ...defaultTokens[1], balance: testTokenBalance.toFixed(4) }
        }));
      } catch (error) {
        console.error("Error fetching balances:", error);
      }
    };

    fetchBalances();
  }, [user?.addr, flowClient]);

  // Remove setupTestTokenVault function - user already has tokens
  // const setupTestTokenVault = async () => {
  //   // Vault setup removed - user already has TestTokens
  // };

  // Remove mint-related state and functions
  // const [mintAmount, setMintAmount] = useState<string>("1000");
  // const [isMinting, setIsMinting] = useState(false);

  // Remove mint function
  // const handleMint = async () => {
  //   // Mint functionality removed - user already has tokens
  // };

  // Calculate swap amounts
  useEffect(() => {
    if (lastEdited === "from") {
      if (!swapState.fromAmount) {
        setSwapState((p) => ({ ...p, toAmount: "" }));
        return;
      }
      
      const amountIn = parseFloat(swapState.fromAmount);
      // Use live price if available, otherwise use fallback prices
      const price = livePrice ?? (swapState.fromToken.symbol === "FLOW" ? 1.5 : 0.67);
      const amountOut = amountIn * price;
      
      setSwapState((p) => ({ ...p, toAmount: amountOut.toFixed(6) }));
    } else if (lastEdited === "to") {
      if (!swapState.toAmount) {
        setSwapState((p) => ({ ...p, fromAmount: "" }));
        return;
      }
      
      const amountOut = parseFloat(swapState.toAmount);
      // Use live price if available, otherwise use fallback prices
      // For reverse calculation, we need the inverse price
      const basePrice = livePrice ?? (swapState.fromToken.symbol === "FLOW" ? 1.5 : 0.67);
      const inversePrice = 1 / basePrice;
      const amountIn2 = amountOut * inversePrice;
      
      setSwapState((p) => ({ ...p, fromAmount: amountIn2.toFixed(6) }));
    }
  }, [swapState.fromAmount, swapState.toAmount, swapState.fromToken, swapState.toToken, lastEdited, livePrice]);

  // Handle token selection
  const handleTokenSelect = (token: FlowToken) => {
    if (selectedTokenType === "from") {
      setSwapState(prev => ({ ...prev, fromToken: token }));
    } else {
      setSwapState(prev => ({ ...prev, toToken: token }));
    }
    setShowTokenSelector(false);
  };

  // Handle token swap
  const handleSwapTokens = () => {
    setSwapState(prev => ({
      ...prev,
      fromToken: prev.toToken,
      toToken: prev.fromToken,
      fromAmount: "",
      toAmount: ""
    }));
  };

  // Handle swap execution
  const handleSwap = async () => {
    if (!user?.addr) return;

    // Balance kontrolü (ondalık hassasiyetle)
    const fromBalance = parseFloat(Number(swapState.fromToken.balance).toFixed(2));
    const fromAmount = parseFloat(Number(swapState.fromAmount).toFixed(2));

    if (fromAmount > fromBalance) {
      setSwapState((p) => ({ 
        ...p, 
        status: "error", 
        isLoading: false,
        error: "Insufficient balance"
      }));
      return;
    }

    if (fromAmount <= 0) {
      setSwapState((p) => ({ 
        ...p, 
        status: "error", 
        isLoading: false,
        error: "Amount must be greater than 0"
      }));
      return;
    }

    setSwapState((p) => ({ ...p, status: "loading", isLoading: true }));
    
    try {
      const amountIn = parseFloat(swapState.fromAmount);
      const amountOut = parseFloat(swapState.toAmount);
      const minAmountOut = amountOut * (1 - swapState.slippage / 100);

      let txId;
      if (swapState.fromToken.symbol === "FLOW" && swapState.toToken.symbol === "TEST") {
        txId = await flowClient.swapFlowToTestToken(amountIn, minAmountOut);
      } else if (swapState.fromToken.symbol === "TEST" && swapState.toToken.symbol === "FLOW") {
        txId = await flowClient.swapTestTokenToFlow(amountIn, minAmountOut);
      } else {
        throw new Error("Unsupported swap direction");
      }

      setSwapState((p) => ({ 
        ...p, 
        status: "success", 
        isLoading: false,
        fromAmount: "",
        toAmount: ""
      }));

      // Refresh balances after successful swap
      setTimeout(async () => {
        try {
          const balances = await flowClient.refreshBalances(user.addr);
          
          setTokensLive([
            {
              ...defaultTokens[0],
              balance: balances.flow.toFixed(4)
            },
            {
              ...defaultTokens[1],
              balance: balances.test.toFixed(4)
            }
          ]);

          setSwapState(prev => ({
            ...prev,
            fromToken: { ...prev.fromToken, balance: balances.flow.toFixed(4) },
            toToken: { ...prev.toToken, balance: balances.test.toFixed(4) }
          }));
        } catch (error) {
          console.error("Error refreshing balances:", error);
        }
      }, 2000);

    } catch (error) {
      console.error("Swap error:", error);
      setSwapState((p) => ({ 
        ...p, 
        status: "error", 
        isLoading: false,
        error: error instanceof Error ? error.message : "Swap failed"
      }));
    }
  };

  // Click outside handler
  useClickOutside(tokenSelectorRef, () => setShowTokenSelector(false));

  // Balance artırma fonksiyonu
  const handleMaxBalance = (tokenType: "from" | "to") => {
    const token = tokenType === "from" ? swapState.fromToken : swapState.toToken;
    const balance = parseFloat(token.balance.toString());
    
    if (balance > 0) {
      if (tokenType === "from") {
        setSwapState(prev => ({ ...prev, fromAmount: balance.toFixed(6) }));
        setLastEdited("from");
      } else {
        setSwapState(prev => ({ ...prev, toAmount: balance.toFixed(6) }));
        setLastEdited("to");
      }
    }
  };

  // Miktar artirma fonksiyonu
  const handleIncreaseAmount = (tokenType: "from" | "to") => {
    const currentAmountStr = tokenType === "from" ? swapState.fromAmount : swapState.toAmount;
    let currentValue = parseFloat(currentAmountStr);
    if (isNaN(currentValue) || currentValue < 0) currentValue = 0;
    const balance = tokenType === "from" ? swapState.fromToken.balance : swapState.toToken.balance;
    const maxBalance = parseFloat(balance.toString());

    // Eğer current value zaten max balance'a eşit veya büyükse, hiçbir şey yapma
    if (tokenType === "from" && currentValue >= maxBalance && maxBalance > 0) {
      return;
    }

    let newValue = currentValue + 1;
    if (tokenType === "from" && maxBalance > 0 && newValue > maxBalance) {
      newValue = maxBalance;
    }
    const newValueStr = newValue.toString();
    if (tokenType === "from") {
      setSwapState(prev => ({ ...prev, fromAmount: newValueStr }));
      setLastEdited("from");
      setTimeout(() => { fromInputRef.current?.focus(); }, 0);
    } else {
      setSwapState(prev => ({ ...prev, toAmount: newValueStr }));
      setLastEdited("to");
      setTimeout(() => { toInputRef.current?.focus(); }, 0);
    }
  };

  // Miktar azaltma fonksiyonu
  const handleDecreaseAmount = (tokenType: "from" | "to") => {
    const currentAmountStr = tokenType === "from" ? swapState.fromAmount : swapState.toAmount;
    let currentValue = parseFloat(currentAmountStr);
    if (isNaN(currentValue) || currentValue <= 1) {
      if (tokenType === "from") {
        setSwapState(prev => ({ ...prev, fromAmount: "" }));
        setLastEdited("from");
      } else {
        setSwapState(prev => ({ ...prev, toAmount: "" }));
        setLastEdited("to");
      }
      return;
    }
    let newValue = currentValue - 1;
    if (newValue < 0) newValue = 0;
    const newValueStr = newValue === 0 ? "" : newValue.toString();
    if (tokenType === "from") {
      setSwapState(prev => ({ ...prev, fromAmount: newValueStr }));
      setLastEdited("from");
    } else {
      setSwapState(prev => ({ ...prev, toAmount: newValueStr }));
      setLastEdited("to");
    }
  };

  // Balance formatlama fonksiyonu
  const formatBalance = (balance: string | number): string => {
    const numBalance = parseFloat(balance.toString());
    if (numBalance <= 0) return "0.0000";
    if (numBalance < 0.0001) return "< 0.0001";
    return numBalance.toFixed(4);
  };

  // Balance USD değeri hesaplama
  const getBalanceUSD = (balance: string | number, price: number): string => {
    const numBalance = parseFloat(balance.toString());
    if (numBalance <= 0) return "$0.00";
    const usdValue = numBalance * price;
    return `$${usdValue.toFixed(2)}`;
  };

  // Kısa sayı formatlama fonksiyonu
  function formatShortNumber(value: string | number): string {
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (isNaN(num)) return '';
    if (num >= 1e9) return (num / 1e9).toFixed(2) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(2) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(2) + 'K';
    return num.toFixed(2);
  }

  const shouldReduceMotion = useReducedMotion();

  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.6,
        staggerChildren: 0.1
      }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.5 }
    }
  };

  return (
    <motion.div
      className="w-full max-w-md mx-auto"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      style={{ cursor: 'pointer', transition: 'box-shadow 0.25s, border-color 0.25s, transform 0.25s' }}
    >
      <div className="relative bg-black/80 border border-white/10 rounded-3xl p-8 pt-12 pb-12 w-full max-w-lg mx-auto min-h-[650px] flex flex-col justify-between">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-1">
            <Zap className="text-cyan-400 w-7 h-7" />
            <h2 className="text-2xl font-bold text-white tracking-tight">Swap</h2>
            {priceConnected && (
              <div className="flex items-center gap-1 ml-auto">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span className="text-xs text-green-400">Live</span>
              </div>
            )}
          </div>
          <p className="text-sm text-white/50 ml-1">Trade tokens instantly</p>
        </div>
        {/* From Token Box */}
        <div className="bg-black/60 border border-white/10 rounded-2xl p-4 mb-8 flex flex-col gap-2">
          <div className="flex items-center justify-between mb-1">
            <Label className="text-white/80 text-sm">From</Label>
            <span className="text-xs text-white/60">
              Balance: {formatBalance(swapState.fromToken.balance)}
            </span>
          </div>
          <div className="flex items-center gap-6">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedTokenType("from");
                setShowTokenSelector(true);
              }}
              className="flex items-center gap-2 bg-black/40 border border-white/10 rounded-xl min-w-[140px] px-8 py-3 text-white font-semibold hover:bg-cyan-900/10 focus:border-cyan-400 focus:bg-cyan-900/10 transition h-auto"
            >
              <img src={swapState.fromToken.icon} alt={swapState.fromToken.name} className="w-7 h-7 rounded-full" />
              <span className="text-base font-semibold">{swapState.fromToken.symbol}</span>
              <ChevronDown className="h-4 w-4" />
            </Button>
            <div className="flex-1 flex items-center gap-2 min-w-[100px] max-w-[160px]">
              <Input
                ref={fromInputRef}
                type="text"
                inputMode="decimal"
                placeholder="0.0"
                value={swapState.fromAmount ? formatShortNumber(swapState.fromAmount) : ""}
                onChange={(e) => {
                  const value = e.target.value.replace(/[^0-9.]/g, "");
                  setSwapState(prev => ({ ...prev, fromAmount: value }));
                  setLastEdited("from");
                }}
                className="flex-1 text-right bg-transparent border-none text-base md:text-lg font-bold text-white placeholder:text-white/30 focus:ring-0 focus:outline-none transition rounded-xl px-2 md:px-4 hide-number-spin overflow-x-auto whitespace-nowrap min-w-0 max-w-full"
              />
              <div className="flex flex-row gap-1 ml-1">
                <button
                  onClick={() => handleIncreaseAmount("from")}
                  className="flex items-center justify-center w-7 h-7 rounded-full bg-cyan-500/20 hover:bg-cyan-500/30 transition-colors group"
                  title="Increase amount"
                >
                  <ArrowUp className="w-4 h-4 text-cyan-400 group-hover:text-cyan-300" />
                </button>
                <button
                  onClick={() => handleDecreaseAmount("from")}
                  className="flex items-center justify-center w-7 h-7 rounded-full bg-cyan-500/20 hover:bg-cyan-500/30 transition-colors group"
                  title="Decrease amount"
                >
                  <ArrowDown className="w-4 h-4 text-cyan-400 group-hover:text-cyan-300" />
                </button>
              </div>
            </div>
          </div>
          <div className="flex items-center justify-between mt-1">
            <span className="text-xs text-white/40">
              {swapState.fromAmount ? getBalanceUSD(Number(swapState.fromAmount).toFixed(2), livePrice ?? 1.5) : "$0.00"}
            </span>
            <span className="text-xs text-white/40">
              ≈ {swapState.toAmount ? Number(swapState.toAmount).toFixed(2) : "0.00"}
            </span>
          </div>
        </div>
        {/* Swap Button */}
        <div className="flex justify-center -my-2 z-10 mb-8">
          <button
            type="button"
            onClick={handleSwapTokens}
            className="flex items-center justify-center w-12 h-12 rounded-full border border-white/20 bg-black/80 hover:bg-cyan-900/20 transition text-cyan-400 text-xl shadow-none focus:outline-none"
            aria-label="Swap tokens"
          >
            <ArrowUpDown className="h-6 w-6" />
          </button>
        </div>
        {/* To Token Box */}
        <div className="bg-black/60 border border-white/10 rounded-2xl p-4 mt-0 mb-10 flex flex-col gap-2">
          <div className="flex items-center justify-between mb-1">
            <Label className="text-white/80 text-sm">To</Label>
            <span className="text-xs text-white/60">
              Balance: {formatBalance(swapState.toToken.balance)}
            </span>
          </div>
          <div className="flex items-center gap-6">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedTokenType("to");
                setShowTokenSelector(true);
              }}
              className="flex items-center gap-2 bg-black/40 border border-white/10 rounded-xl min-w-[140px] px-8 py-3 text-white font-semibold hover:bg-cyan-900/10 focus:border-cyan-400 focus:bg-cyan-900/10 transition h-auto"
            >
              <img src={swapState.toToken.icon} alt={swapState.toToken.name} className="w-7 h-7 rounded-full" />
              <span className="text-base font-semibold">{swapState.toToken.symbol}</span>
              <ChevronDown className="h-4 w-4" />
            </Button>
            <div className="flex-1 flex items-center gap-2 min-w-[100px] max-w-[160px]">
              <Input
                ref={toInputRef}
                type="text"
                inputMode="decimal"
                placeholder="0.0"
                value={swapState.toAmount ? formatShortNumber(swapState.toAmount) : ""}
                onChange={(e) => {
                  const value = e.target.value.replace(/[^0-9.]/g, "");
                  setSwapState(prev => ({ ...prev, toAmount: value }));
                  setLastEdited("to");
                }}
                className="flex-1 text-right bg-transparent border-none text-base md:text-lg font-bold text-white placeholder:text-white/30 focus:ring-0 focus:outline-none transition rounded-xl px-2 md:px-4 hide-number-spin overflow-x-auto whitespace-nowrap min-w-0 max-w-full"
              />
              <div className="flex flex-row gap-1 ml-1">
                <button
                  onClick={() => handleIncreaseAmount("to")}
                  className="flex items-center justify-center w-7 h-7 rounded-full bg-cyan-500/20 hover:bg-cyan-500/30 transition-colors group"
                  title="Increase amount"
                >
                  <ArrowUp className="w-4 h-4 text-cyan-400 group-hover:text-cyan-300" />
                </button>
                <button
                  onClick={() => handleDecreaseAmount("to")}
                  className="flex items-center justify-center w-7 h-7 rounded-full bg-cyan-500/20 hover:bg-cyan-500/30 transition-colors group"
                  title="Decrease amount"
                >
                  <ArrowDown className="w-4 h-4 text-cyan-400 group-hover:text-cyan-300" />
                </button>
              </div>
            </div>
          </div>
          <div className="flex items-center justify-between mt-1">
            <span className="text-xs text-white/40">
              {swapState.toAmount ? getBalanceUSD(Number(swapState.toAmount).toFixed(2), 1) : "$0.00"}
            </span>
            <span className="text-xs text-white/40">
              ≈ {swapState.fromAmount ? Number(swapState.fromAmount).toFixed(2) : "0.00"}
            </span>
          </div>
        </div>
        {/* Remove TestToken Vault Setup Notice - user already has tokens */}
        {/* {user?.addr && needsTestTokenVault && (
          <motion.div
            className="mb-4 p-4 bg-yellow-500/10 border border-yellow-500/20 rounded-xl"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <div className="flex items-center space-x-2 mb-2">
              <AlertCircle className="h-4 w-4 text-yellow-400" />
              <span className="text-yellow-400 text-sm font-medium">TestToken Vault Required</span>
            </div>
                          <p className="text-yellow-300/80 text-xs mb-3">
                You need to set up your TestToken vault to trade TEST tokens. This is a one-time setup.
              </p>
              <div className="flex gap-2">
                <button
                  onClick={setupTestTokenVault}
                  disabled={swapState.isLoading}
                  className="flex-1 py-2 px-4 bg-yellow-500/20 hover:bg-yellow-500/30 border border-yellow-500/30 rounded-lg text-yellow-300 text-sm font-medium transition-colors disabled:opacity-50"
                >
                  {swapState.isLoading ? (
                    <div className="flex items-center justify-center space-x-2">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      <span>Setting up...</span>
                    </div>
                  ) : (
                    "Setup Vault"
                  )}
                </button>
              </div>
          </motion.div>
        )} */}

        {/* Swap/Connect Button */}
        <div className="mt-8">
        {user?.addr ? (
          <motion.button
            className={cn(
              "w-full py-4 rounded-full font-semibold text-lg bg-gradient-to-r from-cyan-400 to-blue-500 text-white hover:from-cyan-300 hover:to-blue-400 transition-all duration-200",
              swapState.isLoading && "bg-white/20 text-white cursor-not-allowed"
            )}
            onClick={handleSwap}
            disabled={swapState.isLoading || !swapState.fromAmount || !swapState.toAmount}
            variants={itemVariants}
          >
            {swapState.isLoading ? (
              <div className="flex items-center justify-center space-x-2">
                <Loader2 className="h-5 w-5 animate-spin" />
                <span>Swapping...</span>
              </div>
            ) : (
              "Swap"
            )}
          </motion.button>
        ) : (
          <motion.button
            className="w-full py-4 rounded-full font-semibold text-lg bg-white text-black hover:bg-neutral-100 transition-all duration-200"
            onClick={connect}
            variants={itemVariants}
          >
            Connect Wallet
          </motion.button>
        )}
        
        {/* Testnet Notice */}
        <div className="mt-4 text-center">
          <span className="text-xs text-white/50 bg-white/10 px-3 py-1 rounded-full">
            🧪 Running on Flow Testnet
          </span>
        </div>
        {/* Status Messages */}
        {swapState.status === "success" && (
          <motion.div
            className="flex items-center space-x-2 text-green-400 text-sm mt-4"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <CheckCircle className="h-4 w-4" />
            <span>Swap completed successfully!</span>
          </motion.div>
        )}
        {swapState.status === "error" && (
          <motion.div
            className="flex items-center space-x-2 text-red-400 text-sm mt-4"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <AlertCircle className="h-4 w-4" />
            <span>{swapState.error}</span>
          </motion.div>
        )}
        </div>
      </div>
      {/* Token Selector Modal (unchanged) */}
      <AnimatePresence>
        {showTokenSelector && (
          <motion.div
            className="absolute inset-0 z-50"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" />
            <motion.div
              ref={tokenSelectorRef}
              className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-full max-w-sm bg-black/40 backdrop-blur-xl border border-white/10 rounded-2xl p-6 shadow-2xl overflow-x-hidden"
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            >
              <h3 className="text-lg font-serif font-semibold mb-6 text-white">Select Token</h3>
              <div className="space-y-2">
                {tokensLive.map((token) => (
                  <button
                    key={token.symbol}
                    onClick={() => handleTokenSelect(token)}
                    className="w-full flex items-center space-x-3 p-3 rounded-lg hover:bg-white/10 transition-colors"
                  >
                    <img
                      src={token.icon}
                      alt={token.name}
                      className="w-8 h-8 rounded-full"
                    />
                    <div className="flex-1 text-left">
                      <div className="text-white font-medium">{token.symbol}</div>
                      <div className="text-white/60 text-sm">{token.name}</div>
                    </div>
                    <div className="text-white/60 text-sm">
                      {token.balance} {token.symbol}
                    </div>
                  </button>
                ))}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

function FlowSwapDemo() {
  return (
    <div className="flex w-full flex-col min-h-screen bg-black relative">
      {/* Animated background at z-0 */}
      <div className="absolute inset-0 z-0 pointer-events-none">
        <CanvasRevealEffect
          animationSpeed={3}
          containerClassName="bg-black"
          colors={[[0, 255, 255]]}
          dotSize={6}
          showGradient={true}
          reverse={false}
        />
      </div>
      {/* Main content at z-10 */}
      <div className="relative z-10 flex items-center justify-center min-h-screen p-4">
        <div className="w-full flex flex-col items-center">
          <FlowSwapBox />
          {/* Logo under swap component */}
          <div className="mt-8 flex items-center justify-center space-x-2">
            <span className="text-4xl font-bold text-white">FlowSwap</span>
            <span className="text-4xl animate-pulse">🌠</span>
          </div>
        </div>
      </div>
    </div>
  );
}

export default FlowSwapDemo; 