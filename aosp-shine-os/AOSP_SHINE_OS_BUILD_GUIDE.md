# ═══════════════════════════════════════════════════════════════
# GUÍA MAESTRA: CÓMO CONSTRUIR UN AOSP REAL (SHINE OS ROM)
# Para Teléfonos Shine (A, Nomad, X, i-Fold) & Coki Studios
# ═══════════════════════════════════════════════════════════════

## 1. 🏗️ ¿Cómo se estructura un AOSP Real con las Apps de Coki Studios?

En el código fuente de Android Open Source Project (AOSP), las aplicaciones del sistema viven en `packages/apps/`. Creamos un árbol de fuentes nativo con `Android.bp` (el sistema de compilación oficial de Google/AOSP Soong):

```
aosp-shine-os/
├── packages/apps/
│   ├── ShineLauncher/          <-- Launcher oficial (Shine UI / XUI / FlUI)
│   │   ├── Android.bp
│   │   └── src/
│   ├── ShineSettings/          <-- App Config (Página 16 de tu guía)
│   │   ├── Android.bp
│   │   └── src/
│   ├── BubblyDotService/       <-- Dynamic Island en SystemUI
│   │   ├── Android.bp
│   │   └── src/
│   ├── ForkarApp/              <-- Red Social & Eco-Hub
│   ├── CSMSApp/                <-- Mensajería Coki Studios
│   ├── LookItAntivirus/        <-- Antivirus y Seguridad
│   └── UIConnectService/       <-- Puente con Shinebook PC
└── device/cokistudios/
    ├── shine_phone_a/          <-- Gama A (Android Go / hi!UI)
    ├── shine_phone_nomad/      <-- Gama Nomad (Stock AOSP)
    ├── shine_phone_1a/         <-- Gama X (XUI 240Hz)
    └── shine_phone_fold/       <-- Gama i (FlUI Dual-Screen)
```

---

## 2. 📄 Ejemplo de Archivo de Compilación AOSP (`Android.bp`)

Cada app independiente se declara con un archivo `Android.bp` para que el compilador de AOSP la integre como **System App Privilegiada**:

```bp
// packages/apps/ShineLauncher/Android.bp
android_app {
    name: "ShineLauncher",
    srcs: ["src/**/*.kt"],
    resource_dirs: ["res"],
    manifest: "AndroidManifest.xml",
    platform_apis: true,
    certificate: "platform",
    privileged: true,
    static_libs: [
        "androidx.compose.runtime_runtime",
        "androidx.compose.material3_material3",
        "androidx.core_core-ktx",
    ],
    overrides: ["Launcher3", "Launcher3QuickStep"],
}
```

---

## 3. 🚀 Pasos para Compilar AOSP en tu Máquina:

### Paso 1: Descargar las Herramientas Oficiales de Google
```bash
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH
```

### Paso 2: Inicializar el Árbol AOSP (Android 14 / 15)
```bash
mkdir shine-os-aosp && cd shine-os-aosp
repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r50 --depth=1
repo sync -c -j8
```

### Paso 3: Inyectar las Apps de Coki Studios
Copiamos las carpetas de `ShineLauncher`, `ShineSettings` y `ShineUISystem` dentro de:
👉 `packages/apps/ShineLauncher/`

### Paso 4: Compilar la ROM del Sistema Operativo
```bash
source build/envsetup.sh
lunch aosp_x86_64-userdebug    # O tu target de procesador
m -j$(nproc)
```

### Paso 5: Probar en el Emulador de Android
```bash
emulator
```

¡El emulador arrancará mostrando **Shine OS**, el **Bubbly Dot** y el **Shine Launcher** con el acabado **Frosted Glass Acrílico Aqua A17** directamente en el sistema! 📱✨
