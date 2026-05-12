#!/bin/sh
# nullsec-lib.sh — Универсальная библиотека для Hak5 Pineapple Pager пейлоудов
# Версия: 1.0.0
# Автор: GitHub Copilot
# Дата: 2026-05-12
# Архитектура: mipsel_24kc (OpenWrt 24.10.1)

# =============================================================================
# ГЛОБАЛЬНЫЕ НАСТРОЙКИ И КОНСТАНТЫ
# =============================================================================

# Цвета для вывода
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Пути и файлы
readonly LIB_VERSION="1.0.0"
readonly LIB_NAME="nullsec-lib"
readonly CONFIG_DIR="/root/.nullsec"
readonly LOG_DIR="/root/.nullsec/logs"
readonly DATA_DIR="/root/.nullsec/data"
readonly TMP_DIR="/tmp/nullsec"

# Сетевые интерфейсы (стандартные для Pineapple Pager)
readonly WLAN0="wlan0"
readonly WLAN1="wlan1"
readonly BR_LAN="br-lan"
readonly ETH0="eth0"

# =============================================================================
# ФУНКЦИИ ИНИЦИАЛИЗАЦИИ
# =============================================================================

# Инициализация библиотеки
nullsec_init() {
    # Создание директорий
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$DATA_DIR" "$TMP_DIR"

    # Установка прав
    chmod 755 "$CONFIG_DIR" "$LOG_DIR" "$DATA_DIR"
    chmod 1777 "$TMP_DIR"  # sticky bit для tmp

    # Проверка зависимостей
    nullsec_check_dependencies

    # Настройка логирования
    nullsec_setup_logging

    # Очистка при выходе
    trap nullsec_cleanup EXIT

    log_info "Библиотека $LIB_NAME v$LIB_VERSION инициализирована"
}

# Проверка зависимостей
nullsec_check_dependencies() {
    local missing_deps=""

    # Обязательные команды (busybox)
    for cmd in grep sed awk echo cat ls kill sleep date mkdir rm cp mv chmod ifconfig iw route ping find xargs basename dirname which expr printf read test; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps="$missing_deps $cmd"
        fi
    done

    # Установленные пакеты
    local required_pkgs="curl jq sqlite3 macchanger tmux socat ncat pixiewps wget"
    for pkg in $required_pkgs; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing_deps="$missing_deps $pkg"
        fi
    done

    if [ -n "$missing_deps" ]; then
        log_error "Отсутствуют зависимости:$missing_deps"
        log_error "Установите пакеты: opkg install -d mmc curl jq sqlite3-cli macchanger tmux socat ncat pixiewps wget-ssl"
        return 1
    fi

    return 0
}

# Настройка логирования
nullsec_setup_logging() {
    # Создание лог-файла с timestamp
    LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S).log"

    # Функция для ротации логов (оставляем последние 10)
    find "$LOG_DIR" -name "*.log" -type f | sort | head -n -10 | xargs rm -f 2>/dev/null || true
}

# Очистка при выходе
nullsec_cleanup() {
    # Удаление временных файлов
    rm -rf "$TMP_DIR" 2>/dev/null || true

    # Остановка фоновых процессов (если есть)
    nullsec_kill_background_processes

    log_info "Библиотека $LIB_NAME завершена"
}

# =============================================================================
# ФУНКЦИИ ЛОГИРОВАНИЯ
# =============================================================================

# Базовая функция логирования
_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Вывод в консоль с цветом
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $timestamp: $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $timestamp: $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $timestamp: $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $timestamp: $message" ;;
        *)       echo -e "${CYAN}[$level]${NC} $timestamp: $message" ;;
    esac

    # Запись в файл (если инициализировано)
    if [ -n "$LOG_FILE" ]; then
        echo "[$level] $timestamp: $message" >> "$LOG_FILE"
    fi
}

log_info()  { _log "INFO" "$1"; }
log_warn()  { _log "WARN" "$1"; }
log_error() { _log "ERROR" "$1"; }
log_debug() { _log "DEBUG" "$1"; }

# =============================================================================
# ФУНКЦИИ КОНФИГУРАЦИИ
# =============================================================================

# Загрузка конфигурации
nullsec_load_config() {
    local config_file="$CONFIG_DIR/config.sh"

    if [ -f "$config_file" ]; then
        source "$config_file"
        log_debug "Конфигурация загружена из $config_file"
    else
        log_warn "Файл конфигурации не найден: $config_file"
        nullsec_create_default_config
    fi
}

# Создание конфигурации по умолчанию
nullsec_create_default_config() {
    cat > "$CONFIG_DIR/config.sh" << 'EOF'
# Конфигурация nullsec-lib по умолчанию

# Сетевые настройки
DEFAULT_IFACE="wlan0"
MONITOR_IFACE="wlan0mon"
AP_IFACE="wlan1"

# Таймауты (секунды)
SCAN_TIMEOUT=30
CONNECT_TIMEOUT=15
DOWNLOAD_TIMEOUT=60

# Пути
PAYLOAD_DIR="/root/payload"
DATA_DIR="/root/.nullsec/data"
LOG_DIR="/root/.nullsec/logs"

# Настройки WiFi
DEFAULT_CHANNEL=6
DEFAULT_TXPOWER=20

# Настройки базы данных
DB_FILE="/root/.nullsec/data/payloads.db"

# Настройки безопасности
ENABLE_ENCRYPTION=false
AUTO_CLEANUP=true
LOG_ROTATION_DAYS=7
EOF

    log_info "Создана конфигурация по умолчанию: $CONFIG_DIR/config.sh"
}

# Получение значения из конфигурации
nullsec_get_config() {
    local key="$1"
    local default="$2"

    if [ -f "$CONFIG_DIR/config.sh" ]; then
        grep "^${key}=" "$CONFIG_DIR/config.sh" | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//'
    else
        echo "$default"
    fi
}

# =============================================================================
# СЕТЕВЫЕ ФУНКЦИИ
# =============================================================================

# Получение информации о WiFi интерфейсе
nullsec_get_wifi_info() {
    local iface="${1:-$WLAN0}"

    if command -v iwinfo >/dev/null 2>&1; then
        iwinfo "$iface" info 2>/dev/null
    else
        log_warn "iwinfo не установлен, используем iw"
        iw dev "$iface" link 2>/dev/null
    fi
}

# Сканирование WiFi сетей
nullsec_scan_wifi() {
    local iface="${1:-$WLAN0}"
    local timeout="${2:-30}"

    log_info "Сканирование WiFi сетей на $iface (timeout: ${timeout}s)"

    if command -v iw >/dev/null 2>&1; then
        timeout "$timeout" iw dev "$iface" scan 2>/dev/null | grep -E "(BSS|SSID|signal|freq)"
    else
        log_error "iw не найден"
        return 1
    fi
}

# Смена MAC адреса
nullsec_change_mac() {
    local iface="${1:-$WLAN0}"
    local new_mac="$2"

    if ! command -v macchanger >/dev/null 2>&1; then
        log_error "macchanger не установлен"
        return 1
    fi

    if [ -n "$new_mac" ]; then
        log_info "Установка MAC $new_mac на $iface"
        macchanger -m "$new_mac" "$iface"
    else
        log_info "Генерация случайного MAC на $iface"
        macchanger -r "$iface"
    fi
}

# Получение текущего IP
nullsec_get_ip() {
    local iface="${1:-$BR_LAN}"
    ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1
}

# Проверка интернет-соединения
nullsec_check_internet() {
    local timeout="${1:-5}"

    if ping -c 1 -W "$timeout" 8.8.8.8 >/dev/null 2>&1; then
        log_debug "Интернет доступен"
        return 0
    else
        log_warn "Интернет недоступен"
        return 1
    fi
}

# =============================================================================
# ФУНКЦИИ РАБОТЫ С ДАННЫМИ
# =============================================================================

# Инициализация базы данных
nullsec_init_db() {
    local db_file="${1:-$(nullsec_get_config DB_FILE)}"

    if ! command -v sqlite3 >/dev/null 2>&1; then
        log_error "sqlite3 не установлен"
        return 1
    fi

    mkdir -p "$(dirname "$db_file")"

    sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ssid TEXT,
    bssid TEXT,
    channel INTEGER,
    signal INTEGER,
    encryption TEXT,
    data TEXT
);

CREATE TABLE IF NOT EXISTS payloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    type TEXT,
    status TEXT DEFAULT 'inactive',
    config TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level TEXT,
    message TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF

    log_info "База данных инициализирована: $db_file"
}

# Сохранение результатов сканирования
nullsec_save_scan() {
    local ssid="$1"
    local bssid="$2"
    local channel="$3"
    local signal="$4"
    local encryption="$5"
    local data="$6"
    local db_file="${7:-$(nullsec_get_config DB_FILE)}"

    if [ ! -f "$db_file" ]; then
        nullsec_init_db "$db_file"
    fi

    sqlite3 "$db_file" << EOF
INSERT INTO scans (ssid, bssid, channel, signal, encryption, data)
VALUES ('$ssid', '$bssid', $channel, $signal, '$encryption', '$data');
EOF

    log_debug "Результат сканирования сохранён: $ssid ($bssid)"
}

# Получение результатов сканирования
nullsec_get_scans() {
    local limit="${1:-10}"
    local db_file="${2:-$(nullsec_get_config DB_FILE)}"

    if [ ! -f "$db_file" ]; then
        log_error "База данных не найдена: $db_file"
        return 1
    fi

    sqlite3 "$db_file" "SELECT * FROM scans ORDER BY timestamp DESC LIMIT $limit;"
}

# Работа с JSON
nullsec_json_get() {
    local json="$1"
    local key="$2"

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq не установлен"
        return 1
    fi

    echo "$json" | jq -r "$key" 2>/dev/null
}

# HTTP запросы
nullsec_http_get() {
    local url="$1"
    local timeout="${2:-30}"

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl не установлен"
        return 1
    fi

    curl -s --max-time "$timeout" "$url"
}

nullsec_http_post() {
    local url="$1"
    local data="$2"
    local timeout="${3:-30}"

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl не установлен"
        return 1
    fi

    curl -s -X POST -d "$data" --max-time "$timeout" "$url"
}

# =============================================================================
# ФУНКЦИИ УПРАВЛЕНИЯ ПРОЦЕССАМИ
# =============================================================================

# Запуск в фоне
nullsec_run_background() {
    local cmd="$1"
    local pid_file="$TMP_DIR/$(basename "$cmd" | sed 's/[^a-zA-Z0-9]/_/g').pid"

    log_info "Запуск в фоне: $cmd"

    # Запуск команды
    eval "$cmd" &
    local pid=$!

    # Сохранение PID
    echo "$pid" > "$pid_file"

    log_debug "PID сохранён: $pid_file ($pid)"
    echo "$pid"
}

# Остановка фоновых процессов
nullsec_kill_background_processes() {
    local pids=""

    # Поиск всех PID файлов
    for pid_file in "$TMP_DIR"/*.pid; do
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file" 2>/dev/null)
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                pids="$pids $pid"
                kill "$pid" 2>/dev/null && log_debug "Остановлен процесс: $pid"
            fi
            rm -f "$pid_file"
        fi
    done

    if [ -n "$pids" ]; then
        log_info "Остановлены фоновые процессы:$pids"
    fi
}

# Ожидание завершения
nullsec_wait_for() {
    local pid="$1"
    local timeout="${2:-30}"

    local count=0
    while [ $count -lt "$timeout" ]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            log_debug "Процесс $pid завершён"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done

    log_warn "Таймаут ожидания процесса $pid"
    return 1
}

# =============================================================================
# ФУНКЦИИ БЕЗОПАСНОСТИ И ОЧИСТКИ
# =============================================================================

# Очистка временных файлов
nullsec_clean_temp() {
    log_info "Очистка временных файлов"

    # Удаление старых логов
    find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true

    # Очистка tmp
    rm -rf "$TMP_DIR"/* 2>/dev/null || true

    # Очистка системного tmp
    find /tmp -name "nullsec_*" -type f -mtime +1 -delete 2>/dev/null || true
}

# Проверка свободного места
nullsec_check_space() {
    local path="${1:-/mmc}"
    local min_mb="${2:-50}"

    local avail_kb=$(df "$path" | tail -1 | awk '{print $4}')
    local avail_mb=$((avail_kb / 1024))

    if [ "$avail_mb" -lt "$min_mb" ]; then
        log_error "Недостаточно места на $path: ${avail_mb}MB < ${min_mb}MB"
        return 1
    else
        log_debug "Свободное место на $path: ${avail_mb}MB"
        return 0
    fi
}

# Генерация случайного имени файла
nullsec_random_filename() {
    local prefix="${1:-file}"
    local ext="${2:-tmp}"

    echo "${prefix}_$(date +%s)_$RANDOM.$ext"
}

# =============================================================================
# ФУНКЦИИ ДЛЯ ПЕЙЛОУДОВ
# =============================================================================

# Стандартный заголовок пейлоуда
nullsec_payload_header() {
    local payload_name="$1"
    local payload_version="${2:-1.0.0}"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Pineapple Pager Payload: $payload_name v$payload_version"
    echo "║  Library: $LIB_NAME v$LIB_VERSION"
    echo "║  Date: $(date)"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Стандартный footer пейлоуда
nullsec_payload_footer() {
    local payload_name="$1"
    local status="${2:-completed}"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Payload $payload_name $status"
    echo "║  Cleanup: $(nullsec_clean_temp && echo 'OK' || echo 'Failed')"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Проверка аргументов пейлоуда
nullsec_validate_args() {
    local required_args="$1"
    local actual_args="$#"

    if [ "$actual_args" -lt "$required_args" ]; then
        log_error "Недостаточно аргументов. Требуется: $required_args, получено: $actual_args"
        echo "Использование: $0 [аргументы]"
        return 1
    fi

    return 0
}

# =============================================================================
# ФУНКЦИИ ДЛЯ WPS И WIFI АТАК
# =============================================================================

# WPS сканирование
nullsec_wps_scan() {
    local iface="${1:-$WLAN0}"

    if ! command -v wash >/dev/null 2>&1; then
        log_error "wash не найден (из пакета reaver)"
        return 1
    fi

    log_info "Сканирование WPS сетей на $iface"
    wash -i "$iface" 2>/dev/null
}

# Pixie Dust атака
nullsec_pixie_dust() {
    local bssid="$1"
    local channel="$2"

    if ! command -v pixiewps >/dev/null 2>&1; then
        log_error "pixiewps не установлен"
        return 1
    fi

    if [ -z "$bssid" ] || [ -z "$channel" ]; then
        log_error "Требуется BSSID и канал"
        return 1
    fi

    log_info "Запуск Pixie Dust атаки на $bssid (канал $channel)"

    # Здесь должна быть логика захвата WPS handshake
    # Для демонстрации - просто вызов pixiewps
    pixiewps -e "PIN_PLACEHOLDER" -s "PSK_PLACEHOLDER" -n "$bssid"
}

# =============================================================================
# ФУНКЦИИ ДЛЯ MITM АТАК
# =============================================================================

# ARP spoofing (требует dsniff/arpspoof)
nullsec_arp_spoof() {
    local target="$1"
    local gateway="$2"
    local iface="${3:-$BR_LAN}"

    if ! command -v arpspoof >/dev/null 2>&1; then
        log_error "arpspoof не найден (требуется dsniff)"
        log_info "Альтернатива: используй python3 + scapy"
        return 1
    fi

    log_info "ARP spoofing: $target <-> $gateway на $iface"

    arpspoof -i "$iface" -t "$target" "$gateway" &
    local pid1=$!

    arpspoof -i "$iface" -t "$gateway" "$target" &
    local pid2=$!

    echo "$pid1 $pid2"
}

# =============================================================================
# ЭКСПОРТ ФУНКЦИЙ
# =============================================================================

# Экспорт всех функций для использования в пейлоудах
export -f nullsec_init
export -f nullsec_check_dependencies
export -f nullsec_setup_logging
export -f nullsec_cleanup
export -f nullsec_load_config
export -f nullsec_create_default_config
export -f nullsec_get_config
export -f nullsec_get_wifi_info
export -f nullsec_scan_wifi
export -f nullsec_change_mac
export -f nullsec_get_ip
export -f nullsec_check_internet
export -f nullsec_init_db
export -f nullsec_save_scan
export -f nullsec_get_scans
export -f nullsec_json_get
export -f nullsec_http_get
export -f nullsec_http_post
export -f nullsec_run_background
export -f nullsec_kill_background_processes
export -f nullsec_wait_for
export -f nullsec_clean_temp
export -f nullsec_check_space
export -f nullsec_random_filename
export -f nullsec_payload_header
export -f nullsec_payload_footer
export -f nullsec_validate_args
export -f nullsec_wps_scan
export -f nullsec_pixie_dust
export -f nullsec_arp_spoof
export -f log_info
export -f log_warn
export -f log_error
export -f log_debug

# =============================================================================
# ИНИЦИАЛИЗАЦИЯ ПРИ ЗАГРУЗКЕ
# =============================================================================

# Автоматическая инициализация при source
if [ "${NULLSEC_LIB_LOADED:-false}" != "true" ]; then
    NULLSEC_LIB_LOADED=true
    nullsec_init
fi

log_info "Библиотека $LIB_NAME готова к использованию"