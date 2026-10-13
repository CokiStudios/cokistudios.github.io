# COKI STUDIOS & FORKAR — MEMORIA INTEGRAL DE CONTEXTO Y ARQUITECTURA
**Documento de traspaso y persistencia para nuevas sesiones de asistencia / LLM.**
*Generado: 13 de Octubre de 2026*

---

## 1. REGLAS CRÍTICAS Y DIRECTIVAS MANDATORIAS
Estas reglas deben respetarse **sin excepción** en cualquier código, respuesta o propuesta:

1. **Sincronización con Xcode**:
   - Cada vez que se cree o modifique un archivo en `Forkar.iOS/`, debe sincronizarse inmediatamente con la ruta local de Xcode:
     `/Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/`
     *(Comando zsh: `rsync -av --delete Forkar.iOS/ /Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/`)*.
2. **Criptografía Hardware-Backed E2EE en CSMS y CS ID**:
   - **Apple (iOS/macOS)**: Secure Enclave Processor (SEP) o Apple T2 vía `CryptoKit.SecureEnclave`.
   - **Android**: `AndroidKeyStore` con hardware backing (TEE / StrongBox Keymaster).
   - **Algoritmo**: AES-256-GCM (`AES/GCM/NoPadding` en Android, `CryptoKit.AES.GCM` en Apple).
   - **Formato Estándar de Cifrado**: `🔒 enc:v1:<base64-iv>:<base64-ciphertext>` (donde ciphertext incluye el tag GCM de 16 bytes).
   - **Derivación de Clave de Sala CSMS**: SHA-256 de `\(roomId):CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR`.
3. **Prohibición Estricta de Pasarelas de Pago**:
   - **CERO cobros**, cero Stripe, cero pasarelas. El ecosistema es 100% abierto, federado y soberano.
4. **Zero Hardcoding & Backend First**:
   - Ningún dato mockeado estático (`mockPosts`, nombres inventados como `"John Doe"` o `"Admin"`).
   - Todo se conecta a Supabase (`SupabaseManager`), Cloudflare Workers o se calcula dinámicamente.
5. **Cero Dimensiones Fijas en UI**:
   - Prohibido `UIScreen.main.bounds` o anchos rígidos.
   - Usar `@Environment(\.horizontalSizeClass)`, `GeometryReader` y `maxWidth: .infinity` para soporte universal (iPhone, iPhone Duo de doble pantalla, iPad, Mac).
6. **Minimizar Node.js al Mínimo**:
   - Priorizar siempre terminal nativa `zsh`, Swift, Kotlin y C++ antes de crear scripts Node.js.
7. **Ciclo de Despliegue Permanente**:
   - `npm run build` -> `rsync` a Xcode -> `npx wrangler deploy` -> `git push origin main`.

---

## 2. ANÁLISIS DE LA INFORMACIÓN DE APPLE INTELLIGENCE & SIRI AI (OCTUBRE 2026)
A partir de la documentación oficial de Apple Developer para Apple Intelligence y Siri AI:

### A. Núcleos Tecnológicos
1. **Apple Foundation Models & Private Cloud Compute (PCC)**:
   - Acceso nativo Swift con `Foundation Models framework`.
   - Ejecución local on-device y en **Private Cloud Compute** (cómputo seguro en la nube donde los datos no se guardan ni comparten).
   - Soporte para multimodalidad (visión + texto) y **Dynamic Profiles** (cambiar modelos, herramientas e instrucciones en vivo durante una sesión).
   - Protocolo universal `Language Model` para conectar cualquier modelo.
2. **App Intents Framework con Siri AI**:
   - **Entity Schemas**: Integra contenido en el índice semántico de Spotlight para comprensión del contexto personal.
   - **Intent Schemas**: Permite acciones del usuario sin necesidad de frases clave rígidas o código adicional cuando la comprensión de Siri evoluciona.
   - **View Annotations API**: Otorga **on-screen awareness** a Siri, mapeando elementos de la vista de SwiftUI/UIKit con entidades para que el usuario pueda decir *"envía esto a mi chat"* o *"navega hacia allá"*.
3. **Visual Intelligence**:
   - Reconocimiento y búsqueda sobre contenido de cámara en iPhone, pantalla en Mac/iPad y visión espacial en Apple Vision Pro.
4. **Image Playground & Genmoji**:
   - Generación de imágenes y avatares/stickers personalizados integrados en los campos de texto del sistema y APIs de UIKit/SwiftUI.
5. **Write with Siri**:
   - Reescritura, resumen y corrección asistida por IA integrada nativamente en los controles del sistema.

### B. Aplicación Estratégica en Coki Studios & Forkar
- **Forkar iOS/macOS**:
  - Adoptar `AppIntents` con Entity Schemas para posts de autos, rutas de telemetría y salas de chat cifradas de CSMS.
  - Implementar View Annotations para que Siri AI entienda la pantalla de navegación en **ShineMaps** y la telemetría en **ForkarEcoView**.
  - Integrar `Foundation Models framework` para el copiloto vehicular local sin servidores externos.

---

## 3. ESTADO ACTUAL DEL ECOSISTEMA COKI STUDIOS

### 1. CS ID Connect & Cripto-Identidad
- **SDK Web (`csid-connect.js`)**:
  - OAuth 2.0 PKCE con `S256`.
  - Soporte para **Passkeys FIDO2 / WebAuthn** biométricas (`registerPasskey`, `signInWithPasskey`) para autenticación One-Tap con Touch ID / Face ID.
  - JWE decrypt con Web Crypto API.
- **CSIDKit Swift (`CSIDKit-Swift/`)**:
  - Swift Package compatible con iOS 15+, macOS 12+, watchOS 8+, tvOS 15+.
  - Clase `CSIDHardwareVault`: cifrado y descifrado AES-256-GCM con soporte para Secure Enclave.
  - Tests unitarios al 100% pasando con `swift test`.
- **CSIDKit Kotlin (`ShineLauncher.Android/`)**:
  - AndroidKeyStore TEE/StrongBox.
  - Métodos `encryptCSMSPayload` y `decryptCSMSPayload` 100% compatibles a nivel binario con Apple SEP.

### 2. Portal de Desarrolladores (`developer.html` / `developer.cokistudios.com`)
- Interfaz Glassmorphism industrial con notificaciones Toast.
- **Tab 01**: Directorio de paquetes de SmileDev / LoopModules.
- **Tab 02**: Autenticación CLI SmileDev (`cs_pat_`).
- **Tab 03**: Telemetría Coki Edge CDN Cloudflare.
- **Tab 04**: Registro de Aplicaciones OAuth 2.0 (gestión con Supabase).
- **Tab 05**: Guías y código para JS, Swift y Kotlin.
- **Tab 06**: Suite de SDKs CSIDKit.
- **Tab 07**: **Looping Engine Web REPL interactivo** (soporte para ShineUI DSL y física).
- **Tab 08**: **Simulador Criptográfico**: generación PKCE en vivo, registro/verificación de Passkeys biométricas y derivación de sala CSMS.

### 3. Looping Engine
- Lenguaje Loop Script con soporte de DSL declarativo:
  ```loop
  target "shine_ui"
  import "physics.loop"
  ui Screen { ... }
  ```
- Motores nativos en C++ y módulos de interop con Python (`loop-gui-qt`, `loop-gui-tk`, `loop-math-3d`).

### 4. ShineMaps & Navegación (Forkar)
- Localización y navegación con MapKit y Mapbox en [`LocationAndMapService.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ShineMaps/LocationAndMapService.swift).
- Soporte para **Co-Navegación Comunitaria / Caravanas P2P**: modelo `CommunityCaravanMember` y telemetría compartida.

---

## 4. RUTAS Y ARCHIVOS CLAVE
- **Sitio Web / Worker Cloudflare**: `/Users/jerix/cokistudios.github.io/`
  - `developer.html`: Portal de desarrolladores.
  - `csid-connect.js`: SDK cliente de identidad y passkeys.
  - `src/index.js`: Cloudflare Worker API.
  - `public/`: Directorio de distribución estática para Wrangler.
- **Swift Package**: `/Users/jerix/cokistudios.github.io/CSIDKit-Swift/`
- **Proyecto Forkar Apple**: `/Users/jerix/cokistudios.github.io/Forkar.iOS/`
  - Ruta de sincronización Xcode: `/Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/`
- **Proyecto Android**: `/Users/jerix/cokistudios.github.io/ShineLauncher.Android/`
- **Motor Looping**: `/Users/jerix/cokistudios.github.io/LoopingEngine/`

---
*Fin del archivo de memoria. Al abrir una nueva conversación, consultar este documento para continuar inmediatamente.*
