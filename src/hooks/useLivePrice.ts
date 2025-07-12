import { useEffect, useState } from "react";

export function useLivePrice(url: string = "ws://localhost:8081") {
  const [price, setPrice] = useState<number | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
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