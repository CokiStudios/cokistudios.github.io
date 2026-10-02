# Shine Maps para iOS & Apple CarPlay 🗺️✨
### Híbrido Apple Maps + Mapbox Directions GL

**Shine Maps para iOS** es una aplicación de mapas y navegación inteligente de última generación construida en **SwiftUI** con arquitectura híbrida:
- **Apple Maps (MapKit & CoreLocation)**: Provee la geocodificación inversa y directa de direcciones exactas, búsqueda autocompletada en vivo (`MKLocalSearchCompleter`) y recomendaciones basadas en lugar por categorías de interés (`MKPointOfInterestCategory` / `MKLocalSearch.Request`).
- **Mapbox Directions GL**: Provee el motor de navegación turn-by-turn con perfiles de tráfico (`mapbox/driving-traffic`, `mapbox/driving`, `mapbox/cycling`, `mapbox/walking`), segmentación de congestión en tiempo real con polilíneas multi-color (Cyan, Ámbar, Rosa, Carmesí), banners de carril y síntesis de voz en español (`AVSpeechSynthesizer`).
- **Apple CarPlay**: Integración nativa con `CPMapTemplate`, lista de recomendaciones de lugares Apple Maps (`CPListTemplate`), atajos a Casa/Estudio, y sesiones de navegación turn-by-turn activas con `CPManeuver` y estimaciones de viaje `CPTravelEstimates`.

---

## Arquitectura Híbrida

```
┌────────────────────────────────────────────────────────┐
│                    SHINE MAPS iOS                      │
├──────────────────────────┬─────────────────────────────┤
│   APPLE MAPS ENGINE      │   MAPBOX DIRECTIONS GL      │
│   (Descubrimiento & Dir) │   (Rutas, Tráfico y HUD)    │
├──────────────────────────┼─────────────────────────────┤
│ • Reverse Geocoding      │ • Directions API v5 Traffic │
│   (CLGeocoder)           │ • Congestion Color Segments │
│ • Live Autocomplete      │ • Voice Guidance (AVSpeech) │
│   (MKLocalSearchComplete)│ • 3D Camera Perspective 60° │
│ • POI Recommendations:   │ • Turn-by-turn Maneuvers    │
│   Gasolina, Comida, Café,│ • Windshield Mirrored HUD   │
│   Parking, Carga EV, Farm│ • Multi-Profile (Car/Bike)  │
└──────────────────────────┴─────────────────────────────┘
                           │
                           ▼
             ┌───────────────────────────┐
             │     APPLE CARPLAY HUD     │
             │ (CPMapTemplate & Maneuver)│
             └───────────────────────────┘
```

---

## Características Principales

### 1. Apple Maps: Direcciones y Recomendaciones Basadas en Lugar
- **Direcciones Precisas**: Geocodificación inversa al tocar cualquier punto del mapa con `CLGeocoder`, mostrando calle, número, localidad y departamento.
- **Autocompletado en Tiempo Real**: Sugerencias directas mientras escribes con `MKLocalSearchCompleter` y badge oficial de Apple Maps.
- **Recomendaciones por Proximidad**: Carrusel superior y hojas modales categorizadas con `MKLocalSearch.Request`:
  - ⛽ **Gasolineras** (`fuelpump.fill`)
  - 🍽️ **Restaurantes** (`fork.knife`)
  - ☕ **Cafeterías** (`cup.and.saucer.fill`)
  - 🅿️ **Parqueaderos** (`parkingsign.circle.fill`)
  - ⚡ **Carga EV** (`bolt.car.fill`)
  - 💊 **Farmacias** (`cross.case.fill`)
  - 🛒 **Supermercados** (`cart.fill`)
  - 🏨 **Hoteles** (`bed.double.fill`)
  - 🏦 **Bancos / Cajeros** (`banknote.fill`)
- **Ficha de Lugar Detallada**: Muestra número de teléfono con botón directo para llamar (`tel://`), sitio web oficial, categoría POI y distancia calculada en vivo.

### 2. Mapbox Directions GL: Tráfico en Vivo, Voz y 3D
- **Polilínea de Tráfico con Congestión GL**:
  - Consulta Mapbox Directions API v5 con anotaciones `congestion,distance,duration`.
  - Descompone la ruta en segmentos coloreados según la densidad del tráfico:
    - 🔵 **Cyan Fluido**: Sin demoras
    - 🟡 **Ámbar Moderado**: Desaceleración
    - 🔴 **Rosa Pesado**: Congestión alta
    - 🩸 **Carmesí Severo**: Embotellamiento
- **Cámara 3D de Navegación**: Inclinación automática de perspectiva a 60° con seguimiento del rumbo del usuario (`MKMapCamera`).
- **Instrucciones por Voz**: Lectura hablada de maniobras con `AVSpeechSynthesizer` en español con botón de silencio rápido.
- **Selector de Perfiles de Ruta**: Conducción con tráfico, ruta directa, bicicleta y peatonal.
- **Modo Parabrisas (HUD)**: Vista OLED oscura con efecto espejo para reflejar la velocidad y maniobras en el parabrisas del vehículo.

### 3. Apple CarPlay Completo
- **Escena Nativa**: `CarPlaySceneDelegate` (`CPTemplateApplicationSceneDelegate`).
- **Botón "Lugares"**: Abre un `CPListTemplate` con las categorías y recomendaciones de Apple Maps directamente en la pantalla del auto.
- **Navegación Activa**: Inicia una `CPNavigationSession` con `CPTrip`, pasando maniobras `CPManeuver` con iconos SF Symbols e indicaciones estimadas `CPTravelEstimates`.
- **Atajos**: Botones en barra para "Casa", "Estudio", "Voz" y estado de autenticación con **CS ID**.

### 4. Identidad Universal CS ID
- Conectado a la base de datos de Coki Studios en Supabase (`cmkumxprmmhuinxfppxl.supabase.co`).
- Sincronización de credenciales y lugares guardados (Casa y Estudio) entre el iPhone y CarPlay.

---

## Estructura del Proyecto

```
ShineMaps.iOS/
├── Info.plist                     # Permisos GPS, Audio en segundo plano y configuración CarPlay
├── ShineMapsApp.swift             # Entrada de la aplicación SwiftUI
├── ShineMapsTheme.swift           # Tokens de diseño Glassmorphism, colores Cyan y estilos
├── Models.swift                   # Modelos: SearchResult, TrafficSegment, RouteInfo, RouteStep, ApplePlaceCategory
├── CSIDManager.swift              # Autenticación y sincronización con Supabase CS ID
├── LocationAndMapService.swift    # Core híbrido: Geocodificador Apple Maps, autocompletado y Mapbox Directions GL
├── ContentView.swift              # UI SwiftUI: Mapa 3D, carrusel de POIs, polilínea de tráfico y HUD
├── CSIDAuthViews.swift            # Vistas modales de Login, Registro y Perfil de CS ID
├── CarPlaySceneDelegate.swift     # Integración CarPlay con CPMapTemplate, CPListTemplate y CPManeuver
└── README.md                      # Documentación completa
```

---

## Requisitos y Compilación

- **iOS 17.0+** / iPadOS 17.0+
- **Xcode 15+** o superior
- **Swift 5.9+ / Swift 6**
- Frameworks: `SwiftUI`, `MapKit`, `CoreLocation`, `CarPlay`, `AVFoundation`, `Combine`
