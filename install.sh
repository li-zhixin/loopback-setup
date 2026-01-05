#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOOPBACK_IP="127.0.18.1"
NETMASK="255.255.255.0"
PLIST_PATH="/Library/LaunchDaemons/com.loopback-setup.plist"
LABEL="com.loopback-setup"

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script only supports macOS"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Please run with sudo: sudo bash install.sh"
    fi
}

# Show help
show_help() {
    cat << EOF
loopback-setup - Persist loopback address on macOS

Usage:
    sudo bash install.sh [OPTIONS]

Options:
    --uninstall    Remove the loopback configuration
    --help         Show this help message

Examples:
    # Install
    curl -fsSL https://raw.githubusercontent.com/<user>/loopback-setup/main/install.sh | sudo bash

    # Uninstall
    curl -fsSL ... | sudo bash -s -- --uninstall
EOF
}

# Create LaunchDaemon plist
create_plist() {
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/sbin/ifconfig</string>
        <string>lo0</string>
        <string>alias</string>
        <string>${LOOPBACK_IP}</string>
        <string>netmask</string>
        <string>${NETMASK}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    chmod 644 "$PLIST_PATH"
}

# Install
install() {
    info "Installing loopback-setup..."

    # Check if already installed
    if [[ -f "$PLIST_PATH" ]]; then
        warn "Already installed. Reinstalling..."
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
    fi

    # Create plist
    info "Creating LaunchDaemon..."
    create_plist

    # Load daemon
    info "Loading LaunchDaemon..."
    launchctl load "$PLIST_PATH"

    # Apply immediately
    info "Applying loopback address..."
    /sbin/ifconfig lo0 alias "$LOOPBACK_IP" netmask "$NETMASK" 2>/dev/null || true

    # Verify
    if ifconfig lo0 | grep -q "$LOOPBACK_IP"; then
        success "Loopback address $LOOPBACK_IP configured successfully!"
        success "This will persist across reboots."
    else
        warn "Address may not be applied yet. It will be applied on next boot."
    fi
}

# Uninstall
uninstall() {
    info "Uninstalling loopback-setup..."

    if [[ ! -f "$PLIST_PATH" ]]; then
        warn "Not installed. Nothing to do."
        exit 0
    fi

    # Unload daemon
    info "Unloading LaunchDaemon..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true

    # Remove plist
    info "Removing plist file..."
    rm -f "$PLIST_PATH"

    # Remove address
    info "Removing loopback address..."
    /sbin/ifconfig lo0 -alias "$LOOPBACK_IP" 2>/dev/null || true

    success "Uninstalled successfully!"
}

# Main
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --uninstall)
            check_macos
            check_root
            uninstall
            ;;
        "")
            check_macos
            check_root
            install
            ;;
        *)
            error "Unknown option: $1. Use --help for usage."
            ;;
    esac
}

main "$@"
