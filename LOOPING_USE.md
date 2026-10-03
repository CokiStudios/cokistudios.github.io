# Looping Programming Language — Official Syntax & Reference Guide
> **Language Specification v2.2 (C++ Native Subsystem & Core Engine)**  
> *Developed by Holo Entertainment (Sub-division of Coki Studios)*  
> *Target Hardware & OS: Shine Loop Console • Holo Looping OoS (Linux Gaming Subsystem)*

---

## 1. Introducción
**Looping** (extensiones de archivo `.loop` y `.ruup`) es un lenguaje de programación declarativo, de alto rendimiento y fácil lectura diseñado especialmente para la creación rápida de videojuegos 2D, aplicaciones interactivas, interfaces hápticas y lógica multimedia.

Originalmente prototipado con Node.js, **Looping ha sido completamente reescrito e implementado en C++17 nativo** (`LoopingEngine/cpp`), eliminando dependencias de Node.js, reduciendo el consumo de memoria a menos de **3 MB RSS** y logrando tiempos de arranque y ejecución de **< 1.0 ms**.

---

## 2. Compilación y Ejecución del Motor C++

### Binario Precompilado
El ejecutable nativo compilado reside directamente en:
```bash
./bin/looping [opciones] [archivo.loop]
```

*(El prototipo anterior de Node.js se conserva como respaldo en [`bin/looping.js`](file:///Users/jerix/cokistudios.github.io/bin/looping.js)).*

### Compilar desde el Código Fuente
El código fuente en C++ se encuentra en `LoopingEngine/cpp/`:
```bash
# Con Makefile nativo (Clang / GCC)
cd LoopingEngine/cpp
make

# O con CMake
mkdir -p build && cd build
cmake ..
cmake --build .
```

### Comandos de la CLI
| Comando | Descripción |
| :--- | :--- |
| `looping <archivo.loop>` | Ejecuta un archivo de código `.loop` o `.ruup` |
| `looping repl` | Inicia la consola interactiva (REPL) con memoria en vivo |
| `looping eval "<code>"` | Evalúa una instrucción o bloque de código en línea |
| `looping test` | Ejecuta la suite de verificación unitaria interna (7/7 pruebas) |
| `looping --version` | Muestra la versión del motor nativo |
| `looping --help` | Despliega el menú de ayuda y opciones |

---

## 3. Reglas Básicas de Sintaxis
- **Sensible a Mayúsculas/Minúsculas**: Sí.
- **Comentarios**:
  ```loop
  # Esto es un comentario estilo Shell/Python
  // Esto también es un comentario válido estilo C
  ```
- **Strings e Interpolación**:
  ```loop
  set player to "Angel Helium"
  set score = 9500
  print "Jugador activo: {player} | Puntos: {score}"
  ```
- **Números**: Enteros (`100`) o decimales de doble precisión (`3.14159`).
- **Coordenadas y Tuplas**: `(x, y)` o `(ancho, alto)`.

---

## 4. Módulos e Importaciones
```loop
import loop.ui as ui
import loop.engine as game
import loop.audio as sound
use python "math"
use python "os"
```

---

## 5. Definición de la Aplicación
```loop
define app "HoloArcade2D" version 2.2:
    create window with title "Shine Loop: Holo Arcade Core" and size (720, 480)
    set theme to "dark_neon"
    set ui_profile to "xui"
```

---

## 6. Variables y Asignaciones

Soporta asignación declarativa (`set ... to ...`) y notación estándar con operadores shorthand:

```loop
# Asignación declarativa
set player_name to "Angel Helium"
set base_power to 10

# Asignación directa y shorthand
set level = 1
level += 5
base_power *= 2
```

---

## 7. Biblioteca Matemática Integrada (`math.*`)
El motor C++ incluye funciones matemáticas de alta precisión integradas en el evaluador AST:
- `math.sqrt(x)`: Raíz cuadrada.
- `math.pow(base, exp)`: Potenciación.
- `math.sin(rad)`, `math.cos(rad)`, `math.tan(rad)`: Trigonometría.
- `math.floor(x)`, `math.ceil(x)`, `math.round(x)`: Redondeo.
- `math.abs(x)`: Valor absoluto.
- `math.pi`: Constante pi ($\approx 3.1415926535$).

```loop
set radius = 10
set area = math.pi * math.pow(radius, 2)
print "Área calculada:", area
```

---

## 8. Puente Bidireccional con Python (`py: expr` y `python { ... }`)

Looping cuenta con un subsistema IPC que detecta automáticamente cualquier instalación de `python3` en el sistema y permite compartir variables y ejecutar código Python con cero configuración.

### Expresiones en línea (`py:`)
```loop
set crit to py: math.sqrt(64) * 1.5
set orbit to py: round(math.pi * 10, 2)
```

### Bloques multilínea con sincronización bidireccional
Dentro de un bloque `python { ... }`, las variables de Looping están disponibles a través del diccionario `looping_vars`. Para exportar variables de vuelta al entorno C++ de Looping, se usa `looping_set(clave, valor)`:

```loop
set level = 20
set hero = "Angel Helium"

python {
    import math
    current_lvl = looping_vars.get('level', 1)
    calculated_xp = int(current_lvl * 250 + math.pow(current_lvl, 2))
    rank = "Diamond Commander" if current_lvl >= 20 else "Platinum Guard"
    
    print(f"Calculando estadísticas para {hero}...")
    looping_set('target_xp', calculated_xp)
    looping_set('hero_rank', rank)
}

print "[SYNC] Target XP:", target_xp
print "[SYNC] Assigned Rank:", hero_rank
```

---

## 9. Control de Flujo: Condicionales y Bucles

### Condicionales en línea y en bloque
```loop
# En línea con 'do'
if target_xp >= 5000 do print "[S-RANK] Nivel maestro desbloqueado!"

# Bloque con llaves
if total_power > 100 {
    print "Modo Hyper activado"
} else {
    print "Modo normal"
}
```

### Bucles Repetitivos (`repeat N times`)
Inyecta automáticamente la variable de índice `i` (desde `0` hasta `N-1`):
```loop
repeat 3 times {
    print "  -> Pulso de sincronización: {i}"
}
```

---

## 10. Funciones del Usuario
```loop
function play_welcome_chime() {
    play tone at 659 Hz for 80 ms
    play tone at 880 Hz for 120 ms
}

call play_welcome_chime()
```

---

## 11. Componentes de UI y HUD Holográfico

### Tarjetas Glassmorphism (`draw card`)
```loop
draw card at (30, 30) with size (270, 115) and title "Shine Loop Status" and text "Engine: Looping C++ v2.2\nLatency: <1ms"
```

### Botones Interactivos (`draw button`)
```loop
draw button at (30, 160) with text "Activar Propulsor" and action "pulse_boost"
```

### Entradas de Texto (`draw input`)
```loop
draw input at (40, 210) with size (320, 40) and placeholder "Escribe un comando..." and var "player_input"
```

---

## 12. Entidades de Videojuego (Motor 2D)

### Spawns de Objetos y Personajes
```loop
# Plataforma física estática:
spawn platform at (200, 330) with size (150, 16) and color "#6366f1"

# Coleccionables / Estrellas:
spawn coin at (275, 290) with points 100

# Sprites animados con motor de física a 60 FPS:
spawn sprite "AngelHelium" at (120, 380) with color "#38bdf8" and size (34, 46)
spawn sprite "CorruptedForkbot" at (480, 380) with color "#ef4444" and size (34, 46)

# Notificación Bubbly Dot:
spawn bubbly_dot with text "Angel Active // Diamond" and state "music"
```

### Efectos y Audio Sintetizado
```loop
# Explosión de partículas:
emit particles at (200, 300) with color "#6366f1"

# Tono de audio sintetizado:
play tone at 587 Hz for 100 ms
```

---

## 13. Mapeo de Controles y Gamepad

| Acción en Juego | Mando Shine Loop | Teclado PC / Mac |
| :--- | :--- | :--- |
| **Mover Izquierda** | D-Pad Izquierda / Stick Izq. | `A` o `Flecha Izquierda` |
| **Mover Derecha** | D-Pad Derecha / Stick Der. | `D` o `Flecha Derecha` |
| **Salto / Flotar** | **Botón A** | `W`, `Flecha Arriba` o `Espacio` |
| **Acción / Disparo** | **Botón B** | `J` o `Z` |
| **Habilidad Especial** | **Botón X** | `K` o `X` |
| **Pausar Menú** | **Botón Start / Menu** | `Escape` |

---

## 14. Comparativa de Rendimiento (Node.js vs. C++17)

| Métrica | Node.js Legacy (`bin/looping.js`) | C++17 Nativo (`bin/looping`) | Mejora |
| :--- | :--- | :--- | :--- |
| **Tiempo de Arranque (Cold Start)** | ~180 ms | **0.3 ms** | **600x más rápido** |
| **Consumo de Memoria RAM (RSS)** | ~48 MB | **< 3 MB** | **16x menos memoria** |
| **Dependencias Externas** | Node runtime, npm packages | **Cero dependencias** (libc++/libstdc++) | Autocontenido |
| **Compilación Binaria** | N/A (Interpretado) | Binario binario nativo POSIX / Win32 | Listo para Shine Loop Console |

---

*© 2026 Holo Entertainment • Coki Studios. Making the world Shine, together.*
