#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🌟 RUN HOLO LOOP OS LAUNCHER (Shine Loop Console Native App)
# Coki Studios & Holo Entertainment
# ═══════════════════════════════════════════════════════════════

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/ShineLoopLauncher.macOS"
BUILD_DIR="$APP_DIR/build"
APP_BUNDLE="$BUILD_DIR/Build/Products/Release/ShineLoopLauncher.app"

echo "=========================================================="
echo "🌟 Building & Launching Holo Loop OS Launcher (Shine Loop)"
echo "   Platform: macOS Universal (Handheld Console Target)"
echo "   Audio: Hardware Tone DSP Synthesizer"
echo "   Engine: Native Looping C++ Subsystem"
echo "=========================================================="

# 1. Compile native Looping C++ binary if missing
if [ ! -f "$ROOT_DIR/bin/looping" ]; then
    echo "⚙️ Compiling native Looping C++ engine..."
    make -C "$ROOT_DIR/LoopingEngine/cpp"
fi

# 2. Build Release native app bundle
echo "🔨 Compiling ShineLoopLauncher.app via xcodebuild..."
xcodebuild -project "$APP_DIR/ShineLoopLauncher.xcodeproj" \
           -scheme ShineLoopLauncher \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           build CODE_SIGNING_ALLOWED=NO > /dev/null

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at $APP_BUNDLE"
    exit 1
fi

echo "✅ Build Succeeded: $APP_BUNDLE"

# 3. Launch application
if [ "$1" == "--no-open" ]; then
    echo "ℹ️ Flag --no-open supplied. Skipping app launch."
else
    echo "🚀 Launching Holo Loop OS Launcher on Shine Loop..."
    open "$APP_BUNDLE"
fi
