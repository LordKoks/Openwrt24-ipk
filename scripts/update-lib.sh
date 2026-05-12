#!/bin/sh
# update-lib.sh — Скрипт для обновления nullsec-lib на Pineapple Pager
# Обновляет библиотеку с GitHub или локального источника

# Конфигурация
LIB_URL="${1:-https://raw.githubusercontent.com/nullsecurity/pineapple-payloads/main/library/nullsec-lib.sh}"
LIB_PATH="/usr/lib/nullsec-lib.sh"
BACKUP_PATH="/usr/lib/nullsec-lib.sh.backup"
TEMP_FILE="/tmp/nullsec-lib-update.sh"

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log_info() {
    log "INFO: $1"
}

log_error() {
    log "ERROR: $1"
}

log_warn() {
    log "WARN: $1"
}

# Функция проверки зависимостей
check_dependencies() {
    local deps="curl wget sha256sum"
    local missing=""

    for dep in $deps; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing="$missing $dep"
        fi
    done

    if [ -n "$missing" ]; then
        log_error "Отсутствуют зависимости:$missing"
        log_info "Установите: opkg install curl wget coreutils-sha256sum"
        return 1
    fi

    return 0
}

# Функция создания резервной копии
create_backup() {
    if [ -f "$LIB_PATH" ]; then
        log_info "Создание резервной копии..."
        cp "$LIB_PATH" "$BACKUP_PATH"
        if [ $? -eq 0 ]; then
            log_info "Резервная копия создана: $BACKUP_PATH"
        else
            log_error "Ошибка создания резервной копии"
            return 1
        fi
    fi
}

# Функция скачивания новой версии
download_update() {
    local url="$1"

    log_info "Скачивание обновления из: $url"

    if echo "$url" | grep -q "^https://"; then
        curl -s -o "$TEMP_FILE" "$url"
    else
        wget -q -O "$TEMP_FILE" "$url"
    fi

    if [ $? -ne 0 ] || [ ! -f "$TEMP_FILE" ]; then
        log_error "Ошибка скачивания обновления"
        return 1
    fi

    # Проверка размера файла
    local size=$(wc -c < "$TEMP_FILE")
    if [ "$size" -lt 1000 ]; then
        log_error "Скачанный файл слишком мал ($size байт)"
        rm -f "$TEMP_FILE"
        return 1
    fi

    log_info "Файл скачан успешно ($size байт)"
}

# Функция проверки целостности
verify_integrity() {
    local file="$1"

    log_info "Проверка целостности..."

    # Проверка, что это bash скрипт
    if ! head -n 1 "$file" | grep -q "^#!/.*sh"; then
        log_error "Файл не является shell скриптом"
        return 1
    fi

    # Проверка наличия основных функций
    local required_functions="nullsec_init nullsec_log nullsec_scan_wifi"
    for func in $required_functions; do
        if ! grep -q "^${func}()" "$file"; then
            log_error "Отсутствует обязательная функция: $func"
            return 1
        fi
    done

    log_info "Целостность проверена"
}

# Функция применения обновления
apply_update() {
    local new_file="$1"

    log_info "Применение обновления..."

    # Установка новой версии
    mv "$new_file" "$LIB_PATH"
    if [ $? -ne 0 ]; then
        log_error "Ошибка установки обновления"
        return 1
    fi

    chmod +x "$LIB_PATH"
    log_info "Обновление применено успешно"
}

# Функция проверки обновления
check_update() {
    log_info "Проверка версии..."

    # Получение версии текущей библиотеки
    if [ -f "$LIB_PATH" ]; then
        local current_version=$(grep "^# Version:" "$LIB_PATH" | head -1 | cut -d: -f2 | tr -d ' ')
        if [ -n "$current_version" ]; then
            log_info "Текущая версия: $current_version"
        fi
    fi

    # Получение версии новой библиотеки
    if [ -f "$TEMP_FILE" ]; then
        local new_version=$(grep "^# Version:" "$TEMP_FILE" | head -1 | cut -d: -f2 | tr -d ' ')
        if [ -n "$new_version" ]; then
            log_info "Новая версия: $new_version"
        fi

        # Сравнение версий
        if [ "$current_version" = "$new_version" ]; then
            log_info "Версия не изменилась, обновление не требуется"
            return 1
        fi
    fi
}

# Функция отката
rollback() {
    if [ -f "$BACKUP_PATH" ]; then
        log_warn "Выполнение отката к предыдущей версии..."
        mv "$BACKUP_PATH" "$LIB_PATH"
        if [ $? -eq 0 ]; then
            log_info "Откат выполнен успешно"
        else
            log_error "Ошибка отката"
        fi
    else
        log_error "Резервная копия не найдена"
    fi
}

# Функция тестирования обновления
test_update() {
    log_info "Тестирование обновления..."

    # Попытка загрузки библиотеки
    if ! sh -c ". $LIB_PATH && nullsec_init >/dev/null 2>&1"; then
        log_error "Ошибка загрузки обновленной библиотеки"
        return 1
    fi

    # Проверка основных функций
    if ! sh -c ". $LIB_PATH && nullsec_log 'test' >/dev/null 2>&1"; then
        log_error "Ошибка в функции nullsec_log"
        return 1
    fi

    log_info "Тестирование пройдено"
}

# Функция очистки
cleanup() {
    rm -f "$TEMP_FILE"
    log_info "Временные файлы очищены"
}

# Основная логика
main() {
    log_info "=== NULLSEC-LIB UPDATE SCRIPT ==="

    # Проверка зависимостей
    if ! check_dependencies; then
        exit 1
    fi

    # Создание резервной копии
    if ! create_backup; then
        exit 1
    fi

    # Скачивание обновления
    if ! download_update "$LIB_URL"; then
        cleanup
        exit 1
    fi

    # Проверка обновления
    if ! check_update; then
        cleanup
        exit 0
    fi

    # Проверка целостности
    if ! verify_integrity "$TEMP_FILE"; then
        cleanup
        exit 1
    fi

    # Применение обновления
    if ! apply_update "$TEMP_FILE"; then
        log_error "Ошибка применения обновления, выполнение отката..."
        rollback
        cleanup
        exit 1
    fi

    # Тестирование
    if ! test_update; then
        log_error "Тестирование не пройдено, выполнение отката..."
        rollback
        cleanup
        exit 1
    fi

    # Очистка
    cleanup

    log_info "=== ОБНОВЛЕНИЕ ЗАВЕРШЕНО УСПЕШНО ==="
    log_info "Перезагрузите сессию или выполните: . $LIB_PATH"
}

# Обработка аргументов
case "$1" in
    "--rollback"|"-r")
        rollback
        ;;
    "--check"|"-c")
        if [ -f "$LIB_PATH" ]; then
            check_update
        else
            log_error "Библиотека не установлена"
        fi
        ;;
    "--help"|"-h")
        echo "Использование: $0 [URL] [опции]"
        echo "  URL - URL для скачивания обновления (по умолчанию: $LIB_URL)"
        echo "  -r, --rollback  - откат к предыдущей версии"
        echo "  -c, --check     - проверка версии"
        echo "  -h, --help      - эта справка"
        ;;
    *)
        main
        ;;
esac