#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ✦ BUILD UI CONNECT NATIVE MACOS APP (SWIFTUI) ✦
# Coki Studios & Shine OS • 2026
# ═══════════════════════════════════════════════════════════════

set -e
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAC_DIR="$ROOT_DIR/UIConnect.macOS"
BUILD_DIR="$MAC_DIR/build"
APP_DIR="$BUILD_DIR/UIConnect.app"

echo "⚡ Compiling UI Connect Native macOS App with swiftc (Apple Silicon arm64)..."
mkdir -p "$BUILD_DIR"

swiftc -O -parse-as-library \
    -framework SwiftUI -framework AppKit -framework AVFoundation -framework CryptoKit \
    $(find "$MAC_DIR/Sources" -name "*.swift") \
    -o "$BUILD_DIR/UIConnect"

echo "📦 Assembling UIConnect.app bundle..."
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/UIConnect" "$APP_DIR/Contents/MacOS/UIConnect"
cp "$MAC_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

if [ -f "$ROOT_DIR/ShineLoopLauncher.macOS/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/ShineLoopLauncher.macOS/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

chmod +x "$APP_DIR/Contents/MacOS/UIConnect"
cp "$BUILD_DIR/UIConnect" "$ROOT_DIR/bin/ui-connect-swift"
chmod +x "$ROOT_DIR/bin/ui-connect-swift"

echo "✔ Build complete: $APP_DIR"
if [ "$1" == "--open" ] || [ "$1" == "-o" ]; then
    open "$APP_DIR"
fi
