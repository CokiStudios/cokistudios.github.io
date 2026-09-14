#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ♾️ COKI STUDIOS — ONE-STEP APT REPO INSTALLER FOR LOOPING
# ═══════════════════════════════════════════════════════════════
set -e

echo "🌟 Installing Looping & Ruuping Runtime for Ubuntu/Debian/Holo Looping OoS..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo bash install.sh"
    exit 1
fi

apt-get update -y
apt-get install -y curl ca-certificates nodejs python3 python3-pip

# Add Coki Studios APT Repository
echo "deb [trusted=yes] https://cokistudios.github.io/apt stable main" > /etc/apt/sources.list.d/cokistudios.list

apt-get update -y
apt-get install -y looping

echo "✅ Looping v2.1.0 installed successfully!"
echo "Type 'looping --help' or 'looping repl' to start."
