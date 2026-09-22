#!/bin/bash
set -e

echo "🚗 [FORKAR PC] Compilando Forkar para macOS (Binario Universal x86_64 y arm64)..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP_NAME="Forkar"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

SWIFT_FILES=(
    "$DIR/ForkarApp.swift"
    "$DIR/ForkarDesktopRootView.swift"
    "$DIR/ForkarLogoView.swift"
    "$DIR/ForkarTheme.swift"
    "$DIR/Models.swift"
    "$DIR/SupabaseManager.swift"
    "$DIR/CSMSExtensionView.swift"
    "$DIR/HomeFeedView.swift"
    "$DIR/PostDetailSheet.swift"
    "$DIR/CreatePostSheet.swift"
    "$DIR/ForkarEcoView.swift"
    "$DIR/ProfileView.swift"
    "$DIR/SecurityAndNotificationManager.swift"
)

# Copiar icono oficial a Resources
if [ -f "$DIR/forkar-icon.png" ]; then
    cp "$DIR/forkar-icon.png" "$RESOURCES_DIR/forkar-icon.png"
fi

# 1. Compilar para Apple Silicon (arm64: M1, M2, M3, M4, M5)
echo "🍎 [1/4] Compilando para Apple Silicon (arm64)..."
swiftc -O -target arm64-apple-macos12.0 -parse-as-library \
    -sdk $(xcrun --show-sdk-path) \
    -framework SwiftUI -framework AppKit -framework AuthenticationServices -framework AVKit -framework AVFoundation \
    "${SWIFT_FILES[@]}" \
    -o "$BUILD_DIR/forkar-arm64"

# 2. Compilar para Intel (x86_64)
echo "💻 [2/4] Compilando para Intel x86_64..."
swiftc -O -target x86_64-apple-macos12.0 -parse-as-library \
    -sdk $(xcrun --show-sdk-path) \
    -framework SwiftUI -framework AppKit -framework AuthenticationServices -framework AVKit -framework AVFoundation \
    "${SWIFT_FILES[@]}" \
    -o "$BUILD_DIR/forkar-x86_64"

# 3. Crear Binario Universal usando lipo
echo "🔗 [3/4] Enlazando Binario Universal con lipo..."
lipo -create -output "$MACOS_DIR/$APP_NAME" "$BUILD_DIR/forkar-arm64" "$BUILD_DIR/forkar-x86_64"

# 4. Crear Info.plist
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Forkar</string>
    <key>CFBundleIdentifier</key>
    <string>com.cokistudios.forkar.mac</string>
    <key>CFBundleName</key>
    <string>Forkar</string>
    <key>CFBundleDisplayName</key>
    <string>Forkar for PC</string>
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
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.cokistudios.forkar.mac</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>forkar</string>
                <string>csms</string>
            </array>
        </dict>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# 5. Firmar ad-hoc
echo "🔏 [4/4] Firmando app ad-hoc..."
codesign --force --deep --sign - "$APP_BUNDLE"

# 6. Empaquetar ZIP Universal para distribución
cd "$BUILD_DIR"
zip -r -y "$DIR/Forkar-macOS-Universal.zip" "$APP_NAME.app"
cd "$DIR"

echo "✅ ¡Forkar for PC compilada con éxito!"
echo "📦 Bundle: $APP_BUNDLE"
echo "🌐 ZIP Universal: $DIR/Forkar-macOS-Universal.zip"
lipo -info "$MACOS_DIR/$APP_NAME"
