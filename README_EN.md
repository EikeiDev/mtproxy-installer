# Teleproxy Installer

🌐 **Language:** [Русский](README.md) | English

Automated installer and manager for **Teleproxy** — a next-generation, high-performance MTProto proxy with advanced DPI resistance, Fake-TLS masking, and Direct-to-DC architecture. It entirely replaces the obsolete MTProxy. Based correctly on the latest [teleproxy/teleproxy](https://github.com/teleproxy/teleproxy) engine.

## ✨ Features

### 🚀 Installation
- **Ultra-fast setup** — no source code compiling anymore! Automatically detects architecture (`amd64`/`arm64`) and downloads the appropriate static binary.
- **Firewall Auto-config** — detects and natively handles opening ports for both `UFW` (Ubuntu) and `Firewalld` (CentOS/AlmaLinux).
- **TCP BBR Integration** — automatically injects the BBR congestion control algorithm into the Linux kernel for maximum networking throughput.
- **Modern Configuration** — automatically generates the `config.toml` structure.

### 🔒 Security & DPI Evasion
- **Fake-TLS** — perfectly masks MTProto traffic as standard TLS 1.3 web traffic.
- **SOCKS5 Upstream Routing** — route all your proxy's outbound traffic to Telegram Datacenters through a SOCKS5 proxy to hide your server origin or bypass ISP outbound blocks!
- **PROXY Protocol v1/v2** — completely "hide" the proxy port from the firewall and funnel traffic behind an Nginx, HAProxy, or Xray VPN router natively while keeping the real client IP.
- **Sponsored Ads & Direct Mode** — choose between Direct-to-DC connection for personal blazing speeds or Public Relay proxying to inject an advertising `@MTProxybot` tag.

### 🛠️ Management (`teleproxy-ctl` CLI)
After installation, a handy manager is accessible from anywhere using `teleproxy-ctl`:

| Command | Description |
|---------|-------------|
| `teleproxy-ctl status` | Service status |
| `teleproxy-ctl user-add` | Add users with support for labels, traffic quotas (`10G`), and IP limits |
| `teleproxy-ctl user-del` | Delete secrets |
| `teleproxy-ctl links` | Generate links (TLS, SECURE, CLASSIC) and show QR codes |
| `teleproxy-ctl check` | Run network diagnostics (DC reachability, NTP drift, SNI checks) |
| `teleproxy-ctl backup` | Save your configuration into a password-encrypted archive |
| `teleproxy-ctl restore` | Restore configuration from an archive |
| `teleproxy-ctl update` | Check and install Teleproxy updates |
| `teleproxy-ctl reload` | Reload configuration seamlessly |

### 📦 Maintenance
- **Cron updater** — standardly checks for Teleproxy binary updates every 3 days in the background cleanly.
- **Full uninstall** — running `./mtproxy.sh uninstall` scrubs everything: services, cron jobs, `/etc` configs, AND gracefully cleans up the previously opened Firewall ports!

## 📋 Usage

**Installation:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh)
```

**Management:**
```bash
teleproxy-ctl status
teleproxy-ctl links
teleproxy-ctl help
```

**Uninstall:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh) uninstall
```

## 📌 Requirements

- **OS:** Debian / Ubuntu, CentOS, AlmaLinux, Rocky Linux, macOS
- **Arch:** x86_64 or aarch64 (ARM64)
- **Privileges:** root or sudo
- **Dependencies:** `curl`, `xxd`
