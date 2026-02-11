#!/bin/bash

# MTProxy Installation Script (GetPageSpeed/MTProxy - C binary)
# Builds from source, creates systemd service with custom port,
# saves secrets to info.txt and creates management utility in /usr/local/bin/mtproxy
#
# Usage:
#   ./mtproxy.sh          - Install MTProxy
#   ./mtproxy.sh uninstall - Remove MTProxy completely

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Language selection
echo -e "${BLUE}MTProxy Installer${NC}"
echo -e "${CYAN}1${NC} - English"
echo -e "${CYAN}2${NC} - Русский"
read -p "Select language / Выберите язык [1/2]: " LANG_CHOICE
[[ "$LANG_CHOICE" == "2" ]] && LANG_SEL="ru" || LANG_SEL="en"

# Save language for management utility
mkdir -p /opt/MTProxy
echo "$LANG_SEL" > /opt/MTProxy/lang

set_messages() {
if [[ "$1" == "ru" ]]; then
    MSG_TITLE="Установка MTProxy (GetPageSpeed Fork)"
    MSG_ROOT="Этот установщик должен быть запущен от root (используйте sudo)."
    MSG_UNINSTALL_TITLE="🗑️  Удаление MTProxy"
    MSG_UNINSTALL_WARN="ВНИМАНИЕ: Это полностью удалит MTProxy и все связанные файлы!"
    MSG_UNINSTALL_LIST="Будет удалено:"
    MSG_UNINSTALL_I1="Сервис: /etc/systemd/system/mtproxy.service"
    MSG_UNINSTALL_I2="Директория: /opt/MTProxy"
    MSG_UNINSTALL_I3="Утилита: /usr/local/bin/mtproxy"
    MSG_UNINSTALL_I4="Cron задача: /etc/cron.daily/mtproxy-update-config"
    MSG_UNINSTALL_I5="Все конфигурации и секреты"
    MSG_UNINSTALL_CONFIRM="Вы уверены? (введите 'YES' для подтверждения): "
    MSG_UNINSTALL_CANCEL="Удаление отменено."
    MSG_REMOVING="Удаление MTProxy..."
    MSG_STOPPING="Остановка сервиса MTProxy..."
    MSG_DISABLING="Отключение сервиса MTProxy..."
    MSG_RM_FIREWALL="Удаление правила файрвола для порта"
    MSG_RM_SERVICE="Удаление файла сервиса..."
    MSG_RM_INSTALLDIR="Удаление директории /opt/MTProxy..."
    MSG_RM_UTILITY="Удаление утилиты управления..."
    MSG_RM_CRON="Удаление cron задачи..."
    MSG_UNINSTALL_DONE="✅ MTProxy полностью удалён!"
    MSG_UNINSTALL_DONE2="Все файлы, сервисы и конфигурации удалены."
    MSG_HELP_TITLE="Скрипт установки MTProxy"
    MSG_HELP_USAGE="Использование:"
    MSG_HELP_INSTALL="Установить MTProxy с интерактивной настройкой"
    MSG_HELP_UNINSTALL="Полностью удалить MTProxy и все файлы"
    MSG_HELP_HELP="Показать эту справку"
    MSG_HELP_AFTER="После установки используйте команду 'mtproxy' для управления."
    MSG_ERR_UNKNOWN="Ошибка: Неизвестный аргумент"
    MSG_ERR_USAGE="Используйте '$0 help' для справки."
    MSG_PORT_PROMPT="Введите порт прокси (по умолчанию"
    MSG_INSTALLING="Установка MTProxy (GetPageSpeed fork)..."
    MSG_DEPS="Установка зависимостей для сборки..."
    MSG_NO_APT="apt не найден. Скрипт поддерживает только Debian/Ubuntu (apt)."
    MSG_DEPS_MANUAL="Установите зависимости вручную: git curl build-essential libssl-dev zlib1g-dev xxd."
    MSG_CLONING="Клонирование репозитория GetPageSpeed/MTProxy..."
    MSG_SRC_EXISTS="Директория исходников существует, обновление..."
    MSG_BUILDING="Сборка MTProxy (это может занять минуту)..."
    MSG_BUILD_OK="Сборка успешна!"
    MSG_BUILD_FAIL="Ошибка сборки! Проверьте зависимости."
    MSG_BIN_INSTALLED="Бинарник установлен в"
    MSG_DL_CONFIG="Загрузка конфигурации Telegram прокси..."
    MSG_DL_FAIL_SECRET="Не удалось загрузить proxy-secret"
    MSG_DL_FAIL_CONFIG="Не удалось загрузить proxy-multi.conf"
    MSG_DL_OK="Конфигурация Telegram загружена"
    MSG_SECRET_EXISTING="Используется существующий секрет:"
    MSG_SECRET_NEW="Сгенерирован новый секрет:"
    MSG_GET_IP="Получение внешнего IPv4 адреса..."
    MSG_IP_FAIL="Не удалось определить внешний IPv4 адрес"
    MSG_IP_MANUAL="Проверьте IPv4 вручную: curl -4 ifconfig.me"
    MSG_IP_OK="Обнаружен внешний IPv4:"
    MSG_DOMAIN_TITLE="🌐 Настройка домена (опционально):"
    MSG_DOMAIN_DESC="Вы можете использовать доменное имя вместо IP адреса."
    MSG_DOMAIN_EXAMPLES="Примеры: proxy.example.com, vpn.mydomain.org"
    MSG_DOMAIN_EMPTY="Оставьте пустым для использования IP:"
    MSG_DOMAIN_PROMPT="Введите доменное имя (опционально): "
    MSG_DOMAIN_USING="Используется домен:"
    MSG_DOMAIN_DNS="Проверка DNS домена..."
    MSG_DOMAIN_WARN="DNS не совпадает с внешним IP."
    MSG_DOMAIN_ARECORD="Убедитесь, что A-запись указывает на"
    MSG_DOMAIN_DNS_OK="DNS в порядке."
    MSG_DOMAIN_INVALID="Неверный формат домена. Используется IP адрес."
    MSG_DOMAIN_IP="Используется IP адрес:"
    MSG_TLS_TITLE="🔒 Настройка TLS домена:"
    MSG_TLS_DESC="MTProxy использует домен для маскировки TLS сертификата."
    MSG_TLS_DESC2="Случайные домены безопаснее, чем google.com по умолчанию"
    MSG_TLS_EXAMPLES="Примеры: google.com, cloudflare.com, microsoft.com"
    MSG_TLS_PROMPT="Введите TLS домен для маскировки (по умолчанию"
    MSG_TLS_CHECK="Проверка поддержки TLS 1.3 для"
    MSG_TLS_OK="✅ поддерживает TLS 1.3"
    MSG_TLS_FAIL="⚠️  НЕ поддерживает TLS 1.3"
    MSG_TLS_REQUIRED="MTProxy EE режим требует домен с поддержкой TLS 1.3 + x25519."
    MSG_TLS_OPT1="1 - Ввести другой домен"
    MSG_TLS_OPT2="2 - Продолжить (подключение может не работать)"
    MSG_TLS_CHOICE="Ваш выбор [1/2]: "
    MSG_TLS_CONTINUE="Продолжение с"
    MSG_TLS_PROMPT2="Введите TLS домен: "
    MSG_TLS_NO_OPENSSL="⚠️  openssl не найден, пропуск проверки TLS 1.3"
    MSG_TLS_USING="Используется TLS домен:"
    MSG_NAT_CHECK="Проверка NAT конфигурации..."
    MSG_NAT_YES="NAT обнаружен: (будет использован --nat-info)"
    MSG_NAT_NO="NAT не обнаружен (прямое подключение)"
    MSG_WORKERS="Используется 1 воркер (рекомендовано для TLS)"
    MSG_SERVICE_CREATE="Создание systemd сервиса..."
    MSG_UFW_OPEN="UFW: Открыт порт"
    MSG_CRON_CREATE="Создание ежедневной cron задачи обновления..."
    MSG_CRON_OK="Cron задача создана:"
    MSG_UTIL_CREATE="Создание утилиты управления..."
    MSG_SVC_RUNNING="✅ Сервис MTProxy запущен!"
    MSG_SVC_FAIL="❌ Сервис не удалось запустить"
    MSG_COMPLETE="🎉 Установка завершена!"
    MSG_QUICK="📋 Быстрые команды:"
    MSG_QUICK1="Статус и ссылки"
    MSG_QUICK2="Перезапуск сервиса"
    MSG_QUICK3="Ссылки подключения"
    MSG_QUICK4="Статистика прокси"
    MSG_QUICK5="Обновить конфиг Telegram"
    MSG_QUICK6="Все команды"
    MSG_SAVED="📄 Конфигурация сохранена в:"
    MSG_UTIL_PATH="🔧 Утилита управления:"
    MSG_AUTOSTART="🔄 Сервис запускается автоматически"
    MSG_STATS_INFO="📊 Статистика:"
    MSG_REMOVE_LATER="💡 Для полного удаления MTProxy:"
else
    MSG_TITLE="MTProxy Installation (GetPageSpeed Fork)"
    MSG_ROOT="This installer must be run as root (use sudo)."
    MSG_UNINSTALL_TITLE="🗑️  MTProxy Uninstallation"
    MSG_UNINSTALL_WARN="WARNING: This will completely remove MTProxy and all related files!"
    MSG_UNINSTALL_LIST="The following will be deleted:"
    MSG_UNINSTALL_I1="Service: /etc/systemd/system/mtproxy.service"
    MSG_UNINSTALL_I2="Installation directory: /opt/MTProxy"
    MSG_UNINSTALL_I3="Management utility: /usr/local/bin/mtproxy"
    MSG_UNINSTALL_I4="Cron job: /etc/cron.daily/mtproxy-update-config"
    MSG_UNINSTALL_I5="All configuration files and secrets"
    MSG_UNINSTALL_CONFIRM="Are you sure? (type 'YES' to confirm): "
    MSG_UNINSTALL_CANCEL="Uninstallation cancelled."
    MSG_REMOVING="Removing MTProxy..."
    MSG_STOPPING="Stopping MTProxy service..."
    MSG_DISABLING="Disabling MTProxy service..."
    MSG_RM_FIREWALL="Removing firewall rule for port"
    MSG_RM_SERVICE="Removing service file..."
    MSG_RM_INSTALLDIR="Removing installation directory /opt/MTProxy..."
    MSG_RM_UTILITY="Removing management utility..."
    MSG_RM_CRON="Removing cron job..."
    MSG_UNINSTALL_DONE="✅ MTProxy has been completely removed!"
    MSG_UNINSTALL_DONE2="All files, services, and configurations have been deleted."
    MSG_HELP_TITLE="MTProxy Installation Script"
    MSG_HELP_USAGE="Usage:"
    MSG_HELP_INSTALL="Install MTProxy with interactive setup"
    MSG_HELP_UNINSTALL="Completely remove MTProxy and all files"
    MSG_HELP_HELP="Show this help message"
    MSG_HELP_AFTER="After installation, use 'mtproxy' command to manage the service."
    MSG_ERR_UNKNOWN="Error: Unknown argument"
    MSG_ERR_USAGE="Use '$0 help' for usage information."
    MSG_PORT_PROMPT="Enter proxy port (default"
    MSG_INSTALLING="Installing MTProxy (GetPageSpeed fork)..."
    MSG_DEPS="Installing build dependencies..."
    MSG_NO_APT="apt not found. This script currently supports Debian/Ubuntu (apt)."
    MSG_DEPS_MANUAL="Install dependencies manually: git curl build-essential libssl-dev zlib1g-dev xxd."
    MSG_CLONING="Cloning GetPageSpeed/MTProxy repository..."
    MSG_SRC_EXISTS="Source directory exists, pulling latest changes..."
    MSG_BUILDING="Building MTProxy (this may take a minute)..."
    MSG_BUILD_OK="Build successful!"
    MSG_BUILD_FAIL="Build failed! Check build dependencies."
    MSG_BIN_INSTALLED="Binary installed to"
    MSG_DL_CONFIG="Downloading Telegram proxy configuration..."
    MSG_DL_FAIL_SECRET="Failed to download proxy-secret"
    MSG_DL_FAIL_CONFIG="Failed to download proxy-multi.conf"
    MSG_DL_OK="Telegram configuration downloaded"
    MSG_SECRET_EXISTING="Using existing secret:"
    MSG_SECRET_NEW="Generated new secret:"
    MSG_GET_IP="Getting external IPv4 address..."
    MSG_IP_FAIL="Failed to detect external IPv4 address"
    MSG_IP_MANUAL="Please manually check your IPv4 with: curl -4 ifconfig.me"
    MSG_IP_OK="Detected external IPv4:"
    MSG_DOMAIN_TITLE="🌐 Domain Setup (Optional):"
    MSG_DOMAIN_DESC="You can use a domain name instead of IP address."
    MSG_DOMAIN_EXAMPLES="Examples: proxy.example.com, vpn.mydomain.org"
    MSG_DOMAIN_EMPTY="Leave empty to use IP address:"
    MSG_DOMAIN_PROMPT="Enter domain name (optional): "
    MSG_DOMAIN_USING="Using domain:"
    MSG_DOMAIN_DNS="Checking DNS for domain..."
    MSG_DOMAIN_WARN="DNS doesn't match detected external IP."
    MSG_DOMAIN_ARECORD="Make sure your domain A-record points to"
    MSG_DOMAIN_DNS_OK="DNS looks ok."
    MSG_DOMAIN_INVALID="Invalid domain format. Using IP address instead."
    MSG_DOMAIN_IP="Using IP address:"
    MSG_TLS_TITLE="🔒 TLS Domain Setup:"
    MSG_TLS_DESC="MTProxy uses a domain for TLS certificate masking to avoid detection."
    MSG_TLS_DESC2="Using random existing domains is more secure than default google.com"
    MSG_TLS_EXAMPLES="Examples: github.com, cloudflare.com, microsoft.com"
    MSG_TLS_PROMPT="Enter TLS domain for masking (default"
    MSG_TLS_CHECK="Checking TLS 1.3 support for"
    MSG_TLS_OK="✅ supports TLS 1.3"
    MSG_TLS_FAIL="⚠️  does NOT appear to support TLS 1.3"
    MSG_TLS_REQUIRED="MTProxy EE mode requires a domain with TLS 1.3 + x25519 support."
    MSG_TLS_OPT1="1 - Enter a different domain"
    MSG_TLS_OPT2="2 - Continue anyway (connection may not work)"
    MSG_TLS_CHOICE="Your choice [1/2]: "
    MSG_TLS_CONTINUE="Continuing with"
    MSG_TLS_PROMPT2="Enter TLS domain for masking: "
    MSG_TLS_NO_OPENSSL="⚠️  openssl not found, skipping TLS 1.3 check"
    MSG_TLS_USING="Using TLS domain:"
    MSG_NAT_CHECK="Checking NAT configuration..."
    MSG_NAT_YES="NAT detected: (will use --nat-info)"
    MSG_NAT_NO="No NAT detected (direct connection)"
    MSG_WORKERS="Using 1 worker (recommended for TLS transport)"
    MSG_SERVICE_CREATE="Creating systemd service..."
    MSG_UFW_OPEN="UFW: Opened port"
    MSG_CRON_CREATE="Creating daily config update cron job..."
    MSG_CRON_OK="Cron job created:"
    MSG_UTIL_CREATE="Creating management utility..."
    MSG_SVC_RUNNING="✅ MTProxy service is running!"
    MSG_SVC_FAIL="❌ Service failed to start"
    MSG_COMPLETE="🎉 Installation Complete!"
    MSG_QUICK="📋 Quick Commands:"
    MSG_QUICK1="Show status and links"
    MSG_QUICK2="Restart service"
    MSG_QUICK3="Show connection links"
    MSG_QUICK4="Show proxy statistics"
    MSG_QUICK5="Update Telegram config"
    MSG_QUICK6="Show all commands"
    MSG_SAVED="📄 Configuration saved to:"
    MSG_UTIL_PATH="🔧 Management utility:"
    MSG_AUTOSTART="🔄 Service will auto-start on boot"
    MSG_STATS_INFO="📊 Statistics:"
    MSG_REMOVE_LATER="💡 To completely remove MTProxy later:"
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
    
    # Read configuration BEFORE deleting anything
    UNINSTALL_PORT=""
    if [[ -f "/etc/systemd/system/mtproxy.service" ]]; then
        UNINSTALL_PORT=$(grep "ExecStart=" /etc/systemd/system/mtproxy.service | grep -oP '(?<=-H )\S+')
    fi
    if [[ -z "$UNINSTALL_PORT" && -f "/opt/MTProxy/info.txt" ]]; then
        UNINSTALL_PORT=$(grep "Selected Port:" /opt/MTProxy/info.txt 2>/dev/null | awk '{print $3}')
    fi
    
    # Stop and disable service
    if systemctl is-active --quiet mtproxy; then
        echo -e "${YELLOW}$MSG_STOPPING${NC}"
        systemctl stop mtproxy
    fi
    
    if systemctl is-enabled --quiet mtproxy 2>/dev/null; then
        echo -e "${YELLOW}$MSG_DISABLING${NC}"
        systemctl disable mtproxy
    fi
    
    # Remove firewall rule for the actual configured port
    if [[ -n "$UNINSTALL_PORT" ]]; then
        if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
            if ufw status | grep -q "${UNINSTALL_PORT}/tcp"; then
                echo -e "${YELLOW}$MSG_RM_FIREWALL $UNINSTALL_PORT...${NC}"
                ufw delete allow ${UNINSTALL_PORT}/tcp 2>/dev/null
            fi
        fi
    fi
    
    # Remove service file
    if [[ -f "/etc/systemd/system/mtproxy.service" ]]; then
        echo -e "${YELLOW}$MSG_RM_SERVICE${NC}"
        rm -f "/etc/systemd/system/mtproxy.service"
        systemctl daemon-reload
    fi
    
    # Remove installation directory (binary, source, configs — everything)
    if [[ -d "/opt/MTProxy" ]]; then
        echo -e "${YELLOW}$MSG_RM_INSTALLDIR${NC}"
        rm -rf "/opt/MTProxy"
    fi
    
    # Remove management utility
    if [[ -f "/usr/local/bin/mtproxy" ]]; then
        echo -e "${YELLOW}$MSG_RM_UTILITY${NC}"
        rm -f "/usr/local/bin/mtproxy"
    fi
    
    # Remove cron job
    if [[ -f "/etc/cron.daily/mtproxy-update-config" ]]; then
        echo -e "${YELLOW}$MSG_RM_CRON${NC}"
        rm -f "/etc/cron.daily/mtproxy-update-config"
    fi
    
    echo -e "\n${GREEN}$MSG_UNINSTALL_DONE${NC}"
    echo -e "${CYAN}$MSG_UNINSTALL_DONE2${NC}"
    
    exit 0
fi

# Check for help or invalid arguments
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
INSTALL_DIR="/opt/MTProxy"
SERVICE_NAME="mtproxy"
DEFAULT_PORT=443
STATS_PORT=2398

# Get user input
read -p "$MSG_PORT_PROMPT: $DEFAULT_PORT): " USER_PORT
PORT=${USER_PORT:-$DEFAULT_PORT}

echo -e "\n${YELLOW}$MSG_INSTALLING${NC}"

# Install dependencies
echo -e "${YELLOW}$MSG_DEPS${NC}"
if command -v apt >/dev/null 2>&1; then
    apt update -qq
    apt install -y git curl build-essential libssl-dev zlib1g-dev xxd || apt install -y vim-common
else
    echo -e "${RED}$MSG_NO_APT${NC}"
    echo -e "${YELLOW}$MSG_DEPS_MANUAL${NC}"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Stop existing service if running
systemctl stop mtproxy 2>/dev/null

# Clone and build MTProxy
echo -e "${YELLOW}$MSG_CLONING${NC}"
if [[ -d "$INSTALL_DIR/src" ]]; then
    echo -e "${YELLOW}$MSG_SRC_EXISTS${NC}"
    cd "$INSTALL_DIR/src"
    git pull
else
    git clone https://github.com/GetPageSpeed/MTProxy "$INSTALL_DIR/src"
    cd "$INSTALL_DIR/src"
fi

echo -e "${YELLOW}$MSG_BUILDING${NC}"
make clean 2>/dev/null
if make; then
    echo -e "${GREEN}$MSG_BUILD_OK${NC}"
else
    echo -e "${RED}$MSG_BUILD_FAIL${NC}"
    exit 1
fi

# Copy binary
cp "$INSTALL_DIR/src/objs/bin/mtproto-proxy" "$INSTALL_DIR/mtproto-proxy"
chmod +x "$INSTALL_DIR/mtproto-proxy"
echo -e "${GREEN}$MSG_BIN_INSTALLED $INSTALL_DIR/mtproto-proxy${NC}"

# Download proxy-secret and proxy-multi.conf
echo -e "${YELLOW}$MSG_DL_CONFIG${NC}"
if ! curl -s https://core.telegram.org/getProxySecret -o "$INSTALL_DIR/proxy-secret"; then
    echo -e "${RED}$MSG_DL_FAIL_SECRET${NC}"
    exit 1
fi
if ! curl -s https://core.telegram.org/getProxyConfig -o "$INSTALL_DIR/proxy-multi.conf"; then
    echo -e "${RED}$MSG_DL_FAIL_CONFIG${NC}"
    exit 1
fi
echo -e "${GREEN}$MSG_DL_OK${NC}"

# Generate user secret (or use existing one)
if [[ -f "$INSTALL_DIR/info.txt" ]] && grep -q "Base Secret:" "$INSTALL_DIR/info.txt"; then
    USER_SECRET=$(grep "Base Secret:" "$INSTALL_DIR/info.txt" | awk '{print $3}')
    echo -e "${GREEN}$MSG_SECRET_EXISTING $USER_SECRET${NC}"
else
    USER_SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo -e "${GREEN}$MSG_SECRET_NEW $USER_SECRET${NC}"
fi

# Get external IP (IPv4 only)
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

# Ask for domain (optional)
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
        echo -e "${YELLOW}$MSG_DOMAIN_DNS${NC}"
        DOMAIN_IP=$(getent ahostsv4 "$PROXY_HOST" 2>/dev/null | awk '/STREAM/ {print $1; exit}')
        if [[ -n "$DOMAIN_IP" && -n "$EXTERNAL_IP" && "$DOMAIN_IP" != "$EXTERNAL_IP" ]]; then
            echo -e "${YELLOW}$MSG_DOMAIN_WARN${NC}"
            echo -e "${YELLOW}$MSG_DOMAIN_ARECORD ${EXTERNAL_IP}.${NC}"
        else
            echo -e "${GREEN}$MSG_DOMAIN_DNS_OK${NC}"
        fi
    else
        echo -e "${RED}$MSG_DOMAIN_INVALID${NC}"
        PROXY_HOST="$EXTERNAL_IP"
    fi
else
    PROXY_HOST="$EXTERNAL_IP"
    echo -e "${GREEN}$MSG_DOMAIN_IP $PROXY_HOST${NC}"
fi

# TLS Domain setup for better security
echo -e "\n${YELLOW}$MSG_TLS_TITLE${NC}"
echo -e "${CYAN}$MSG_TLS_DESC${NC}"
echo -e "${CYAN}$MSG_TLS_DESC2${NC}"
echo -e "${CYAN}$MSG_TLS_EXAMPLES${NC}"
echo ""

# List of TLS 1.3 compatible domains (must support x25519 cipher)
TLS_DOMAINS=("www.google.com" "www.cloudflare.com" "www.microsoft.com" "www.amazon.com" "www.instagram.com" "www.facebook.com")
RANDOM_DOMAIN=${TLS_DOMAINS[$RANDOM % ${#TLS_DOMAINS[@]}]}

read -p "$MSG_TLS_PROMPT: $RANDOM_DOMAIN): " USER_TLS_DOMAIN
TLS_DOMAIN=${USER_TLS_DOMAIN:-$RANDOM_DOMAIN}

# Verify TLS 1.3 support
while true; do
    echo -e "${YELLOW}$MSG_TLS_CHECK $TLS_DOMAIN...${NC}"
    if command -v openssl >/dev/null 2>&1; then
        TLS_CHECK=$(echo | openssl s_client -connect "$TLS_DOMAIN:443" -tls1_3 2>&1)
        if echo "$TLS_CHECK" | grep -qi "TLSv1.3\|tls1.3"; then
            echo -e "${GREEN}$TLS_DOMAIN $MSG_TLS_OK${NC}"
            break
        else
            echo -e "${RED}$TLS_DOMAIN $MSG_TLS_FAIL${NC}"
            echo -e "${YELLOW}$MSG_TLS_REQUIRED${NC}"
            echo ""
            echo -e "${CYAN}Options:${NC}"
            echo -e "  ${GREEN}$MSG_TLS_OPT1${NC}"
            echo -e "  ${GREEN}$MSG_TLS_OPT2${NC}"
            read -p "$MSG_TLS_CHOICE" TLS_CHOICE
            if [[ "$TLS_CHOICE" == "2" ]]; then
                echo -e "${YELLOW}$MSG_TLS_CONTINUE $TLS_DOMAIN...${NC}"
                break
            else
                read -p "$MSG_TLS_PROMPT2" TLS_DOMAIN
                [[ -z "$TLS_DOMAIN" ]] && TLS_DOMAIN="$RANDOM_DOMAIN"
            fi
        fi
    else
        echo -e "${YELLOW}$MSG_TLS_NO_OPENSSL${NC}"
        break
    fi
done

echo -e "${GREEN}$MSG_TLS_USING $TLS_DOMAIN${NC}"

# NAT detection: compare internal IP with external IP
echo -e "${YELLOW}$MSG_NAT_CHECK${NC}"
INTERNAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || hostname -I 2>/dev/null | awk '{print $1}')
NAT_INFO=""
if [[ -n "$INTERNAL_IP" && -n "$EXTERNAL_IP" && "$INTERNAL_IP" != "$EXTERNAL_IP" && "$EXTERNAL_IP" != "YOUR_SERVER_IP" ]]; then
    NAT_INFO="--nat-info ${INTERNAL_IP}:${EXTERNAL_IP}"
    echo -e "${GREEN}$MSG_NAT_YES $INTERNAL_IP -> $EXTERNAL_IP${NC}"
else
    echo -e "${GREEN}$MSG_NAT_NO${NC}"
fi

# Workers: use 1 worker with TLS transport (recommended by upstream)
WORKERS=1
echo -e "${GREEN}$MSG_WORKERS${NC}"

# Create initial info.txt with setup details
mkdir -p "$INSTALL_DIR"
cat > "$INSTALL_DIR/info.txt" << EOL
MTProxy Setup Information
========================
Setup Date: $(date)
Selected Port: $PORT
External IPv4: $EXTERNAL_IP
Internal IP: ${INTERNAL_IP:-N/A}
NAT: ${NAT_INFO:-No}
Proxy Host: $PROXY_HOST
TLS Domain: $TLS_DOMAIN
Base Secret: $USER_SECRET
Workers: $WORKERS
Status: Installing...
EOL

# Create systemd service
echo -e "${YELLOW}$MSG_SERVICE_CREATE${NC}"
cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOL
[Unit]
Description=MTProxy Telegram Proxy (GetPageSpeed)
After=network.target
Wants=network-online.target
After=network-online.target
StartLimitBurst=3
StartLimitIntervalSec=60

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/mtproto-proxy -u nobody -p $STATS_PORT -H $PORT -S $USER_SECRET -D $TLS_DOMAIN $NAT_INFO --http-stats --aes-pwd $INSTALL_DIR/proxy-secret $INSTALL_DIR/proxy-multi.conf -M $WORKERS
Restart=always
RestartSec=10
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30

# Resource limits for stability
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOL

# Set permissions
chown -R root:root "$INSTALL_DIR"

# Configure firewall
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        ufw allow $PORT/tcp
        echo -e "${GREEN}$MSG_UFW_OPEN $PORT/tcp${NC}"
    fi
fi

# Create cron job for daily proxy-multi.conf update
echo -e "${YELLOW}$MSG_CRON_CREATE${NC}"
cat > "/etc/cron.daily/mtproxy-update-config" << 'CRON_EOF'
#!/bin/bash
# Update MTProxy Telegram configuration daily
curl -s https://core.telegram.org/getProxyConfig -o /opt/MTProxy/proxy-multi.conf 2>/dev/null
CRON_EOF
chmod +x "/etc/cron.daily/mtproxy-update-config"
echo -e "${GREEN}$MSG_CRON_OK /etc/cron.daily/mtproxy-update-config${NC}"

# Create management utility
echo -e "${YELLOW}$MSG_UTIL_CREATE${NC}"

cat > "/tmp/mtproxy_utility" << 'UTILITY_EOF'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="/opt/MTProxy"
SERVICE_NAME="mtproxy"

# Load language
LANG_SEL="en"
[[ -f "$INSTALL_DIR/lang" ]] && LANG_SEL=$(cat "$INSTALL_DIR/lang")

if [[ "$LANG_SEL" == "ru" ]]; then
    U_HELP_TITLE="Утилита управления MTProxy"
    U_HELP_USAGE="Использование: mtproxy [команда]"
    U_HELP_COMMANDS="Команды:"
    U_STATUS="Статус"
    U_STATUS_LINKS="Показать статус и ссылки"
    U_START="Запустить сервис MTProxy"
    U_STOP="Остановить сервис MTProxy"
    U_RESTART="Перезапустить сервис MTProxy"
    U_LOGS="Показать логи сервиса"
    U_LINKS="Показать только ссылки"
    U_INFO="Детальная информация"
    U_STATS_CMD="Статистика прокси"
    U_TEST_CMD="Тест подключения"
    U_UPDATE_CMD="Обновить proxy-multi.conf"
    U_HELP_CMD="Показать справку"
    U_SVC_RUNNING="✅ Сервис: Работает"
    U_SVC_STOPPED="❌ Сервис: Остановлен"
    U_CONFIG="📊 Конфигурация:"
    U_PORT="Порт"
    U_SECRET="Секрет"
    U_REG_SECRET="Секрет регистрации (plain для @MTProxybot)"
    U_TLS_DOMAIN="TLS домен"
    U_PROXY_HOST="Хост прокси"
    U_CONN_LINKS="🔗 Ссылки подключения:"
    U_WEB_LINKS="🌐 Веб-ссылки:"
    U_NO_LINKS="❌ Нет доступных ссылок"
    U_NO_ACTIVE="❌ Нет активных ссылок. Сервис запущен?"
    U_DETAIL_TITLE="=== Детальная информация MTProxy ==="
    U_CONFIG_FILE="📄 Файл конфигурации:"
    U_MGMT_CMDS="🛠️  Команды управления:"
    U_FETCHING="📊 Получение статистики с порта"
    U_FETCH_FAIL="❌ Не удалось получить статистику. Сервис запущен?"
    U_UPDATING="Обновление proxy-multi.conf с Telegram..."
    U_UPDATE_OK="✅ proxy-multi.conf обновлён"
    U_RESTARTING="Перезапуск сервиса..."
    U_RESTART_OK="✅ Сервис перезапущен"
    U_RESTART_FAIL="❌ Не удалось перезапустить"
    U_DL_FAIL="❌ Не удалось загрузить proxy-multi.conf"
    U_STARTING="Запуск сервиса MTProxy..."
    U_START_OK="✅ Сервис запущен"
    U_START_FAIL="❌ Не удалось запустить"
    U_STOPPING="Остановка сервиса MTProxy..."
    U_STOP_OK="✅ Сервис остановлен"
    U_TESTING="Тестирование подключения MTProxy..."
    U_PORT_TEST="Тестирование порта"
    U_PORT_OPEN="✅ Порт открыт локально"
    U_PORT_CLOSED="❌ Порт недоступен локально"
    U_NO_NC="⚠️  nc/telnet недоступны"
    U_LISTENING="✅ Сервис слушает на порту"
    U_NOT_LISTENING="❌ Ничего не слушает на порту"
    U_STATS_OK="✅ Эндпоинт статистики отвечает"
    U_STATS_FAIL="⚠️  Эндпоинт статистики не отвечает"
    U_RECENT_ERR="Недавние ошибки в логах:"
    U_NO_ERRORS="✅ Нет недавних ошибок"
    U_NO_PORT="❌ Не удалось определить порт"
    U_UNKNOWN="Неизвестная команда:"
    U_SHOWING_LOGS="Логи MTProxy (Ctrl+C для выхода):"
else
    U_HELP_TITLE="MTProxy Management Utility"
    U_HELP_USAGE="Usage: mtproxy [command]"
    U_HELP_COMMANDS="Commands:"
    U_STATUS="Status"
    U_STATUS_LINKS="Show service status and connection links"
    U_START="Start MTProxy service"
    U_STOP="Stop MTProxy service"
    U_RESTART="Restart MTProxy service"
    U_LOGS="Show service logs"
    U_LINKS="Show connection links only"
    U_INFO="Show detailed configuration"
    U_STATS_CMD="Show proxy statistics"
    U_TEST_CMD="Test proxy connectivity"
    U_UPDATE_CMD="Update proxy-multi.conf from Telegram"
    U_HELP_CMD="Show this help"
    U_SVC_RUNNING="✅ Service: Running"
    U_SVC_STOPPED="❌ Service: Stopped"
    U_CONFIG="📊 Configuration:"
    U_PORT="Port"
    U_SECRET="Secret"
    U_REG_SECRET="Registration Secret (plain for @MTProxybot)"
    U_TLS_DOMAIN="TLS Domain"
    U_PROXY_HOST="Proxy Host"
    U_CONN_LINKS="🔗 Connection Links:"
    U_WEB_LINKS="🌐 Web Links:"
    U_NO_LINKS="❌ No links available"
    U_NO_ACTIVE="❌ No active links found. Is service running?"
    U_DETAIL_TITLE="=== MTProxy Detailed Information ==="
    U_CONFIG_FILE="📄 Configuration File:"
    U_MGMT_CMDS="🛠️  Management Commands:"
    U_FETCHING="📊 Fetching proxy statistics from port"
    U_FETCH_FAIL="❌ Could not fetch stats. Is the service running?"
    U_UPDATING="Updating proxy-multi.conf from Telegram..."
    U_UPDATE_OK="✅ proxy-multi.conf updated successfully"
    U_RESTARTING="Restarting service to apply changes..."
    U_RESTART_OK="✅ Service restarted successfully"
    U_RESTART_FAIL="❌ Failed to restart service"
    U_DL_FAIL="❌ Failed to download proxy-multi.conf"
    U_STARTING="Starting MTProxy service..."
    U_START_OK="✅ Service started successfully"
    U_START_FAIL="❌ Failed to start service"
    U_STOPPING="Stopping MTProxy service..."
    U_STOP_OK="✅ Service stopped"
    U_TESTING="Testing MTProxy connectivity..."
    U_PORT_TEST="Testing port"
    U_PORT_OPEN="✅ Port is open locally"
    U_PORT_CLOSED="❌ Port is not accessible locally"
    U_NO_NC="⚠️  nc/telnet not available for port testing"
    U_LISTENING="✅ Service is listening on port"
    U_NOT_LISTENING="❌ No service listening on port"
    U_STATS_OK="✅ Statistics endpoint is responding"
    U_STATS_FAIL="⚠️  Statistics endpoint not responding"
    U_RECENT_ERR="Recent errors in logs:"
    U_NO_ERRORS="✅ No recent errors in logs"
    U_NO_PORT="❌ Cannot determine port from service config"
    U_UNKNOWN="Unknown command:"
    U_SHOWING_LOGS="Showing MTProxy logs (Ctrl+C to exit):"
fi

# Function to convert domain to hex for TLS link
domain_to_hex() {
    local domain="$1"
    echo -n "$domain" | xxd -p | tr -d '\n'
}

show_help() {
    echo -e "${BLUE}$U_HELP_TITLE${NC}\n"
    echo "$U_HELP_USAGE"
    echo ""
    echo "$U_HELP_COMMANDS"
    echo -e "  ${GREEN}status${NC}    - $U_STATUS_LINKS"
    echo -e "  ${GREEN}start${NC}     - $U_START"
    echo -e "  ${GREEN}stop${NC}      - $U_STOP"
    echo -e "  ${GREEN}restart${NC}   - $U_RESTART"
    echo -e "  ${GREEN}logs${NC}      - $U_LOGS"
    echo -e "  ${GREEN}links${NC}     - $U_LINKS"
    echo -e "  ${GREEN}info${NC}      - $U_INFO"
    echo -e "  ${GREEN}stats${NC}     - $U_STATS_CMD"
    echo -e "  ${GREEN}test${NC}      - $U_TEST_CMD"
    echo -e "  ${GREEN}update${NC}    - $U_UPDATE_CMD"
    echo -e "  ${GREEN}help${NC}      - $U_HELP_CMD"
}

get_service_config() {
    if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        EXEC_START=$(grep "ExecStart=" "/etc/systemd/system/$SERVICE_NAME.service" | cut -d'=' -f2-)

        # Extract port from -H flag
        PORT=$(echo "$EXEC_START" | grep -oP '(?<=-H )\S+')

        # Extract secret from -S flag
        SECRET=$(echo "$EXEC_START" | grep -oP '(?<=-S )\S+')

        # Extract TLS domain from -D flag
        TLS_DOMAIN=$(echo "$EXEC_START" | grep -oP '(?<=-D )\S+')

        # Extract stats port from -p flag
        STATS_PORT=$(echo "$EXEC_START" | grep -oP '(?<=-p )\S+')
    fi
}

get_proxy_host() {
    # Get the proxy host: prefer domain from info.txt, fallback to IP detection
    PROXY_HOST=""

    if [[ -f "$INSTALL_DIR/info.txt" ]]; then
        PROXY_HOST=$(grep "Proxy Host:" "$INSTALL_DIR/info.txt" 2>/dev/null | awk '{print $3}')
    fi

    if [[ -z "$PROXY_HOST" ]]; then
        for service in "ipv4.icanhazip.com" "ipv4.ident.me" "ifconfig.me/ip" "api.ipify.org"; do
            if DETECTED_IP=$(curl -4 -s --connect-timeout 5 "$service" 2>/dev/null) && [[ -n "$DETECTED_IP" ]]; then
                if [[ $DETECTED_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                    IFS='.' read -ra ADDR <<< "$DETECTED_IP"
                    valid=true
                    for i in "${ADDR[@]}"; do
                        if [[ $i -gt 255 || $i -lt 0 ]]; then
                            valid=false
                            break
                        fi
                    done
                    if [[ $valid == true ]]; then
                        PROXY_HOST="$DETECTED_IP"
                        break
                    fi
                fi
            fi
        done
    fi

    if [[ -z "$PROXY_HOST" ]]; then
        PROXY_HOST="YOUR_SERVER_IP"
    fi
}

generate_links() {
    get_service_config
    get_proxy_host

    if [[ -n "$PORT" && -n "$SECRET" ]]; then
        # Get TLS domain
        [[ -z "$TLS_DOMAIN" ]] && TLS_DOMAIN="github.com"
        TLS_DOMAIN_HEX=$(domain_to_hex "$TLS_DOMAIN")

        # Generate all link types
        PLAIN_LINK="tg://proxy?server=$PROXY_HOST&port=$PORT&secret=${SECRET}"
        DD_LINK="tg://proxy?server=$PROXY_HOST&port=$PORT&secret=dd${SECRET}"
        EE_LINK="tg://proxy?server=$PROXY_HOST&port=$PORT&secret=ee${SECRET}${TLS_DOMAIN_HEX}"
    fi
}

show_status() {
    echo -e "${BLUE}=== MTProxy $U_STATUS ===${NC}\n"

    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}$U_SVC_RUNNING${NC}"
    else
        echo -e "${RED}$U_SVC_STOPPED${NC}"
        return 1
    fi

    get_service_config
    get_proxy_host
    echo -e "${YELLOW}$U_CONFIG${NC}"
    echo -e "   $U_PORT: ${GREEN}${PORT:-unknown}${NC}"
    echo -e "   $U_SECRET: ${GREEN}${SECRET:-unknown}${NC}"
    echo -e "   $U_REG_SECRET: ${GREEN}${SECRET:-unknown}${NC}"
    echo -e "   $U_TLS_DOMAIN: ${GREEN}${TLS_DOMAIN:-unknown}${NC}"
    echo -e "   $U_PROXY_HOST: ${GREEN}${PROXY_HOST:-unknown}${NC}"

    generate_links
    if [[ -n "$PLAIN_LINK" || -n "$DD_LINK" || -n "$EE_LINK" ]]; then
        echo -e "\n${YELLOW}$U_CONN_LINKS${NC}"
        [[ -n "$PLAIN_LINK" ]] && echo -e "${GREEN}Plain (for @MTProxybot):${NC} $PLAIN_LINK"
        [[ -n "$DD_LINK" ]] && echo -e "${GREEN}DD (legacy clients):${NC} $DD_LINK"
        [[ -n "$EE_LINK" ]] && echo -e "${GREEN}TLS:${NC}      $EE_LINK"

        echo -e "\n${YELLOW}$U_WEB_LINKS${NC}"
        [[ -n "$PLAIN_LINK" ]] && echo -e "${GREEN}Plain:${NC} $(echo "$PLAIN_LINK" | sed 's|tg://|https://t.me/|')"
        [[ -n "$DD_LINK" ]] && echo -e "${GREEN}DD:${NC} $(echo "$DD_LINK" | sed 's|tg://|https://t.me/|')"
        [[ -n "$EE_LINK" ]] && echo -e "${GREEN}TLS:${NC}      $(echo "$EE_LINK" | sed 's|tg://|https://t.me/|')"
    else
        echo -e "\n${RED}$U_NO_LINKS${NC}"
    fi
}

show_links() {
    generate_links
    if [[ -n "$PLAIN_LINK" || -n "$DD_LINK" || -n "$EE_LINK" ]]; then
        echo -e "${YELLOW}$U_CONN_LINKS${NC}"
        [[ -n "$PLAIN_LINK" ]] && echo "$PLAIN_LINK"
        [[ -n "$DD_LINK" ]] && echo "$DD_LINK"
        [[ -n "$EE_LINK" ]] && echo "$EE_LINK"
    else
        echo -e "${RED}$U_NO_ACTIVE${NC}"
        return 1
    fi
}

show_info() {
    echo -e "${BLUE}$U_DETAIL_TITLE${NC}\n"

    # Service status
    show_status

    # Show info file if exists
    if [[ -f "$INSTALL_DIR/info.txt" ]]; then
        echo -e "\n${YELLOW}$U_CONFIG_FILE${NC}"
        cat "$INSTALL_DIR/info.txt"
    fi

    echo -e "\n${YELLOW}$U_MGMT_CMDS${NC}"
    echo -e "${GREEN}mtproxy status${NC}    - $U_STATUS_LINKS"
    echo -e "${GREEN}mtproxy restart${NC}   - $U_RESTART"
    echo -e "${GREEN}mtproxy logs${NC}      - $U_LOGS"
    echo -e "${GREEN}mtproxy stats${NC}     - $U_STATS_CMD"
}

show_stats() {
    get_service_config
    local stats_port="${STATS_PORT:-2398}"
    echo -e "${YELLOW}$U_FETCHING $stats_port...${NC}"
    STATS=$(curl -s --connect-timeout 5 "http://localhost:$stats_port/stats" 2>/dev/null)
    if [[ -n "$STATS" ]]; then
        echo -e "${GREEN}$STATS${NC}"
    else
        echo -e "${RED}$U_FETCH_FAIL${NC}"
    fi
}

update_config() {
    echo -e "${YELLOW}$U_UPDATING${NC}"
    if curl -s https://core.telegram.org/getProxyConfig -o "$INSTALL_DIR/proxy-multi.conf"; then
        echo -e "${GREEN}$U_UPDATE_OK${NC}"
        echo -e "${YELLOW}$U_RESTARTING${NC}"
        systemctl restart $SERVICE_NAME
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}$U_RESTART_OK${NC}"
        else
            echo -e "${RED}$U_RESTART_FAIL${NC}"
        fi
    else
        echo -e "${RED}$U_DL_FAIL${NC}"
    fi
}

update_info_file() {
    get_service_config
    get_proxy_host
    generate_links

    # Get external IP
    EXTERNAL_IP=""
    for service in "ipv4.icanhazip.com" "ipv4.ident.me"; do
        if EXTERNAL_IP=$(curl -4 -s --connect-timeout 3 "$service" 2>/dev/null) && [[ $EXTERNAL_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            break
        fi
        EXTERNAL_IP=""
    done

    mkdir -p "$INSTALL_DIR"
    cat > "$INSTALL_DIR/info.txt" << EOL
MTProxy Configuration (GetPageSpeed Fork)
==========================================
Installation Date: $(date)
Installation Path: $INSTALL_DIR
Service Name: $SERVICE_NAME
Proxy Type: GetPageSpeed/MTProxy (C binary)

Connection Details:
------------------
Proxy Host: ${PROXY_HOST:-unknown}
External IP: ${EXTERNAL_IP:-unknown}
Port: ${PORT:-unknown}
Base Secret: ${SECRET:-unknown}
Registration Secret (plain, for @MTProxybot): ${SECRET:-unknown}
TLS Domain: ${TLS_DOMAIN:-unknown}

Working Connection Links:
------------------------
Plain Link (for registration): ${PLAIN_LINK:-Not available}
DD Link: ${DD_LINK:-Not available}
TLS Link: ${EE_LINK:-Not available}

Web Browser Links:
-----------------
Plain: $(echo "${PLAIN_LINK:-Not available}" | sed 's|tg://|https://t.me/|')
DD: $(echo "${DD_LINK:-Not available}" | sed 's|tg://|https://t.me/|')
TLS: $(echo "${EE_LINK:-Not available}" | sed 's|tg://|https://t.me/|')

Service Management:
------------------
Status:  mtproxy status
Start:   mtproxy start
Stop:    mtproxy stop
Restart: mtproxy restart
Logs:    mtproxy logs
Stats:   mtproxy stats
Info:    mtproxy info
Update:  mtproxy update

Last Updated: $(date)
EOL
}

# Main command handler
case "${1:-status}" in
    "start")
        echo -e "${YELLOW}$U_STARTING${NC}"
        systemctl start $SERVICE_NAME
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}$U_START_OK${NC}"
            update_info_file
            show_links
        else
            echo -e "${RED}$U_START_FAIL${NC}"
            exit 1
        fi
        ;;
    "stop")
        echo -e "${YELLOW}$U_STOPPING${NC}"
        systemctl stop $SERVICE_NAME
        echo -e "${GREEN}$U_STOP_OK${NC}"
        ;;
    "restart")
        echo -e "${YELLOW}$U_RESTARTING${NC}"
        systemctl restart $SERVICE_NAME
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}$U_RESTART_OK${NC}"
            update_info_file
            show_links
        else
            echo -e "${RED}$U_RESTART_FAIL${NC}"
            exit 1
        fi
        ;;
    "status")
        show_status
        update_info_file
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
    "update")
        update_config
        ;;
    "test")
        echo -e "${YELLOW}$U_TESTING${NC}"
        get_service_config
        if [[ -n "$PORT" ]]; then
            echo -e "$U_PORT_TEST $PORT..."
            if command -v nc >/dev/null 2>&1; then
                if timeout 5 nc -z localhost "$PORT" 2>/dev/null; then
                    echo -e "${GREEN}$U_PORT_OPEN${NC}"
                else
                    echo -e "${RED}$U_PORT_CLOSED${NC}"
                fi
            elif command -v telnet >/dev/null 2>&1; then
                if timeout 5 bash -c "echo | telnet localhost $PORT" 2>/dev/null | grep -q "Connected"; then
                    echo -e "${GREEN}$U_PORT_OPEN${NC}"
                else
                    echo -e "${RED}$U_PORT_CLOSED${NC}"
                fi
            else
                echo -e "${YELLOW}$U_NO_NC${NC}"
            fi

            # Check if service is actually listening
            if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
                echo -e "${GREEN}$U_LISTENING $PORT${NC}"
            else
                echo -e "${RED}$U_NOT_LISTENING $PORT${NC}"
            fi

            # Check statistics endpoint
            stats_port="${STATS_PORT:-2398}"
            STATS=$(curl -s --connect-timeout 3 "http://localhost:$stats_port/stats" 2>/dev/null)
            if [[ -n "$STATS" ]]; then
                echo -e "${GREEN}$U_STATS_OK${NC}"
            else
                echo -e "${YELLOW}$U_STATS_FAIL${NC}"
            fi

            # Check logs for errors
            RECENT_ERRORS=$(journalctl -u mtproxy --no-pager -n 10 --since "10 minutes ago" | grep -i "error\|fail\|exception" | tail -3)
            if [[ -n "$RECENT_ERRORS" ]]; then
                echo -e "${RED}$U_RECENT_ERR${NC}"
                echo "$RECENT_ERRORS"
            else
                echo -e "${GREEN}$U_NO_ERRORS${NC}"
            fi
        else
            echo -e "${RED}$U_NO_PORT${NC}"
        fi
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

# Move the utility to final location and set permissions
mv "/tmp/mtproxy_utility" "/usr/local/bin/mtproxy"
chmod +x "/usr/local/bin/mtproxy"

# Reload and start service
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

sleep 3

# Check service status and create info file
if systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "${GREEN}$MSG_SVC_RUNNING${NC}"

    # Update info file using the management utility
    /usr/local/bin/mtproxy status

    echo -e "\n${YELLOW}$MSG_COMPLETE${NC}"
    echo -e "\n${CYAN}$MSG_QUICK${NC}"
    echo -e "${GREEN}mtproxy${NC}         - $MSG_QUICK1"
    echo -e "${GREEN}mtproxy restart${NC} - $MSG_QUICK2"
    echo -e "${GREEN}mtproxy links${NC}   - $MSG_QUICK3"
    echo -e "${GREEN}mtproxy stats${NC}   - $MSG_QUICK4"
    echo -e "${GREEN}mtproxy update${NC}  - $MSG_QUICK5"
    echo -e "${GREEN}mtproxy help${NC}    - $MSG_QUICK6"

else
    echo -e "${RED}$MSG_SVC_FAIL${NC}"
    systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

echo -e "\n${BLUE}$MSG_SAVED ${GREEN}$INSTALL_DIR/info.txt${NC}"
echo -e "${BLUE}$MSG_UTIL_PATH ${GREEN}/usr/local/bin/mtproxy${NC}"
echo -e "${BLUE}$MSG_AUTOSTART${NC}"
echo -e "${BLUE}$MSG_STATS_INFO ${GREEN}curl http://localhost:$STATS_PORT/stats${NC}"
echo -e "\n${YELLOW}$MSG_REMOVE_LATER${NC}"
echo -e "${GREEN}$0 uninstall${NC}"
