# Shine Maps para iOS & Apple CarPlay 🗺️✨

**Shine Maps para iOS** es una aplicación de mapas, geointeligencia y navegación GPS de última generación construida en **SwiftUI**, diseñada con la estética Glassmorphism de Coki Studios, integración universal de identidad **CS ID**, sugerencias de búsqueda basadas en proximidad, modo **HUD para parabrisas** y soporte completo para **Apple CarPlay**.

---

## Características Principales

### 1. Autenticación Universal CS ID
- Integración nativa con el backend de **Coki Studios ID** en Supabase (`cmkumxprmmhuinxfppxl.supabase.co`).
- Inicio de sesión y registro de cuenta CS ID directamente desde la aplicación.
- Vinculación de `device_hash` (`/rest/v1/user_device_hashes`) para sincronización entre dispositivos.
- Sincronización de ubicaciones frecuentes (Casa y Estudio).
- Avatar de usuario interactivo en la barra superior.

### 2. Barra de Búsqueda con Sugerencias por Proximidad
- **Sugerencias Instantáneas**: Al tocar la barra de búsqueda vacía, se despliegan accesos directos categorizados según la ubicación actual:
  - ⛽ **Gasolineras cercanas** (`fuelpump.fill`)
  - 🍽️ **Restaurantes y comida** (`fork.knife`)
  - 🅿️ **Parqueaderos** (`parkingsign.circle.fill`)
  - 💊 **Farmacias y droguerías** (`cross.case.fill`)
  - ☕ **Cafeterías y panaderías** (`cup.and.saucer.fill`)
  - 🛒 **Supermercados y tiendas** (`cart.fill`)
- **Distancia en Tiempo Real**: Cálculo preciso de metros o kilómetros desde la ubicación del usuario (`CLLocation.distance(from:)`), con insignias como `250 m` o `1.4 km`.
- **Geocodificación Proximity de Mapbox**: Búsqueda asistida de direcciones y puntos de interés (POIs) ponderados por cercanía geográfica.

### 3. Navegación Turn-by-Turn y Modo HUD
- Cálculo de rutas dinámicas mediante **Mapbox Driving Traffic**.
- Tarjeta de navegación flotante con icono de maniobra, instrucción de giro, distancia restante, hora estimada de llegada (ETA) y velocímetro GPS en vivo.
- **Modo Parabrisas (HUD)**: Interfaz en fondo negro absoluto con opción de efecto espejo (`scaleEffect(x: -1, y: 1)`) para colocar el iPhone sobre el tablero del automóvil y proyectar la navegación en el cristal.

### 4. Apple CarPlay Integrado
- Delegado de escena `CarPlaySceneDelegate` (`CPTemplateApplicationSceneDelegate`).
- Plantilla `CPMapTemplate` con accesos directos a lugares guardados (Casa / Estudio).
- Sesiones de navegación activas con maniobras `CPManeuver` y estimaciones `CPTravelEstimates`.

### 5. Estética y Símbolos Nativos
- Implementación 100% de **Apple SF Symbols** en toda la interfaz (sin uso de emojis en componentes del sistema).
- Paleta **Shine Dark** con acentos Cyan (`#38bdf8`) y acabados de cristal líquido (`.ultraThinMaterial`).

---

## Estructura del Proyecto

```
ShineMaps.iOS/
├── Info.plist                     # Permisos de GPS, audio en segundo plano y configuración CarPlay
├── ShineMapsApp.swift             # Punto de entrada @main SwiftUI
├── ShineMapsTheme.swift           # Tokens de diseño, colores y modificadores Glassmorphism
├── Models.swift                   # Modelos de datos (CSIDUser, SearchResult, RouteInfo, RouteStep)
├── CSIDManager.swift              # Cliente de autenticación Supabase CS ID
├── LocationAndMapService.swift    # Gestor GPS, Geocodificación Mapbox y Rutas
├── ContentView.swift              # Mapa nativo MapKit, buscador, navegación HUD
├── CSIDAuthViews.swift            # Diálogos modales para Login, Registro y Perfil
├── CarPlaySceneDelegate.swift     # Soporte para pantallas de autos con Apple CarPlay
└── README.md
```

---

## Requisitos y Compilación

- **iOS 17.0+** / iPadOS 17.0+
- **Xcode 15+** o superior
- **Swift 5.9+ / Swift 6**
- Frameworks del sistema: `SwiftUI`, `MapKit`, `CoreLocation`, `CarPlay`, `Combine`
