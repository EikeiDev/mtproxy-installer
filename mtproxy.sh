#!/bin/bash

# Teleproxy Installation Script
# Downloads binary, creates TOML config, creates systemd service,
# and creates management utility in /usr/local/bin/teleproxy-ctl
#
# Usage:
#   ./mtproxy.sh          - Install Teleproxy
#   ./mtproxy.sh uninstall - Remove Teleproxy completely

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Language selection
echo -e "${BLUE}Teleproxy Installer${NC}"
echo -e "${CYAN}1${NC} - English"
echo -e "${CYAN}2${NC} - Русский"
read -p "Select language / Выберите язык [1/2]: " LANG_CHOICE
[[ "$LANG_CHOICE" == "2" ]] && LANG_SEL="ru" || LANG_SEL="en"

# Save language for management utility
mkdir -p /etc/teleproxy
echo "$LANG_SEL" > /etc/teleproxy/lang

set_messages() {
if [[ "$1" == "ru" ]]; then
    MSG_TITLE="Установка Teleproxy"
    MSG_ROOT="Этот установщик должен быть запущен от root (используйте sudo)."
    MSG_UNINSTALL_TITLE="🗑️  Удаление Teleproxy"
    MSG_UNINSTALL_WARN="ВНИМАНИЕ: Это полностью удалит Teleproxy и все связанные файлы!"
    MSG_UNINSTALL_LIST="Будет удалено:"
    MSG_UNINSTALL_I1="Сервис: /etc/systemd/system/teleproxy.service"
    MSG_UNINSTALL_I2="Директория: /etc/teleproxy (конфигурации)"
    MSG_UNINSTALL_I3="Утилиты: /usr/local/bin/teleproxy, /usr/local/bin/teleproxy-ctl, и скрипт обновления"
    MSG_UNINSTALL_I4="Системный пользователь: teleproxy"
    MSG_UNINSTALL_I5="Cron задача: /etc/cron.d/teleproxy-updater"
    MSG_UNINSTALL_CONFIRM="Вы уверены? (введите 'YES' для подтверждения): "
    MSG_UNINSTALL_CANCEL="Удаление отменено."
    MSG_REMOVING="Удаление Teleproxy..."
    MSG_STOPPING="Остановка сервиса Teleproxy..."
    MSG_DISABLING="Отключение сервиса Teleproxy..."
    MSG_RM_FIREWALL="Удаление правила файрвола для порта"
    MSG_RM_SERVICE="Удаление файла сервиса..."
    MSG_RM_INSTALLDIR="Удаление директории /etc/teleproxy..."
    MSG_RM_UTILITY="Удаление бинарника и утилиты управления..."
    MSG_RM_USER="Удаление пользователя teleproxy..."
    MSG_UNINSTALL_DONE="✅ Teleproxy полностью удалён!"
    MSG_UNINSTALL_DONE2="Все файлы, сервисы и конфигурации удалены."
    MSG_HELP_TITLE="Скрипт установки Teleproxy"
    MSG_HELP_USAGE="Использование:"
    MSG_HELP_INSTALL="Установить Teleproxy с интерактивной настройкой"
    MSG_HELP_UNINSTALL="Полностью удалить Teleproxy и все файлы"
    MSG_HELP_HELP="Показать эту справку"
    MSG_HELP_AFTER="После установки используйте команду 'teleproxy-ctl' для управления."
    MSG_ERR_UNKNOWN="Ошибка: Неизвестный аргумент"
    MSG_ERR_USAGE="Используйте '$0 help' для справки."
    MSG_PORT_PROMPT="Введите порт прокси (по умолчанию"
    MSG_INSTALLING="Установка Teleproxy..."
    MSG_DEPS="Установка зависимостей..."
    MSG_NO_APT="apt не найден. Установите curl и xxd вручную."
    MSG_DEPS_MANUAL="Установите: curl, xxd."
    MSG_DOWNLOADING="Загрузка бинарника Teleproxy..."
    MSG_DOWNLOAD_FAIL="Установка не удалась! Проверьте вашу архитектуру ОС и сеть."
    MSG_BIN_INSTALLED="Бинарник установлен в"
    MSG_SECRET_EXISTING="Используется существующий секрет:"
    MSG_SECRET_NEW="Сгенерирован новый секрет:"
    MSG_GET_IP="Получение внешнего IPv4 адреса..."
    MSG_IP_FAIL="Не удалось определить внешний IPv4 адрес"
    MSG_IP_MANUAL="Проверьте IPv4 вручную: curl -4 ifconfig.me"
    MSG_IP_OK="Обнаружен внешний IPv4:"
    MSG_DOMAIN_TITLE="🌐 Настройка домена сервера (опционально):"
    MSG_DOMAIN_DESC="Вы можете использовать доменное имя вместо IP адреса для ссылок."
    MSG_DOMAIN_EXAMPLES="Примеры: proxy.example.com, vpn.mydomain.org"
    MSG_DOMAIN_EMPTY="Оставьте пустым для использования IP:"
    MSG_DOMAIN_PROMPT="Введите доменное имя сервера (опционально): "
    MSG_DOMAIN_USING="Используется домен:"
    MSG_DOMAIN_INVALID="Неверный формат домена. Используется IP адрес."
    MSG_DOMAIN_IP="Используется IP адрес:"
    MSG_TLS_TITLE="🔒 Настройка TLS домена (Fake-TLS Маскировка):"
    MSG_TLS_DESC="Teleproxy использует домен для маскировки под обычный трафик HTTPS."
    MSG_TLS_EXAMPLES="Примеры: cloudflare.com, microsoft.com, apple.com"
    MSG_TLS_PROMPT="Введите TLS домен для маскировки (по умолчанию"
    MSG_TLS_USING="Используется TLS домен:"
    MSG_WORKERS="Используется 1 воркер (по умолчанию)"
    MSG_SERVICE_CREATE="Создание systemd сервиса..."
    MSG_UFW_OPEN="UFW: Открыт порт"
    MSG_UTIL_CREATE="Создание утилиты управления teleproxy-ctl..."
    MSG_SVC_RUNNING="✅ Сервис Teleproxy запущен!"
    MSG_SVC_FAIL="❌ Сервис не удалось запустить"
    MSG_COMPLETE="🎉 Установка завершена!"
    MSG_QUICK="📋 Быстрые команды:"
    MSG_QUICK1="Статус и ссылки"
    MSG_QUICK2="Перезапуск сервиса"
    MSG_QUICK3="Ссылки подключения"
    MSG_QUICK4="Статистика прокси"
    MSG_QUICK6="Все команды"
    MSG_SAVED="📄 Конфигурация сохранена в:"
    MSG_UTIL_PATH="🔧 Утилита управления:"
    MSG_AUTOSTART="🔄 Сервис запускается автоматически"
    MSG_STATS_INFO="📊 QR коды и Статистика:"
    MSG_REMOVE_LATER="💡 Для полного удаления:"
else
    MSG_TITLE="Teleproxy Installation"
    MSG_ROOT="This installer must be run as root (use sudo)."
    MSG_UNINSTALL_TITLE="🗑️  Teleproxy Uninstallation"
    MSG_UNINSTALL_WARN="WARNING: This will completely remove Teleproxy and all related files!"
    MSG_UNINSTALL_LIST="The following will be deleted:"
    MSG_UNINSTALL_I1="Service: /etc/systemd/system/teleproxy.service"
    MSG_UNINSTALL_I2="Configuration directory: /etc/teleproxy"
    MSG_UNINSTALL_I3="Binaries: /usr/local/bin/teleproxy, /usr/local/bin/teleproxy-ctl, and updater script"
    MSG_UNINSTALL_I4="System user: teleproxy"
    MSG_UNINSTALL_I5="Cron job: /etc/cron.d/teleproxy-updater"
    MSG_UNINSTALL_CONFIRM="Are you sure? (type 'YES' to confirm): "
    MSG_UNINSTALL_CANCEL="Uninstallation cancelled."
    MSG_REMOVING="Removing Teleproxy..."
    MSG_STOPPING="Stopping Teleproxy service..."
    MSG_DISABLING="Disabling Teleproxy service..."
    MSG_RM_FIREWALL="Removing firewall rule for port"
    MSG_RM_SERVICE="Removing service file..."
    MSG_RM_INSTALLDIR="Removing configuration directory /etc/teleproxy..."
    MSG_RM_UTILITY="Removing binaries and management utility..."
    MSG_RM_USER="Removing system user teleproxy..."
    MSG_UNINSTALL_DONE="✅ Teleproxy has been completely removed!"
    MSG_UNINSTALL_DONE2="All files, services, and configurations have been deleted."
    MSG_HELP_TITLE="Teleproxy Installation Script"
    MSG_HELP_USAGE="Usage:"
    MSG_HELP_INSTALL="Install Teleproxy with interactive setup"
    MSG_HELP_UNINSTALL="Completely remove Teleproxy and all files"
    MSG_HELP_HELP="Show this help message"
    MSG_HELP_AFTER="After installation, use 'teleproxy-ctl' command to manage the service."
    MSG_ERR_UNKNOWN="Error: Unknown argument"
    MSG_ERR_USAGE="Use '$0 help' for usage information."
    MSG_PORT_PROMPT="Enter proxy port (default"
    MSG_INSTALLING="Installing Teleproxy..."
    MSG_DEPS="Installing dependencies..."
    MSG_NO_APT="apt not found. Install curl and xxd manually."
    MSG_DEPS_MANUAL="Install: curl, xxd."
    MSG_DOWNLOADING="Downloading Teleproxy binary..."
    MSG_DOWNLOAD_FAIL="Installation failed! Check your OS architecture and network."
    MSG_BIN_INSTALLED="Binary installed to"
    MSG_SECRET_EXISTING="Using existing secret:"
    MSG_SECRET_NEW="Generated new secret:"
    MSG_GET_IP="Getting external IPv4 address..."
    MSG_IP_FAIL="Failed to detect external IPv4 address"
    MSG_IP_MANUAL="Please manually check your IPv4 with: curl -4 ifconfig.me"
    MSG_IP_OK="Detected external IPv4:"
    MSG_DOMAIN_TITLE="🌐 Server Domain Setup (Optional):"
    MSG_DOMAIN_DESC="You can use a domain name instead of IP address for links."
    MSG_DOMAIN_EXAMPLES="Examples: proxy.example.com, vpn.mydomain.org"
    MSG_DOMAIN_EMPTY="Leave empty to use IP address:"
    MSG_DOMAIN_PROMPT="Enter server domain name (optional): "
    MSG_DOMAIN_USING="Using domain:"
    MSG_DOMAIN_INVALID="Invalid domain format. Using IP address instead."
    MSG_DOMAIN_IP="Using IP address:"
    MSG_TLS_TITLE="🔒 TLS Domain Setup (Fake-TLS):"
    MSG_TLS_DESC="Teleproxy uses a domain for TLS certificate masking to avoid DPI detection."
    MSG_TLS_EXAMPLES="Examples: cloudflare.com, github.com, microsoft.com"
    MSG_TLS_PROMPT="Enter TLS domain for masking (default"
    MSG_TLS_USING="Using TLS domain:"
    MSG_WORKERS="Using 1 worker (default)"
    MSG_SERVICE_CREATE="Creating systemd service..."
    MSG_UFW_OPEN="UFW: Opened port"
    MSG_UTIL_CREATE="Creating management utility teleproxy-ctl..."
    MSG_SVC_RUNNING="✅ Teleproxy service is running!"
    MSG_SVC_FAIL="❌ Service failed to start"
    MSG_COMPLETE="🎉 Installation Complete!"
    MSG_QUICK="📋 Quick Commands:"
    MSG_QUICK1="Show status and links"
    MSG_QUICK2="Restart service"
    MSG_QUICK3="Show connection links"
    MSG_QUICK4="Show proxy statistics"
    MSG_QUICK6="Show all commands"
    MSG_SAVED="📄 Configuration saved to:"
    MSG_UTIL_PATH="🔧 Management utility:"
    MSG_AUTOSTART="🔄 Service will auto-start on boot"
    MSG_STATS_INFO="📊 QR Codes mapping & Statistics:"
    MSG_REMOVE_LATER="💡 To completely remove later:"
fi
}
set_messages "$LANG_SEL"

echo -e "${BLUE}$MSG_TITLE${NC}\n"

# Require root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}$MSG_ROOT${NC}"
    exit 1
fi

# Check for uninstall option
if [[ "$1" == "uninstall" ]]; then
    echo -e "${YELLOW}$MSG_UNINSTALL_TITLE${NC}\n"
    
    echo -e "${RED}$MSG_UNINSTALL_WARN${NC}"
    echo -e "${YELLOW}$MSG_UNINSTALL_LIST${NC}"
    echo -e "  • $MSG_UNINSTALL_I1"
    echo -e "  • $MSG_UNINSTALL_I2"
    echo -e "  • $MSG_UNINSTALL_I3"
    echo -e "  • $MSG_UNINSTALL_I4"
    echo -e "  • $MSG_UNINSTALL_I5"
    echo ""
    
    read -p "$MSG_UNINSTALL_CONFIRM" CONFIRM
    
    if [[ "$CONFIRM" != "YES" ]]; then
        echo -e "${GREEN}$MSG_UNINSTALL_CANCEL${NC}"
        exit 0
    fi
    
    echo -e "\n${YELLOW}$MSG_REMOVING${NC}"
    
    UNINSTALL_PORT=""
    if [[ -f "/etc/teleproxy/config.toml" ]]; then
        UNINSTALL_PORT=$(grep "port =" /etc/teleproxy/config.toml | awk '{print $3}')
    fi
    
    if systemctl is-active --quiet teleproxy; then
        echo -e "${YELLOW}$MSG_STOPPING${NC}"
        systemctl stop teleproxy
    fi
    
    if systemctl is-enabled --quiet teleproxy 2>/dev/null; then
        echo -e "${YELLOW}$MSG_DISABLING${NC}"
        systemctl disable teleproxy
    fi
    
    if [[ -n "$UNINSTALL_PORT" ]]; then
        if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
            if ufw status | grep -q "${UNINSTALL_PORT}/tcp"; then
                echo -e "${YELLOW}$MSG_RM_FIREWALL $UNINSTALL_PORT...${NC}"
                ufw delete allow ${UNINSTALL_PORT}/tcp 2>/dev/null
            fi
        fi
    fi
    
    if [[ -f "/etc/systemd/system/teleproxy.service" ]]; then
        echo -e "${YELLOW}$MSG_RM_SERVICE${NC}"
        rm -f "/etc/systemd/system/teleproxy.service"
        systemctl daemon-reload
    fi
    
    if [[ -d "/etc/teleproxy" ]]; then
        echo -e "${YELLOW}$MSG_RM_INSTALLDIR${NC}"
        rm -rf "/etc/teleproxy"
    fi
    
    if [[ -f "/usr/local/bin/teleproxy" ]]; then
        echo -e "${YELLOW}$MSG_RM_UTILITY${NC}"
        rm -f "/usr/local/bin/teleproxy"
        rm -f "/usr/local/bin/teleproxy-ctl"
        rm -f "/usr/local/bin/teleproxy-updater"
        rm -f "/etc/cron.d/teleproxy-updater"
    fi
    
    if id "teleproxy" &>/dev/null; then
        echo -e "${YELLOW}$MSG_RM_USER${NC}"
        userdel teleproxy 2>/dev/null || true
    fi
    
    echo -e "\n${GREEN}$MSG_UNINSTALL_DONE${NC}"
    echo -e "${CYAN}$MSG_UNINSTALL_DONE2${NC}"
    
    exit 0
fi

if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "${BLUE}$MSG_HELP_TITLE${NC}\n"
    echo "$MSG_HELP_USAGE"
    echo -e "  ${GREEN}$0${NC}              - $MSG_HELP_INSTALL"
    echo -e "  ${GREEN}$0 uninstall${NC}    - $MSG_HELP_UNINSTALL"
    echo -e "  ${GREEN}$0 help${NC}         - $MSG_HELP_HELP"
    echo ""
    echo "$MSG_HELP_AFTER"
    exit 0
fi

if [[ -n "$1" && "$1" != "install" ]]; then
    echo -e "${RED}$MSG_ERR_UNKNOWN '$1'${NC}"
    echo -e "$MSG_ERR_USAGE"
    exit 1
fi

# Configuration
CONFIG_DIR="/etc/teleproxy"
SERVICE_NAME="teleproxy"
SERVICE_USER="teleproxy"
BIN_FILE="/usr/local/bin/teleproxy"
DEFAULT_PORT=443
STATS_PORT=8888
WORKERS=1

# Get user input
read -p "$MSG_PORT_PROMPT: $DEFAULT_PORT): " USER_PORT
PORT=${USER_PORT:-$DEFAULT_PORT}

echo -e "\n${YELLOW}$MSG_INSTALLING${NC}"

echo -e "${YELLOW}$MSG_DEPS${NC}"
if command -v apt >/dev/null 2>&1; then
    apt update -qq
    apt install -y curl xxd jq vim-common
else
    if ! command -v curl >/dev/null 2>&1 || ! command -v xxd >/dev/null 2>&1; then
        echo -e "${RED}$MSG_NO_APT${NC}"
        echo -e "${YELLOW}$MSG_DEPS_MANUAL${NC}"
        exit 1
    fi
fi

mkdir -p "$CONFIG_DIR"

systemctl stop teleproxy 2>/dev/null

echo -e "${YELLOW}$MSG_DOWNLOADING${NC}"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_SUFFIX="amd64" ;;
    aarch64) ARCH_SUFFIX="arm64" ;;
    *)       echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

GITHUB_REPO="teleproxy/teleproxy"
URL="https://github.com/$GITHUB_REPO/releases/latest/download/teleproxy-linux-${ARCH_SUFFIX}"

if ! curl -fsSL -o "$BIN_FILE.tmp" "$URL"; then
    echo -e "${RED}$MSG_DOWNLOAD_FAIL${NC}"
    exit 1
fi
chmod +x "$BIN_FILE.tmp"
mv "$BIN_FILE.tmp" "$BIN_FILE"
echo "$URL" > "$CONFIG_DIR/installed_url"
echo -e "${GREEN}$MSG_BIN_INSTALLED $BIN_FILE${NC}"

if [[ -f "$CONFIG_DIR/config.toml" ]] && grep -q "key =" "$CONFIG_DIR/config.toml"; then
    USER_SECRET=$(grep "key =" "$CONFIG_DIR/config.toml" | head -1 | cut -d'"' -f2)
    echo -e "${GREEN}$MSG_SECRET_EXISTING $USER_SECRET${NC}"
else
    USER_SECRET=$($BIN_FILE generate-secret 2>/dev/null || head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
    echo -e "${GREEN}$MSG_SECRET_NEW $USER_SECRET${NC}"
fi

echo -e "${YELLOW}$MSG_GET_IP${NC}"
EXTERNAL_IP=""
for service in "ipv4.icanhazip.com" "ipv4.ident.me" "ifconfig.me/ip" "api.ipify.org"; do
    if EXTERNAL_IP=$(curl -4 -s --connect-timeout 10 "$service" 2>/dev/null) && [[ -n "$EXTERNAL_IP" ]]; then
        if [[ $EXTERNAL_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            IFS='.' read -ra ADDR <<< "$EXTERNAL_IP"
            valid=true
            for i in "${ADDR[@]}"; do
                if [[ $i -gt 255 || $i -lt 0 ]]; then
                    valid=false
                    break
                fi
            done
            if [[ $valid == true ]]; then
                break
            fi
        fi
    fi
    EXTERNAL_IP=""
done

if [[ -z "$EXTERNAL_IP" ]]; then
    EXTERNAL_IP="YOUR_SERVER_IP"
    echo -e "${RED}$MSG_IP_FAIL${NC}"
    echo -e "${YELLOW}$MSG_IP_MANUAL${NC}"
else
    echo -e "${GREEN}$MSG_IP_OK $EXTERNAL_IP${NC}"
fi

echo -e "\n${YELLOW}$MSG_DOMAIN_TITLE${NC}"
echo -e "${CYAN}$MSG_DOMAIN_DESC${NC}"
echo -e "${CYAN}$MSG_DOMAIN_EXAMPLES${NC}"
echo -e "${CYAN}$MSG_DOMAIN_EMPTY $EXTERNAL_IP${NC}"
echo ""
read -p "$MSG_DOMAIN_PROMPT" USER_DOMAIN

if [[ -n "$USER_DOMAIN" ]]; then
    if [[ $USER_DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        PROXY_HOST="$USER_DOMAIN"
        echo -e "${GREEN}$MSG_DOMAIN_USING $PROXY_HOST${NC}"
    else
        echo -e "${RED}$MSG_DOMAIN_INVALID${NC}"
        PROXY_HOST="$EXTERNAL_IP"
    fi
else
    PROXY_HOST="$EXTERNAL_IP"
    echo -e "${GREEN}$MSG_DOMAIN_IP $PROXY_HOST${NC}"
fi

echo -e "\n${YELLOW}$MSG_TLS_TITLE${NC}"
echo -e "${CYAN}$MSG_TLS_DESC${NC}"
echo -e "${CYAN}$MSG_TLS_EXAMPLES${NC}"
echo ""

TLS_DOMAINS=("www.cloudflare.com" "www.microsoft.com" "www.apple.com" "www.samsung.com")
RANDOM_DOMAIN=${TLS_DOMAINS[$RANDOM % ${#TLS_DOMAINS[@]}]}

read -p "$MSG_TLS_PROMPT: $RANDOM_DOMAIN): " USER_TLS_DOMAIN
TLS_DOMAIN=${USER_TLS_DOMAIN:-$RANDOM_DOMAIN}
echo -e "${GREEN}$MSG_TLS_USING $TLS_DOMAIN${NC}"

if ! id "$SERVICE_USER" >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
fi

cat > "$CONFIG_DIR/config.toml" << EOL
# Teleproxy configuration
# Edit and run: systemctl reload teleproxy
port = $PORT
stats_port = $STATS_PORT
http_stats = true
user = "$SERVICE_USER"
direct = true
workers = $WORKERS
domain = "$TLS_DOMAIN"

[[secret]]
key = "$USER_SECRET"
# label = "default"
EOL

chown root:"$SERVICE_USER" "$CONFIG_DIR/config.toml"
chmod 640 "$CONFIG_DIR/config.toml"

cat > "$CONFIG_DIR/info.txt" << EOL
External IP: $EXTERNAL_IP
Proxy Host: $PROXY_HOST
EOL

echo -e "${YELLOW}$MSG_SERVICE_CREATE${NC}"
cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOL
[Unit]
Description=Teleproxy MTProto Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
ExecStart=$BIN_FILE --config $CONFIG_DIR/config.toml
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOL

chown -R root:root "$CONFIG_DIR/info.txt"

if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        ufw allow $PORT/tcp
        echo -e "${GREEN}$MSG_UFW_OPEN $PORT/tcp${NC}"
    fi
fi

echo -e "${YELLOW}Создание автоматического обновления (cron)...${NC}"
cat > "/usr/local/bin/teleproxy-updater" << 'UPDATER_EOF'
#!/bin/bash
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_SUFFIX="amd64" ;;
    aarch64) ARCH_SUFFIX="arm64" ;;
    *)       exit 1 ;;
esac

LATEST_URL=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/teleproxy/teleproxy/releases/latest/download/teleproxy-linux-${ARCH_SUFFIX}")
if [[ -z "$LATEST_URL" ]]; then exit 1; fi

CURRENT_URL=""
[[ -f "/etc/teleproxy/installed_url" ]] && CURRENT_URL=$(cat "/etc/teleproxy/installed_url")

if [[ "$LATEST_URL" != "$CURRENT_URL" ]]; then
    if curl -fsSL -o "/tmp/teleproxy.new" "$LATEST_URL"; then
        chmod +x "/tmp/teleproxy.new"
        systemctl stop teleproxy
        mv "/tmp/teleproxy.new" "/usr/local/bin/teleproxy"
        systemctl start teleproxy
        echo "$LATEST_URL" > "/etc/teleproxy/installed_url"
    fi
fi
UPDATER_EOF
chmod +x "/usr/local/bin/teleproxy-updater"

cat > "/etc/cron.d/teleproxy-updater" << 'CRON_EOF'
30 4 */3 * * root /usr/local/bin/teleproxy-updater
CRON_EOF
chmod 644 "/etc/cron.d/teleproxy-updater"

echo -e "${YELLOW}$MSG_UTIL_CREATE${NC}"

cat > "/tmp/teleproxy_utility" << 'UTILITY_EOF'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_DIR="/etc/teleproxy"
SERVICE_NAME="teleproxy"
BIN_FILE="/usr/local/bin/teleproxy"

LANG_SEL="en"
[[ -f "$CONFIG_DIR/lang" ]] && LANG_SEL=$(cat "$CONFIG_DIR/lang")

if [[ "$LANG_SEL" == "ru" ]]; then
    U_HELP_TITLE="Утилита управления Teleproxy"
    U_HELP_USAGE="Использование: teleproxy-ctl [команда]"
    U_HELP_COMMANDS="Команды:"
    U_STATUS="Статус"
    U_STATUS_LINKS="Показать статус и ссылки"
    U_START="Запустить сервис Teleproxy"
    U_STOP="Остановить сервис Teleproxy"
    U_RESTART="Перезапустить сервис Teleproxy"
    U_RELOAD="Перезагрузить конфигурацию (без остановки)"
    U_UPDATE="Проверить и установить обновления"
    U_LOGS="Показать логи сервиса"
    U_LINKS="Показать только ссылки"
    U_INFO="Детальная информация"
    U_STATS_CMD="Статистика прокси"
    U_HELP_CMD="Показать справку"
    U_SVC_RUNNING="✅ Сервис: Работает"
    U_SVC_STOPPED="❌ Сервис: Остановлен"
    U_CONFIG="📊 Конфигурация:"
    U_PORT="Порт"
    U_SECRET="Секрет"
    U_TLS_DOMAIN="TLS домен"
    U_PROXY_HOST="Хост прокси"
    U_CONN_LINKS="🔗 Ссылки подключения:"
    U_NO_LINKS="❌ Нет доступных ссылок"
    U_DETAIL_TITLE="=== Детальная информация Teleproxy ==="
    U_CONFIG_FILE="📄 Файл конфигурации:"
    U_MGMT_CMDS="🛠️  Команды управления:"
    U_FETCHING="📊 Получение статистики с порта"
    U_FETCH_FAIL="❌ Не удалось получить статистику. Сервис запущен?"
    U_RESTARTING="Перезапуск сервиса..."
    U_RESTART_OK="✅ Сервис перезапущен"
    U_STARTING="Запуск сервиса Teleproxy..."
    U_START_OK="✅ Сервис запущен"
    U_STOPPING="Остановка сервиса Teleproxy..."
    U_STOP_OK="✅ Сервис остановлен"
    U_RELOADING="Перезагрузка конфигурации..."
    U_RELOAD_OK="✅ Конфигурация перезагружена"
    U_UNKNOWN="Неизвестная команда:"
    U_SHOWING_LOGS="Логи Teleproxy (Ctrl+C для выхода):"
else
    U_HELP_TITLE="Teleproxy Management Utility"
    U_HELP_USAGE="Usage: teleproxy-ctl [command]"
    U_HELP_COMMANDS="Commands:"
    U_STATUS="Status"
    U_STATUS_LINKS="Show service status and connection links"
    U_START="Start Teleproxy service"
    U_STOP="Stop Teleproxy service"
    U_RESTART="Restart Teleproxy service"
    U_RELOAD="Reload configuration cleanly"
    U_UPDATE="Check and install updates"
    U_LOGS="Show service logs"
    U_LINKS="Show connection links only"
    U_INFO="Show detailed configuration"
    U_STATS_CMD="Show proxy statistics"
    U_HELP_CMD="Show this help"
    U_SVC_RUNNING="✅ Service: Running"
    U_SVC_STOPPED="❌ Service: Stopped"
    U_CONFIG="📊 Configuration:"
    U_PORT="Port"
    U_SECRET="Secret"
    U_TLS_DOMAIN="TLS Domain"
    U_PROXY_HOST="Proxy Host"
    U_CONN_LINKS="🔗 Connection Links:"
    U_NO_LINKS="❌ No links available"
    U_DETAIL_TITLE="=== Teleproxy Detailed Information ==="
    U_CONFIG_FILE="📄 Configuration File:"
    U_MGMT_CMDS="🛠️  Management Commands:"
    U_FETCHING="📊 Fetching proxy statistics from port"
    U_FETCH_FAIL="❌ Could not fetch stats. Is the service running?"
    U_RESTARTING="Restarting service..."
    U_RESTART_OK="✅ Service restarted successfully"
    U_STARTING="Starting Teleproxy service..."
    U_START_OK="✅ Service started successfully"
    U_STOPPING="Stopping Teleproxy service..."
    U_STOP_OK="✅ Service stopped"
    U_RELOADING="Reloading configuration..."
    U_RELOAD_OK="✅ Configuration reloaded successfully"
    U_UNKNOWN="Unknown command:"
    U_SHOWING_LOGS="Showing Teleproxy logs (Ctrl+C to exit):"
fi

show_help() {
    echo -e "${BLUE}$U_HELP_TITLE${NC}\n"
    echo "$U_HELP_USAGE"
    echo ""
    echo "$U_HELP_COMMANDS"
    echo -e "  ${GREEN}status${NC}    - $U_STATUS_LINKS"
    echo -e "  ${GREEN}start${NC}     - $U_START"
    echo -e "  ${GREEN}stop${NC}      - $U_STOP"
    echo -e "  ${GREEN}restart${NC}   - $U_RESTART"
    echo -e "  ${GREEN}reload${NC}    - $U_RELOAD"
    echo -e "  ${GREEN}update${NC}    - $U_UPDATE"
    echo -e "  ${GREEN}logs${NC}      - $U_LOGS"
    echo -e "  ${GREEN}links${NC}     - $U_LINKS"
    echo -e "  ${GREEN}info${NC}      - $U_INFO"
    echo -e "  ${GREEN}stats${NC}     - $U_STATS_CMD"
    echo -e "  ${GREEN}help${NC}      - $U_HELP_CMD"
}

get_config_vars() {
    PORT=$(grep "^port = " $CONFIG_DIR/config.toml | awk '{print $3}')
    STATS_PORT=$(grep "^stats_port = " $CONFIG_DIR/config.toml | awk '{print $3}')
    TLS_DOMAIN=$(grep "^domain = " $CONFIG_DIR/config.toml | cut -d'"' -f2 || true)
    SECRET=$(grep "^key = " $CONFIG_DIR/config.toml | cut -d'"' -f2 || true)
    PROXY_HOST=$(grep "Proxy Host:" $CONFIG_DIR/info.txt 2>/dev/null | awk '{print $3}')
    if [[ -z "$PROXY_HOST" ]]; then PROXY_HOST="127.0.0.1"; fi
}

show_links() {
    get_config_vars
    if [[ -n "$PORT" && -n "$SECRET" ]]; then
        echo -e "${YELLOW}$U_CONN_LINKS${NC}"
        domain_hex=""
        if [[ -n "$TLS_DOMAIN" ]]; then
            domain_hex=$(echo -n "$TLS_DOMAIN" | xxd -p | tr -d '\n')
            full_secret="ee${SECRET}${domain_hex}"
        else
            full_secret="$SECRET"
        fi
        
        $BIN_FILE link --server "$PROXY_HOST" --port "$PORT" --secret "$full_secret"
    else
        echo -e "${RED}$U_NO_LINKS${NC}"
        return 1
    fi
}

show_status() {
    echo -e "${BLUE}=== Teleproxy $U_STATUS ===${NC}\n"

    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}$U_SVC_RUNNING${NC}"
    else
        echo -e "${RED}$U_SVC_STOPPED${NC}"
        return 1
    fi

    get_config_vars
    echo -e "${YELLOW}$U_CONFIG${NC}"
    echo -e "   $U_PORT: ${GREEN}${PORT:-unknown}${NC}"
    echo -e "   $U_SECRET: ${GREEN}${SECRET:-unknown}${NC}"
    echo -e "   $U_TLS_DOMAIN: ${GREEN}${TLS_DOMAIN:-none}${NC}"
    echo -e "   $U_PROXY_HOST: ${GREEN}${PROXY_HOST:-unknown}${NC}"

    echo ""
    show_links
}

show_info() {
    echo -e "${BLUE}$U_DETAIL_TITLE${NC}\n"
    show_status

    if [[ -f "$CONFIG_DIR/config.toml" ]]; then
        echo -e "\n${YELLOW}$U_CONFIG_FILE${NC}"
        cat "$CONFIG_DIR/config.toml"
    fi

    echo -e "\n${YELLOW}$U_MGMT_CMDS${NC}"
    echo -e "${GREEN}teleproxy-ctl status${NC}    - $U_STATUS_LINKS"
    echo -e "${GREEN}teleproxy-ctl restart${NC}   - $U_RESTART"
    echo -e "${GREEN}teleproxy-ctl logs${NC}      - $U_LOGS"
}

show_stats() {
    get_config_vars
    local sp="${STATS_PORT:-8888}"
    echo -e "${YELLOW}$U_FETCHING $sp...${NC}"
    STATS=$(curl -s --connect-timeout 5 "http://localhost:$sp/metrics" 2>/dev/null | grep -v "^#")
    if [[ -n "$STATS" ]]; then
        echo -e "${GREEN}$STATS${NC}"
    else
        echo -e "${RED}$U_FETCH_FAIL${NC}"
    fi
}

case "${1:-status}" in
    "start")
        echo -e "${YELLOW}$U_STARTING${NC}"
        systemctl start $SERVICE_NAME
        echo -e "${GREEN}$U_START_OK${NC}"
        show_links
        ;;
    "stop")
        echo -e "${YELLOW}$U_STOPPING${NC}"
        systemctl stop $SERVICE_NAME
        echo -e "${GREEN}$U_STOP_OK${NC}"
        ;;
    "restart")
        echo -e "${YELLOW}$U_RESTARTING${NC}"
        systemctl restart $SERVICE_NAME
        echo -e "${GREEN}$U_RESTART_OK${NC}"
        show_links
        ;;
    "reload")
        echo -e "${YELLOW}$U_RELOADING${NC}"
        systemctl reload $SERVICE_NAME
        echo -e "${GREEN}$U_RELOAD_OK${NC}"
        ;;
    "status")
        show_status
        ;;
    "update")
        echo -e "${YELLOW}Запуск проверки обновлений / Checking for updates...${NC}"
        /usr/local/bin/teleproxy-updater
        echo -e "${GREEN}Готово! / Done!${NC}"
        ;;
    "links")
        show_links
        ;;
    "logs")
        echo -e "${YELLOW}$U_SHOWING_LOGS${NC}"
        journalctl -u $SERVICE_NAME -f
        ;;
    "info")
        show_info
        ;;
    "stats")
        show_stats
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}$U_UNKNOWN $1${NC}"
        show_help
        exit 1
        ;;
esac
UTILITY_EOF

mv "/tmp/teleproxy_utility" "/usr/local/bin/teleproxy-ctl"
chmod +x "/usr/local/bin/teleproxy-ctl"

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

sleep 3

if systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "\n${GREEN}$MSG_SVC_RUNNING${NC}"
    echo -e "\n${YELLOW}$MSG_COMPLETE${NC}"
    echo -e "\n${CYAN}$MSG_QUICK${NC}"
    echo -e "${GREEN}teleproxy-ctl${NC}         - $MSG_QUICK1"
    echo -e "${GREEN}teleproxy-ctl restart${NC} - $MSG_QUICK2"
    echo -e "${GREEN}teleproxy-ctl links${NC}   - $MSG_QUICK3"
    echo -e "${GREEN}teleproxy-ctl update${NC}  - Обновить бинарник Teleproxy"
    echo -e "${GREEN}teleproxy-ctl reload${NC}  - Обновить секреты/конфиг без прерывания"
    echo -e "${GREEN}teleproxy-ctl stats${NC}   - $MSG_QUICK4"
    echo -e "${GREEN}teleproxy-ctl help${NC}    - $MSG_QUICK6"
    echo ""
    /usr/local/bin/teleproxy-ctl links
else
    echo -e "${RED}$MSG_SVC_FAIL${NC}"
    systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

echo -e "\n${BLUE}$MSG_SAVED ${GREEN}$CONFIG_DIR/config.toml${NC}"
echo -e "${BLUE}$MSG_UTIL_PATH ${GREEN}/usr/local/bin/teleproxy-ctl${NC}"
echo -e "${BLUE}$MSG_AUTOSTART${NC}"
echo -e "${BLUE}$MSG_STATS_INFO ${GREEN}http://$EXTERNAL_IP:$STATS_PORT${NC}"
echo -e "\n${YELLOW}$MSG_REMOVE_LATER${NC}"
echo -e "${GREEN}$0 uninstall${NC}"
