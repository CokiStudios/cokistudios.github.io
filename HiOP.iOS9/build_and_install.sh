#!/bin/zsh
set -e
export THEOS=/Users/jerix/theos
cd "$(dirname "$0")"

echo "Compilando HiOP para iPad 3 (armv7, iOS 9.3.6)..."
make

APP_DIR=".theos/obj/debug/armv7/HiOP.app"

# 1. Inyectar Info.plist obligatorio dentro del bundle .app
cp Info.plist "$APP_DIR/Info.plist"

# 2. Limpiar dSYM para que el IPA sea ligero y limpio
rm -rf "$APP_DIR/HiOP.dSYM"

# 3. Firmar el bundle con entitlements
codesign -s - --force --deep --entitlements Entitlements.plist "$APP_DIR" 2>/dev/null || true

# 4. Empaquetar el IPA con la estructura estándar Payload/HiOP.app
rm -rf Payload
mkdir -p Payload
cp -r "$APP_DIR" Payload/
rm -f HiOP-iOS9.ipa ../HiOP-iOS9.ipa
zip -q -r HiOP-iOS9.ipa Payload
rm -rf Payload
cp HiOP-iOS9.ipa ../HiOP-iOS9.ipa

echo "✓ HiOP-iOS9.ipa empaquetado con Info.plist exitosamente."
