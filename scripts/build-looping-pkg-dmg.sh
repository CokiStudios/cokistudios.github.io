#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🌟 PROFESSIONAL macOS .PKG & .DMG INSTALLER GENERATOR
# For Looping & Ruuping Dual Hybrid Engine v2.5.0
# Developed by Holo Entertainment & Coki Studios
# ═══════════════════════════════════════════════════════════════

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist-dmg"
BUILD_TEMP="$DIST_DIR/build-temp"
STAGING_DIR="$DIST_DIR/dmg-staging"
PKG_OUTPUT="$DIST_DIR/Instalar Looping.pkg"
DMG_OUTPUT="$DIST_DIR/Looping-Engine-v2.5.0-macOS.dmg"
VERSION="2.5.0"
IDENTIFIER="com.cokistudios.looping"

echo "=========================================================="
echo "🌟 Building Apple .PKG and .DMG Installers for Looping v$VERSION"
echo "   Target Platform: macOS Universal (arm64 & x86_64)"
echo "   Install Target:  /usr/local/bin/looping (System PATH)"
echo "=========================================================="

# 1. Ensure bin/looping is compiled
if [ ! -f "$ROOT_DIR/bin/looping" ]; then
    echo "⚙️ Compiling native Looping C++ engine..."
    make -C "$ROOT_DIR/LoopingEngine/cpp"
fi

# Clean previous build artifacts
rm -rf "$BUILD_TEMP" "$STAGING_DIR"
mkdir -p "$DIST_DIR" "$BUILD_TEMP/root/usr/local/bin" "$BUILD_TEMP/root/etc/paths.d" "$BUILD_TEMP/scripts" "$STAGING_DIR"

# 2. Prepare payload root for PKG
echo "📦 1/4 Staging payload files for Apple .PKG..."
cp "$ROOT_DIR/bin/looping" "$BUILD_TEMP/root/usr/local/bin/looping"
chmod 755 "$BUILD_TEMP/root/usr/local/bin/looping"

# Symlink ruuping -> looping
ln -sf "looping" "$BUILD_TEMP/root/usr/local/bin/ruuping"

# Package Manager: smiledev
cp "$ROOT_DIR/bin/smiledev" "$BUILD_TEMP/root/usr/local/bin/smiledev"
chmod 755 "$BUILD_TEMP/root/usr/local/bin/smiledev"

# Ensure /usr/local/bin is permanently in macOS PATH via /etc/paths.d
echo "/usr/local/bin" > "$BUILD_TEMP/root/etc/paths.d/looping"
chmod 644 "$BUILD_TEMP/root/etc/paths.d/looping"

# 3. Create postinstall script
cat << 'EOF' > "$BUILD_TEMP/scripts/postinstall"
#!/bin/sh
# Looping Engine & smiledev Post-Install Script
chmod 755 /usr/local/bin/looping 2>/dev/null || true
ln -sf /usr/local/bin/looping /usr/local/bin/ruuping 2>/dev/null || true
chmod 755 /usr/local/bin/ruuping 2>/dev/null || true
chmod 755 /usr/local/bin/smiledev 2>/dev/null || true
chmod 644 /etc/paths.d/looping 2>/dev/null || true
exit 0
EOF
chmod 755 "$BUILD_TEMP/scripts/postinstall"

# 4. Build Component Package using pkgbuild
echo "🔨 2/4 Building component .pkg via pkgbuild..."
pkgbuild --root "$BUILD_TEMP/root" \
         --identifier "$IDENTIFIER" \
         --version "$VERSION" \
         --install-location "/" \
         --scripts "$BUILD_TEMP/scripts" \
         "$BUILD_TEMP/looping-component.pkg"

# 5. Build Distribution Package with productbuild
echo "📜 3/4 Generating final Apple Distribution .PKG via productbuild..."
productbuild --package "$BUILD_TEMP/looping-component.pkg" \
             "$PKG_OUTPUT"

echo "✅ Created Apple Installer: $PKG_OUTPUT"

# 6. Prepare DMG Staging Folder
echo "💿 4/4 Assembling and compressing Disk Image (.DMG)..."
cp "$PKG_OUTPUT" "$STAGING_DIR/Instalar Looping.pkg"

# Create double-clickable Terminal Installer script
cat << 'EOF' > "$STAGING_DIR/Instalar_por_Terminal.command"
#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=========================================================="
echo "🌟 Instalador de Looping Engine & smiledev v2.5.0 (Coki Studios)"
echo "=========================================================="
echo "Instalando en /usr/local/bin/looping y /usr/local/bin/smiledev..."
sudo installer -pkg "$DIR/Instalar Looping.pkg" -target /
echo ""
echo "✅ ¡Looping y smiledev se han instalado exitosamente en el PATH del sistema!"
echo "   Looping:  /usr/local/bin/looping"
echo "   smiledev: /usr/local/bin/smiledev"
echo "   Versión:  $(/usr/local/bin/looping --version 2>/dev/null || echo '2.5.0')"
echo ""
echo "Comandos disponibles:"
echo "   looping tu_archivo.loop"
echo "   smiledev install <modulo>"
echo "   smiledev list"
echo ""
read -p "Presiona ENTER para cerrar..."
EOF
chmod 755 "$STAGING_DIR/Instalar_por_Terminal.command"

# Create double-clickable Terminal Uninstaller script
cat << 'EOF' > "$STAGING_DIR/Desinstalar_Looping.command"
#!/bin/bash
echo "=========================================================="
echo "🗑️ Desinstalador de Looping Engine (Coki Studios)"
echo "=========================================================="
read -p "¿Deseas desinstalar Looping de /usr/local/bin? (s/N): " confirm
if [[ "$confirm" =~ ^[sSyY]$ ]]; then
    sudo rm -f /usr/local/bin/looping /usr/local/bin/ruuping /etc/paths.d/looping
    echo "✅ Looping desinstalado correctamente."
else
    echo "Operación cancelada."
fi
read -p "Presiona ENTER para cerrar..."
EOF
chmod 755 "$STAGING_DIR/Desinstalar_Looping.command"

# Copy sample compiled projects
mkdir -p "$STAGING_DIR/Proyectos Compilados"
if [ -d "$ROOT_DIR/sample_loop_projects/compiled" ]; then
    cp -R "$ROOT_DIR/sample_loop_projects/compiled/"* "$STAGING_DIR/Proyectos Compilados/"
fi

# Add Readme
cat << 'EOF' > "$STAGING_DIR/LEEME.txt"
═══════════════════════════════════════════════════════════════
🌟 LOOPING PROGRAMMING LANGUAGE & RUNTIME v2.5.0
Holo Entertainment • Coki Studios
═══════════════════════════════════════════════════════════════

¿Cómo instalar Looping en el PATH del sistema?
1. Haz doble clic en "Instalar Looping.pkg" y sigue el asistente oficial de macOS.
2. O haz doble clic en "Instalar_por_Terminal.command".

Una vez instalado:
- El comando "looping" y "ruuping" estarán disponibles globalmente en cualquier terminal.
- Los scripts con shebang (como ./ShineLauncher_flUI) se ejecutarán directamente con doble clic o desde terminal.

Verificar instalación en Terminal:
$ looping --version
$ looping test
EOF

# Include icon if available
if [ -f "$ROOT_DIR/assets/loop-file-icon.png" ]; then
    cp "$ROOT_DIR/assets/loop-file-icon.png" "$STAGING_DIR/.VolumeIcon.png" 2>/dev/null || true
fi

# 7. Generate Compressed Read-Only DMG
rm -f "$DMG_OUTPUT"
hdiutil create -srcfolder "$STAGING_DIR" \
               -volname "Looping Engine v2.5.0" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDZO \
               -imagekey zlib-level=9 \
               -ov "$DMG_OUTPUT"

# Clean temporary folders
rm -rf "$BUILD_TEMP" "$STAGING_DIR"

echo "=========================================================="
echo "🎉 ¡PAQUETES CREADOS EXITOSAMENTE!"
echo "   1. Apple PKG Installer: $PKG_OUTPUT"
echo "   2. Apple DMG Image:     $DMG_OUTPUT"
echo "=========================================================="
