#!/bin/sh
# Simplified download script - только доступные пакеты
# OpenWrt 24.10.1 mipsel_24kc (Pineapple Pager)

DEST="./ipk-cache"
BASE="https://downloads.openwrt.org/releases/24.10.1/packages/mipsel_24kc"

cd "$DEST"

echo "=== Простая загрузка основных пакетов ==="
echo ""

# Главные приложения
wget -q -t 3 "${BASE}/packages/macchanger_1.7.0-r3_mipsel_24kc.ipk" && echo "✓ macchanger" || echo "✗ macchanger"
wget -q -t 3 "${BASE}/packages/curl_8.12.1-r1_mipsel_24kc.ipk" && echo "✓ curl" || echo "✗ curl"
wget -q -t 3 "${BASE}/packages/iwinfo_2024.10.20~b94f066e-r1_mipsel_24kc.ipk" && echo "✓ iwinfo" || echo "✗ iwinfo"
wget -q -t 3 "${BASE}/packages/pixiewps_1.4.2-r2_mipsel_24kc.ipk" && echo "✓ pixiewps" || echo "✗ pixiewps"
wget -q -t 3 "${BASE}/packages/ncat_7.95-r1_mipsel_24kc.ipk" && echo "✓ ncat" || echo "✗ ncat"
wget -q -t 3 "${BASE}/packages/socat_1.8.0.3-r2_mipsel_24kc.ipk" && echo "✓ socat" || echo "✗ socat"
wget -q -t 3 "${BASE}/packages/jq_1.8.1-r1_mipsel_24kc.ipk" && echo "✓ jq" || echo "✗ jq"
wget -q -t 3 "${BASE}/packages/sqlite3-cli_3530000-r1_mipsel_24kc.ipk" && echo "✓ sqlite3" || echo "✗ sqlite3"
wget -q -t 3 "${BASE}/packages/tmux_3.5a-r1_mipsel_24kc.ipk" && echo "✓ tmux" || echo "✗ tmux"
wget -q -t 3 "${BASE}/packages/wget-ssl_1.24.5-r1_mipsel_24kc.ipk" && echo "✓ wget-ssl" || echo "✗ wget-ssl"
wget -q -t 3 "${BASE}/packages/usbutils_017-r1_mipsel_24kc.ipk" && echo "✓ usbutils" || echo "✗ usbutils"

echo ""
echo "=== Результат ==="
ls -lh *.ipk 2>/dev/null | wc -l | xargs echo "Пакетов загружено:"
du -sh . | awk '{print "Размер: " $1}'
