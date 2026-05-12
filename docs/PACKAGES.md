# Полный список пакетов и зависимостей

## 📋 СПИСОК 1: Обязательные базовые пакеты

> Эти пакеты необходимы для работы 80% пейлоудов Hak5 и NullSec.

### Сетевые / Утилиты

| Пакет | Версия | Размер | Зависимости | Команда | Цель |
|-------|--------|--------|------------|---------|------|
| `macchanger` | 1.7.0-3 | 0.3 MB | libc | `macchanger` | Смена MAC адреса, спуфинг |
| `curl` | 8.11.1-1 | 0.8 MB | libcurl4, libssl3 | `curl` | HTTP/HTTPS запросы, API |
| `libcurl4` | 8.11.1-1 | 0.6 MB | zlib, libssl3 | — | Библиотека для curl |
| `netcat` / `ncat` | 7.95-1 | 0.1 MB | libc | `ncat` / `nc` | Сетевые сокеты, reverse shell |
| `socat` | 1.8.0.1-1 | 0.4 MB | libc | `socat` | Туннель данных, port forwarding |
| `wget-ssl` | 1.25.0-1 | 0.4 MB | libssl3 | `wget` | Загрузки с SSL/TLS |
| `libssl3` | 3.3.2-1 | 1.0 MB | zlib, ca-certificates | — | OpenSSL 3.0 библиотека |

### WiFi / Информационные

| Пакет | Версия | Размер | Зависимости | Команда | Цель |
|-------|--------|--------|------------|---------|------|
| `iwinfo` | 2024-10-20-68e9da35-1 | 0.2 MB | libiwinfo | `iwinfo` | Информация о WiFi интерфейсах |
| `libiwinfo` | 2024-10-20-68e9da35-1 | 0.2 MB | libuci, ubus | — | Библиотека для iwinfo |

### Утилиты обработки данных

| Пакет | Версия | Размер | Зависимости | Команда | Цель |
|-------|--------|--------|------------|---------|------|
| `jq` | 1.7.1-1 | 0.5 MB | libc | `jq` | Парсинг и фильтрация JSON |
| `sqlite3-cli` | 3470200-1 | 0.8 MB | libsqlite3, libcrypto | `sqlite3` | Работа с БД |
| `libsqlite3` | 3470200-1 | 0.3 MB | zlib | — | SQLite библиотека |

### Терминал / Сессии

| Пакет | Версия | Размер | Зависимости | Команда | Цель |
|-------|--------|--------|------------|---------|------|
| `tmux` | 3.5a-1 | 0.8 MB | libc, ncurses | `tmux` | Мультиплексер терминала (фоновые сессии) |

### WPS / Брутфорс

| Пакет | Версия | Размер | Зависимости | Команда | Цель |
|-------|--------|--------|------------|---------|------|
| `pixiewps` | 1.4.2-4 | 0.3 MB | libz | `pixiewps` | WPS Pixie Dust атака |

---

## 📋 СПИСОК 2: Опциональные специализированные пакеты

> Используются в конкретных пейлоудах, не требуются для основной функциональности.

### GPS / Геолокация

| Пакет | Версия | Размер | Зависимости | Цель |
|-------|--------|--------|------------|------|
| `gpsd` | 3.25-1 | 2 MB | libusb-1.0 | GPS daemon для wardriving |

### USB / Периферия

| Пакет | Версия | Размер | Зависимости | Цель |
|-------|--------|--------|------------|------|
| `libusb-1.0` | 1.0.27-2 | 0.2 MB | libusb-1.0-0 | USB API |
| `usbutils` | 017-1 | 0.3 MB | libudev, libusb-1.0 | lsusb, usb-devices |

### VPN / Туннели

| Пакет | Версия | Размер | Зависимости | Цель |
|-------|--------|--------|------------|------|
| `openvpn-openssl` | 2.6.12-1 | 1.5 MB | libssl3, libcrypto | VPN клиент |
| `stunnel` | 5.73-1 | 0.5 MB | libssl3, libc | SSL/TLS туннель |
| `libopenssl1` | 1.1.1w-2 | 1.2 MB | zlib | OpenSSL 1.1 (совместимость) |

---

## ⚙️ Таблица зависимостей (Dependency Graph)

```
curl
├── libcurl4
│   ├── zlib
│   └── libssl3
│       └── zlib
└── ca-certificates

iwinfo
└── libiwinfo
    ├── libuci
    └── ubus
        ├── libubox
        ├── libsystemd
        └── libubus

jq
└── oniguruma (встроено в jq)

sqlite3-cli
├── libsqlite3
│   └── zlib
└── libcrypto (не требуется часто)

tmux
├── libc
└── ncurses
    └── terminfo-data

wget-ssl
├── libssl3
└── zlib

gpsd
├── libusb-1.0
│   ├── libusb-1.0-0
│   └── libpthread
└── ncurses

openvpn-openssl
├── libssl3
├── libcrypto
├── zlib
├── lzo
└── iproute2 (опция)
```

---

## 💾 Общие зависимости (предустановлены в Pager)

Эти пакеты **уже входят в стандартную прошивку** Pineapple и не нужно скачивать:

| Пакет | Версия (примерная) | Команды в прошивке |
|-------|-------------------|-------------------|
| libc | 2.37 | libc, malloc, stdio и т.д. |
| libpthread | 2.37 | pthread функции |
| zlib | 1.2.13 | Сжатие данных |
| ncurses | 6.4 | Терминальный интерфейс |
| ca-certificates | 2024.10 | SSL сертификаты |
| ubus | 2024 | OpenWrt message bus |
| uci | 2024 | OpenWrt конфиг система |
| iproute2 | 6.2 | ip, tc, ss команды |
| iptables | 1.8 | Фаервол (уже есть) |
| dnsmasq | 2.89 | DNS/DHCP (уже есть) |
| hostapd | 2024 | AP режим (уже есть) |

---

## 🎯 Матрица: Пейлоуд → Требуемые пакеты

### Recon пейлоуды

| Пейлоуд | Обязательные | Опциональные |
|---------|-------------|-------------|
| `scan_ap.sh` | iwinfo | — |
| `handshake_capture.sh` | aircrack-ng, hcxdumptool | hcxtools |
| `probe_sniff.sh` | tcpdump, aircrack-ng | tshark |
| `wardriving_gps.sh` | — | gpsd, iwinfo |

### Access Control пейлоуды

| Пейлоуд | Обязательные | Опциональные |
|---------|-------------|-------------|
| `deauth_mdk4.sh` | mdk4 | — |
| `wps_reaver.sh` | reaver, wash | pixiewps |
| `handshake_capture.sh` | aircrack-ng | hcxdumptool |

### Exfiltration пейлоуды

| Пейлоуд | Обязательные | Опциональные |
|---------|-------------|-------------|
| `dns_exfil.sh` | dnsmasq | jq |
| `http_tunnel.sh` | curl, wget-ssl | socat |
| `reverse_shell.sh` | ncat, socat | tmux |

### Tools

| Пейлоуд | Обязательные | Опциональные |
|---------|-------------|-------------|
| `network_scan.sh` | nmap | jq |
| `api_call.sh` | curl, wget-ssl, jq | — |
| `database_query.sh` | sqlite3 | — |

### NullSec / Advanced

| Пейлоуд | Обязательные | Опциональные |
|---------|-------------|-------------|
| `nullsec-iface.sh` | iwinfo, ip | — |
| `nullsec-parse.sh` | jq, sqlite3, awk | — |
| `arp_mitm.sh` | arpspoof* | curl, socat |
| `dns_spoof.sh` | dnsmasq, curl | dnsspoof* |
| `ssl_mitm.sh` | sslstrip** | curl, wget-ssl |

> `*` — требует компиляции из dsniff
> `**` — требует python3 + twisted

---

## 📊 Потребление ресурсов

### ОЗУ при запуске

| Пакет / Команда | Resident | Shared | Комментарий |
|-----------------|----------|--------|-----------|
| `curl` | 1-2 MB | ~0.5 MB | Пиковое потребление при больших файлах |
| `jq` | 3-5 MB | ~1 MB | Зависит от размера JSON |
| `sqlite3` | 2-3 MB | ~0.5 MB | Пиковое при больших DB |
| `tmux` | 1-2 MB | ~0.5 MB | Постоянный процесс |
| `netcat` | ~0.5 MB | ~0.2 MB | Очень легкий |
| `socat` | ~1 MB | ~0.3 MB | Легкий |
| `pixiewps` | ~0.8 MB | ~0.2 MB | Легкий |
| `macchanger` | ~0.3 MB | ~0.1 MB | Очень легкий |

> ✅ Сумме: ~15-20 MB на все. Pager имеет 80 MB, что достаточно.

### Дисковое пространство

| Пакет | На диск | Распаковано | Итого |
|-------|--------|------------|-------|
| Все обязательные | ~2 MB | ~8 MB | ~10 MB |
| + опциональные | ~1 MB | ~5 MB | ~6 MB |
| **Итого** | **~3 MB** | **~13 MB** | **~16 MB** |

> `/mmc` должна иметь минимум **50 MB** свободного места.

---

## 🔍 Архитектурные замечания

### MIPS Little Endian (mipsel)

Процессор Pineapple Pager: **ramips/mt76x8 (MIPS 24K)**

- Байтовый порядок: Little Endian
- Вариант: 24K (Мicroarchitecture)
- 32-битная архитектура
- Пакеты в OpenWrt для этой архитектуры выбираются автоматически

### Проверка совместимости

```bash
# На Pager:
uname -m    # mips
file /bin/busybox  # ELF 32-bit LSB executable, MIPS...
opkg info curl | grep Architecture  # mipsel_24kc
```

---

## 📥 Источники пакетов (OpenWrt 24.10.1)

| Категория | Источник | URL |
|-----------|----------|-----|
| Базовые пакеты | packages/mipsel_24kc | `https://downloads.openwrt.org/.../24.10.1/packages/mipsel_24kc/` |
| Target-специфичные | targets/ramips/mt76x8 | `https://downloads.openwrt.org/.../24.10.1/targets/ramips/mt76x8/packages/` |
| Зависимости | Embedded inside .ipk | Извлекаются автоматически `opkg` |

---

## ⚡ Быстрая установка всех обязательных

```bash
# На Pager:
opkg update
opkg install -d mmc \
  macchanger curl libcurl4 \
  iwinfo libiwinfo \
  pixiewps \
  ncat socat \
  jq \
  sqlite3-cli libsqlite3 \
  tmux \
  wget-ssl libssl3
```

---

## 🚀 Проверка после установки

```bash
# На Pager, после установки:

# 1. Проверь наличие всех команд:
which macchanger curl iwinfo pixiewps ncat socat jq sqlite3 tmux wget

# 2. Проверь версии:
macchanger --version
curl --version
jq --version
sqlite3 --version
tmux -V
wget --version

# 3. Проверь размер:
du -sh /mmc

# 4. Проверь свободное место:
df -h /mmc

# 5. Проверь список установленных (через opkg):
opkg list-installed | grep -E '(macchanger|curl|iwinfo|jq|sqlite|tmux|wget|socat|ncat|pixiewps)'
```

---

## 📚 Доп. ссылки

- [OpenWrt Package Search](https://openwrt.org/packages/start)
- [IPK Format Documentation](https://openwrt.org/docs/guide_user/installation/sysupgrade.html)
- [Pineapple Pager Documentation](https://docs.hak5.org/pineapple-pager)
- [Hak5 Payloads](https://github.com/hak5/wifipineapplepager-payloads)

---

**Последнее обновление:** 2026-05-12  
**Версия:** 1.0.0
