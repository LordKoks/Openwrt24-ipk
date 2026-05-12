# ⚡ QUICK REFERENCE - Как использовать скачанные пакеты

## На вашем компьютере (хост)

```bash
# 1️⃣ Перейди в папку проекта
cd Openwrt24-ipk

# 2️⃣ Копируй все .ipk на Pager
scp ipk-cache/*.ipk root@192.168.1.1:/mmc/

# Если не знаешь IP Pager:
scp ipk-cache/*.ipk root@pineapple:/mmc/
```

## На Pineapple Pager

```bash
# 1️⃣ Подключайся по SSH
ssh root@192.168.1.1
# или
ssh root@pineapple

# 2️⃣ (Опционально) Обнови список пакетов (требует интернет)
opkg update

# 3️⃣ Устанавливай ВСЁ СРАЗУ
opkg install -d mmc /mmc/*.ipk

# 4️⃣ ГОТОВО! Проверь
which curl jq sqlite3
curl --version
```

---

## Если что-то пошло не так

### "Package not found"
```bash
opkg update
opkg list | grep packagename
```

### "No space left on device"
```bash
df -h /mmc
rm /mmc/*.ipk.1 /mmc/*.ipk.old
opkg clean
```

### Зависание
```
Нажми: Ctrl-C
Затем: ssh root@pineapple "reboot"
Попробуй установить по одному:
  opkg install -d mmc /mmc/curl_8.12.1-r1_mipsel_24kc.ipk
  sleep 2
  opkg install -d mmc /mmc/jq_1.8.1-r1_mipsel_24kc.ipk
```

---

## ✅ Чек-лист

- [ ] Скопировал все .ipk на /mmc
- [ ] Подключился SSH к Pager
- [ ] Запустил `opkg update`
- [ ] Запустил `opkg install -d mmc /mmc/*.ipk`
- [ ] Проверил `which curl jq tmux`

**✨ ГОТОВО!**

---

## 📦 Что установилось (10 пакетов)

| Команда | Что это | Где использовать |
|---------|---------|------------------|
| `curl` | Качаем файлы/API | Везде |
| `wget` | Альтернатива curl | Везде |
| `jq` | JSON парсинг | Обработка результатов |
| `sqlite3` | Base данных | Хранение результатов |
| `macchanger` | Смена MAC | Маскировка |
| `tmux` | Фоновые сессии |长ие задачи |
| `socat` | Туннели | Переадресация котов |
| `ncat` | Сокеты | Reverse shell |
| `pixiewps` | WPS атака | Подбор WPS |
| `lsusb` | Информация USB | Обнаружение приборов |

---

## 🎯 Примеры использования

### Скачивание файла
```bash
curl https://example.com/file.zip -o file.zip
wget https://example.com/file.zip
```

### Парсинг JSON
```bash
curl https://api.example.com/data | jq '.results[]'
```

### Работа с БД  
```bash
sqlite3 results.db "INSERT INTO scans VALUES (1, 'AP1', 100)"
sqlite3 results.db "SELECT * FROM scans"
```

### WPS атака
```bash
pixiewps -e PSK1 -s PSK2 -n BSSID
```

### Фоновая сессия
```bash
tmux new-session -d "длинная_команда"
tmux list-sessions
tmux attach -t 0
```

---

## 📚 Подробнее

- Полная инструкция: `DEPLOYMENT_REPORT.md`
- Список пакетов: `IPK_MANIFEST.txt`
- Зависимости: `docs/PACKAGES.md`
- Пошагово: `docs/INSTALLATION.md`

---

**Автор:** GitHub Copilot  
**Дата:** 12.05.2026  
**Версия:** 1.0.0
