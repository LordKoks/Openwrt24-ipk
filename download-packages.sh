#!/bin/sh
BASE="https://downloads.openwrt.org/releases/24.10.1/packages/mipsel_24kc"
DEST="./ipk-cache"

cd "$DEST" 2>/dev/null || mkdir -p "$DEST" && cd "$DEST"

echo "=== Загрузка основных пакетов ===" && echo ""

wget -q -t 2 "${BASE}/packages/macchanger_1.7.0-r3_mipsel_24kc.ipk" && echo "✓ macchanger" || echo "✗ macchanger"
wget -q -t 2 "${BASE}/packages/curl_8.12.1-r1_mipsel_24kc.ipk" && echo "✓ curl" || echo "✗ curl"
wget -q -t 2 "${BASE}/packages/jq_1.8.1-r1_mipsel_24kc.ipk" && echo "✓ jq" || echo "✗ jq"
wget -q -t 2 "${BASE}/packages/sqlite3-cli_3530000-r1_mipsel_24kc.ipk" && echo "✓ sqlite3-cli" || echo "✗ sqlite3-cli"
wget -q -t 2 "${BASE}/packages/tmux_3.5a-r1_mipsel_24kc.ipk" && echo "✓ tmux" || echo "✗ tmux"
wget -q -t 2 "${BASE}/packages/wget-ssl_1.24.5-r1_mipsel_24kc.ipk" && echo "✓ wget-ssl" || echo "✗ wget-ssl"

echo "" && echo "=== Итого ===" && find . -name "*.ipk" -type f | wc -l | xargs echo "IPK файлов:" && du -sh . | awk '{print "Размер: " $1}'
