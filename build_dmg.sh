#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 📦 Build macOS Application & .DMG for hiOP by CS
# ═══════════════════════════════════════════════════════════════

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist-dmg"
DMG_PATH="$DIST_DIR/hiOP-by-CS-macOS.dmg"

echo "⚡ Starting hiOP by CS (.DMG) generation..."
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

echo "1/2 Compiling native hiOP macOS Studio (Xcode Release)..."
xcodebuild -project "$ROOT_DIR/hiOP.macOS/hiOP.xcodeproj" -scheme hiOP -configuration Release -derivedDataPath "$ROOT_DIR/hiOP.macOS/build" clean build CODE_SIGNING_ALLOWED=NO

APP_BUNDLE="$ROOT_DIR/hiOP.macOS/build/Build/Products/Release/hiOP.app"

if [ -d "$APP_BUNDLE" ]; then
    echo "2/2 Packaging .DMG disk image from $APP_BUNDLE..."
    hdiutil create -volname "hiOP by CS" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"
    echo "========================================================="
    echo "✅ DMG INSTALLER CREATED SUCCESSFULLY!"
    echo "📂 File Path: $DMG_PATH"
    echo "========================================================="
else
    echo "❌ Error: App bundle not found at $APP_BUNDLE"
    exit 1
fi
