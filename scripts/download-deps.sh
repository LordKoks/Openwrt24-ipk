#!/bin/sh
# download-deps.sh — скачивает все .ipk зависимостей для Pineapple Pager
# Архитектура: mipsel_24kc, OpenWrt 24.10.1
# Использование:
#   1. На хосте сборки: ./scripts/download-deps.sh
#   2. На Pineapple Pager: opkg install /mmc/ipk-cache/*.ipk

set -e

BASE_PACKAGES="https://downloads.openwrt.org/releases/24.10.1/packages/mipsel_24kc"
BASE_TARGETS="https://downloads.openwrt.org/releases/24.10.1/targets/ramips/mt76x8/packages"
DEST="${1:-./ipk-cache}"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mkdir -p "$DEST"
cd "$DEST"

log_info() {
    echo "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo "${RED}[✗]${NC} $1"
}

download_pkg() {
    local url="$1"
    local filename="$2"
    
    if wget -q --timeout=10 "$url" -O "$filename" 2>/dev/null; then
        log_info "Скачан: $filename"
        return 0
    else
        log_error "Ошибка при скачивании: $url"
        return 1
    fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  OpenWrt 24.10.1 IPK Dependency Downloader (mipsel_24kc)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "[*] Целевая папка: $(pwd)"
echo "[*] Архитектура: mipsel_24kc"
echo "[*] Версия OpenWrt: 24.10.1"
echo ""

# ============================================================================
# СПИСОК 1: ОБЯЗАТЕЛЬНЫЕ ПАКЕТЫ ДЛЯ ОСНОВНЫХ ПЕЙЛОУДОВ
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "СПИСОК 1: ОБЯЗАТЕЛЬНЫЕ ПАКЕТЫ (Core Wireless Tools)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[1/14] macchanger — смена MAC адреса"
download_pkg "${BASE_PACKAGES}/packages/macchanger_1.7.0-r3_mipsel_24kc.ipk" \
             "macchanger_1.7.0-r3_mipsel_24kc.ipk" || true

echo "[2/14] curl — загрузка файлов / API запросы"
download_pkg "${BASE_PACKAGES}/packages/curl_8.12.1-r1_mipsel_24kc.ipk" \
             "curl_8.12.1-r1_mipsel_24kc.ipk" || true

echo "[3/14] libcurl — зависимость для curl"
download_pkg "${BASE_PACKAGES}/base/libcurl_8.12.1-r1_mipsel_24kc.ipk" \
             "libcurl_8.12.1-r1_mipsel_24kc.ipk" || true

echo "[4/14] libiwinfo — информация о WiFi интерфейсах"
download_pkg "${BASE_PACKAGES}/base/libiwinfo_2024-10-20_mipsel_24kc.ipk" \
             "libiwinfo_2024-10-20_mipsel_24kc.ipk" || true

echo "[5/14] iwinfo — информационная утилита WiFi"
download_pkg "${BASE_PACKAGES}/packages/iwinfo_2024-10-20_mipsel_24kc.ipk" \
             "iwinfo_2024-10-20_mipsel_24kc.ipk" || true

echo "[6/14] pixiewps — WPS Pixie Dust атака"
download_pkg "${BASE_PACKAGES}/packages/pixiewps_1.4.2-r2_mipsel_24kc.ipk" \
             "pixiewps_1.4.2-r2_mipsel_24kc.ipk" || true

echo "[7/14] ncat / netcat — сетевые сокеты, reverse shell"
download_pkg "${BASE_PACKAGES}/packages/ncat_7.95-r1_mipsel_24kc.ipk" \
             "ncat_7.95-r1_mipsel_24kc.ipk" || true

echo "[8/14] socat — универсальный туннель данных"
download_pkg "${BASE_PACKAGES}/packages/socat_1.8.0.3-r2_mipsel_24kc.ipk" \
             "socat_1.8.0.3-r2_mipsel_24kc.ipk" || true

echo "[9/14] jq — парсинг JSON"
download_pkg "${BASE_PACKAGES}/packages/jq_1.8.1-r1_mipsel_24kc.ipk" \
             "jq_1.8.1-r1_mipsel_24kc.ipk" || true

echo "[10/14] sqlite3-cli — работа с БД"
download_pkg "${BASE_PACKAGES}/packages/sqlite3-cli_3530000-r1_mipsel_24kc.ipk" \
             "sqlite3-cli_3530000-r1_mipsel_24kc.ipk" || true

echo "[11/14] libsqlite3 — зависимость для sqlite3"
download_pkg "${BASE_PACKAGES}/base/libsqlite3_3530000-r1_mipsel_24kc.ipk" \
             "libsqlite3_3530000-r1_mipsel_24kc.ipk" || true

echo "[12/14] tmux — мультиплексер терминала"
download_pkg "${BASE_PACKAGES}/packages/tmux_3.5a-r1_mipsel_24kc.ipk" \
             "tmux_3.5a-r1_mipsel_24kc.ipk" || true

echo "[13/14] wget-ssl — загрузки с SSL/TLS"
download_pkg "${BASE_PACKAGES}/packages/wget-ssl_1.24.5-r1_mipsel_24kc.ipk" \
             "wget-ssl_1.24.5-r1_mipsel_24kc.ipk" || true

echo "[14/14] libssl — зависимость для wget-ssl"
download_pkg "${BASE_PACKAGES}/base/libssl3_3.3.3-r1_mipsel_24kc.ipk" \
             "libssl3_3.3.3-r1_mipsel_24kc.ipk" || true

# ============================================================================
# СПИСОК 2: ОПЦИОНАЛЬНЫЕ И СПЕЦИАЛИЗИРОВАННЫЕ ПАКЕТЫ
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "СПИСОК 2: ОПЦИОНАЛЬНЫЕ ПАКЕТЫ (Специализированные инструменты)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[Опц 1] gpsd — GPS daemon для wardriving"
download_pkg "${BASE_PACKAGES}/packages/gpsd_3.25-r2_mipsel_24kc.ipk" \
             "gpsd_3.25-r2_mipsel_24kc.ipk" || true

echo "[Опц 2] libusb-1.0 — зависимость для USB инструментов"
download_pkg "${BASE_PACKAGES}/base/libusb-1.0-0_1.0.27-r2_mipsel_24kc.ipk" \
             "libusb-1.0-0_1.0.27-r2_mipsel_24kc.ipk" || true

echo "[Опц 3] usbutils — утилиты для работы с USB"
download_pkg "${BASE_PACKAGES}/packages/usbutils_017-r1_mipsel_24kc.ipk" \
             "usbutils_017-r1_mipsel_24kc.ipk" || true

echo "[Опц 4] openvpn-openssl — VPN клиент"
download_pkg "${BASE_PACKAGES}/packages/openvpn-openssl_2.6.12-r1_mipsel_24kc.ipk" \
             "openvpn-openssl_2.6.12-r1_mipsel_24kc.ipk" || true

echo "[Опц 5] stunnel — SSL/TLS туннель"
download_pkg "${BASE_PACKAGES}/packages/stunnel_5.73-r1_mipsel_24kc.ipk" \
             "stunnel_5.73-r1_mipsel_24kc.ipk" || true

echo "[Опц 6] libopenssl1 — зависимость для OpenVPN/Stunnel"
download_pkg "${BASE_PACKAGES}/base/libopenssl1.1_1.1.1w-r3_mipsel_24kc.ipk" \
             "libopenssl1.1_1.1.1w-r3_mipsel_24kc.ipk" || true

# ============================================================================
# СВОДКА И ПРОВЕРКА
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "РЕЗУЛЬТАТЫ ЗАГРУЗКИ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "$DEST" ] && [ "$(find "$DEST" -name "*.ipk" 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "[*] Скачанные пакеты:"
    ls -lh "$DEST"/*.ipk 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}'
    echo ""
    
    PKG_COUNT=$(find "$DEST" -name "*.ipk" 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -sh "$DEST" | awk '{print $1}')
    
    echo "[*] Всего пакетов: $PKG_COUNT"
    echo "[*] Общий размер: $TOTAL_SIZE"
    echo ""
    
    cat > "$DEST/MANIFEST.txt" << 'EOF'
═══════════════════════════════════════════════════════════════════
OpenWrt 24.10.1 IPK Packages Manifest (mipsel_24kc)
═══════════════════════════════════════════════════════════════════

ОБЯЗАТЕЛЬНЫЕ ПАКЕТЫ (Core):
EOF
    
    ls -1 "$DEST"/*.ipk 2>/dev/null | while read ipk; do
        echo "  • $(basename "$ipk")" >> "$DEST/MANIFEST.txt"
    done
    
    cat >> "$DEST/MANIFEST.txt" << 'EOF'

УСТАНОВКА НА PINEAPPLE PAGER:
────────────────────────────────────────────────────────────────

1. Скопируй все .ipk на Pager поверх /mmc:
   $ scp ipk-cache/*.ipk root@pineapple:/mmc/

2. На Pager: обнови репозитории
   $ opkg update

3. Установи все пакеты:
   $ opkg install /mmc/*.ipk

4. Или установи только обязательные:
   $ opkg install -d mmc \
       macchanger curl libcurl4 iwinfo libiwinfo \
       pixiewps ncat socat jq sqlite3-cli libsqlite3 tmux wget-ssl

ПРИМЕЧАНИЯ:
────────────────────────────────────────────────────────────────
• -d mmc: установка на microSD (/mmc), а не в ROM
• Если нет /mmc — создай: mkdir -p /mmc
• Проверь свободное место: df -h /mmc
EOF

    log_info "Manifest создан: $DEST/MANIFEST.txt"
    
else
    log_warn "Пакеты не скачаны или папка пуста."
fi

echo ""
echo "✓ Скрипт завершён."
echo ""
