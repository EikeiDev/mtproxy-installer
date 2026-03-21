# MTProxy Installer (GetPageSpeed Fork)

🌐 **Language:** [Русский](README.md) | English

Automated installer and manager for **MTProxy** based on [GetPageSpeed/MTProxy](https://github.com/GetPageSpeed/MTProxy) — a community fork with improved stability and support.

## ✨ Features

### 🚀 Installation
- **Build from source** — automatic cloning and compilation of the latest GetPageSpeed/MTProxy version
- **Interactive setup** — step-by-step wizard with port, TLS domain, and link domain selection
- **Auto IPv4 detection** — external IP is detected automatically via multiple services
- **NAT auto-detect** — detects servers behind NAT (Yandex Cloud, AWS, etc.) and adds `--nat-info` automatically
- **TLS 1.3 verification** — checks TLS 1.3 support for the selected domain via `openssl` before installation
- **Systemd service** — auto-start on reboot, managed via systemctl
- **UFW integration** — automatic firewall port opening
- **Bilingual** — supports English and Russian interface (selected during installation)

### 🔒 Security
- **Fake-TLS (EE mode)** — traffic masking as TLS 1.3 with configurable domain
- **DD mode** — random padding support for DPI bypass
- **Secret generation** — automatic cryptographically secure secret generation
- **Secret preservation** — existing secret is preserved from `info.txt` during reinstallation

### 🌐 Connection
- **Optional domain** — use a domain name instead of IP address for connection links
- **3 link types** — Plain (for @MTProxybot registration), DD, and TLS (EE)
- **tg:// and https:// formats** — links are generated in both formats

### 🛠️ Management (`mtproxy` CLI)

| Command | Description |
|---------|-------------|
| `mtproxy status` | Service status + connection links |
| `mtproxy start` | Start the service |
| `mtproxy stop` | Stop the service |
| `mtproxy restart` | Restart the service |
| `mtproxy logs` | View real-time logs |
| `mtproxy links` | Show connection links only |
| `mtproxy info` | Detailed configuration info |
| `mtproxy stats` | Proxy statistics (HTTP endpoint) |
| `mtproxy update` | Update Telegram configuration |
| `mtproxy test` | Connectivity test and diagnostics |

### 📦 Maintenance
- **Cron job** — daily `proxy-multi.conf` update from Telegram servers
- **Full uninstall** — `./mtproxy.sh uninstall` removes everything: service, files, cron, firewall rules
- **Smart uninstall** — only the configured port rule is removed, other rules are untouched

## 📋 Usage

**Installation:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh)
```

**Management:**
```bash
mtproxy status
mtproxy restart
```

**Uninstall:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh) uninstall
```

## 📌 Requirements

- **OS:** Debian / Ubuntu (apt)
- **Privileges:** root
- **Dependencies:** installed automatically (`git`, `build-essential`, `libssl-dev`, `zlib1g-dev`, `xxd`)
