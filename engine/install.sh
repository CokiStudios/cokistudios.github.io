#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ♾️ COKI STUDIOS — LOOPING ENGINE & SMILEDEV NATIVE INSTALLER
# Universal macOS (arm64 + x86_64) • v2.6.0
# Hosted on: https://repo.cokistudios.com/engine
# ═══════════════════════════════════════════════════════════════
set -e

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_CYAN="\033[38;5;51m"
C_AQUA="\033[38;5;49m"
C_PURPLE="\033[38;5;141m"
C_GREEN="\033[38;5;48m"
C_YELLOW="\033[38;5;220m"
C_RED="\033[38;5;196m"

VERSION="2.6.0"
TARBALL_SHA256="c028b5e0e78545d038b5cb18877514f835deba49ae00dae7d3ee30c5b9eca4bd"
PRIMARY_URL="https://repo.cokistudios.com/engine/looping-v${VERSION}-darwin-universal.tar.gz"
FALLBACK_URL1="https://cokistudios.github.io/engine/looping-v${VERSION}-darwin-universal.tar.gz"
FALLBACK_URL2="https://github.com/CokiStudios/cokistudios.github.io/releases/download/v${VERSION}/looping-v${VERSION}-darwin-universal.tar.gz"

echo -e "${C_CYAN}  _____           _ _      ${C_PURPLE}____${C_RESET}"
echo -e "${C_CYAN} / ____|         (_) |    ${C_PURPLE}|  _ \   ${C_BOLD}Looping & smiledev ${C_AQUA}v$VERSION${C_RESET}"
echo -e "${C_CYAN}| (___  _ __ ___  _| | ___${C_PURPLE}| | | | _____   __${C_RESET}"
echo -e "${C_CYAN} \___ \| '_ \` _ \| | |/ _ \ ${C_PURPLE}| | |/ _ \ \ / /${C_RESET}"
echo -e "${C_CYAN} ____) | | | | | | | |  __/${C_PURPLE} |_| |  __/\ V / ${C_RESET}"
echo -e "${C_CYAN}|_____/|_| |_| |_|_|_|\___${C_PURPLE}|____/ \___| \_/  ${C_DIM}(Universal Native Engine)${C_RESET}"
echo ""
echo -e "${C_BOLD}🌟 Installing Looping Engine and smiledev for macOS (Universal arm64/x86_64)...${C_RESET}"

# Verify operating system
OS="$(uname -s)"
if [ "$OS" != "Darwin" ]; then
    echo -e "${C_YELLOW}⚠ Notice:${C_RESET} This universal package is optimized for macOS (Darwin)."
    echo -e "   For Linux / Debian / Holo Looping OS, run: ${C_CYAN}curl -fsSL https://cokistudios.github.io/apt/install.sh | sudo bash${C_RESET}"
fi

# Determine destination directory
TARGET_DIR="/usr/local/bin"
if [ ! -d "$TARGET_DIR" ]; then
    if [ -d "/opt/homebrew/bin" ]; then
        TARGET_DIR="/opt/homebrew/bin"
    else
        mkdir -p "$HOME/.local/bin" 2>/dev/null || true
        TARGET_DIR="$HOME/.local/bin"
    fi
fi

TMP_DIR="$(mktemp -d /tmp/looping-install-XXXXXX)"
TMP_TAR="$TMP_DIR/engine.tar.gz"

echo -e "📦 Downloading Looping v$VERSION from repo.cokistudios.com/engine..."
if ! curl -fsSL --connect-timeout 8 "$PRIMARY_URL" -o "$TMP_TAR" 2>/dev/null; then
    echo -e "${C_DIM}Trying fallback mirror 1...${C_RESET}"
    if ! curl -fsSL --connect-timeout 8 "$FALLBACK_URL1" -o "$TMP_TAR" 2>/dev/null; then
        echo -e "${C_DIM}Trying fallback mirror 2 (GitHub)...${C_RESET}"
        curl -fsSL --connect-timeout 10 "$FALLBACK_URL2" -o "$TMP_TAR"
    fi
fi

# Checksum verification
if command -v shasum &>/dev/null; then
    ACTUAL_SHA="$(shasum -a 256 "$TMP_TAR" | awk '{print $1}')"
    if [ "$ACTUAL_SHA" != "$TARBALL_SHA256" ]; then
        echo -e "${C_RED}✘ Security verification failed! SHA256 mismatch.${C_RESET}"
        echo -e "  Expected: $TARBALL_SHA256"
        echo -e "  Received: $ACTUAL_SHA"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    echo -e "🔒 ${C_GREEN}SHA256 signature verified:${C_RESET} ${C_DIM}$ACTUAL_SHA${C_RESET}"
fi

echo -e "⚙️ Extracting binaries..."
tar -xzf "$TMP_TAR" -C "$TMP_DIR"
chmod 755 "$TMP_DIR/looping" "$TMP_DIR/smiledev"

NEED_SUDO=false
if [ ! -w "$TARGET_DIR" ]; then
    NEED_SUDO=true
fi

echo -e "🚀 Installing into ${C_BOLD}$TARGET_DIR${C_RESET}..."
if [ "$NEED_SUDO" = true ]; then
    echo -e "${C_YELLOW}🔑 Administrator permissions required to write to $TARGET_DIR. Prompting sudo...${C_RESET}"
    sudo cp "$TMP_DIR/looping" "$TARGET_DIR/looping"
    sudo chmod 755 "$TARGET_DIR/looping"
    sudo ln -sf "$TARGET_DIR/looping" "$TARGET_DIR/ruuping" 2>/dev/null || true
    sudo cp "$TMP_DIR/smiledev" "$TARGET_DIR/smiledev"
    sudo chmod 755 "$TARGET_DIR/smiledev"
else
    cp "$TMP_DIR/looping" "$TARGET_DIR/looping"
    chmod 755 "$TARGET_DIR/looping"
    ln -sf "$TARGET_DIR/looping" "$TARGET_DIR/ruuping" 2>/dev/null || true
    cp "$TMP_DIR/smiledev" "$TARGET_DIR/smiledev"
    chmod 755 "$TARGET_DIR/smiledev"
fi

rm -rf "$TMP_DIR"

# Verify installations
echo ""
echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
echo -e "${C_BOLD}🎉 LOOPING & SMILEDEV v$VERSION INSTALLED SUCCESSFULLY!${C_RESET}"
echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
if [ -x "$TARGET_DIR/looping" ]; then
    echo -n "  • Looping:  "
    "$TARGET_DIR/looping" --version | head -n1
fi
if [ -x "$TARGET_DIR/smiledev" ]; then
    echo -n "  • smiledev: "
    "$TARGET_DIR/smiledev" version
fi

echo ""
echo -e "${C_BOLD}QUICK START:${C_RESET}"
echo -e "  ${C_CYAN}looping${C_RESET}             Interactive REPL"
echo -e "  ${C_CYAN}looping run <file>${C_RESET}  Execute a .loop script"
echo -e "  ${C_CYAN}looping test${C_RESET}        Run the native test suite"
echo -e "  ${C_CYAN}smiledev install <mod>${C_RESET} Install a community module"
echo -e "  ${C_CYAN}smiledev upgrade${C_RESET}    Auto-update Looping & smiledev"
echo ""
