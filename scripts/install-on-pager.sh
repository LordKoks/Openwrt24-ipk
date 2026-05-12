#!/bin/sh
# install-on-pager.sh — установка зависимостей на Pineapple Pager
# Предполагается, что .ipk файлы уже в /mmc:
# $ scp ipk-cache/*.ipk root@pineapple:/mmc/

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo "${RED}[✗]${NC} $1"
}

log_header() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}  $1${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Проверка, на Pager ли мы
if [ ! -f /etc/openwrt_release ]; then
    log_error "Этот скрипт должен запускаться на Pineapple Pager (OpenWrt)"
    exit 1
fi

log_header "Установка OpenWrt зависимостей на Pineapple Pager"

# Проверка /mmc
if [ ! -d /mmc ]; then
    log_warn "/mmc не существует, создаём..."
    mkdir -p /mmc
fi

# Проверка свободного места
AVAIL=$(df /mmc | tail -1 | awk '{print int($4/1024)}')  # MB
log_info "Свободное место на /mmc: ${AVAIL} MB"

if [ "$AVAIL" -lt 50 ]; then
    log_error "Недостаточно места на /mmc (< 50 MB). Удали ненужные файлы."
    exit 1
fi

# Проверка наличия .ipk файлов
if [ -z "$(find /mmc -name "*.ipk" -type f 2>/dev/null)" ]; then
    log_error "Нет .ipk файлов в /mmc. Сначала скопируй их:"
    echo "  $ scp ipk-cache/*.ipk root@pineapple:/mmc/"
    exit 1
fi

PKG_COUNT=$(find /mmc -name "*.ipk" -type f | wc -l)
log_info "Найдено IPK пакетов: $PKG_COUNT"

# Настройка opkg для установки на /mmc
log_header "Конфигурация opkg"

if ! grep -q "^dest mmc" /etc/opkg.conf 2>/dev/null; then
    log_info "Добавляем направление установки /mmc в opkg.conf"
    echo "dest mmc /mmc" >> /etc/opkg.conf
else
    log_info "Конфиг opkg уже настроен"
fi

# Обновление репозиториев
log_header "Обновление репозиториев"

if opkg update; then
    log_info "Репозитории обновлены"
else
    log_warn "Ошибка при обновлении репозиториев (интернета может не быть)"
fi

# Установка обязательных пакетов
log_header "Установка ОБЯЗАТЕЛЬНЫХ пакетов"

REQUIRED_PACKAGES="
  macchanger
  curl
  libcurl4
  iwinfo
  libiwinfo
  pixiewps
  ncat
  socat
  jq
  sqlite3-cli
  libsqlite3
  tmux
  wget-ssl
  libssl3
"

echo "[*] Установка пакетов на /mmc (это займёт несколько минут)..."
echo ""

PKG_SUCCESS=0
PKG_FAILED=0

for pkg in $REQUIRED_PACKAGES; do
    echo -n "  $pkg... "
    
    if opkg install -d mmc "$pkg" >/dev/null 2>&1; then
        echo "${GREEN}OK${NC}"
        PKG_SUCCESS=$((PKG_SUCCESS + 1))
    else
        # Может быть уже установлен
        if opkg list-installed | grep -q "^${pkg} "; then
            echo "${YELLOW}уже установлен${NC}"
            PKG_SUCCESS=$((PKG_SUCCESS + 1))
        else
            echo "${RED}ошибка${NC}"
            PKG_FAILED=$((PKG_FAILED + 1))
        fi
    fi
done

echo ""
log_info "Результат: успешно обработано $PKG_SUCCESS пакетов"

if [ "$PKG_FAILED" -gt 0 ]; then
    log_warn "Не удалось установить $PKG_FAILED пакетов (может быть недоступны в офиц. репо)"
fi

# Проверка памяти
log_header "Проверка ресурсов"

FREE_RAM=$(free -m | grep Mem | awk '{print $7}')
USED_STORAGE=$(du -sh /mmc | awk '{print $1}')

log_info "Свободной ОЗУ: ${FREE_RAM} MB"
log_info "Использовано в /mmc: $USED_STORAGE"

# Проверка установленных команд
log_header "Проверка установленных команд"

CMDS="macchanger curl iwinfo pixiewps ncat socat jq sqlite3 tmux wget"

for cmd in $CMDS; do
    if command -v "$cmd" >/dev/null 2>&1; then
        VERSION=$($cmd --version 2>/dev/null | head -1 || echo "OK")
        log_info "$cmd: установлен ($VERSION)"
    else
        log_warn "$cmd: не найден (может быть, не установлен)"
    fi
done

# Финальные рекомендации
log_header "Готово!"

echo "✅ Установка завершена!"
echo ""
echo "Рекомендуемые следующие шаги:"
echo ""
echo "1. Проверь окончательно свободное место:"
echo "   $ df -h"
echo ""
echo "2. Проверь список установленных пакетов:"
echo "   $ opkg list-installed | grep -E '(macchanger|curl|jq|sqlite|tmux)'"
echo ""
echo "3. Запусти пейлоуды Hak5:"
echo "   /root/payload/*."
echo ""
echo "4. Если нужны опциональные пакеты (GPS, VPN и т.д.):"
echo "   $ opkg install -d mmc gpsd openvpn-openssl"
echo ""
echo ""
echo "📚 Лог установки: $0"
echo ""
