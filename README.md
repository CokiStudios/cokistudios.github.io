# Coki Studios LLC — Engineering & Platform Monorepo
> **Universal Platform Ecosystem, Looping Engine v2.8.0 & smiledev Package Manager**  
> *Developed by Coki Studios LLC & Holo Entertainment © 2026*

Welcome to the official monorepo of **Coki Studios LLC**, containing the core programming language engines, package managers, native Apple and Android applications, web infrastructure, and identity services.

---

## 🏛️ Ecosystem Architecture

```
cokistudios.github.io/
├── LoopingEngine/            # Custom C++17 Native Game, UI & Scripting Engine (.loop)
│   ├── cpp/                  # Core Interpreter, Parser, AST, SwiftUI TUI & Python Bridge
│   └── Makefile              # Universal Binary Builder (arm64 + x86_64)
├── bin/                      # Precompiled CLI binaries (looping, smiledev, cs-webs, ui-connect)
├── modules/                  # Official & Community modules for Looping & smiledev
├── Formula/                  # Official Homebrew Formulae (looping.rb, smiledev.rb)
├── sample_loop_projects/     # Sample games, SwiftUI components and AST projects in .loop
│
├── Forkar.iOS/ & .macOS/     # Forkar Official Client (Universal Apple SwiftUI Target)
├── Forkar.Android/           # Forkar Android Client (Kotlin / Jetpack Compose)
├── CSMS.iOS/ & .macOS/       # Coki Studios Messaging Service with Hardware E2EE (SEP / T2)
├── CSMS.watchOS/             # CSMS Wearable Companion (Apple Watch)
├── CSMS.Android/             # CSMS Android Client with StrongBox Hardware Keymaster
│
├── CSMail.macOS/             # Native corporate mail client for @cokistudios.com accounts
├── CokiAccountManager.iOS/   # Central identity, device enrollment & license manager
├── hiOP.macOS/ & hiOP-VSCode/# Developer IDE tooling & VS Code Extension Suite
├── ShineFind/ & ShineMaps    # Shine hardware telemetry, micro-location & custom navigation
│
├── coki-auth.js              # CS ID Universal Identity & Passkey (WebAuthn) Engine
├── oauth-server.js           # Supabase Native OAuth 2.1 RFC 6749 Authorization Server
├── coki-theme.js             # Universal Theme Engine & Waflera 9-dot App Launcher
└── index.html, developer.html# Web platform, developer console & Looping Web REPL
```

---

## ⚡ Looping Engine v1.0.0 Commercial (Architecture 2.8A)

**Looping** (`.loop` / `.ruup`) es un lenguaje de programación comercial moderno, de alto rendimiento y tipado dinámico optimizado para desarrollo ágil, videojuegos 2D con física cuántica, síntesis de audio procedural, ciencia de datos e interfaces reactivas. Las versiones previas han sido consolidadas bajo la serie de arquitectura (`2.8A`, `2.7A`, `2.6A`, etc.).

* **Motor C++17 Nativo Ultra-Rápido**: Tiempo de arranque de **< 0.5 ms**, ejecución directa sin dependencias de Node.js ni contenedores web.
* **Universal Binary macOS**: Compilado nativamente para Apple Silicon (`arm64`) e Intel (`x86_64`).
* **Sintaxis Expresiva**: Declaraciones `let`, `mut`, `val`, operador morsa `:=`, funciones de flecha `fn() => ...`, destructuring `[a, b]`, condicional ternario `? :`, null-coalescing `??` y pattern matching `match`.
* **Pipelines Funcionales**: Operador `|>` combinado con `map`, `filter`, `reduce`, `group_by`, `sort_by`, `take`, `drop` y `partition`.
* **Criptografía Segura**: SHA-256, HMAC-SHA256, UUID v4, CRC-32, comparación en tiempo constante `constant_time_eq` y derivación de sala CSMS.
* **Manipulación de Datos**: Módulos stdlib nativos para `csv.*`, `json.*`, `datetime.*`, `regex.*` y alta resolución `time.nanos`.
* **Visualizador TUI de SwiftUI**: Previsualización en caja simulada de terminal para jerarquías de componentes declarativos Apple (`view`, `VStack`, `HStack`, `Text`, `Button`, `Toggle`, `@state`).
* **Transpilador Nativo a Swift**: Generación automática de código fuente Swift 5.9+ y compilación a binarios Mach-O vía `swiftc`.
* **Puente Python / PyLoop**: Interoperabilidad fluida con Python para inferencia de IA y librerías externas mediante `py!(...)` y `use python`.
* **Batería de Pruebas**: Suite de verificación exhaustiva con **57/57 tests nativos pasando al 100%**.

### Comandos Principales de Looping
```bash
# Ejecutar un script
looping mi_app.loop

# Previsualizar componentes SwiftUI en la terminal
looping preview mi_app.loop [NombreVista]

# Transpilar a Swift puro
looping compile mi_app.loop --target swiftui -o App.swift

# Inspeccionar árbol sintáctico abstracto (AST)
looping ast mi_app.loop

# Analizador estático y verificación sintáctica
looping check mi_app.loop

# Benchmark de throughput nativo C++17
looping bench

# Ejecutar suite de pruebas del motor
looping test
```

---

## 🌟 smiledev v1.0.0 Commercial (Universal Package Manager / Arch 2.8A)

**`smiledev`** es el gestor oficial de módulos y paquetes para el ecosistema Looping y Loop OS.

* **Soporte Políglota**: Módulos en Looping puro (`.loop`), Python/PyLoop (`.py`), C++ nativo (`.hpp`) y C2 declarativo (`.c2`).
* **Resolución Inteligente**: Descubrimiento dinámico de manifiestos `smile.json`, resolución jerárquica (directorio local `./modules` ➔ global `~/.smiledev/modules` ➔ stdlib interna).
* **Gestión de Dependencias**: Instalación automática en cascada de dependencias declaradas en `smile.json`.
* **Desarrollo Local**: `smiledev link` para enlazar simbólicamente módulos locales en la caché global sin necesidad de publicarlos.
* **Empaquetado y Distribución**: `smiledev pack` para crear paquetes `.tar.gz` con verificación SHA-256.
* **Registro en la Nube (LoopModules)**: Publicación y búsqueda en tiempo real respaldada por PostgreSQL / Supabase.
* **Diagnóstico Integrado**: `smiledev doctor` para validar el estado del entorno, compiladores y conectividad.

### Comandos de smiledev
```bash
# Instalar un módulo o resolver dependencias de smile.json
smiledev install loop-core-utils

# Desinstalar un módulo local o global
smiledev uninstall loop-gui-tk [--global]

# Listar módulos instalados
smiledev list

# Inicializar un nuevo módulo
smiledev init mi-plugin --lang loop

# Enlazar módulo para desarrollo entre proyectos
smiledev link ./modules/mi-plugin

# Empaquetar módulo para distribución
smiledev pack ./modules/mi-plugin

# Ejecutar tests de un módulo
smiledev test loop-core-utils

# Autenticación con Coki Studios ID (PAT)
smiledev login --token cs_pat_...
smiledev whoami

# Publicar módulo al registro global
smiledev upload-module ./modules/mi-plugin
```

Consulta la guía completa de smiledev en [`SMILEDEV_README.md`](./SMILEDEV_README.md).

---

## 🍺 Instalación Oficial con Homebrew

El tap oficial de Coki Studios permite instalar y mantener actualizados tanto `looping` como `smiledev` con un solo comando:

```bash
# 1. Agregar el tap
brew tap cokistudios/tap

# 2. Instalar el ecosistema
brew install looping smiledev

# 3. Actualizar a las versiones más recientes
brew update
brew upgrade smiledev looping
```

---

## 📱 Aplicaciones Nativas y Multiplataforma

### 🚗 Forkar (iOS, macOS & Android)
Plataforma automotriz comunitaria con soporte universal Apple y Android:
* **Árbol de Código Único**: Un solo target compila para iOS (`generic/platform=iOS`) y macOS (`platform=macOS,arch=arm64`).
* **Sincronización Automática con Xcode**: Todos los cambios en `Forkar.iOS/` se sincronizan con la ruta local de Xcode.
* **Eco Hub & Misiones**: Sistema de puntos ecológicos, encuestas comunitarias y asistente inteligente Forkman AI.

### 🔒 CSMS (Coki Studios Messaging Service)
Servicio de mensajería con cifrado de extremo a extremo respaldado por hardware:
* **Apple (iOS / macOS)**: Cifrado con respaldo por **Secure Enclave Processor (SEP)** o chip **Apple T2** vía `CryptoKit.SecureEnclave`.
* **Android**: Cifrado con respaldo por **AndroidKeyStore** en hardware seguro (TEE / StrongBox Keymaster).
* **Algoritmo**: AES-256-GCM (`AES/GCM/NoPadding` en Android, `CryptoKit.AES.GCM` en Apple) con payload `🔒 enc:v1:<iv>:<ciphertext>`.

---

## 🔑 Identidad y Seguridad Universal (CS ID)

* **Supabase Native OAuth 2.1**: Servidor de autorización compatible con RFC 6749 / OAuth 2.1 (`oauth-server.js`).
* **WebAuthn / Passkeys**: Autenticación biométrica nativa (Face ID, Touch ID, Windows Hello) con fallback de claves maestras.
* **Microsoft Entra ID (Azure AD)**: Identidad corporativa y control de acceso basado en roles (RBAC) para grupos `@cokistudios.com`.

---

## 🎨 Plataforma Web y Experiencia de Usuario

* **Waflera Universal**: Menú desplegable interactivo de 9 puntos estilo Google integrado en todas las barras de navegación (`coki-theme.js`).
* **Motor de Temas Claro / Oscuro**: Coherencia visual universal con alto contraste, garantizando texto legible en todos los temas.
* **Landing Page Minimalista (`index.html`)**: Enfoque directo en productos principales (Forkar, CSMS, Shine Maps, Shine Find, Felte) y llamado a la acción.
* **Portal de Desarrolladores (`developer.html`)**: Centro exclusivo para el Looping Engine, smiledev, Web REPL, benchmarks y generación de tokens PAT.

---

## 🚀 Inicio Rápido para Desarrolladores

1. **Requisitos Previos**:
   - macOS 12+ con Xcode 15+ y Swift 5.9+.
   - Clang++ con soporte C++17 (`clang++ --version`).
   - Homebrew (`brew update`).
   - Python 3.9+ (para interoperabilidad PyLoop y utilidades CLI).
2. **Compilar el Motor Looping**:
   ```bash
   make -C LoopingEngine/cpp
   ```
3. **Ejecutar Pruebas**:
   ```bash
   ./bin/looping test
   ./bin/smiledev doctor
   ```

---

## 🔒 Políticas de Seguridad e Integridad

* **Cero Secretos en el Repositorio**: Prohibido hacer commit de tokens reales, certificados privados o credenciales `.env`.
* **Prohibición de Emojis en el Compilador**: Los emojis están estrictamente prohibidos en el código fuente de `LoopingEngine/`, tokens del lexer y binarios compilados.
* **Divulgación Responsable**: Reportar cualquier incidente de seguridad a `contact@cokistudios.com`.

---

*© 2026 Coki Studios LLC. All rights reserved. Making the world Shine, together.*
