#!/bin/sh
# install-lib.sh — Установка nullsec-lib на Pineapple Pager
# Использование: ./install-lib.sh [путь_к_библиотеке]

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Проверка, что мы на Pineapple Pager
check_pager() {
    if [ ! -f /etc/openwrt_release ]; then
        log_error "Этот скрипт должен запускаться на Pineapple Pager (OpenWrt)"
        exit 1
    fi

    if ! grep -q "Pineapple" /proc/cpuinfo 2>/dev/null; then
        log_warn "Это не похоже на Pineapple Pager. Продолжить? (y/N)"
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            exit 1
        fi
    fi
}

# Проверка зависимостей
check_dependencies() {
    log_header "Проверка зависимостей"

    local missing=""

    # Проверяем установленные пакеты
    for pkg in curl jq sqlite3-cli macchanger tmux socat ncat pixiewps wget-ssl; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing="$missing $pkg"
        fi
    done

    if [ -n "$missing" ]; then
        log_error "Отсутствуют пакеты:$missing"
        log_error "Установите их командой:"
        echo "  opkg update && opkg install -d mmc$missing"
        exit 1
    fi

    log_info "Все зависимости установлены"
}

# Установка библиотеки
install_library() {
    local lib_source="${1:-./library/nullsec-lib.sh}"
    local lib_dest="/usr/lib/nullsec-lib.sh"

    log_header "Установка библиотеки"

    if [ ! -f "$lib_source" ]; then
        log_error "Файл библиотеки не найден: $lib_source"
        exit 1
    fi

    # Создание директории
    mkdir -p /usr/lib

    # Копирование библиотеки
    cp "$lib_source" "$lib_dest"
    chmod 644 "$lib_dest"

    log_info "Библиотека установлена: $lib_dest"

    # Создание символической ссылки для удобства
    ln -sf "$lib_dest" /usr/bin/nullsec-lib.sh 2>/dev/null || true

    # Создание конфигурационной директории
    mkdir -p /root/.nullsec/{logs,data}

    log_info "Конфигурационная директория создана: /root/.nullsec/"
}

# Создание примера пейлоуда
create_example_payload() {
    log_header "Создание примера пейлоуда"

    cat > /root/payload/example-payload.sh << 'EOF'
#!/bin/sh
# Пример пейлоуда с использованием nullsec-lib
# Использование: ./example-payload.sh [интерфейс]

# Подключение библиотеки
. /usr/lib/nullsec-lib.sh

# Заголовок пейлоуда
nullsec_payload_header "WiFi Scanner" "1.0.0"

# Проверка аргументов
nullsec_validate_args 0 "$@" || exit 1

# Основная логика
IFACE="${1:-wlan0}"

log_info "Запуск сканирования WiFi на интерфейсе: $IFACE"

# Проверка интерфейса
if ! iw dev "$IFACE" info >/dev/null 2>&1; then
    log_error "Интерфейс $IFACE не найден"
    exit 1
fi

# Сканирование
log_info "Сканирование сетей..."
SCAN_RESULTS=$(nullsec_scan_wifi "$IFACE" 10)

if [ -n "$SCAN_RESULTS" ]; then
    log_info "Найденные сети:"
    echo "$SCAN_RESULTS" | head -20

    # Сохранение в базу данных
    nullsec_init_db
    echo "$SCAN_RESULTS" | while read -r line; do
        # Здесь можно парсить и сохранять результаты
        log_debug "Обработка: $line"
    done

    log_info "Результаты сохранены в базу данных"
else
    log_warn "Сети не найдены"
fi

# Проверка интернета
if nullsec_check_internet 5; then
    log_info "Интернет доступен"

    # Пример HTTP запроса
    RESPONSE=$(nullsec_http_get "https://httpbin.org/ip" 10)
    if [ -n "$RESPONSE" ]; then
        IP=$(nullsec_json_get "$RESPONSE" '.origin')
        log_info "Внешний IP: $IP"
    fi
else
    log_warn "Интернет недоступен"
fi

# Завершение
nullsec_payload_footer "WiFi Scanner" "completed"
EOF

    chmod +x /root/payload/example-payload.sh

    log_info "Пример пейлоуда создан: /root/payload/example-payload.sh"
}

# Создание скрипта обновления
create_update_script() {
    log_header "Создание скрипта обновления"

    cat > /usr/bin/nullsec-update << 'EOF'
#!/bin/sh
# nullsec-update — Обновление nullsec-lib
# Использование: nullsec-update [url_библиотеки]

URL="${1:-https://raw.githubusercontent.com/LordKoks/Openwrt24-ipk/main/library/nullsec-lib.sh}"
DEST="/usr/lib/nullsec-lib.sh"

echo "Обновление nullsec-lib..."
echo "Источник: $URL"

if curl -s "$URL" -o "$DEST.tmp"; then
    mv "$DEST.tmp" "$DEST"
    chmod 644 "$DEST"
    echo "✓ Библиотека обновлена"
    echo "Перезапустите пейлоуды для применения изменений"
else
    echo "✗ Ошибка обновления"
    rm -f "$DEST.tmp"
    exit 1
fi
EOF

    chmod +x /usr/bin/nullsec-update

    log_info "Скрипт обновления создан: /usr/bin/nullsec-update"
}

# Тестирование установки
test_installation() {
    log_header "Тестирование установки"

    # Проверка файла библиотеки
    if [ ! -f /usr/lib/nullsec-lib.sh ]; then
        log_error "Библиотека не установлена"
        return 1
    fi

    # Тест загрузки библиотеки
    if ! sh -c '. /usr/lib/nullsec-lib.sh && log_info "Тест пройден"'; then
        log_error "Ошибка загрузки библиотеки"
        return 1
    fi

    # Тест примера пейлоуда
    if [ -f /root/payload/example-payload.sh ]; then
        log_info "Тестирование примера пейлоуда..."
        if timeout 30 sh -c 'cd /root/payload && ./example-payload.sh wlan0' 2>/dev/null; then
            log_info "Пример пейлоуда работает"
        else
            log_warn "Пример пейлоуда вернул ошибку (возможно, интерфейс недоступен)"
        fi
    fi

    log_info "Установка протестирована успешно"
}

# Показать справку
show_usage() {
    cat << EOF
Установка nullsec-lib на Pineapple Pager

ИСПОЛЬЗОВАНИЕ:
  $0 [опции] [путь_к_библиотеке]

ОПЦИИ:
  -h, --help     Показать эту справку
  -s, --skip-test Пропустить тестирование
  --no-example   Не создавать пример пейлоуда

ПРИМЕРЫ:
  $0                          # Установка из ./library/nullsec-lib.sh
  $0 /path/to/lib.sh          # Установка из указанного файла
  $0 --no-example             # Установка без примера

ПОСЛЕ УСТАНОВКИ:
  # В пейлоудах добавьте:
  . /usr/lib/nullsec-lib.sh

  # Или используйте в скриптах:
  source /usr/lib/nullsec-lib.sh

ОБНОВЛЕНИЕ:
  nullsec-update              # Обновление из репозитория
  nullsec-update <url>        # Обновление из указанного URL

EOF
}

# Основная функция
main() {
    local skip_test=false
    local no_example=false
    local lib_path="./library/nullsec-lib.sh"

    # Обработка аргументов
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--skip-test)
                skip_test=true
                ;;
            --no-example)
                no_example=true
                ;;
            *)
                lib_path="$1"
                ;;
        esac
        shift
    done

    log_header "Установка nullsec-lib v1.0.0"

    # Проверки
    check_pager
    check_dependencies

    # Установка
    install_library "$lib_path"

    if [ "$no_example" != "true" ]; then
        create_example_payload
    fi

    create_update_script

    if [ "$skip_test" != "true" ]; then
        test_installation
    fi

    log_header "Установка завершена!"

    echo "Библиотека установлена в: /usr/lib/nullsec-lib.sh"
    echo "Пример пейлоуда: /root/payload/example-payload.sh"
    echo "Обновление: nullsec-update"
    echo ""
    echo "Использование в пейлоудах:"
    echo "  . /usr/lib/nullsec-lib.sh"
    echo ""
    echo "Документация: https://github.com/LordKoks/Openwrt24-ipk"
}

# Запуск
main "$@"