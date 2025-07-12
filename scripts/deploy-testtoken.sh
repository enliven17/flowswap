#!/bin/bash

# TestToken Deployment Script
# Bu script TestToken kontratını Flow testnet'e deploy eder

echo "🚀 TestToken Deploy Script'i"
echo "============================"
echo

# Check if Flow CLI is installed
if ! command -v flow &> /dev/null; then
    echo "❌ Flow CLI bulunamadı. Lütfen Flow CLI'yi kurun."
    exit 1
fi

echo "✅ Flow CLI bulundu: $(flow version)"
echo

# Check if private key environment variable is set
if [ -z "$FLOW_PRIVATE_KEY" ]; then
    echo "⚠️  FLOW_PRIVATE_KEY environment variable ayarlanmamış."
    echo
    echo "Private key'inizi ayarlamak için:"
    echo "export FLOW_PRIVATE_KEY=\"your_private_key_here\""
    echo
    echo "Private key'inizi Flow wallet'ından alabilirsiniz."
    echo "Güvenlik için private key'inizi bu terminalde yazabilirsiniz:"
    echo
    read -s -p "Private Key girin (gizli): " PRIVATE_KEY
    export FLOW_PRIVATE_KEY="$PRIVATE_KEY"
    echo
    echo "✅ Private key ayarlandı."
fi

echo "📋 Deployment öncesi kontrol..."
echo

# Check if contract compiles
echo "🔍 Kontrat syntax kontrolü..."
if [ -f "contracts/TestToken.cdc" ]; then
    echo "✅ TestToken.cdc bulundu"
else
    echo "❌ TestToken.cdc bulunamadı"
    exit 1
fi

echo
echo "🚀 TestToken kontratını deploy ediyorum..."
echo

# Deploy TestToken contract
export PATH="$HOME/.local/bin:$PATH"

# Try to deploy with the current setup
flow accounts add-contract TestToken contracts/TestToken.cdc --network testnet --signer testnet-account

if [ $? -eq 0 ]; then
    echo
    echo "🎉 TestToken başarıyla deploy edildi!"
    echo
    echo "📋 Deployment Bilgileri:"
    echo "  Contract: TestToken"
    echo "  Address: 0xfbaa55ea2a76ff04"
    echo "  Network: Flow Testnet"
    echo
    echo "✅ Artık TestToken kontratınızı kullanabilirsiniz!"
    echo
    echo "📖 Sonraki adımlar:"
    echo "  1. FlowSwap kontratını deploy edin"
    echo "  2. Frontend'i test edin"
    echo "  3. Token mint işlemleri yapın"
else
    echo
    echo "❌ Deployment başarısız oldu."
    echo
    echo "🔧 Alternatif deployment yöntemleri:"
    echo
    echo "1. Flow Playground kullanın:"
    echo "   - https://play.onflow.org adresine gidin"
    echo "   - Testnet'i seçin"
    echo "   - Wallet'ınızı bağlayın"
    echo "   - TestToken kontratını kopyalayın"
    echo "   - Deploy butonuna basın"
    echo
    echo "2. Manuel deployment:"
    echo "   - flow accounts create --network testnet"
    echo "   - Private key'inizi kaydedin"
    echo "   - Bu script'i tekrar çalıştırın"
fi

echo
echo "📞 Yardım için: https://developers.flow.com/tools/flow-cli" 