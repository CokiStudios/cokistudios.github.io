#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# [MODULE] PROFESSIONAL macOS .DMG GENERATOR WITH APPS DRAG-AND-DROP
# For hiOP Studio by CS (Looping Compile)
# ═══════════════════════════════════════════════════════════════

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist-dmg"
DMG_FINAL="$DIST_DIR/hiOP-Studio-macOS-Installer.dmg"
DMG_TEMP="$DIST_DIR/temp-hiOP.dmg"
VOLUME_NAME="hiOP Studio by CS"
STAGING_DIR="$DIST_DIR/staging"

echo "[SYS] Starting Professional .DMG build for hiOP Studio by CS..."

# 1. Clean previous build artifacts
mkdir -p "$DIST_DIR"
rm -rf "$STAGING_DIR"
rm -f "$DMG_FINAL" "$DMG_TEMP"

# 2. Build Release macOS App Bundle via Xcode
echo " 1/3 Compiling native hiOP Application (Xcode Release)..."
xcodebuild -project "$ROOT_DIR/hiOP.macOS/hiOP.xcodeproj" \
           -scheme hiOP \
           -configuration Release \
           -derivedDataPath "$ROOT_DIR/hiOP.macOS/build" \
           clean build CODE_SIGNING_ALLOWED=NO > /dev/null

APP_BUNDLE="$ROOT_DIR/hiOP.macOS/build/Build/Products/Release/hiOP.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "[ERROR] Error: App bundle not found at $APP_BUNDLE"
    exit 1
fi

# 3. Create Staging Directory with Drag to Applications Symlink
echo " 2/3 Creating DMG Staging Directory with /Applications link..."
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/hiOP.app"

# Create standard macOS Drag-to-Apps symlink
ln -s /Applications "$STAGING_DIR/Applications"

# Copy custom icon and Looping projects into installer
if [ -f "$ROOT_DIR/assets/cs-logo.png" ]; then
    cp "$ROOT_DIR/assets/cs-logo.png" "$STAGING_DIR/.VolumeIcon.png" 2>/dev/null || true
fi
mkdir -p "$STAGING_DIR/Sample Projects"
cp -R "$ROOT_DIR/sample_loop_projects/"* "$STAGING_DIR/Sample Projects/" 2>/dev/null || true

# 4. Generate Final Compressed DMG Image with HD Format
echo " 3/3 Generating Compressed Read-Only .DMG with Drag-and-Drop..."
hdiutil create -srcfolder "$STAGING_DIR" \
               -volname "$VOLUME_NAME" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDZO \
               -imagekey zlib-level=9 \
               -ov "$DMG_FINAL"

# Clean temporary staging directory
rm -rf "$STAGING_DIR"

echo "========================================================="
echo " PROFESSIONAL .DMG INSTALLER CREATED SUCCESSFULLY!"
echo " Volume: $VOLUME_NAME"
echo " Path:   $DMG_FINAL"
echo " Features: Native hiOP.app + Drag-to-Applications Symlink"
echo "========================================================="
