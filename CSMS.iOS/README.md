# CSMS iOS — Standalone Native Swift & SwiftUI Client

**CSMS (Coki Messaging Service)** es una aplicación 100% nativa en **Swift** y **SwiftUI** desarrollada para iOS.

---

## Características Principales

1. **Sincronización Supabase REST**: Conectado directamente a las tablas `chat_rooms` y `chat_messages` de Supabase sobre `URLSession`.
2. **Diseño Liquid Glass UI**: Modo oscuro nativo de alto contraste (`#06090F` / `#0F172A`), pastillas de mensaje púrpura y actualización automática.
3. **Desarrollo Nativo Xcode**: Compila directamente en Xcode con cero dependencias externas de terceros.

---

## Cómo Ejecutar en Xcode

1. Abre **Xcode** en tu Mac.
2. Crea un proyecto nuevo de **iOS App** con Nombre: `CSMS` e Identificador: `com.cokistudios.csms`.
3. Importa los archivos `.swift` de este directorio (`CSMSApp.swift`, `ContentView.swift`, `SupabaseManager.swift`).
4. Selecciona un simulador de iOS o dispositivo físico y presiona **Run** (`⌘ + R`).
