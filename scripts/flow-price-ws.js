// Basit Flow fiyat WebSocket sunucusu (simülasyon)
const WebSocket = require('ws');
const PORT = 8081;

const wss = new WebSocket.Server({ port: PORT });

let price = 1.5; // Başlangıç fiyatı (ör: 1 FLOW = 1.5 USDC)

function randomizePrice() {
  // Fiyatı rastgele biraz değiştir (simülasyon)
  const change = (Math.random() - 0.5) * 0.02;
  price = Math.max(1.2, Math.min(1.8, price + change));
}

function broadcastPrice() {
  const msg = JSON.stringify({ type: 'price', price: Number(price.toFixed(6)) });
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });
}

setInterval(() => {
  randomizePrice();
  broadcastPrice();
}, 2000); // Her 2 saniyede bir fiyat güncelle

wss.on('connection', ws => {
  ws.send(JSON.stringify({ type: 'price', price: Number(price.toFixed(6)) }));
});

console.log(`Flow price WebSocket server running on ws://localhost:${PORT}`); 