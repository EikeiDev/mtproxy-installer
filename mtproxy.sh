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

echo -e "${BLUE}MTProxy Installation (GetPageSpeed Fork)${NC}\n"

# Require root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This installer must be run as root (use sudo).${NC}"
    exit 1
fi

# Check for uninstall option
if [[ "$1" == "uninstall" ]]; then
    echo -e "${YELLOW}🗑️  MTProxy Uninstallation${NC}\n"
    
    echo -e "${RED}WARNING: This will completely remove MTProxy and all related files!${NC}"
    echo -e "${YELLOW}The following will be deleted:${NC}"
    echo -e "  • Service: /etc/systemd/system/mtproxy.service"
    echo -e "  • Installation directory: /opt/MTProxy"
    echo -e "  • Management utility: /usr/local/bin/mtproxy"
    echo -e "  • Cron job: /etc/cron.daily/mtproxy-update-config"
    echo -e "  • All configuration files and secrets"
    echo ""
    
    read -p "Are you sure you want to continue? (type 'YES' to confirm): " CONFIRM
    
    if [[ "$CONFIRM" != "YES" ]]; then
        echo -e "${GREEN}Uninstallation cancelled.${NC}"
        exit 0
    fi
    
    echo -e "\n${YELLOW}Removing MTProxy...${NC}"
    
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
        echo -e "${YELLOW}Stopping MTProxy service...${NC}"
        systemctl stop mtproxy
    fi
    
    if systemctl is-enabled --quiet mtproxy 2>/dev/null; then
        echo -e "${YELLOW}Disabling MTProxy service...${NC}"
        systemctl disable mtproxy
    fi
    
    # Remove firewall rule for the actual configured port
    if [[ -n "$UNINSTALL_PORT" ]]; then
        if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
            if ufw status | grep -q "${UNINSTALL_PORT}/tcp"; then
                echo -e "${YELLOW}Removing firewall rule for port $UNINSTALL_PORT...${NC}"
                ufw delete allow ${UNINSTALL_PORT}/tcp 2>/dev/null
            fi
        fi
    fi
    
    # Remove service file
    if [[ -f "/etc/systemd/system/mtproxy.service" ]]; then
        echo -e "${YELLOW}Removing service file...${NC}"
        rm -f "/etc/systemd/system/mtproxy.service"
        systemctl daemon-reload
    fi
    
    # Remove installation directory (binary, source, configs — everything)
    if [[ -d "/opt/MTProxy" ]]; then
        echo -e "${YELLOW}Removing installation directory /opt/MTProxy...${NC}"
        rm -rf "/opt/MTProxy"
    fi
    
    # Remove management utility
    if [[ -f "/usr/local/bin/mtproxy" ]]; then
        echo -e "${YELLOW}Removing management utility...${NC}"
        rm -f "/usr/local/bin/mtproxy"
    fi
    
    # Remove cron job
    if [[ -f "/etc/cron.daily/mtproxy-update-config" ]]; then
        echo -e "${YELLOW}Removing cron job...${NC}"
        rm -f "/etc/cron.daily/mtproxy-update-config"
    fi
    
    echo -e "\n${GREEN}✅ MTProxy has been completely removed!${NC}"
    echo -e "${CYAN}All files, services, and configurations have been deleted.${NC}"
    
    exit 0
fi

# Check for help or invalid arguments
if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "${BLUE}MTProxy Installation Script${NC}\n"
    echo "Usage:"
    echo -e "  ${GREEN}$0${NC}              - Install MTProxy with interactive setup"
    echo -e "  ${GREEN}$0 uninstall${NC}    - Completely remove MTProxy and all files"
    echo -e "  ${GREEN}$0 help${NC}         - Show this help message"
    echo ""
    echo "After installation, use 'mtproxy' command to manage the service."
    exit 0
fi

if [[ -n "$1" && "$1" != "install" ]]; then
    echo -e "${RED}Error: Unknown argument '$1'${NC}"
    echo -e "Use '${GREEN}$0 help${NC}' for usage information."
    exit 1
fi

# Configuration
INSTALL_DIR="/opt/MTProxy"
SERVICE_NAME="mtproxy"
DEFAULT_PORT=443
STATS_PORT=2398

# Get user input
read -p "Enter proxy port (default: $DEFAULT_PORT): " USER_PORT
PORT=${USER_PORT:-$DEFAULT_PORT}

echo -e "\n${YELLOW}Installing MTProxy (GetPageSpeed fork)...${NC}"

# Install dependencies
echo -e "${YELLOW}Installing build dependencies...${NC}"
if command -v apt >/dev/null 2>&1; then
    apt update -qq
    apt install -y git curl build-essential libssl-dev zlib1g-dev xxd || apt install -y vim-common
else
    echo -e "${RED}apt not found. This script currently supports Debian/Ubuntu (apt).${NC}"
    echo -e "${YELLOW}Install dependencies manually: git curl build-essential libssl-dev zlib1g-dev xxd.${NC}"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Stop existing service if running
systemctl stop mtproxy 2>/dev/null

# Clone and build MTProxy
echo -e "${YELLOW}Cloning GetPageSpeed/MTProxy repository...${NC}"
if [[ -d "$INSTALL_DIR/src" ]]; then
    echo -e "${YELLOW}Source directory exists, pulling latest changes...${NC}"
    cd "$INSTALL_DIR/src"
    git pull
else
    git clone https://github.com/GetPageSpeed/MTProxy "$INSTALL_DIR/src"
    cd "$INSTALL_DIR/src"
fi

echo -e "${YELLOW}Building MTProxy (this may take a minute)...${NC}"
make clean 2>/dev/null
if make; then
    echo -e "${GREEN}Build successful!${NC}"
else
    echo -e "${RED}Build failed! Check build dependencies.${NC}"
    exit 1
fi

# Copy binary
cp "$INSTALL_DIR/src/objs/bin/mtproto-proxy" "$INSTALL_DIR/mtproto-proxy"
chmod +x "$INSTALL_DIR/mtproto-proxy"
echo -e "${GREEN}Binary installed to $INSTALL_DIR/mtproto-proxy${NC}"

# Download proxy-secret and proxy-multi.conf
echo -e "${YELLOW}Downloading Telegram proxy configuration...${NC}"
if ! curl -s https://core.telegram.org/getProxySecret -o "$INSTALL_DIR/proxy-secret"; then
    echo -e "${RED}Failed to download proxy-secret${NC}"
    exit 1
fi
if ! curl -s https://core.telegram.org/getProxyConfig -o "$INSTALL_DIR/proxy-multi.conf"; then
    echo -e "${RED}Failed to download proxy-multi.conf${NC}"
    exit 1
fi
echo -e "${GREEN}Telegram configuration downloaded${NC}"

# Generate user secret (or use existing one)
if [[ -f "$INSTALL_DIR/info.txt" ]] && grep -q "Base Secret:" "$INSTALL_DIR/info.txt"; then
    USER_SECRET=$(grep "Base Secret:" "$INSTALL_DIR/info.txt" | awk '{print $3}')
    echo -e "${GREEN}Using existing secret: $USER_SECRET${NC}"
else
    USER_SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo -e "${GREEN}Generated new secret: $USER_SECRET${NC}"
fi

# Get external IP (IPv4 only)
echo -e "${YELLOW}Getting external IPv4 address...${NC}"
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
    echo -e "${RED}Failed to detect external IPv4 address${NC}"
    echo -e "${YELLOW}Please manually check your IPv4 with: curl -4 ifconfig.me${NC}"
else
    echo -e "${GREEN}Detected external IPv4: $EXTERNAL_IP${NC}"
fi

# Ask for domain (optional)
echo -e "\n${YELLOW}🌐 Domain Setup (Optional):${NC}"
echo -e "${CYAN}You can use a domain name instead of IP address for better user experience.${NC}"
echo -e "${CYAN}Examples: proxy.example.com, vpn.mydomain.org${NC}"
echo -e "${CYAN}Leave empty to use IP address: $EXTERNAL_IP${NC}"
echo ""
read -p "Enter domain name (optional): " USER_DOMAIN

if [[ -n "$USER_DOMAIN" ]]; then
    if [[ $USER_DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        PROXY_HOST="$USER_DOMAIN"
        echo -e "${GREEN}Using domain: $PROXY_HOST${NC}"
        echo -e "${YELLOW}Checking DNS for domain...${NC}"
        DOMAIN_IP=$(getent ahostsv4 "$PROXY_HOST" 2>/dev/null | awk '/STREAM/ {print $1; exit}')
        if [[ -n "$DOMAIN_IP" && -n "$EXTERNAL_IP" && "$DOMAIN_IP" != "$EXTERNAL_IP" ]]; then
            echo -e "${YELLOW}Warning:${NC} DNS ($PROXY_HOST -> ${DOMAIN_IP}) doesn't match detected external IP (${EXTERNAL_IP})."
            echo -e "${YELLOW}Make sure your domain A-record points to ${EXTERNAL_IP}.${NC}"
        else
            echo -e "${GREEN}DNS looks ok.${NC}"
        fi
    else
        echo -e "${RED}Invalid domain format. Using IP address instead.${NC}"
        PROXY_HOST="$EXTERNAL_IP"
    fi
else
    PROXY_HOST="$EXTERNAL_IP"
    echo -e "${GREEN}Using IP address: $PROXY_HOST${NC}"
fi

# TLS Domain setup for better security
echo -e "\n${YELLOW}🔒 TLS Domain Setup:${NC}"
echo -e "${CYAN}MTProxy uses a domain for TLS certificate masking to avoid detection.${NC}"
echo -e "${CYAN}Using random existing domains is more secure than default google.com${NC}"
echo -e "${CYAN}Examples: github.com, cloudflare.com, microsoft.com, amazon.com${NC}"
echo ""

# List of TLS 1.3 compatible domains (must support x25519 cipher)
TLS_DOMAINS=("www.google.com" "www.cloudflare.com" "www.microsoft.com" "www.amazon.com" "www.instagram.com" "www.facebook.com")
RANDOM_DOMAIN=${TLS_DOMAINS[$RANDOM % ${#TLS_DOMAINS[@]}]}

read -p "Enter TLS domain for masking (default: $RANDOM_DOMAIN): " USER_TLS_DOMAIN
TLS_DOMAIN=${USER_TLS_DOMAIN:-$RANDOM_DOMAIN}

# Verify TLS 1.3 support
while true; do
    echo -e "${YELLOW}Checking TLS 1.3 support for $TLS_DOMAIN...${NC}"
    if command -v openssl >/dev/null 2>&1; then
        TLS_CHECK=$(echo | openssl s_client -connect "$TLS_DOMAIN:443" -tls1_3 2>&1)
        if echo "$TLS_CHECK" | grep -qi "TLSv1.3\|tls1.3"; then
            echo -e "${GREEN}✅ $TLS_DOMAIN supports TLS 1.3${NC}"
            break
        else
            echo -e "${RED}⚠️  $TLS_DOMAIN does NOT appear to support TLS 1.3${NC}"
            echo -e "${YELLOW}MTProxy EE mode requires a domain with TLS 1.3 + x25519 support.${NC}"
            echo ""
            echo -e "${CYAN}Options:${NC}"
            echo -e "  ${GREEN}1${NC} - Enter a different domain"
            echo -e "  ${GREEN}2${NC} - Continue anyway (connection may not work)"
            read -p "Your choice [1/2]: " TLS_CHOICE
            if [[ "$TLS_CHOICE" == "2" ]]; then
                echo -e "${YELLOW}Continuing with $TLS_DOMAIN...${NC}"
                break
            else
                read -p "Enter TLS domain for masking: " TLS_DOMAIN
                [[ -z "$TLS_DOMAIN" ]] && TLS_DOMAIN="$RANDOM_DOMAIN"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  openssl not found, skipping TLS 1.3 check${NC}"
        break
    fi
done

echo -e "${GREEN}Using TLS domain: $TLS_DOMAIN${NC}"

# NAT detection: compare internal IP with external IP
echo -e "${YELLOW}Checking NAT configuration...${NC}"
INTERNAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || hostname -I 2>/dev/null | awk '{print $1}')
NAT_INFO=""
if [[ -n "$INTERNAL_IP" && -n "$EXTERNAL_IP" && "$INTERNAL_IP" != "$EXTERNAL_IP" && "$EXTERNAL_IP" != "YOUR_SERVER_IP" ]]; then
    NAT_INFO="--nat-info ${INTERNAL_IP}:${EXTERNAL_IP}"
    echo -e "${GREEN}NAT detected: $INTERNAL_IP -> $EXTERNAL_IP (will use --nat-info)${NC}"
else
    echo -e "${GREEN}No NAT detected (direct connection)${NC}"
fi

# Workers: use 1 worker with TLS transport (recommended by upstream)
WORKERS=1
echo -e "${GREEN}Using $WORKERS worker (recommended for TLS transport)${NC}"

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
echo -e "${YELLOW}Creating systemd service...${NC}"
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
ExecStart=$INSTALL_DIR/mtproto-proxy -u nobody -p $STATS_PORT -H $PORT -S $USER_SECRET -D $TLS_DOMAIN $NAT_INFO --aes-pwd $INSTALL_DIR/proxy-secret $INSTALL_DIR/proxy-multi.conf -M $WORKERS
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
        echo -e "${GREEN}UFW: Opened port $PORT/tcp${NC}"
    fi
fi

# Create cron job for daily proxy-multi.conf update
echo -e "${YELLOW}Creating daily config update cron job...${NC}"
cat > "/etc/cron.daily/mtproxy-update-config" << 'CRON_EOF'
#!/bin/bash
# Update MTProxy Telegram configuration daily
curl -s https://core.telegram.org/getProxyConfig -o /opt/MTProxy/proxy-multi.conf 2>/dev/null
CRON_EOF
chmod +x "/etc/cron.daily/mtproxy-update-config"
echo -e "${GREEN}Cron job created: /etc/cron.daily/mtproxy-update-config${NC}"

# Create management utility
echo -e "${YELLOW}Creating management utility...${NC}"

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

# Function to convert domain to hex for TLS link
domain_to_hex() {
    local domain="$1"
    echo -n "$domain" | xxd -p | tr -d '\n'
}

show_help() {
    echo -e "${BLUE}MTProxy Management Utility${NC}\n"
    echo "Usage: mtproxy [command]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}status${NC}    - Show service status and connection links"
    echo -e "  ${GREEN}start${NC}     - Start MTProxy service"
    echo -e "  ${GREEN}stop${NC}      - Stop MTProxy service"
    echo -e "  ${GREEN}restart${NC}   - Restart MTProxy service"
    echo -e "  ${GREEN}logs${NC}      - Show service logs"
    echo -e "  ${GREEN}links${NC}     - Show connection links only"
    echo -e "  ${GREEN}info${NC}      - Show detailed configuration"
    echo -e "  ${GREEN}stats${NC}     - Show proxy statistics"
    echo -e "  ${GREEN}test${NC}      - Test proxy connectivity"
    echo -e "  ${GREEN}update${NC}    - Update proxy-multi.conf from Telegram"
    echo -e "  ${GREEN}help${NC}      - Show this help"
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
    echo -e "${BLUE}=== MTProxy Status ===${NC}\n"

    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Service: Running${NC}"
    else
        echo -e "${RED}❌ Service: Stopped${NC}"
        return 1
    fi

    get_service_config
    get_proxy_host
    echo -e "${YELLOW}📊 Configuration:${NC}"
    echo -e "   Port: ${GREEN}${PORT:-unknown}${NC}"
    echo -e "   Secret: ${GREEN}${SECRET:-unknown}${NC}"
    echo -e "   Registration Secret (plain for @MTProxybot): ${GREEN}${SECRET:-unknown}${NC}"
    echo -e "   TLS Domain: ${GREEN}${TLS_DOMAIN:-unknown}${NC}"
    echo -e "   Proxy Host: ${GREEN}${PROXY_HOST:-unknown}${NC}"

    generate_links
    if [[ -n "$PLAIN_LINK" || -n "$DD_LINK" || -n "$EE_LINK" ]]; then
        echo -e "\n${YELLOW}🔗 Connection Links:${NC}"
        [[ -n "$PLAIN_LINK" ]] && echo -e "${GREEN}Plain (for @MTProxybot):${NC} $PLAIN_LINK"
        [[ -n "$DD_LINK" ]] && echo -e "${GREEN}DD (legacy clients):${NC} $DD_LINK"
        [[ -n "$EE_LINK" ]] && echo -e "${GREEN}TLS:${NC}      $EE_LINK"

        echo -e "\n${YELLOW}🌐 Web Links:${NC}"
        [[ -n "$PLAIN_LINK" ]] && echo -e "${GREEN}Plain:${NC} $(echo "$PLAIN_LINK" | sed 's|tg://|https://t.me/|')"
        [[ -n "$DD_LINK" ]] && echo -e "${GREEN}DD:${NC} $(echo "$DD_LINK" | sed 's|tg://|https://t.me/|')"
        [[ -n "$EE_LINK" ]] && echo -e "${GREEN}TLS:${NC}      $(echo "$EE_LINK" | sed 's|tg://|https://t.me/|')"
    else
        echo -e "\n${RED}❌ No links available${NC}"
    fi
}

show_links() {
    generate_links
    if [[ -n "$PLAIN_LINK" || -n "$DD_LINK" || -n "$EE_LINK" ]]; then
        echo -e "${YELLOW}🔗 MTProxy Connection Links:${NC}"
        [[ -n "$PLAIN_LINK" ]] && echo "$PLAIN_LINK"
        [[ -n "$DD_LINK" ]] && echo "$DD_LINK"
        [[ -n "$EE_LINK" ]] && echo "$EE_LINK"
    else
        echo -e "${RED}❌ No active links found. Is service running?${NC}"
        return 1
    fi
}

show_info() {
    echo -e "${BLUE}=== MTProxy Detailed Information ===${NC}\n"

    # Service status
    show_status

    # Show info file if exists
    if [[ -f "$INSTALL_DIR/info.txt" ]]; then
        echo -e "\n${YELLOW}📄 Configuration File:${NC}"
        cat "$INSTALL_DIR/info.txt"
    fi

    echo -e "\n${YELLOW}🛠️  Management Commands:${NC}"
    echo -e "${GREEN}mtproxy status${NC}    - Show status and links"
    echo -e "${GREEN}mtproxy restart${NC}   - Restart service"
    echo -e "${GREEN}mtproxy logs${NC}      - View logs"
    echo -e "${GREEN}mtproxy stats${NC}     - Show proxy statistics"
}

show_stats() {
    get_service_config
    local stats_port="${STATS_PORT:-2398}"
    echo -e "${YELLOW}📊 Fetching proxy statistics from port $stats_port...${NC}"
    STATS=$(curl -s --connect-timeout 5 "http://localhost:$stats_port/stats" 2>/dev/null)
    if [[ -n "$STATS" ]]; then
        echo -e "${GREEN}$STATS${NC}"
    else
        echo -e "${RED}❌ Could not fetch stats. Is the service running?${NC}"
    fi
}

update_config() {
    echo -e "${YELLOW}Updating proxy-multi.conf from Telegram...${NC}"
    if curl -s https://core.telegram.org/getProxyConfig -o "$INSTALL_DIR/proxy-multi.conf"; then
        echo -e "${GREEN}✅ proxy-multi.conf updated successfully${NC}"
        echo -e "${YELLOW}Restarting service to apply changes...${NC}"
        systemctl restart $SERVICE_NAME
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✅ Service restarted successfully${NC}"
        else
            echo -e "${RED}❌ Failed to restart service${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to download proxy-multi.conf${NC}"
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
        echo -e "${YELLOW}Starting MTProxy service...${NC}"
        systemctl start $SERVICE_NAME
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✅ Service started successfully${NC}"
            update_info_file
            show_links
        else
            echo -e "${RED}❌ Failed to start service${NC}"
            exit 1
        fi
        ;;
    "stop")
        echo -e "${YELLOW}Stopping MTProxy service...${NC}"
        systemctl stop $SERVICE_NAME
        echo -e "${GREEN}✅ Service stopped${NC}"
        ;;
    "restart")
        echo -e "${YELLOW}Restarting MTProxy service...${NC}"
        systemctl restart $SERVICE_NAME
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✅ Service restarted successfully${NC}"
            update_info_file
            show_links
        else
            echo -e "${RED}❌ Failed to restart service${NC}"
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
        echo -e "${YELLOW}Showing MTProxy logs (Ctrl+C to exit):${NC}"
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
        echo -e "${YELLOW}Testing MTProxy connectivity...${NC}"
        get_service_config
        if [[ -n "$PORT" ]]; then
            echo -e "Testing port $PORT connectivity..."
            if command -v nc >/dev/null 2>&1; then
                if timeout 5 nc -z localhost "$PORT" 2>/dev/null; then
                    echo -e "${GREEN}✅ Port $PORT is open locally${NC}"
                else
                    echo -e "${RED}❌ Port $PORT is not accessible locally${NC}"
                fi
            elif command -v telnet >/dev/null 2>&1; then
                if timeout 5 bash -c "echo | telnet localhost $PORT" 2>/dev/null | grep -q "Connected"; then
                    echo -e "${GREEN}✅ Port $PORT is open locally${NC}"
                else
                    echo -e "${RED}❌ Port $PORT is not accessible locally${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  nc/telnet not available for port testing${NC}"
            fi

            # Check if service is actually listening
            if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
                echo -e "${GREEN}✅ Service is listening on port $PORT${NC}"
            else
                echo -e "${RED}❌ No service listening on port $PORT${NC}"
            fi

            # Check statistics endpoint
            stats_port="${STATS_PORT:-2398}"
            STATS=$(curl -s --connect-timeout 3 "http://localhost:$stats_port/stats" 2>/dev/null)
            if [[ -n "$STATS" ]]; then
                echo -e "${GREEN}✅ Statistics endpoint is responding${NC}"
            else
                echo -e "${YELLOW}⚠️  Statistics endpoint not responding${NC}"
            fi

            # Check logs for errors
            RECENT_ERRORS=$(journalctl -u mtproxy --no-pager -n 10 --since "10 minutes ago" | grep -i "error\|fail\|exception" | tail -3)
            if [[ -n "$RECENT_ERRORS" ]]; then
                echo -e "${RED}Recent errors in logs:${NC}"
                echo "$RECENT_ERRORS"
            else
                echo -e "${GREEN}✅ No recent errors in logs${NC}"
            fi
        else
            echo -e "${RED}❌ Cannot determine port from service config${NC}"
        fi
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
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
    echo -e "${GREEN}✅ MTProxy service is running!${NC}"

    # Update info file using the management utility
    /usr/local/bin/mtproxy status

    echo -e "\n${YELLOW}🎉 Installation Complete!${NC}"
    echo -e "\n${CYAN}📋 Quick Commands:${NC}"
    echo -e "${GREEN}mtproxy${NC}         - Show status and links"
    echo -e "${GREEN}mtproxy restart${NC} - Restart service"
    echo -e "${GREEN}mtproxy links${NC}   - Show connection links"
    echo -e "${GREEN}mtproxy stats${NC}   - Show proxy statistics"
    echo -e "${GREEN}mtproxy update${NC}  - Update Telegram config"
    echo -e "${GREEN}mtproxy help${NC}    - Show all commands"

else
    echo -e "${RED}❌ Service failed to start${NC}"
    systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

echo -e "\n${BLUE}📄 Configuration saved to: ${GREEN}$INSTALL_DIR/info.txt${NC}"
echo -e "${BLUE}🔧 Management utility: ${GREEN}/usr/local/bin/mtproxy${NC}"
echo -e "${BLUE}🔄 Service will auto-start on boot${NC}"
echo -e "${BLUE}📊 Statistics: ${GREEN}curl http://localhost:$STATS_PORT/stats${NC}"
echo -e "\n${YELLOW}💡 To completely remove MTProxy later:${NC}"
echo -e "${GREEN}$0 uninstall${NC}"
