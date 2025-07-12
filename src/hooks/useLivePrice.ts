import { useEffect, useState } from "react";

export function useLivePrice(url: string = "ws://localhost:8081") {
  const [price, setPrice] = useState<number | null>(null);

  useEffect(() => {
    const ws = new WebSocket(url);
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === "price" && typeof data.price === "number") {
          setPrice(data.price);
        }
      } catch {}
    };
    return () => ws.close();
  }, [url]);

  return price;
} 