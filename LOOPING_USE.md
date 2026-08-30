# ♾️ Looping Programming Language — Official Syntax & Reference Guide
> **Language Specification v2.0**  
> *Developed by Holo Entertainment (Sub-division of Coki Studios)*  
> *Target Hardware & OS: Shine Loop Console • Holo Looping OoS (Linux Gaming Subsystem)*

---

## 📖 1. Introducción
**Looping** (extensión de archivo `.loop`) es un lenguaje de programación declarativo, de alto rendimiento y fácil lectura diseñado especialmente para la creación rápida de videojuegos 2D, aplicaciones interactivas y experiencias multimedia. 

Su filosofía combina la legibilidad humana del pseudocódigo con la potencia de un motor gráfico y de físicas 2D en tiempo real a **60 FPS**.

---

## 🔤 2. Reglas Básicas de Sintaxis
- **Sensible a Mayúsculas/Minúsculas**: Sí (las palabras clave se escriben generalmente en minúsculas).
- **Comentarios**:
  ```loop
  # Esto es un comentario de una línea
  // Esto también es un comentario válido
  ```
- **Strings**: Se encierran entre comillas dobles (`"texto"`) o simples (`'texto'`).
- **Números**: Enteros (`100`) o decimales (`3.14`).
- **Coordenadas y Tuplas**: Se definen como `(x, y)` o `(ancho, alto)`.

---

## 📦 3. Módulos e Importaciones
Para habilitar subsistemas de interfaz de usuario o motor de física/juegos:

```loop
import loop.ui as ui
import loop.engine as game
import loop.audio as sound
```

---

## 🚀 4. Definición de la Aplicación
Toda aplicación o juego en Looping se declara mediante el bloque `define app`:

```loop
define app "NombreDelJuego" version 1.0:
    # Contenido del programa aquí...
```

---

## 🧱 5. Variables y Tipos de Datos
Las variables se declaran y asignan con la instrucción `set <nombre> to <valor>`:

```loop
# Texto (String)
set player_name to "Angel Helium"

# Números (Integer / Float)
set player_speed to 260
set gravity_force to 9.8

# Expresiones booleanas o estados
set is_game_active to true

# Temas visuales soportados: "dark_neon", "cyber_dark", "light_clean"
set theme to "dark_neon"
```

---

## 🖨️ 6. Salida de Consola y Depuración
Para imprimir información o variables en la terminal de depuración:

```loop
print "⚡ Inicializando sistema..."
print player_name
print "Velocidad actual:", player_speed
```

---

## 🖥️ 7. Ventana y Lienzo Gráfico (Display)
Crea la ventana de renderizado con tamaño personalizado:

```loop
create window with title "Holo Arcade Adventure" and size (720, 480)
```
- **`title`**: Nombre que aparece en el marco de la ventana / barra superior.
- **`size (ancho, alto)`**: Resolución en píxeles (ej. `(720, 480)` o `(1280, 720)`).

---

## 🎨 8. Interfaz de Usuario (UI & HUD)

### 🪟 Tarjetas Glassmorphism (`draw card`)
Dibuja cajas translúcidas con desenfoque, bordes neón y texto formateado:
```loop
draw card at (30, 30) with size (270, 115) and title "Shine Loop Status" and text "Engine: Looping v2.0\nFPS: 60 Estables"
```

### 🔘 Botones Interactivos (`draw button`)
Crea botones con degradado neón que responden a clics y eventos de gamepad:
```loop
draw button at (30, 160) with text "⚡ Activar Propulsor" and action "pulse_boost"
```

---

## 👾 9. Motor de Videojuegos y Entidades (2D Sprites)

### 🎮 Spawn de Entidades (`spawn sprite`)
Genera jugadores, enemigos o plataformas en el escenario con físicas automáticas:

```loop
# Jugador principal (con controles A/D/Espacio automáticos):
spawn sprite "AngelHelium" at (120, 380) with color "#38bdf8" and size (34, 46)

# Enemigo o NPC patrullero:
spawn sprite "CorruptedForkbot" at (480, 380) with color "#ef4444" and size (34, 46)
```

#### Propiedades del Sprite:
- **`at (x, y)`**: Posición inicial en el canvas.
- **`color`**: Color hexadecimal o nombre (`#38bdf8`, `#ef4444`, `#10b981`).
- **`size (w, h)`**: Ancho y alto del sprite en píxeles.

---

## ✨ 10. Sistema de Partículas (`emit particles`)
Genera explosiones y chispas neón con físicas de gravedad:

```loop
emit particles at (200, 300) with color "#6366f1"
emit particles at (400, 150) with color "#38bdf8"
```

---

## 🎮 11. Mapeo de Controles y Gamepad

El runtime de Looping mapea automáticamente las entradas para la consola **Shine Loop** y teclados de PC/Mac:

| Acción en Juego | Mando Shine Loop | Teclado PC / Mac |
| :--- | :--- | :--- |
| **Mover Izquierda** | D-Pad Izquierda / Stick Izq. | `A` o `Flecha Izquierda` |
| **Mover Derecha** | D-Pad Derecha / Stick Der. | `D` o `Flecha Derecha` |
| **Salto / Flotar** | **Botón A** | `W`, `Flecha Arriba` o `Espacio` |
| **Acción / Disparo** | **Botón B** | `J` o `Z` |
| **Habilidad Especial** | **Botón X** | `K` o `X` |
| **Pausar Menú** | **Botón Start / Menu** | `Escape` |

---

## 📄 12. Ejemplo Completo de un Juego en Looping (`arcade.loop`)

```loop
# ═══════════════════════════════════════════════════════════════
# 🎮 Holo Arcade — Proyecto Oficial Looping Compile
# Desarrollado por Holo Entertainment / Coki Studios
# ═══════════════════════════════════════════════════════════════

import loop.ui as ui
import loop.engine as game

define app "HoloArcade2D" version 2.0:
    create window with title "Shine Loop: Holo Arcade Core" and size (720, 480)
    set theme to "dark_neon"
    
    set player_name to "Angel Helium"
    set high_score to 14500
    
    print "⚡ Compilando entorno Looping..."
    print "🎮 Jugador listo:", player_name
    
    # ── Elementos HUD en pantalla ──
    draw card at (30, 30) with size (270, 115) and title "Shine Loop Console" and text "Engine: Looping Runtime\nStatus: 60 FPS Stable"
    draw button at (30, 160) with text "⚡ Pulso de Energía" and action "pulse_boost"

    # ── Entidades en Escena ──
    spawn sprite "AngelHelium" at (120, 380) with color "#38bdf8" and size (34, 46)
    spawn sprite "CorruptedForkbot" at (480, 380) with color "#ef4444" and size (34, 46)
    
    print "🎮 Presiona [A/D] para moverte y [W/Espacio] para saltar!"
```

---

## 🛠️ 13. Herramientas de Desarrollo y Compilación
- **IDE Oficial**: `hiOP Studio by CS` (disponible en la web [`hiop-ide.html`](file:///Users/jerix/cokistudios.github.io/hiop-ide.html) y en la app nativa para macOS `hiOP.app`).
- **Extensión VS Code**: `looping-cs-core` (resaltado de sintaxis y snippets).
- **Core Runtime**: [`LoopingEngine/looping_core.js`](file:///Users/jerix/cokistudios.github.io/LoopingEngine/looping_core.js).

---
*© 2026 Holo Entertainment • Coki Studios. Making the world Shine, together.*
