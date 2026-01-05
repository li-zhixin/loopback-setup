# loopback-setup

Persist additional loopback addresses on macOS across reboots.

## Quick Start

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/loopback-setup/main/install.sh | sudo bash
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/loopback-setup/main/install.sh | sudo bash -s -- --uninstall
```

## What it does

This script configures `127.0.18.1/24` as an alias on the `lo0` (loopback) interface and ensures it persists across system reboots using macOS LaunchDaemon.

### Files created

- `/Library/LaunchDaemons/com.loopback-setup.plist` - LaunchDaemon configuration

## Manual Configuration

If you prefer to configure manually:

### Add the address (temporary)

```bash
sudo ifconfig lo0 alias 127.0.18.1 netmask 255.255.255.0
```

### Verify

```bash
ifconfig lo0 | grep 127.0.18.1
```

## Requirements

- macOS
- sudo/root access

## License

MIT
