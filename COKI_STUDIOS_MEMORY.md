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
- **Coki with Apple Intelligence (iOS 27, iPadOS 27, macOS 27 & watchOS 27)**:
  - **Framework `FoundationModels` On-Device**: Habilitado nativamente on-device en iOS 27, iPadOS 27 y macOS 27 mediante `SystemLanguageModel` y `LanguageModelSession` en [`AppleContentModerator.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/AppleContentModerator.swift) con guardrails de hardware y privacidad total.
  - **Insignia Dinámica**: [`CreatePostView.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/CreatePostView.swift) exhibe `"Coki with Apple Intelligence (iOS 27 / iPadOS 27 / macOS 27)"` y certifica publicaciones en el Neural Engine.
  - **Resúmenes Privados On-Device de Chat CSMS**: [`ChatRoomDetailView.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ChatRoomDetailView.swift) incluye botón y modal "Resumen Coki" para resumir conversaciones cifradas sin enviarlas fuera del dispositivo.
  - **Diagnóstico Automotriz y Mantenimiento**: [`ForkarEcoView.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ForkarEcoView.swift) incorpora diagnóstico en vivo de síntomas mecánicos y testigos con Coki with Apple Intelligence.
  - **App Intents y Siri AI (`ForkarAppIntents.swift`)**: Integración de `AppShortcutsProvider` para buscar puntos de recarga (`FindEcoChargingPointsIntent`), unirse a caravanas P2P (`JoinCaravanIntent`), validar check-ins verdes (`EcoCheckInIntent`) y resumir chats por voz con Siri AI.
  - **Copiloto en Apple Watch (`watchOS 27`)**: [`ForkarWatchContentView.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/Watch/ForkarWatchContentView.swift) y [`ForkarWatchComplications.swift`](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/Watch/ForkarWatchComplications.swift) integran Coki Copilot con sugerencias eco-eficientes y respuestas rápidas asistidas por IA.

- **Coki with Gemini Intelligence (Android 17 & Gemini Nano AICore)**:
  - **Arquitectura On-Device AICore**: Integración en [`CokiGeminiAssistant.kt`](file:///Users/jerix/cokistudios.github.io/Forkar.Android/app/src/main/java/com/cokistudios/forkar/data/CokiGeminiAssistant.kt) ejecutando Gemini Nano v3 directamente sobre la NPU de Android 17 con cero salida de datos (Zero Data Egress).
  - **Insignia y Moderación On-Device**: [`CreatePostScreen.kt`](file:///Users/jerix/cokistudios.github.io/Forkar.Android/app/src/main/java/com/cokistudios/forkar/ui/screens/CreatePostScreen.kt) muestra el badge `"Coki with Gemini Intelligence (Android 17 AICore)"` y realiza moderación contextual y anti-evasión previa a publicación en Supabase.
  - **Resúmenes Privados de Salas CSMS E2EE**: [`CSMSScreen.kt`](file:///Users/jerix/cokistudios.github.io/Forkar.Android/app/src/main/java/com/cokistudios/forkar/ui/screens/CSMSScreen.kt) cuenta con botón y diálogo en vivo ("✨ Resumen Coki") para procesar el hilo de chat descifrado localmente en RAM sin telemetría externa.
  - **Diagnóstico Automotriz en Eco Hub**: [`EcoHubScreen.kt`](file:///Users/jerix/cokistudios.github.io/Forkar.Android/app/src/main/java/com/cokistudios/forkar/ui/screens/EcoHubScreen.kt) incorpora tarjeta y modal interactivo de diagnóstico vehicular (Check Engine, frenos, batería, neumáticos TPMS) asistido por Gemini Nano.

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

### 5. Integración Universal Forkar iOS & watchOS (`ForkarWatchSyncManager` & `Forkar for Watch Watch App`)
- **Vinculación Obligatoria al iPhone para Datos Reales de los 3 (Cero Hardcoding)**:
  - Eliminados todos los valores estáticos (`co2Saved = 0.0`, `ecoPoints = 0`, identidades vacías).
  - El Apple Watch requiere enlace activo con el iPhone (`isPhoneLinked`, `hasReceivedInitialSync`). Si no está vinculado, muestra la barrera: *"Vincular con iPhone • Abre Forkar en tu iPhone para sincronizar los datos reales de los 3 (CO₂, Puntos y Nivel)"*.
  - Handshake interactivo: `requestSyncFromiPhone()` despacha `action: "request_sync"`, disparando `pushFullEcosystemSync()` en el iPhone para transferir los datos autenticados en Supabase (`forkman_user_eco`) y el perfil del usuario.
- **Sincronización Bidireccional (`WCSessionDelegate`)**:
  - `syncEcoImpact(co2:points:level:)`: Transmite balances y métricas en vivo de Supabase Eco Hub entre iPhone y Apple Watch (`updateApplicationContext` y `sendMessage`).
  - `syncUserProfile(name:email:userId:)`: Proporciona credenciales autenticadas al reloj para identificación en la red CSMS.
  - `syncCopilotInsight(_:)`: Pasa recomendaciones contextuales de Coki Copilot directamente a la muñeca.
  - **Acciones Inmediatas en la Muñeca**:
    - `"eco_check_in"`: Registra acciones sostenibles desde el Apple Watch persistiendo en Supabase (`SupabaseManager.shared.logUserEcoImpact`), refresca widgets en iOS y emite eventos en Dynamic Island.
    - `"send_chat_message"`: Envía mensajes rápidos desde el reloj a salas CSMS protegidas (`CSMSCanonicalRooms.communityGlobal`) mediante `SupabaseManager.shared.sendMessage`.
- **Arquitectura watchOS Multitab (`ContentView.swift` & `CSMSWatchApp.swift`)**:
  - `WatchEcoDashboardView`: Tacómetro circular de CO₂ ahorrado con `Gauge`, balance de Puntos Eco, tarjeta Coki Copilot y botón de registro rápido con certificación *"iPhone Vinculado • Datos Reales"*.
  - `WatchRoomsListView`: Visualizador de salas protegidas CSMS y respuestas rápidas (bloqueado con aviso si no está vinculado).
  - `WatchHardwareStatusView`: Diagnóstico en vivo de Secure Enclave (SEP), cifrado AES-256-GCM y estado del enlace WCSession.
### 6. Pantallas de Vinculación y Sincronización Oficial (`ForkarWatchPairingView.swift` & `WCSession` Robusto)
- **Resolución de Errores WCSession**:
  - `isActivating` evita activaciones concurrentes (`already in progress or activated`).
  - `pendingEcoSync` retiene actualizaciones hasta que `activationState == .activated`, eliminando `WCErrorCodeSessionNotActivated` y `Application context data is nil`.
  - Verificación de `isReachable` y mitigación de caída de handlers (`cannot add handler to 0 from 0 - dropping`).
- **Pantalla Oficial de Vinculación (`ForkarWatchPairingView.swift`)**:
  - Cabecera animada con ondas de enlace iPhone <-> Apple Watch.
  - Tarjeta de diagnóstico de sesión (`WCSession`, `isPaired`, `isWatchAppInstalled`, `isReachable`).
  - Tarjeta de los 3 datos reales autenticados de Supabase (`CO₂`, `Puntos Eco`, `Nivel`).
  - Puntos de entrada en la app: accesible desde el botón de estado en `ForkarEcoView.swift` y desde la tarjeta de perfil en `ProfileView.swift`.

### 7. CSMS Menciones Universales, Copiloto /Coki y Playground /Genimg
- **Menciones Universales (@alguien)**:
  - Detección reactiva de `@` con chips de autocompletado basados en los miembros reales del chat (cero identidades inventadas) y `@Coki`.
  - Distintivo visual `"📢 Te mencionó"` en burbujas dirigidas al usuario autenticado.
- **Consultas Rápidas `/Coki` (Apple Intelligence & Gemini Nano)**:
  - En Apple (iOS, iPadOS, macOS, watchOS): Procesa `/Coki [consulta]` usando `FoundationModels` on-device (`SystemLanguageModel` / `LanguageModelSession` de iOS 27 y macOS 27) y responde como *"Coki with Apple Intelligence"*.
  - En Android 17: Procesa consultas con Google AICore / Gemini Nano y responde como *"Coki with Gemini Intelligence"*.
  - En watchOS: Responde con métricas reales de sostenibilidad y telemetría de conducción.
- **Generación Visual `/Genimg` (Apple Playground API)**:
  - En iOS, iPadOS y macOS: Invoca la hoja nativa `.imagePlaygroundSheet` de `ImagePlayground.framework`, renderiza conceptos con Apple Intelligence on-device, convierte a Base64 y envía la imagen generada directamente a la sala.
  - `CSMSMediaImageView` compatible universalmente con Base64 data URIs, archivos locales y URLs remotas de CDN.
  - En Android: Despliega guía explicativa indicando la exclusividad de ImagePlayground en Apple OSes y permitiendo adjuntos directos con `📎`.

---

## 4. RUTAS Y ARCHIVOS CLAVE
- **Sitio Web / Worker Cloudflare**: `/Users/jerix/cokistudios.github.io/`
  - `developer.html`: Portal de desarrolladores.
  - `csid-connect.js`: SDK cliente de identidad y passkeys.
  - `src/index.js`: Cloudflare Worker API.
  - `public/`: Directorio de distribución estática para Wrangler.
- **Swift Package**: `/Users/jerix/cokistudios.github.io/CSIDKit-Swift/`
- **Proyecto Forkar Apple**: `/Users/jerix/cokistudios.github.io/Forkar.iOS/`
  - `ForkarWatchSyncManager.swift`: Gestor blindado de enlace y sincronización WCSession.
  - `ForkarWatchPairingView.swift`: Deck interactivo de vinculación, diagnóstico y datos reales de los 3.
  - `ForkarEcoView.swift` & `ProfileView.swift`: Integración de accesos al emparejamiento.
  - Ruta de sincronización Xcode: `/Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/`
- **Proyecto Forkar Apple Watch**:
  - Repo: `/Users/jerix/cokistudios.github.io/Forkar for Watch Watch App/`
  - Xcode: `/Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar for Watch Watch App/`
- **Proyecto CSMS watchOS**: `/Users/jerix/cokistudios.github.io/CSMS.watchOS/` (`CSMS_Watch.xcodeproj`)
- **Proyecto Android**: `/Users/jerix/cokistudios.github.io/ShineLauncher.Android/` & `Forkar.Android/`
- **Motor Looping**: `/Users/jerix/cokistudios.github.io/LoopingEngine/`

---
*Fin del archivo de memoria. Al abrir una nueva conversación, consultar este documento para continuar inmediatamente.*
