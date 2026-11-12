# Component 2 (.c2) — Especificación de Módulos Dinámicos de UI para Shine OS
> **Versión de la Especificación:** 2.0 (Signature Format)  
> **Ecosistema:** Shine OS • Forkar Services (FMS) • UI Connect (PC) • Looping Engine  
> **Dispositivos Objetivo:** Shine f1 (Fold), Shine i1 (Flip), Shine fW1 (Fold Wider), Shine X1 (240Hz Titanio), Shine Xa1, Shine Nomad 1, Shine A1, Shine Vintage (niminticos)

---

## 1. ¿Qué es un Módulo `.c2`?
Un archivo **`.c2` (Component 2)** es un contenedor modular firmado criptográficamente que permite **personalizar, extender e inyectar interfaces de usuario en caliente (hot-reload)** en cualquier teléfono Shine sin necesidad de reinstalar la app ni reiniciar el sistema.

A diferencia de los APKs completos o temas estáticos tradicionales:
* **Ligero (< 50 KB a 5 MB)**: Contiene solo las definiciones declarativas de interfaz, paletas de tokens, componentes modulares y assets.
* **Hot-Reload en Vivo**: Se instala vía **UI Connect (PC)** por USB o Wi-Fi, o mediante **CS WEBS (OTA)**, y el launcher se actualiza al instante.
* **Firmado con Hardware Attestation**: Cada paquete incluye una firma de integridad SHA-256 respaldada por la clave de desarrollador de Coki Studios.

---

## 2. Estructura Interna de un Archivo `.c2`

Un archivo `.c2` es un archivo ZIP estándar empaquetado con la siguiente arquitectura:

```
mi_modulo.c2
├── manifest.json       # Metadatos del componente, compatibilidad y puntos de entrada
├── tokens.json         # Paleta de diseño (colores HSL/Hex, tipografía, bordes, FPS)
├── layout.json         # Composición visual (dock, widgets, paneles flotantes, gestos)
├── source.loop         # Código fuente opcional en Looping para interactividad y física
└── signature.sha256    # Firma de integridad de los archivos del paquete
```

---

## 3. Especificación de Archivos

### `manifest.json`
```json
{
  "c2_version": "2.0",
  "component_id": "com.cokistudios.c2.cyber_neon",
  "name": "Cyber Neon XUI Pro",
  "author": "Coki Studios",
  "target_device": "x1",
  "target_family": "xui",
  "target_fps": 240,
  "theme": "cyber_neon_xui",
  "primary_color": "#38bdf8",
  "accent_color": "#082f49",
  "entrypoint": "source.loop"
}
```

### `tokens.json`
```json
{
  "primary": "#38bdf8",
  "accent": "#0284c7",
  "background": "#07090e",
  "surface": "rgba(15, 23, 42, 0.85)",
  "text": "#f8fafc",
  "text_muted": "#94a3b8",
  "fps": 240,
  "layout_mode": "Pro Gamer Esports HUD (High-Refresh APU)",
  "corner_radius": 16,
  "elevation_dp": 8
}
```

### `layout.json`
```json
{
  "version": "2.0",
  "type": "modular_surface",
  "title": "Cyber Neon XUI",
  "components": [
    {
      "id": "bubbly_dot",
      "type": "status_pill",
      "position": "top",
      "glow": true
    },
    {
      "id": "modern_dock",
      "type": "dock",
      "position": "bottom",
      "apps": ["phone", "messages", "shinemaps", "camera", "settings"]
    },
    {
      "id": "telemetry_card",
      "type": "widget",
      "source": "forkar.eco.telemetry"
    }
  ]
}
```

---

## 4. Familias de Dispositivos y Perfiles Soportados

| Familia | Dispositivo | Refresco | Modo de Pantalla | Paleta Primaria |
| :--- | :--- | :--- | :--- | :--- |
| **`flui`** | Shine f1, i1, fW1 | 120 Hz | Plegable / Flex Mode 90° / Doble Pantalla | `#c084fc` (Aurora Indigo) |
| **`xui`** | Shine X1, Xa1 | 240 Hz | Direct-to-Vulkan Ultra-Baja Latencia | `#38bdf8` (Cyber Neon) |
| **`ui`** | Shine Nomad 1 (N1) | 90 Hz | Balanceado todo-terreno (3 días de batería) | `#00f5d4` (Frosted Aqua) |
| **`hiui`** | Shine A1 | 60 Hz | Eficiencia ultra-ligera (<30 MB RAM) | `#06b6d4` (Feather Lite) |
| **`vintage`** | Shine Vintage | 60 Hz | `tUIlbar` inferior curvada ergonómica | `#f59e0b` (Amber Monospace) |

---

## 5. Herramientas del Ecosistema
1. **Compilación en Looping**:
   ```bash
   looping compile mi_script.loop --target c2 -o mi_modulo.c2
   ```
2. **Instalación con UI Connect (PC)**:
   ```bash
   ui-connect install mi_modulo.c2
   ```
3. **Distribución Empresarial vía CS WEBS**:
   ```bash
   curl -X POST http://localhost:8080/api/v1/c2/upload -H "X-C2-Filename: mi_modulo.c2" --data-binary @mi_modulo.c2
   ```
