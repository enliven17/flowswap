# FlowSwap Deployment Guide

Bu rehber, FlowSwap projesini Flow testnet'e deploy etmek için gerekli adımları açıklar.

## Ön Gereksinimler

1. **Node.js** (v18+)
2. **Flow CLI** - [Kurulum Rehberi](https://docs.onflow.org/flow-cli/install/)
3. **Flow Wallet** (Blocto, Dapper, vs.)

## Kurulum

### 1. Dependencies'leri Yükleyin
```bash
npm install
```

### 2. Flow CLI'yi Kurun
```bash
# macOS
brew install flow-cli

# Windows
# https://docs.onflow.org/flow-cli/install/

# Linux
sh -ci "$(curl -fsSL https://storage.googleapis.com/flow-cli/install.sh)"
```

### 3. Flow Hesabı Oluşturun
```bash
# Testnet hesabı oluşturun
flow accounts create --network testnet

# Hesap bilgilerini kaydedin
flow keys generate --network testnet
```

## Contract Deployment

### 1. Smart Contract'ı Deploy Edin
```bash
npm run deploy:contract
```

### 2. Contract Adresini Güncelleyin
Deployment tamamlandıktan sonra, `src/config/flow.ts` dosyasındaki `SWAP_CONTRACT` adresini güncelleyin:

```typescript
// src/config/flow.ts
export const FLOW_CONFIG = {
  // ... diğer ayarlar
  SWAP_CONTRACT: "0xYOUR_DEPLOYED_CONTRACT_ADDRESS", // Burayı güncelleyin
  // ...
};
```

## Liquidity Ekleme

### 1. Test Tokenları Alın
- **FLOW Testnet Faucet**: https://testnet-faucet-v2.onflow.org/
- **FUSD Testnet**: Flow testnet'te otomatik olarak mevcut

### 2. Liquidity Ekleyin
```bash
# Flow CLI ile liquidity ekleyin
flow transactions send transactions/add_liquidity.cdc \
  --args-json '[{"type": "UFix64", "value": "100.0"}, {"type": "UFix64", "value": "150.0"}]' \
  --network testnet
```

## Test Etme

### 1. Uygulamayı Çalıştırın
```bash
npm run dev
```

### 2. Wallet Bağlayın
- Blocto, Dapper veya diğer Flow wallet'larından birini kullanın
- Testnet ağına bağlandığınızdan emin olun

### 3. Swap Test Edin
- FLOW ↔ FUSD arasında küçük miktarlarda swap yapın
- Slippage ayarlarını test edin
- Error handling'i kontrol edin

## Production Deployment

### 1. Mainnet'e Geçiş
```typescript
// src/config/flow.ts
export const FLOW_CONFIG = {
  ACCESS_NODE: "https://rest-mainnet.onflow.org",
  WALLET_DISCOVERY: "https://fcl-discovery.onflow.org/mainnet/authn",
  NETWORK: "mainnet",
  // ...
};
```

### 2. Contract'ı Mainnet'e Deploy Edin
```bash
flow deploy contracts/FlowSwap.cdc --network mainnet
```

### 3. Security Audit
- Smart contract güvenlik audit'i yapın
- Penetration testing yapın
- Bug bounty programı başlatın

## Troubleshooting

### Yaygın Sorunlar

1. **Flow CLI Hatası**
   ```bash
   # Flow CLI'yi yeniden yükleyin
   flow update
   ```

2. **Contract Deployment Hatası**
   ```bash
   # Network bağlantısını kontrol edin
   flow ping --network testnet
   ```

3. **Wallet Bağlantı Sorunu**
   - Browser cache'ini temizleyin
   - Farklı wallet deneyin
   - Network ayarlarını kontrol edin

### Log Kontrolü
```bash
# Flow CLI logları
flow logs --network testnet

# Uygulama logları
npm run dev
```

## Güvenlik Notları

1. **Private Key Güvenliği**
   - Private key'leri asla kodda saklamayın
   - Environment variables kullanın
   - Hardware wallet kullanmayı düşünün

2. **Contract Güvenliği**
   - Reentrancy attack'lere karşı koruma
   - Integer overflow/underflow kontrolü
   - Access control implementasyonu

3. **Frontend Güvenliği**
   - Input validation
   - XSS koruması
   - CSRF token'ları

## Destek

Sorun yaşarsanız:
- [Flow Discord](https://discord.gg/flow)
- [Flow Forum](https://forum.onflow.org/)
- [GitHub Issues](https://github.com/your-repo/flowswap/issues)

## Lisans

MIT License - Detaylar için LICENSE dosyasına bakın. 