# Instrucciones y Reglas del Proyecto (Coki Studios)

## Forkar iOS & macOS
* **Sincronización con Xcode**: Siempre que se generen o modifiquen archivos, funciones o novedades en `Forkar.iOS/`, se deben copiar/sincronizar los cambios a la ruta local del proyecto Xcode:
  `/Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/`

## Seguridad Criptográfica y E2EE en CSMS (Coki Studios Messaging Service)
* **Hardware-Backed Encryption**:
  * **iPhone (iOS)**: Usar el **Secure Enclave Processor (SEP)** vía `CryptoKit.SecureEnclave` o Keychain con `kSecAttrTokenIDSecureEnclave` para proteger las claves criptográficas.
  * **Mac (macOS)**: Usar el chip **Apple T2** (en Macs Intel con T2) o el **Secure Enclave** (en Apple Silicon M1-M4) vía `CryptoKit.SecureEnclave`.
  * **Android**: Usar **AndroidKeyStore** con respaldo por hardware (TEE / StrongBox Keymaster).
  * **Algoritmo**: AES-256-GCM (`AES/GCM/NoPadding` en Android, `CryptoKit.AES.GCM` en Apple).
  * **Formato del payload**: `🔒 enc:v1:<base64-iv>:<base64-ciphertext>`.
  * **Derivación de clave simétrica de sala**: SHA-256 de `\(roomId):CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR`.

## Prohibición Estricta de Datos Hardcodeados (Zero Hardcoding)
* **Backend First**: Toda información debe conectarse con `SupabaseManager` (`fetchPosts`, `fetchChatRooms`, etc.). No inventar arrays estáticos (`mockPosts = [...]`, `fakeMessages = [...]`).
* **Cero Identidades Falsas**: No usar nombres inventados (`"John Doe"`, `"Admin"`, `"Chat Instantáneo"`), UUIDs fijos o imágenes placeholder. Resolver dinámicamente desde Supabase o mostrar `CircleAvatarPlaceholder(initials: ...)`.
* **Cero Dimensiones Fijas**: Prohibido usar `UIScreen.main.bounds` o anchos rígidos. Usar `@Environment(\.horizontalSizeClass)`, `GeometryReader` y `maxWidth: .infinity` para compatibilidad universal (iPhone, iPhone Duo, iPad, Mac).

## Arquitectura Universal Multiplataforma (iOS + macOS + iPhone Duo)
* **Árbol de Código Único**: Un solo target `Forkar` compila para iOS (`generic/platform=iOS`) y macOS (`platform=macOS,arch=arm64`). No bifurcar carpetas.
* **Aislamiento Condicional**: Aislar APIs específicas con `#if os(macOS)` / `#if os(iOS)` (`CoreNFC`, `ActivityKit`, `@NSApplicationDelegateAdaptor`).
* **Extensiones Embebidas**: Toda extensión de iOS como `ForkarEcoWidgetExtension.appex` debe tener `platformFilter = ios;` en `project.pbxproj` para permitir la firma y compilación limpia en macOS.


