# Инструкция по установке пакетов на Pineapple Pager

## 📋 Оглавление

1. [Подготовка хоста](#подготовка-хоста)
2. [Загрузка .ipk файлов](#загрузка-ipk-файлов)
3. [Передача на Pager](#передача-на-pager)
4. [Установка на Pager](#установка-на-pager)
5. [Проверка и верификация](#проверка-и-верификация)
6. [Решение проблем](#решение-проблем)

---

## Подготовка хоста

### Требования

- **ОС:** Linux (Ubuntu 20.04+), macOS, или WSL2
- **Инструменты:** wget/curl, git, ssh, scp
- **Пространство:** ~50 MB свободного места
- **速度:** Интернет-соединение (для загрузки)

### Установка инструментов

#### Linux (Ubuntu / Debian)

```bash
sudo apt-get update
sudo apt-get install -y wget curl openssh-client

# Установка git (опционально для клонирования репо)
sudo apt-get install -y git
```

#### macOS

```bash
# Используй Homebrew
brew install wget curl openssh git
```

#### Windows (WSL2)

```bash
# В терминале WSL2 (Ubuntu):
sudo apt-get install -y wget curl openssh-client git
```

---

## Загрузка .ipk файлов

### Вариант 1: Использование скрипта (рекомендуется)

```bash
# Клонируй репозиторий
git clone <repo> Openwrt24-ipk
cd Openwrt24-ipk

# Дай права на выполнение
chmod +x scripts/download-deps.sh

# Запусти загрузку
./scripts/download-deps.sh

# Результат: все .ipk в папке ipk-cache/
ls -lh ipk-cache/*.ipk
```

### Вариант 2: Ручная загрузка отдельных пакетов

```bash
# Создай папку
mkdir -p ipk-cache && cd ipk-cache

# Базовый URL
BASE="https://downloads.openwrt.org/releases/24.10.1/packages/mipsel_24kc/packages"
TARGET="https://downloads.openwrt.org/releases/24.10.1/targets/ramips/mt76x8/packages"

# Загрузи вручную нужные пакеты
wget "${BASE}/macchanger_1.7.0-3_mipsel_24kc.ipk"
wget "${BASE}/curl_8.11.1-1_mipsel_24kc.ipk"
wget "${BASE}/libcurl4_8.11.1-1_mipsel_24kc.ipk"
# ... и так далее
```

---

## Передача на Pager

### Требования для связи с Pager

1. Pager включён и подключён в сеть
2. SSH доступ включен (по умолчанию есть)
3. Известен IP адрес или hostname пager (обычно `192.168.1.1` или `pineapple`)

### Вариант 1: SCP (рекомендуется)

```bash
# Проверь IP Pager
ping pineapple  # или ping 192.168.1.1

# Создай папку на Pager (если её нет)
ssh root@pineapple "mkdir -p /mmc"

# Скопируй все .ipk
scp ipk-cache/*.ipk root@pineapple:/mmc/

# Подтверди передачу
ssh root@pineapple "ls -lh /mmc/*.ipk | wc -l"
```

### Вариант 2: Прямая загрузка на Pager через curl

Если у Pager есть интернет:

```bash
ssh root@pineapple "cd /mmc && $(cat scripts/download-deps.sh)"
```

### Вариант 3: USB накопитель (если сеть не работает)

```bash
# На хосте: скопируй файлы на USB
cp ipk-cache/*.ipk /media/usb/

# На Pager: подключи USB и скопируй
mount /dev/sda1 /mnt
cp /mnt/*.ipk /mmc/
umount /mnt
```

### Проверка передачи

```bash
# На хосте проверь, что все скопировалось
ssh root@pineapple "du -sh /mmc && ls -1 /mmc/*.ipk | wc -l"

# Сравни с локальным:
ls -1 ipk-cache/*.ipk | wc -l
```

---

## Установка на Pager

### Предварительные проверки

```bash
# SSH на Pager
ssh root@pineapple

# Проверь версию OpenWrt
cat /etc/os-release | grep OPENWRT_RELEASE

# Проверь свободное место
df -h
# Свободное место: /mmc     (основное)
# Свободное место: / (ROM)   (должно быть хотя бы 1 MB)
```

### Способ 1: Автоматическая установка (скрипт)

```bash
# На хосте скопируй скрипт установки
scp scripts/install-on-pager.sh root@pineapple:/tmp/

# На Pager запусти
ssh root@pineapple "chmod +x /tmp/install-on-pager.sh && /tmp/install-on-pager.sh"

# Дождись завершения
```

### Способ 2: Ручная пошаговая установка

```bash
# На Pager:
ssh root@pineapple

# Обновляем список пакетов
opkg update

# Добавляем направление установки на /mmc (если ещё не добавлено)
echo "dest mmc /mmc" >> /etc/opkg.conf

# Устанавливаем обязательные пакеты
opkg install -d mmc \
  macchanger \
  curl libcurl4 \
  iwinfo libiwinfo \
  pixiewps \
  ncat socat \
  jq \
  sqlite3-cli libsqlite3 \
  tmux \
  wget-ssl libssl3

# Дождись завершения (может занять 5-10 минут)
```

### Способ 3: Установка с локальными .ipk

```bash
# На Pager:
cd /mmc

# Обновляем зависимости (если возможно)
opkg update

# Устанавливаем локально из /mmc
opkg install -d mmc *.ipk

# Если есть конфликты, устанавливай по группам:
opkg install -d mmc \
  libssl3 libcurl4 libivinfo libsqlite3
# Дождись

opkg install -d mmc \
  macchanger curl iwinfo wget-ssl
# Дождись

opkg install -d mmc \
  pixiewps ncat socat jq sqlite3-cli tmux
```

### Флаги opkg

| Флаг | Значение | Пример |
|------|----------|--------|
| `-d mmc` | Установить на /mmc (microSD) вместо ROM | `opkg install -d mmc curl` |
| `-f` | Force (переписать конфликтующие файлы) | `opkg install -f curl` |
| `--force-depends` | Игнорировать конфликты зависимостей | `opkg install --force-depends pkg` |
| `--no-install` | Только скачать, не устанавливать | `opkg install --no-install pkg` |
| `update` | Обновить список репо | `opkg update` |

---

## Проверка и верификация

### После установки

```bash
# На Pager проверь все команды:

macchanger --version
curl --version
iwinfo wlan0 info       # Проверка работы
pixiewps --version
ncat --version
socat -V
jq --version
sqlite3 --version
tmux -V
wget --version

# Проверь списоке установленных:
opkg list-installed | grep -E '(macchanger|curl|iwinfo|jq|sqlite|tmux)'
```

### Проверка памяти

```bash
# Свободное ОЗУ
free -m

# Использовано на /mmc
du -sh /mmc

# Свободное место
df -h /mmc /

# PID процессы (чтобы убедиться ничего не висит)
ps aux | grep -E '(curl|wget|opkg)'
```

### Логирование

```bash
# Проверь логи opkg
cat /var/log/opkg.log

# Проверь системные логи
dmesg | tail -20

# Проверь, есть ли ошибки при загрузке
journalctl -xe | tail -20
```

---

## Решение проблем

### Проблема 1: "No space left on device"

```bash
# Причина: недостаточно места на /mmc или /

# Решение:
df -h  # Проверь размер

# Если /mmc заполнена:
rm -rf /mmc/*.ipk      # Удали старые .ipk если нужно
opkg cleanup           # Очисти временные файлы

# Если / (ROM) заполнена:
# Можешь только переустановить прошивку
# ИЛИ используй только -d mmc при установке
```

### Проблема 2: "Package not found"

```bash
# Причина: пакет не в официальном репо 24.10.1

# Решение:
opkg update
opkg list-available | grep packagename

# Если не находит:
# 1. Проверь название: может быть другое имя
# 2. Проверь версию Pager
# 3. Попробуй установить из локального .ipk:
opkg install ./packagename_*.ipk -d mmc
```

### Проблема 3: "Dependency issue" / "Conflicts"

```bash
# Причина: конфликт зависимостей или несовместимость

# Решение 1: Установи зависимости вручную
opkg install libssl3
opkg install libcurl4
opkg install curl

# Решение 2: Используй --force-depends
opkg install --force-depends curl

# Решение 3: Установи пакеты по одному
for pkg in curl jq tmux sqlite3-cli; do
  opkg install -d mmc "$pkg"
  sleep 2
done
```

### Проблема 4: SSH не работает

```bash
# Проверь подключение:
ping 192.168.1.1   # Или IP твого Pager

# Если не пингуется:
# 1. Проверь физическое подключение (USB, Ethernet)
# 2. Проверь, включен ли Pager
# 3. Перезагрузи: ssh root@pineapple "reboot"

# Если пингуется, но SSH не открывается:
ssh -v root@pineapple  # Проверка с логированием

# Проверь SSH сервис на Pager
ssh root@pineapple "/etc/init.d/dropbear status"
```

### Проблема 5: Pager зависает при установке

```bash
# Причина: недостаточно ОЗУ или процесс завис

# На хосте убей SSH:
Ctrl-C

# На Pager (если может подключиться):
pkill -f opkg
pkill -f wget

# Перезагрузи:
ssh root@pineapple "reboot"

# Попробуй установить по одному пакету:
opkg install -d mmc macchanger
sleep 10
opkg install -d mmc curl
# и так далее
```

### Проблема 6: Интернета на Pager нет

```bash
# Способ 1: Скачай .ipk на хосте, затем SCP:
./scripts/download-deps.sh
scp ipk-cache/*.ipk root@pineapple:/mmc/
ssh root@pineapple "opkg install /mmc/*.ipk -d mmc"

# Способ 2: Используй USB накопитель:
# (см. выше в "Передача на Pager -> Вариант 3")
```

---

## 🎯 Чек-лист установки

```
[ ] Загружены все .ipk файлы (./scripts/download-deps.sh)
[ ] Проверено свободное место на хосте (50+ MB)
[ ] Pager подключен в сеть и SSH доступен
[ ] Скопированы все .ipk на Pager (/mmc)
[ ] ssh root@pineapple "ls /mmc/*.ipk | wc -l" совпадает с локальным
[ ] На Pager: opkg update выполнена успешно
[ ] На Pager: /etc/opkg.conf содержит "dest mmc /mmc"
[ ] На Pager: установлены все обязательные пакеты
[ ] На Pager: проверены все команды (macchanger, curl, jq, и т.д.)
[ ] На Pager: свободное ОЗУ > 20 MB
[ ] На Pager: свободное место на /mmc > 10 MB
[ ] На Pager: логи не содержат критических ошибок
```

---

## 📚 Дополнительные ресурсы

- [OpenWrt Package Manager](https://openwrt.org/docs/guide_user/additional_software/opkg)
- [Pineapple Pager SSH](https://docs.hak5.org/pineapple-pager/getting-started)
- [OpenWrt SSH](https://openwrt.org/docs/guide_user/base_system/manage_packages)

---

**Последнее обновление:** 2026-05-12  
**Версия:** 1.0.0
