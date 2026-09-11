# Shine Find Browser 🌐✨
### El Navegador de Próxima Generación de Coki Studios LLC

**Shine Find** es un navegador web de alto rendimiento diseñado desde cero para combinar la velocidad y compatibilidad del motor **Chromium Embedded Framework (CEF C++)** con el diseño vanguardista **Liquid Glass**, el escudo de privacidad **Sentinel Shield**, integración universal de identidad **CS ID** y una barra lateral de **Inteligencia Artificial Multimodelo**.

---

## 🌟 Pilares Fundamentales

### 1. Motor Chromium CEF C++
- Renderizado de latencia ultra baja con aceleración directa por hardware (Metal en macOS y DirectX en Windows).
- Soporte para estándares web modernos, WebGPU, WebAssembly y reproducción fluida a 120 FPS.
- Modo de optimización inteligente: desconexión de decodificación de video innecesaria y reducción dinámica de memoria VRAM Swap.

### 2. Escudo Sentinel Anti-Rastreadores
- Intercepción de scripts invasivos, cookies de terceros y telemetría a nivel de socket de red antes de tocar la memoria RAM.
- Protección activa contra huella digital (Canvas y WebGL fingerprinting).
- Contador interactivo de amenazas neutralizadas en tiempo real.

### 3. Asistente IA Multimodelo en Barra Lateral
- Integración nativa sin necesidad de cambiar de pestaña:
  - **Gemini** (Google DeepMind)
  - **ChatGPT** (OpenAI)
  - **Claude** (Anthropic)
  - **Kimi** (Moonshot AI)
  - **IA Personalizada**: Conexión directa a tu propio endpoint de inferencia o modelo local.
- Resúmenes instantáneos de contenido web, extracción de datos y asistencia contextual.

### 4. Identidad Universal CS ID
- Sesión única para todo el ecosistema de Coki Studios (Forkar, Shine Maps, Developer Portal).
- Vinculación criptográfica de `device_hash` con Supabase Cloud.
- Sincronización transparente de marcadores, pestañas abiertas e historial.

### 5. Formato Autónomo `.componentsave`
- Guardado y exportación de páginas web, estados de aplicaciones y notas en un archivo seguro cifrado `.componentsave`, compatible entre todas las plataformas.

---

## 📁 Plataformas Disponibles

| Plataforma | Tecnología | Ubicación | Características |
|---|---|---|---|
| **Web** | HTML5 / Vanilla CSS / JS | [`shine-find.html`](../shine-find.html) | Simulador interactivo con multi-pestañas, barra de marcadores, modal Sentinel Shield y panel de IA. |
| **macOS** | Swift / SwiftUI / WebKit / CEF | [`ShineFind.macOS/`](./ShineFind.macOS/) | UI Liquid Glass nativa (.ultraThinMaterial), 100% SF Symbols, pestañas con traffic lights integrados. |
| **Windows** | C# / WPF / CefSharp Chromium | [`ShineFind.Windows/`](./ShineFind.Windows/) | Fluent Design Windows 11, glifos vectoriales MDL2, aceleración por hardware y atajos globales. |

---

## ⌨️ Atajos de Teclado Principales

| Atajo (macOS) | Atajo (Windows) | Acción |
|---|---|---|
| `Cmd + T` | `Ctrl + T` | Abrir nueva pestaña |
| `Cmd + W` | `Ctrl + W` | Cerrar pestaña actual |
| `Cmd + R` | `Ctrl + R` / `F5` | Recargar página web |
| `Cmd + ,` | `Ctrl + ,` | Abrir panel de preferencias y configuración de IA |
| `Option + Cmd + I` | `F12` | Abrir herramientas de desarrollador (DevTools) |

---

© 2026 Coki Studios LLC. Todos los derechos reservados.
