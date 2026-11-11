#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ♾️ COKI STUDIOS — LOOPING ENGINE & SMILEDEV NATIVE INSTALLER
# Universal macOS (arm64 + x86_64) • v1.1 (Arch 3.0A)
# Channels: Looping (Prod) • Omega Looping (RC) • Alpha! Looping (Super Exp)
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

CHANNEL="${LOOPING_CHANNEL:-prod}"
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --channel=*) CHANNEL="${1#*=}" ;;
        --channel|-c) shift || true; CHANNEL="${1:-prod}" ;;
        --alpha|--alpha!|--1.1a|--1.1A) CHANNEL="alpha" ;;
        --omega|--rc) CHANNEL="omega" ;;
        --prod|--stable) CHANNEL="prod" ;;
    esac
    shift || true
done

CHANNEL_LC="$(echo "$CHANNEL" | tr '[:upper:]' '[:lower:]')"
case "$CHANNEL_LC" in
    alpha|alpha!|1.1a|alpha-1.1a|experimental|super-experimental)
        BRAND_NAME="Alpha! SmileDev & Looping"
        TIER_LABEL="Super Experimental"
        VERSION="1.1A"
        CH_KEY="alpha"
        TAR_NAME="looping-v1.1A-darwin-universal.tar.gz"
        TARBALL_SHA256="6494f61686a699aab2715b3ed9cca3778a7dd5cd35ab4859d5fbf7f4d2193b7d"
        ;;
    omega|rc|release-candidate)
        BRAND_NAME="Omega Looping"
        TIER_LABEL="Release Candidate (RC)"
        VERSION="1.1-omega"
        CH_KEY="omega"
        TAR_NAME="looping-v1.1-darwin-universal.tar.gz"
        TARBALL_SHA256="6494f61686a699aab2715b3ed9cca3778a7dd5cd35ab4859d5fbf7f4d2193b7d"
        ;;
    *)
        BRAND_NAME="Looping"
        TIER_LABEL="Production Release"
        VERSION="1.1"
        CH_KEY="prod"
        TAR_NAME="looping-v1.1-darwin-universal.tar.gz"
        TARBALL_SHA256="6494f61686a699aab2715b3ed9cca3778a7dd5cd35ab4859d5fbf7f4d2193b7d"
        ;;
esac

ARCH_VER="3.0A"
PRIMARY_URL="https://repo.cokistudios.com/engine/${TAR_NAME}"
FALLBACK_URL1="https://cokistudios.github.io/engine/${TAR_NAME}"
FALLBACK_URL2="https://github.com/CokiStudios/engine/releases/download/v1.1/${TAR_NAME}"

echo -e "${C_CYAN}  _____           _ _      ${C_PURPLE}____${C_RESET}"
echo -e "${C_CYAN} / ____|         (_) |    ${C_PURPLE}|  _ \   ${C_BOLD}${BRAND_NAME} & smiledev ${C_AQUA}v$VERSION${C_RESET} ${C_YELLOW}(Arch $ARCH_VER)${C_RESET}"
echo -e "${C_CYAN}| (___  _ __ ___  _| | ___${C_PURPLE}| | | | _____   __${C_RESET}"
echo -e "${C_CYAN} \___ \| '_ \` _ \| | |/ _ \ ${C_PURPLE}| | |/ _ \ \ / /${C_RESET}"
echo -e "${C_CYAN} ____) | | | | | | | |  __/${C_PURPLE} |_| |  __/\ V / ${C_RESET}"
echo -e "${C_CYAN}|_____/|_| |_| |_|_|_|\___${C_PURPLE}|____/ \___| \_/  ${C_DIM}($TIER_LABEL • Universal Native Engine)${C_RESET}"
echo ""
echo -e "${C_BOLD}🌟 Installing ${BRAND_NAME} v$VERSION (${TIER_LABEL} / Arch $ARCH_VER) for macOS (arm64/x86_64)...${C_RESET}"

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

echo -e "📦 Downloading ${BRAND_NAME} v$VERSION from repo.cokistudios.com/engine..."
if ! curl -fsSL --connect-timeout 8 "$PRIMARY_URL" -o "$TMP_TAR" 2>/dev/null; then
    echo -e "${C_DIM}Trying fallback mirror 1...${C_RESET}"
    if ! curl -fsSL --connect-timeout 8 "$FALLBACK_URL1" -o "$TMP_TAR" 2>/dev/null; then
        echo -e "${C_DIM}Trying fallback mirror 2 (GitHub CokiStudios/engine)...${C_RESET}"
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
mkdir -p "$HOME/.smiledev" 2>/dev/null || true
echo "$CH_KEY" > "$HOME/.smiledev/channel" 2>/dev/null || true

# Verify installations
echo ""
echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
echo -e "${C_BOLD}🎉 ${BRAND_NAME} v$VERSION (ARCH $ARCH_VER) INSTALLED!${C_RESET}"
echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
if [ -x "$TARGET_DIR/looping" ]; then
    echo -n "  • Engine:   "
    LOOPING_CHANNEL="$CH_KEY" "$TARGET_DIR/looping" --version | head -n1
fi
if [ -x "$TARGET_DIR/smiledev" ]; then
    echo -n "  • smiledev: "
    "$TARGET_DIR/smiledev" version --channel="$CH_KEY"
fi

echo ""
echo -e "${C_BOLD}QUICK START:${C_RESET}"
echo -e "  ${C_CYAN}looping${C_RESET}                        Interactive REPL (Prod v1.1 / Arch 3.0A)"
echo -e "  ${C_CYAN}looping run <file.loop>${C_RESET}        Execute a 2D/3D .loop script (-i for persistent)"
echo -e "  ${C_CYAN}looping preview3d <file.loop>${C_RESET}  TrueColor Z-Buffer 3D terminal preview"
echo -e "  ${C_CYAN}looping test${C_RESET}                   Run native test suite (71/71 tests)"
echo -e "  ${C_CYAN}smiledev upgrade --alpha${C_RESET}       Switch channel (prod [1.1] | omega [RC] | alpha [1.1A])"
echo ""
