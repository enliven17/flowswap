import { useEffect, useState } from "react";

export function useLivePrice(url?: string) {
  const [price, setPrice] = useState<number | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    // In production, use fallback prices since WebSocket server won't be available
    if (import.meta.env.PROD || !url) {
      setPrice(1.5); // Fallback FLOW price
      setIsConnected(false);
      return;
    }

    const ws = new WebSocket(url);
    
    ws.onopen = () => {
      console.log("WebSocket connected to price feed");
      setIsConnected(true);
    };
    
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === "price" && typeof data.price === "number") {
          setPrice(data.price);
        }
      } catch (error) {
        console.warn("Failed to parse WebSocket message:", error);
      }
    };
    
    ws.onerror = (error) => {
      console.warn("WebSocket connection failed, using fallback prices:", error);
      setIsConnected(false);
    };
    
    ws.onclose = (event) => {
      console.log("WebSocket connection closed:", event.code, event.reason);
      setIsConnected(false);
    };
    
    return () => {
      ws.close();
    };
  }, [url]);

  return { price, isConnected };
} 