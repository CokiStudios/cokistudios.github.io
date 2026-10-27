# Looping Programming Language — Official Syntax & Reference Guide
> **Looping Commercial Production Edition v1.0.0 (Architecture 2.8A Quantum Signature & C++17 Native Engine)**  
> *Developed by Coki Studios & Holo Entertainment*  
> *Target Hardware & OS: Shine Loop Console • Holo Looping OoS (POSIX / macOS Universal / Linux Gaming Subsystem)*  
> *Historical Architecture Series: 2.8A, 2.7A, 2.6A, 2.5A, 2.0A, 1.0A*

---

## 1. Introducción & Filosofía de Diseño
**Looping** (extensiones de archivo `.loop` y `.ruup`) es un lenguaje de programación moderno, expresivo y de alto rendimiento diseñado para la creación ágil de videojuegos 2D, aplicaciones gráficas interactivas, ciencia de datos, criptografía segura, síntesis de audio en tiempo real y lógica multimedia.

Con el lanzamiento de **Looping v1.0.0 Comercial** (impulsado por la arquitectura **2.8A Quantum Signature**), Looping consolida su **sintaxis propia, concisa y distintiva** (`let`, `mut`, `val`, `:=`, `fn` con argumentos por defecto, `match` multi-patrón `|` y por rangos `..=`, `? :`, `??`, `try / catch`, destructuring `[a, b]`, llamadas de método sobre variables `s.trim().upper()`, `loop (N)`, `for..in` con `..=` y `step`, `|>`, `ui.*`, `spawn.*`, `audio.*`, `crypto.*`, `csv.*`, `datetime.*`, `regex.*`, `py!`), manteniendo un rendimiento de ejecución nativo en C++17 de **< 0.5 ms** y cero dependencias de Node.js.

Las versiones anteriores de desarrollo han sido oficialmente consolidadas bajo la serie de arquitectura (**2.8A**, **2.7A**, **2.6A**, **2.5A**, **2.0A**, **1.0A**), dando paso a la primera línea comercial de producción oficial.

### Transición de Node.js a C++17 Nativo (Hito del 3 de Octubre de 2026)
Looping comenzó como un prototipo experimental interpretado en JavaScript / Node.js (`bin/looping.js` en la serie 1.0A). El **3 de octubre de 2026** (Commit `67a72391`), el motor fue completamente reescrito en **C++17 nativo**, eliminando el entorno V8, reduciendo los tiempos de arranque de ~120 ms a **< 0.5 ms**, la memoria de 45 MB a **< 2.8 MB RSS**, y produciendo binarios universales sin dependencias de Node.js para macOS (`arm64`/`x86_64`) y Linux.

---

## 2. Compilación y Ejecución del Motor C++

### Binario Precompilado Universal
El ejecutable nativo compilado reside directamente en el repositorio (`arm64` + `x86_64`):
```bash
./bin/looping [opciones] [archivo.loop]
```

### Comandos de la CLI
| Comando | Descripción |
| :--- | :--- |
| `looping <archivo.loop>` | Ejecuta un archivo de código `.loop` o `.ruup` |
| `looping --gui <archivo.loop>` | Ejecuta el script abriendo la ventana gráfica interactiva |
| `looping --native <archivo.loop>` | Ejecuta el script sintetizando una ventana nativa del SO (sin HTML5) |
| `looping compile <archivo.loop> --target <shine_ui\|xui\|flui\|c2> [-o out]` | Compila el script para una arquitectura de interfaz nativa |
| `looping check <archivo.loop>` | Analizador estático recursivo de sintaxis y reporte de métricas AST en microsegundos |
| `looping ast <archivo.loop>` | Visualiza el árbol sintáctico abstracto (AST) jerárquico completo del script |
| `looping fmt <archivo.loop> [--write]` | Formatea y normaliza la indentación de un archivo `.loop` |
| `looping doc [topic]` | Manual de referencia integrado (`syntax`, `math`, `collections`, `crypto`, `csv`, `datetime`, `regex`, `ui`) |
| `looping bench` | Ejecuta el benchmark de rendimiento de la máquina virtual nativa C++17 |
| `looping doctor` | Verifica el estado del motor C++, perfiles de UI, criptografía e interoperabilidad Python |
| `looping repl` | Inicia la consola interactiva (REPL) con comandos `vars`, `funcs`, `bench`, `reset` |
| `looping eval "<code>"` | Evalúa una instrucción o bloque de código en línea |
| `looping test` | Ejecuta la suite de verificación unitaria (**50/50 pruebas**) |
| `looping --version` | Muestra la versión del motor nativo (`v2.8.0`) |
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

## 16. Novedades de Looping v2.6 (Pattern Matching, Stdlib Funcional, Crypto & UI Extendida)

### 16.1 Expresiones Ternarias (`? :`) y Null-Coalescing (`??`)
```loop
val tier = score >= 90 ? "DIAMOND" : "GOLD";
val active_theme = custom_theme ?? "frosted_aqua_a17";
```

### 16.2 Pattern Matching (`match`)
```loop
match rank_code {
    "S" => out("Grandmaster")
    "A" => out("Commander")
    _   => out("Recruit")
}
```

### 16.3 Rangos Inclusivos (`..=`), Paso (`step`) y `continue`
```loop
for (i in 1..=10 step 2) {
    if (i == 5) -> continue
    out($"Pulso impar: {i}")
}
```

### 16.4 Destructuring y Manejo de Errores (`try / catch / throw`)
```loop
let [first, second, third] = [100, 200, 300]
let (pos_x, pos_y) = (45, 90)

try {
    throw "OverheatFault"
} catch (err) {
    out($"[RECOVERY] Error capturado: {err}")
}
```

### 16.5 Biblioteca Estándar Funcional, Estadística y Criptográfica (`crypto.*`)
```loop
fn square(x) => x * x
fn is_even(x) => x % 2 == 0

val evens = [1, 2, 3, 4, 5, 6] |> filter(is_even) |> map(square)
val dedup = unique([1, 2, 2, 3, 1])
val flat  = flatten([[1, 2], [3, 4]])
val avg   = math.mean([10, 20, 30, 40])

// Criptografía nativa C++17 (cero dependencias externas)
val hash_hex = crypto.sha256("HoloOoS")
val b64      = crypto.base64_encode("ShineLoop")
val session  = crypto.uuid()
val room_key = crypto.csms_key("room_alpha")
```

### 16.6 Componentes UI Extendidos (`slider`, `toggle`, `progress` y Snippets en Botones)
```loop
draw slider at (10, 20) with label "Volumen" and min 0 and max 100 and val 75 and bind "vol"
draw toggle at (10, 70) with label "Modo Oscuro" and bind "dark_mode" checked
draw progress at (10, 110) with label "Batería" and val 90 and bind "batt"

insert button "Incrementar" with snippet:
    counter += 1
end
```

---

## 17. Novedades de Looping v2.8 Quantum Signature

### 17.1 Argumentos de Función por Defecto y Operador `%=`
```loop
fn greet_pilot(name, rank = "Commander", bonus = 50) => $"{rank} {name} (+{bonus})"
val p1 = greet_pilot("Jerix")                     // "Commander Jerix (+50)"
val p2 = greet_pilot("Jerix", "Admiral", 200)     // "Admiral Jerix (+200)"

mut rem = 29
rem %= 6                                          // 5
```

### 17.2 Pattern Matching Multi-Patrón (`|`) y por Rangos (`..=` / `..`)
```loop
match tier_code {
    "S" | "SS" | "SSS" => out("🏆 Rango Maestro Cuántico")
    "A" | "B"          => out("⭐ Rango Comandante")
    _                  => out("🎮 Rango Estándar")
}

match score {
    90..=100 => out("Calificación: A+")
    80..90   => out("Calificación: B")
    _        => out("Calificación: C")
}
```

### 17.3 Llamadas de Método sobre Variables (`var.method()`)
Cualquier función de cadenas o colecciones puede invocarse directamente con notación de punto sobre la variable:
```loop
let raw_title = "   coki studios shine   "
val clean_title = raw_title.trim()
val final_title = clean_title.upper()             // "COKI STUDIOS SHINE"

mut dyn_list = [40, 10, 30]
dyn_list.push(20)
val sorted_list = dyn_list.sort()                 // [10, 20, 30, 40]
val total_items = sorted_list.len()               // 4
```

### 17.4 Subsistema Nativo CSV (`csv.*`) y DateTime (`datetime.*` / `time.*`)
```loop
val csv_raw = "city,altitude,hub\nBogota,2640,true\nChia,2564,true"
val rows    = csv.parse(csv_raw)                  // Lista 2D de filas
val records = csv.parse_maps(csv_raw)             // Lista de Maps indexados por cabecera
val out_csv = csv.stringify(rows)

val now_iso = datetime.iso()                      // "2026-10-23T02:35:00Z"
val dt_info = datetime.now()                      // Map {year, month, day, hour, minute, second, iso}
val fmt_str = datetime.format(1767225600, "%Y-%m-%d")
val ns_tick = time.nanos()
```

### 17.5 Álgebra Vectorial, Estadística Avanzada y Colecciones Funcionales
```loop
// Álgebra lineal y estadística (math.*)
val dot_prod = math.dot([1, 2, 3], [4, 5, 6])     // 32
val l2_norm  = math.norm([3, 4])                  // 5
val dist_2d  = math.distance((0, 0), (6, 8))      // 10
val grid     = math.linspace(0, 10, 5)            // [0, 2.5, 5, 7.5, 10]
val p90      = math.percentile([10, 20, 30, 40, 50], 90)

// Colecciones de orden superior
fn parity(n) => n % 2 == 0 ? "even" : "odd"
val grouped = group_by([1, 2, 3, 4, 5, 6], parity)
val parts   = partition([10, 60, 20, 80], is_big)
val first_3 = take([1, 2, 3, 4, 5], 3)
val rest_2  = drop([1, 2, 3, 4, 5], 3)
val freqs   = frequencies(["a", "b", "a", "c", "a"])
```

### 17.6 Criptografía Extendida v2.8 (`crc32`, `constant_time_eq`, `csms_payload`)
```loop
val crc_hex  = crypto.crc32("LoopingEngine")
val hmac_hex = crypto.hmac_sha256("secret_key", "message_payload")
val safe_cmp = crypto.constant_time_eq(hmac_hex, expected_hmac)
val csms_pkt = crypto.csms_payload("room_sabana", "Hola Cota") // 🔒 enc:v1:<iv>:<ciphertext>
```

---

## 18. Experiencia Declarativa SwiftUI en Looping (v2.9 Apple Ecosystem Bridge)

Looping incorpora una experiencia de desarrollo de interfaces declarativas inspirada directamente en **SwiftUI** de Apple. Permite diseñar componentes reactivos, jerárquicos y encadenados con modificadores fluidos (`.padding()`, `.background()`, `.foregroundColor()`), visualizar vistas en vivo en la terminal mediante un Canvas TUI de alta fidelidad, y transpilar o compilar directamente a código **Swift 6** nativo listo para Xcode (`Forkar.iOS`, macOS, watchOS o visionOS).

### 18.1 Sintaxis de Vistas y Componentes Declarativos
```loop
view DashboardView {
    @state count = 100
    @state is_active = true
    @state username = "Jerix"

    VStack(spacing: 16) {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundColor(.cyan)
            Text("Coki Studios Quantum")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
            Spacer()
            Badge("Live 120Hz")
        }

        Divider()

        VStack(spacing: 8) {
            Text("Telemetría de Sistema")
                .font(.headline)
            Text("Operaciones procesadas: $count")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)

        HStack(spacing: 12) {
            Button("Disminuir") {
                count -= 10
            }
            .buttonStyle(.bordered)

            Button("Incrementar") {
                count += 25
            }
            .buttonStyle(.borderedProminent)
        }

        Toggle("Activar ProMotion E2EE", isOn: $is_active)
            .padding(10)

        ProgressView(value: 0.85)
            .tint(.cyan)
    }
    .padding(20)
    .frame(width: 440)
}
```

### 18.2 Catálogo de Contenedores y Controles
| Categoría | Constructores en Looping |
|---|---|
| **Contenedores de Disposición** | `VStack(spacing: N, alignment: .leading)`, `HStack(spacing: N)`, `ZStack`, `List`, `ScrollView`, `Section`, `Group`, `ForEach` |
| **Controles de Texto e Imagen** | `Text("...")`, `Image(systemName: "...")`, `Image("asset.png")`, `Badge("...")` |
| **Interactividad y Entrada** | `Button("Label") { action }`, `TextField("Placeholder", text: $var)`, `Toggle("Label", isOn: $var)`, `Slider(value: $var)` |
| **Indicadores y Separadores** | `ProgressView(value: N)`, `Spacer()`, `Divider()`, `Circle()`, `Rectangle()`, `RoundedRectangle(cornerRadius: N)` |

### 18.3 Modificadores Fluidos Encadenados (Dot Modifiers)
- `.font(.largeTitle | .title | .headline | .subheadline | .body | .caption)`
- `.fontWeight(.bold | .semibold | .medium | .regular | .light)`
- `.foregroundColor(color)` / `.foregroundStyle(color)` / `.tint(color)`
- `.padding([amount])` / `.padding(.horizontal, N)`
- `.background(.ultraThinMaterial | .blue | Color("..."))`
- `.cornerRadius(radius)`
- `.frame(width: W, height: H)`
- `.shadow(radius: R, y: Y)`
- `.opacity(alpha)`
- `.buttonStyle(.bordered | .borderedProminent | .plain)`

### 18.4 Previsualización en Vivo en la Terminal (Canvas TUI)
Puedes inspeccionar cualquier componente SwiftUI directamente en la terminal con renderizado visual en caja simulada de dispositivo:
```bash
# Vista previa en vivo del Canvas SwiftUI
looping preview app.loop [NombreComponente]
```

### 18.5 Transpilación y Compilación Nativa a Swift / Mach-O
```bash
# Transpilar a código fuente Swift puro (.swift)
looping compile app.loop --target swiftui -o MyApp.swift

# Compilar directamente a binario Mach-O ejecutable para macOS (vía swiftc)
looping compile app.loop --target swiftui -o build/MyApp
```

### 18.6 Funciones del Módulo Stdlib `swiftui.*`
- `swiftui.components()`: Lista de nombres de vistas registradas.
- `swiftui.has_component("Name")`: Verifica existencia de una vista.
- `swiftui.preview("Name")`: Imprime el Canvas TUI en la terminal.
- `swiftui.transpile("Name")`: Genera y retorna el código fuente Swift como string.
- `swiftui.export("Name", "out.swift")`: Exporta el archivo `.swift` al disco.

---

## 19. Motor de Videojuegos 2D Quantum en Looping (60 FPS Native Graphics)

Looping v2.8+ incorpora un motor completo de videojuegos 2D diseñado para ejecutarse a **60 FPS** nativos con aceleración por hardware tanto en la web (`LoopingInterpreter`), en la consola POSIX/Win32 (`looping eval`), en el IDE hiOP y en **Holo Looping OoS**.

### 19.1 Ejemplo Completo de Nivel 2D
```loop
import loop.engine as game

define game "QuantumRunner2D" version 2.8:
    create window with title "Holo Quantum Arcade" and size (720, 420)
    set theme to "dark_neon"
    
    # ── Configuración de Mundo y Físicas ──
    game.world(width: 1400, height: 420)
    game.gravity(980)
    game.friction(0.82)
    game.lives(3)

    # ── Héroe Protagonista (Doble Salto, Dash, Disparo e Inercia) ──
    spawn.player(name: "Angel Helium", at: (100, 310), speed: 280, jump: 440, health: 100)

    # ── Maglev Plataforma Móvil & Plataformas Neón ──
    spawn.platform(at: (60, 330), size: (180, 18), color: "#6366f1")
    spawn.moving_platform(at: (280, 250), size: (140, 18), range: (220, 500), speed: 85, color: "#06b6d4")
    spawn.platform(at: (560, 190), size: (160, 18), color: "#8b5cf6")
    spawn.platform(at: (780, 260), size: (150, 18), color: "#6366f1")

    # ── Trampas Neón, Impulsores y Anillos de Salto ──
    spawn.spike(at: (430, 376), size: (44, 20), damage: 35)
    spawn.pad(at: (250, 376), power: 670)
    spawn.orb(at: (720, 170), power: 560, color: "#f59e0b")

    # ── Coleccionables & Kits de Salud ──
    spawn.coin(at: (340, 200), points: 100)
    spawn.coin(at: (620, 140), points: 150)
    spawn.coin(at: (840, 210), points: 200)
    spawn.heart(at: (590, 140), heal: 35)

    # ── Enemigo Autónomo (Derrotable por pisada o disparando) ──
    spawn.enemy(name: "CorruptedForkbot", at: (800, 216), range: (780, 930), speed: 70, health: 30)

    # ── Portal de Victoria ──
    spawn.portal(at: (1180, 308), label: "NEON HUB")

    print("✔ Nivel cargado exitosamente a 60 FPS")
```

### 19.2 Catálogo de Entidades 2D y Directivas
| Entidad / Directiva | Sintaxis Declarativa | Descripción |
|---|---|---|
| **Jugador / Héroe** | `spawn.player(name, at, speed, jump, health)` | Protagonista con i-frames, doble salto, coyote time y dash. |
| **Plataforma Estática** | `spawn.platform(at, size, color)` | Superficie sólida con reborde neón y brillo volumétrico. |
| **Plataforma Móvil** | `spawn.moving_platform(at, size, range, speed)` | Maglev oscilante con arrastre inercial automático del jugador. |
| **Picos / Trampas** | `spawn.spike(at, size, damage)` | Dientes triangulares neón que infligen daño y rebote de impacto. |
| **Impulsor (Jump Pad)** | `spawn.pad(at, power, color)` | Base con resorte energético que impulsa al jugador hacia arriba. |
| **Anillo de Salto (Orb)** | `spawn.orb(at, power, color)` | Anillo gravitatorio que permite un impulso aéreo al presionarlo. |
| **Moneda / Estrella** | `spawn.coin(at, points)` | Coleccionable con animación de levitación y sonido de cristal. |
| **Kit de Salud (Heart)** | `spawn.heart(at, heal)` | Restaura vida con aura de chispas verdes y chime ascendente. |
| **Enemigo Autónomo** | `spawn.enemy(name, at, range, speed, health)` | Patrullero con IA de límites; derrotado al pisarlo o dispararle. |
| **Portal de Victoria** | `spawn.portal(at, label)` | Vórtice de meta con rotación neón y jingle de victoria. |
| **Gravedad y Fricción** | `game.gravity(val)` / `game.friction(val)` | Control de aceleración y desaceleración del mundo 2D. |
| **Cámara Suave** | `game.camera(follow: "player", smooth: 0.12)` | Seguimiento cinemático con sacudida (*screen shake*) en golpes. |

### 19.3 Mecánicas de Juego Pulidas
1. **Físicas y Plataformeo**:
   - **Coyote Time**: Ventana de 120 ms para saltar justo después de abandonar una plataforma.
   - **Jump Buffering**: Detección de salto previa al aterrizaje para una respuesta inmediata.
   - **Doble Salto Cuántico**: Salto secundario en el aire con partículas violeta.
   - **Dash**: Impulso horizontal de alta velocidad con rastro de movimiento.
   - **Squash & Stretch**: Deformación procedural del personaje en saltos y caídas.
2. **Combate y Enemigos**:
   - **Mecánica de Pisada**: Si el héroe cae sobre un enemigo desde arriba, lo neutraliza instantáneamente con rebote y +250 pts.
   - **Disparo Láser**: Disparo de proyectiles con trazas neón (`[Z]` o `[J]`).
   - **Invulnerabilidad Temporal**: Parpadeo defensivo de 1 segundo tras recibir impacto.
3. **Audio Sintetizado Retro-Futurista**:
   - Generación en tiempo real con Web Audio API (seno, triángulo, diente de sierra y ruido).
   - Efectos para salto, doble salto, dash, moneda, propulsor, pisada, daño, disparo, curación y victoria.
4. **Controles Universales**:
   - **Teclado**: `[A/D]` o Flechas para mover, `[W / Espacio]` saltar, `[Z / J]` disparar, `[X / K / Shift]` dash, `[R]` reiniciar.
   - **Gamepad**: Compatible directamente con mandos Bluetooth/USB (Xbox, PlayStation, Switch).
   - **Táctil**: Cruceta virtual D-Pad y botones [A] y [B] automáticos en dispositivos móviles y tabletas.

---

*© 2026 Holo Entertainment • Coki Studios. Making the world Shine, together.*
