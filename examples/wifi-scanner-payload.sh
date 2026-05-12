#!/bin/sh
# wifi-scanner.sh — Пейлоуд для сканирования WiFi сетей
# Использует nullsec-lib для надежной работы
# Категория: recon/wifi

# Подключение библиотеки
. /usr/lib/nullsec-lib.sh

# Заголовок пейлоуда
nullsec_payload_header "WiFi Scanner" "2.0.0"

# Проверка аргументов
IFACE="${1:-wlan0}"
TIMEOUT="${2:-30}"

nullsec_validate_args 0 "$@" || exit 1

log_info "Запуск WiFi сканера на интерфейсе: $IFACE"
log_info "Таймаут сканирования: ${TIMEOUT} секунд"

# Проверка интерфейса
if ! iw dev "$IFACE" info >/dev/null 2>&1; then
    log_error "WiFi интерфейс $IFACE не найден или не готов"
    log_info "Доступные интерфейсы:"
    iw dev | grep Interface | awk '{print "  " $2}'
    exit 1
fi

# Проверка свободного места для базы данных
nullsec_check_space "/root" 10 || exit 1

# Инициализация базы данных
nullsec_init_db

# Смена MAC для анонимности (опционально)
if [ "${CHANGE_MAC:-false}" = "true" ]; then
    log_info "Смена MAC адреса для анонимности"
    nullsec_change_mac "$IFACE"
fi

# Запуск сканирования в фоне
log_info "Запуск сканирования WiFi сетей..."

SCAN_PID=$(nullsec_run_background "nullsec_scan_wifi '$IFACE' '$TIMEOUT'")

# Ожидание завершения сканирования
if nullsec_wait_for "$SCAN_PID" "$TIMEOUT"; then
    log_info "Сканирование завершено"
else
    log_warn "Сканирование прервано по таймауту"
fi

# Получение и обработка результатов
log_info "Обработка результатов сканирования..."

# Получаем последние результаты
SCAN_DATA=$(nullsec_get_scans 50)

if [ -z "$SCAN_DATA" ]; then
    log_warn "Результаты сканирования не найдены"
else
    # Парсинг и сохранение результатов
    echo "$SCAN_DATA" | while IFS='|' read -r id timestamp ssid bssid channel signal encryption data; do
        if [ -n "$ssid" ] && [ "$ssid" != "NULL" ]; then
            log_info "Найдена сеть: $ssid ($bssid) канал:$channel сигнал:$signal"
        fi
    done

    # Статистика
    NETWORK_COUNT=$(echo "$SCAN_DATA" | wc -l)
    OPEN_COUNT=$(echo "$SCAN_DATA" | grep -c "OPEN\|NONE" || echo "0")
    WPA_COUNT=$(echo "$SCAN_DATA" | grep -c "WPA" || echo "0")

    log_info "Статистика сканирования:"
    log_info "  Всего сетей: $NETWORK_COUNT"
    log_info "  Открытых: $OPEN_COUNT"
    log_info "  Защищенных WPA: $WPA_COUNT"
fi

# Экспорт результатов (опционально)
if [ "${EXPORT_RESULTS:-false}" = "true" ]; then
    EXPORT_FILE="/root/.nullsec/data/wifi_scan_$(date +%Y%m%d_%H%M%S).json"

    # Создание JSON с результатами
    JSON_DATA=$(nullsec_get_scans 100 | jq -R -s '
        split("\n") |
        map(select(. != "")) |
        map(split("|")) |
        map({
            id: .[0],
            timestamp: .[1],
            ssid: .[2],
            bssid: .[3],
            channel: .[4],
            signal: .[5],
            encryption: .[6],
            data: .[7]
        })
    ' 2>/dev/null)

    if [ -n "$JSON_DATA" ]; then
        echo "$JSON_DATA" > "$EXPORT_FILE"
        log_info "Результаты экспортированы: $EXPORT_FILE"
    fi
fi

# Проверка интернет-соединения
if nullsec_check_internet 5; then
    log_info "Интернет доступен - можно отправить результаты на сервер"

    # Пример отправки результатов (закомментировано)
    # nullsec_http_post "https://your-server.com/api/scans" "$JSON_DATA"
fi

# Завершение
nullsec_payload_footer "WiFi Scanner" "completed"