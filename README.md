# Teleproxy Installer

🌐 **Язык:** Русский | [English](README_EN.md)

Автоматический установщик и менеджер **Teleproxy** — высокоскоростного MTProto прокси нового поколения с защитой от DPI, маскировкой Fake-TLS и поддержкой Direct-to-DC. Он полностью заменяет устаревший MTProxy. Базируется на проекте [teleproxy/teleproxy](https://github.com/teleproxy/teleproxy).

## ✨ Возможности

### 🚀 Установка
- **Быстрая загрузка** — скрипт больше не компилирует код! Автоматически определяет архитектуру (`amd64`/`arm64`) и скачивает оптимизированный бинарник.
- **Авто-настройка Firewall** — интеллектуальная поддержка и автоматическое открытие портов в `UFW` (Ubuntu) и `Firewalld` (CentOS/Alma).
- **Сетевой форсаж (TCP BBR)** — установщик автоматически интегрирует алгоритм `BBR` в ядро Linux для максимальной пропускной способности.
- **Новая система конфигурации** — автоматическая генерация современного `config.toml`.

### 🔒 Безопасность и обход блокировок (DPI)
- **Fake-TLS** — трафик на 100% маскируется под защищенный HTTPS-переход (браузерный TLS 1.3).
- **SOCKS5 Upstream-маршрутизация** — полная поддержка перенаправления всего трафика к дата-центрам через сторонний SOCKS5 прокси (обход бан-листов магистральных серверов).
- **PROXY Protocol v1/v2** — возможность спрятать прокси за Nginx, HAProxy или Xray VPN без потери реальных IP-адресов клиентов в логах ("Хайд" режим без открытия портов).
- **Поддержка Спонсорских каналов** — интерактивный выбор: Direct-to-DC (Максимальная скорость) или Relay (Публичный режим c Ad-тегом).

### 🛠️ Управление (`teleproxy-ctl` CLI)
После установки в системе появится утилита `teleproxy-ctl` для управления прокси:

| Команда | Описание |
|---------|----------|
| `teleproxy-ctl status` | Статус сервиса |
| `teleproxy-ctl user-add` | Добавление пользователей с поддержкой лейблов, квот (`10G`) и лимитов IP |
| `teleproxy-ctl user-del` | Удаление секретов |
| `teleproxy-ctl links` | Генерация ссылок (TLS, SECURE, CLASSIC) и вывод QR-кодов в терминале |
| `teleproxy-ctl check` | Диагностика (доступность DC, NTP, проверка SNI) |
| `teleproxy-ctl backup` | Создание зашифрованного паролем бэкапа конфигурации |
| `teleproxy-ctl restore` | Восстановление конфигурации из архива |
| `teleproxy-ctl update` | Проверка обновлений и установка нового бинарника |
| `teleproxy-ctl reload` | Перезагрузка конфигов "на лету" без разрыва соединений |

### 📦 Обслуживание
- **Автообновление (Cron)** — скрипт сам раз в 3 дня проверяет новые релизы `teleproxy` на GitHub и обновляет их в фоне.
- **Полная деинсталляция** — `./mtproxy.sh uninstall` вычищает всё: сервис, cron-задачи, конфиги из `/etc` и автоматически закроет порты в Firewall, которые он открыл ранее.

## 📋 Использование

**Установка:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh)
```

**Управление:**
```bash
teleproxy-ctl status
teleproxy-ctl links
teleproxy-ctl help
```

**Удаление:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh) uninstall
```

## 📌 Требования

- **ОС:** Debian / Ubuntu (apt), CentOS, AlmaLinux, Rocky Linux, macOS
- **Архитектура:** x86_64 или aarch64 (ARM64)
- **Права:** root или sudo
- **Зависимости:** `curl`, `xxd`
