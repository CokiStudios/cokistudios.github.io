# Looping Programming Language — Official Syntax & Reference Guide
> **Language Specification v2.5 (Signature Syntax & C++ Native Engine)**  
> *Developed by Holo Entertainment (Sub-division of Coki Studios)*  
> *Target Hardware & OS: Shine Loop Console • Holo Looping OoS (Linux Gaming Subsystem)*

---

## 1. Introducción & Filosofía de Diseño
**Looping** (extensiones de archivo `.loop` y `.ruup`) es un lenguaje de programación moderno, expresivo y de alto rendimiento diseñado para la creación ágil de videojuegos 2D, aplicaciones gráficas interactivas, síntesis de audio en tiempo real y lógica multimedia.

En la versión **v2.5**, Looping abandona el estilo de "prosa en inglés" de las primeras versiones preliminares para consolidar una **sintaxis propia, concisa, auténtica y distintiva** (`let`, `mut`, `val`, `:=`, `fn`, `loop (N)`, `for..in`, `|>`, `ui.*`, `spawn.*`, `audio.*`, `py!`), manteniendo un rendimiento de ejecución nativo en C++17 de **< 1.0 ms** y cero dependencias de Node.js.

---

## 2. Compilación y Ejecución del Motor C++

### Binario Precompilado
El ejecutable nativo compilado reside directamente en el repositorio:
```bash
./bin/looping [opciones] [archivo.loop]
```

### Comandos de la CLI
| Comando | Descripción |
| :--- | :--- |
| `looping <archivo.loop>` | Ejecuta un archivo de código `.loop` o `.ruup` |
| `looping compile <archivo.loop> --target <shine_ui\|xui\|flui> [-o out]` | Compila el script para una arquitectura de interfaz nativa |
| `looping build <archivo.loop> -t <target>` | Alias de compilación de interfaz para scripts de sistema |
| `looping repl` | Inicia la consola interactiva (REPL) con memoria de variables en vivo |
| `looping eval "<code>"` | Evalúa una instrucción o bloque de código en línea |
| `looping test` | Ejecuta la suite de verificación unitaria (12/12 pruebas) |
| `looping --version` | Muestra la versión del motor nativo |
| `looping --help` | Despliega el menú de ayuda |

---

## 3. Declaración de Variables y Tipos (`let`, `mut`, `val`, `:=`)

Looping ofrece una sintaxis moderna y tipificada para declaración de estados y mutabilidad:

```loop
// Constantes e inmutables
let hero = "Angel Helium";
val max_hp = 250;

// Variables mutables
mut hp = 100;
mut energy = 45.5;

// Declaración rápida estilo Walrus (:=)
xp := 1500;
level := 12;

// Operadores de incremento y shorthand
level++;
hp += 25;
energy *= 1.2;
```

*(Por compatibilidad retroactiva, la sintaxis heredada `set x to 10` y `set x = 10` sigue funcionando).*

---

## 4. Funciones de Expresión y Bloque (`fn`)

### Funciones Flecha (One-line Arrow Functions)
```loop
fn add(a, b) => a + b;
fn compute_shield(base, lvl) => base * 1.5 + (lvl * 10);

val shield = compute_shield(40, level);
```

### Funciones en Bloque con Retorno (`return` / `->`)
```loop
fn evaluate_rank(points) {
    if (points >= 5000) {
        return "S-Rank Master";
    }
    return "Veteran Guard";
}

let current_rank = evaluate_rank(xp);
```

---

## 5. Bucles Únicos (`loop`, `for..in`, `while`)

### Bucle Contador (`loop (N)`)
Inyecta automáticamente la variable de índice `i`:
```loop
loop (5) {
    out($"  -> Pulso de sincronización: {i}");
}
```

### Bucle de Rango (`for (var in start..end)`)
```loop
for (step in 0..10) {
    out($"Procesando paso #{step}");
}
```

### Bucle de Condición (`while`) y Bucle Infinito (`loop`)
```loop
while (hp < max_hp) {
    hp += 10;
    if (hp >= max_hp) break;
}

loop {
    out("Bucle continuo...");
    break;
}
```

---

## 6. Control de Flujo: Condicionales

### Condicionales en Bloque (`if / else`)
```loop
if (hp >= 100) {
    out("[STATUS] Armadura sobrecargada.");
} else if (hp >= 50) {
    out("[STATUS] Armadura estable.");
} else {
    out("[ALERT] Daño crítico!");
}
```

### Condicional en Línea con Flecha (`->` / `=>`)
```loop
if (shield > 100) -> out("[SHIELD] Campo de deflexión activo");
```

---

## 7. Operador Pipeline (`|>`)

Permite encadenar transformaciones de datos de izquierda a derecha de forma fluida:
```loop
val sqrt_val = 81 |> math.sqrt;
$"[PIPELINE] Raíz calculada: {sqrt_val}" |> out;
```

---

## 8. Puente con Python (`pyloop`, `pysnippet`, `runpy`, `py!`)

### PyLoop Snippets & Ejecución (`from pyloop import snippets runpy`)
Permite importar el subsistema `pyloop` y capturar fragmentos de código Python puros como snippets nombrados para ejecutarlos dinámicamente con `runpy`:

```loop
from pyloop import snippets runpy
define app "Test" version 1.0
      insert pysnippet as sn1:
         print("Hello World!")
      runpy(sn1)
```

**Salida en consola:**
```text
[FUNC RUNPY] Executing sn1...
Hello World!
```

Los snippets pueden contener múltiples líneas, funciones, bibliotecas de Python, y acceden bidireccionalmente a las variables de Looping mediante `looping_vars` y `looping_set(clave, valor)`:
```loop
from pyloop import snippets, runpy

set factor = 10
insert pysnippet as calc_score:
    base = looping_vars.get("factor", 1)
    result = base * 25 + 100
    looping_set("calculated_score", result)

runpy(calc_score)
print "Score recibido:", calculated_score
```

### Macro en línea (`py!`)
```loop
val crit = py!(math.sqrt(64) * 1.5);
val orbit = py!(round(math.pi * 10, 3));
```

### Bloque multilínea con sincronización bidireccional
```loop
py! {
    import math
    current_lvl = looping_vars.get('level', 1)
    calculated_xp = int(current_lvl * 250 + math.pow(current_lvl, 2))
    
    // Guardamos de regreso en Looping
    looping_set('target_xp', calculated_xp)
}

out($"[SYNC] Target XP sincronizado desde Python: {target_xp}");
```

---

## 9. Directivas de UI Glassmorphism (`ui.*`)

Reemplazan la prosa en inglés por llamadas estructuradas con parámetros nombrados o posicionales:

```loop
// Tarjetas de estado con desenfoque holográfico
ui.card(at: (20, 20), size: (760, 60), title: "STATUS // SYSTEM", text: "Pipeline: 60 FPS Low-Latency");

// Botones interactivos con degradado neón
ui.btn(at: (40, 255), text: "EJECUTAR HYPERDRIVE", action: "hyper_boost");

// Entradas de texto interactivas
ui.input(at: (40, 200), size: (320, 40), placeholder: "Ingresa comando...", bind: "terminal_cmd");
```

*(También se acepta la sintaxis con anotación `@ui::card(...)` o `@ui::btn(...)`).*

---

## 10. Entidades de Videojuego y Físicas 2D (`spawn.*`)

```loop
// Plataformas físicas estáticas
spawn.platform(at: (420, 310), size: (350, 16), color: "#38bdf8");

// Monedas / Estrellas coleccionables
spawn.coin(at: (520, 250), points: 500);

// Sprites de jugador y enemigos con físicas a 60 FPS
spawn.sprite("Hero", at: (460, 240), size: (34, 46), color: "#6366f1");

// Indicador dinámico Bubbly Dot
spawn.bubbly("System Active // Diamond", state: "music");
```

---

## 11. Audio y Partículas (`audio.*`, `fx.*`)

```loop
// Generador de tono de hardware (frecuencia Hz, duración ms)
audio.tone(587, 80);
audio.tone(880, 100);

// Explosión de partículas FX con física de gravedad
fx.particles(at: (460, 240), color: "#38bdf8");
```

---

## 12. Configuración de Ventana y Aplicación

```loop
@app("CyberShineCore", "2.5") {
    window("CyberShine OS // Looping Native", 800, 520);
    theme("cyber_dark");
    profile("xui");
}
```

---

## 13. Ejemplo Completo (`signature_demo.loop`)

```loop
// ═══════════════════════════════════════════════════════════════
// ♾️ [LOOPING v2.5] Signature Syntax Showcase
// Holo Entertainment (Coki Studios)
// ═══════════════════════════════════════════════════════════════

import loop.engine as engine;
use python "math";

@app("CyberShineCore", "2.5") {
    window("CyberShine OS // Looping Native", 800, 520);
    theme("cyber_dark");
    profile("xui");

    let hero = "Angel Helium";
    mut hp = 100;
    val max_hp = 250;
    level := 12;

    level++;
    hp += 25;

    out($"[INIT] Pilot: {hero} | Level: {level} | HP: {hp}/{max_hp}");

    fn compute_shield(base, lvl) => base * 1.5 + (lvl * 10);
    val shield_rating = compute_shield(40, level);

    val sqrt_val = 81 |> math.sqrt;
    $"[PIPELINE] 81 piped into math.sqrt => {sqrt_val}" |> out;

    val py_calc = py!(round(math.pi * 10, 3));
    out($"[PYTHON MACRO] Pi scaled: {py_calc}");

    if (hp >= 120) -> out("[STATUS] Armor supercharged & ready for battle.");

    for (step in 0..3) {
        out($"  -> [TELEMETRY] Sensor array ping #{step} OK");
    }

    loop (2) {
        out("  -> [HEARTBEAT] Sub-millisecond tick verified");
    }

    ui.card(at: (20, 20), size: (760, 60), title: "CYBERSHINE CORE", text: "Kernel: Holo Looping OoS");
    ui.btn(at: (40, 255), text: "EJECUTAR HYPERDRIVE", action: "hyper_boost");

    spawn.platform(at: (420, 310), size: (350, 16), color: "#38bdf8");
    spawn.sprite("AngelPilot", at: (460, 240), size: (34, 46), color: "#6366f1");

    audio.tone(587, 80);
    fx.particles(at: (460, 240), color: "#38bdf8");

    out("[READY] CyberShine Core compilado y ejecutado en Looping v2.5!");
}
```


---

## 14. Compilación de Interfaces Nativas: Shine UI, XUI y flUI

Looping v2.5 incluye un compilador de perfiles de interfaz de usuario de hardware diseñado específicamente para el ecosistema **Shine Loop Console**, permitiendo adaptar el pipeline gráfico, la tasa de refresco (FPS) y los shaders de visualización a diferentes factores de forma y propósitos de uso:

### 🌟 Los 3 Perfiles de Interfaz de Usuario

| Perfil UI | Alias | Tasa de Refresco | Pipeline Gráfico | Shader Palette & Theme | Propósito / Dispositivo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Shine UI** | `shine_ui`, `shine` | **60 FPS** | Shine APU Direct V-Sync | `frosted_aqua_a17` (`#00f5d4` / `#0284c7`) | Consola portátil insignia, carrusel 3D y cuadrícula de juegos |
| **XUI** | `xui`, `gama_x` | **240 FPS** | Direct-to-Vulkan (<0.2ms) | `cyber_neon_xui` (`#38bdf8` / `#082f49`) | HUD competitivo para esports, alta tasa de refresco ultra-rápida |
| **flUI** | `flui`, `foldable` | **120 FPS** | Fold-Aware Dynamic Engine | `aurora_indigo_fold` (`#c084fc` / `#ec4899`) | Dispositivos plegables, doble pantalla y tarjetas flotantes |

---

### Compilación desde la CLI de Looping

Puedes compilar cualquier script `.loop` especificando el flag `--target` o `-t`:

```bash
# Compilar el launcher del sistema para Shine UI (Handheld 60Hz)
./bin/looping compile sample_loop_projects/shine_launcher.loop --target shine_ui --output build/ShineLauncher_ShineUI

# Compilar para XUI (Esports 240Hz Direct-to-Vulkan)
./bin/looping compile sample_loop_projects/shine_launcher.loop --target xui --output build/ShineLauncher_XUI

# Compilar para flUI (Plegable / Dual-Screen 120Hz)
./bin/looping compile sample_loop_projects/shine_launcher.loop --target flui --output build/ShineLauncher_flUI
```

El compilador genera un binario ejecutable (`chmod +x`) con shebang `#!/usr/bin/env looping` y metadatos de arquitectura embebidos que puede ejecutarse directamente:

```bash
./build/ShineLauncher_ShineUI
# o mediante:
./bin/looping build/ShineLauncher_ShineUI
```

---

### Sintaxis en Código Fuente (.loop)

Dentro del código de Looping, puedes declarar o bloquear el target de UI con cualquiera de las siguientes formas declarativas:

```loop
// Directiva de compilación explícita
compile target "shine_ui"

// Forma de función funcional
target("xui")

// Macro decorador de arquitectura
@target("flui")
profile("shine_ui")
```

Al ejecutarse, el motor exporta automáticamente las variables de entorno de sistema correspondientes:
- `UI_PROFILE`: Código del perfil (`"shine_ui"`, `"xui"`, `"flui"`)
- `UI_NAME`: Nombre oficial de la arquitectura (`"Shine UI"`, `"XUI"`, `"flUI"`)
- `UI_THEME`: Tema de sombreador de cristal activo
- `UI_FPS`: Tasa de refresco objetivo (`60`, `240`, `120`)

---

## 15. Comparativa de Sintaxis (Antes vs. Ahora)

| Característica | Prosa en Inglés (Legacy v2.0) | Sintaxis de Firma Looping (v2.5) |
| :--- | :--- | :--- |
| **Variables** | `set player to "Angel"` | `let player = "Angel"` / `player := "Angel"` |
| **Mutables** | `set hp = 100` | `mut hp = 100`, `hp += 25`, `hp++` |
| **Funciones** | `function foo(x) { ... }` | `fn foo(x) => x * 2` / `fn foo(x) { ... }` |
| **Bucles** | `repeat 5 times { ... }` | `loop (5) { ... }` / `for (i in 0..5) { ... }` |
| **Condicional** | `if hp >= 20 do print "ok"` | `if (hp >= 20) -> out("ok")` |
| **Pipelines** | N/A | `81 \|> math.sqrt \|> out` |
| **Puente Python** | `set x to py: math.sqrt(64)` | `val x = py!(math.sqrt(64))` / `py! { ... }` |
| **UI Card** | `draw card at (20,20) with size...` | `ui.card(at: (20, 20), size: (760, 60), ...)` |
| **UI Button** | `draw button at (30,150) with text...` | `ui.btn(at: (30, 150), text: "Go", action: "act")` |
| **2D Entities** | `spawn sprite "Hero" at (10,10)...` | `spawn.sprite("Hero", at: (10, 10), color: "#fff")` |
| **Audio** | `play tone at 587 Hz for 80 ms` | `audio.tone(587, 80)` |

---

*© 2026 Holo Entertainment • Coki Studios. Making the world Shine, together.*
