import { WebSocketServer } from 'ws';

const wss = new WebSocketServer({ port: 8081 });

console.log('Price WebSocket server started on port 8081');

// Mock price data
let flowPrice = 1.5; // 1 FLOW = 1.5 FUSD
let priceVolatility = 0.02; // 2% volatility

wss.on('connection', (ws) => {
  console.log('Client connected to price feed');
  
  // Send initial price
  ws.send(JSON.stringify({
    type: 'price',
    price: flowPrice,
    timestamp: Date.now()
  }));
  
  // Send price updates every 5 seconds
  const priceInterval = setInterval(() => {
    // Simulate price movement
    const change = (Math.random() - 0.5) * priceVolatility;
    flowPrice = Math.max(0.1, flowPrice * (1 + change));
    
    ws.send(JSON.stringify({
      type: 'price',
      price: flowPrice,
      timestamp: Date.now()
    }));
  }, 5000);
  
  ws.on('close', () => {
    console.log('Client disconnected from price feed');
    clearInterval(priceInterval);
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    clearInterval(priceInterval);
  });
});

// Handle server shutdown
process.on('SIGINT', () => {
  console.log('Shutting down price server...');
  wss.close();
  process.exit(0);
}); 