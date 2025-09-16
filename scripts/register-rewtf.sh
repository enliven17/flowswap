#!/bin/bash

# FlowSwap - REWTF Registry Kayıt Script'i
# Bu script REWTF registry'sine otomatik kayıt yapar

echo "🌊 FlowSwap - REWTF Registry Kayıt Script'i"
echo "=========================================="

# Geçici dizin oluştur
TEMP_DIR="temp-rewtf-registration"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

echo "📥 REWTF registry'si indiriliyor..."
git clone https://github.com/onflow/rewtf-registry.git
cd rewtf-registry

echo "🔧 Yeni branch oluşturuluyor..."
git checkout -b add-flowswap-team

echo "📝 Registry'ye FlowSwap team bilgileri ekleniyor..."

# YAML içeriğini dosyaya ekle
cat >> registry.yaml << 'EOF'
-
  name: FlowSwap Team
  github:
    - enliven17
  repos:
    - https://github.com/enliven17/flowswap
  wallets:
    evm: "0x000000000000000000000002765b8119A01C2aE4"
    flow: "0x5313e3163ad0f4a1"
  x:
    - 17cankat
EOF

echo "💾 Değişiklikler commit ediliyor..."
git add registry.yaml
git commit -m "Add FlowSwap team to REWTF registry

- Added FlowSwap decentralized token swap application
- Built on Flow blockchain with Cadence smart contracts
- Uses @onflow/fcl for blockchain integration
- Deployed on Flow testnet

#ReWTF #FlowBlockchain"

echo "🚀 GitHub'a push ediliyor..."
echo "⚠️  Not: Bu adım için GitHub authentication gerekli!"
echo "📋 Manuel olarak şu komutu çalıştırın:"
echo "    git push origin add-flowswap-team"
echo ""
echo "🌐 Sonra GitHub'da Pull Request oluşturun:"
echo "    https://github.com/onflow/rewtf-registry/compare"

echo ""
echo "✅ Kayıt hazırlığı tamamlandı!"
echo "📊 Leaderboard: https://app.databox.com/datawall/fc5f1f7de13471eac8bd5eb2e3d90a752817ac68a86fd6"

# Geçici dizini temizle
cd ../../
rm -rf $TEMP_DIR

echo "🎉 REWTF'e hoş geldiniz! #ReWTF #FlowBlockchain"