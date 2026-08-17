#!/bin/bash
set -e

echo "🚀 Compilando CSMS para macOS (Binario Universal x86_64 y arm64)..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP_NAME="CSMS"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 1. Compilar para Apple Silicon (arm64: M1, M2, M3, M4, M5)
echo "📦 Compilando para Apple Silicon (arm64)..."
swiftc -O -target arm64-apple-macos12.0 -parse-as-library \
    -sdk $(xcrun --show-sdk-path) \
    -framework SwiftUI -framework WebKit -framework AppKit \
    "$DIR/main.swift" \
    -o "$BUILD_DIR/csms-arm64"

# 2. Compilar para Intel (x86_64)
echo "📦 Compilando para Intel (x86_64)..."
swiftc -O -target x86_64-apple-macos12.0 -parse-as-library \
    -sdk $(xcrun --show-sdk-path) \
    -framework SwiftUI -framework WebKit -framework AppKit \
    "$DIR/main.swift" \
    -o "$BUILD_DIR/csms-x86_64"

# 3. Crear Binario Universal usando lipo
echo "🔗 Enlazando Binario Universal con lipo..."
lipo -create -output "$MACOS_DIR/$APP_NAME" "$BUILD_DIR/csms-arm64" "$BUILD_DIR/csms-x86_64"

# 4. Crear Info.plist del Bundle
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CSMS</string>
    <key>CFBundleIdentifier</key>
    <string>com.cokistudios.csms.mac</string>
    <key>CFBundleName</key>
    <string>CSMS</string>
    <key>CFBundleDisplayName</key>
    <string>CSMS</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# 5. Firmar la app ad-hoc para ejecución local
codesign --force --deep --sign - "$APP_BUNDLE"

# 6. Crear archivo comprimido .zip listo para distribución
cd "$BUILD_DIR"
zip -r -y "$DIR/CSMS-macOS-Universal.zip" "$APP_NAME.app"
cd "$DIR"

echo "✅ ¡CSMS App compilada con éxito como Binario Universal!"
echo "📁 Bundle: $APP_BUNDLE"
echo "📦 ZIP Universal: $DIR/CSMS-macOS-Universal.zip"
lipo -info "$MACOS_DIR/$APP_NAME"
