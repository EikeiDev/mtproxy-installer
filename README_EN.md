# Teleproxy Installer

🌐 **Language:** [Русский](README.md) | English

Automated installer and manager for **Teleproxy** — a next-generation, high-performance MTProto proxy with advanced DPI resistance, Fake-TLS masking, and Direct-to-DC architecture. It entirely replaces the obsolete MTProxy. Based correctly on the latest [teleproxy/teleproxy](https://github.com/teleproxy/teleproxy) engine.

## ✨ Features

### 🚀 Installation
- **Ultra-fast setup** — no source code compiling anymore! It automatically detects your machine architecture (`amd64`/`arm64`) and downloads the appropriate static binary directly from GitHub.
- **Interactive setup** — step-by-step wizard with port, fake-TLS domain selection.
- **Modern Configuration** — automatically generates the new `config.toml` structure.
- **Auto IPv4 detection** — external IP is detected automatically via multiple APIs.
- **Systemd service** — auto-start on reboot, managed via systemctl (`teleproxy.service`).
- **Bilingual** — supports English and Russian interface (selected during installation).

### 🔒 Security & Evasion
- **Fake-TLS** — perfectly masks MTProto traffic as standard TLS 1.3 web traffic.
- **Direct-to-DC mode** — bypasses middleware servers and connects straight to Telegram Datacenters (no daily list-downloads needed).
- **State-of-the-art obfuscation** — features Dynamic Record Sizing (DRS), E2E fingerprint masking and replay-attack resistance.
- **Secret generation** — automatic cryptographically secure secret creation.

### 🛠️ Management (`teleproxy-ctl` CLI)
After installation, a handy manager is accessible from anywhere using `teleproxy-ctl`:

| Command | Description |
|---------|-------------|
| `teleproxy-ctl status` | Service status + connection links |
| `teleproxy-ctl start` | Start the service |
| `teleproxy-ctl stop` | Stop the service |
| `teleproxy-ctl restart` | Hard restart |
| `teleproxy-ctl reload` | **(NEW)** Reload TOML configuration on the fly without dropping traffic |
| `teleproxy-ctl logs` | View real-time logs |
| `teleproxy-ctl links` | Show connection links and QR codes |
| `teleproxy-ctl info` | Detailed configuration info |
| `teleproxy-ctl stats` | Prometheus-compatible HTTP metric stats |
| `teleproxy-ctl update` | **(NEW)** Check for Teleproxy binary updates and install them instantly |

### 📦 Maintenance
- **Cron updater** — standardly checks for Teleproxy binary updates every 3 days in the background cleanly.
- **Full uninstall** — running `./mtproxy.sh uninstall` scrubs everything: systemd files, cron jobs, updater scripts, and `/etc` configs.

## 📋 Usage

**Installation:**
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/mtproxy-installer/refs/heads/main/mtproxy.sh)
```

**Management:**
```bash
teleproxy-ctl status
teleproxy-ctl links
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
