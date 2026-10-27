# 📦 Looping Modules Directory & Manual Authoring Guide

> **Guía Oficial de Módulos para Looping Engine & smiledev (Comercial v1.0.0 / Arch 2.8A)**  
> *Coki Studios & Holo Entertainment © 2026*

---

## 🌟 Módulos Oficiales Incluidos en el Ecosistema

| Módulo | Versión | Lenguaje | Punto de Entrada | Descripción |
| :--- | :---: | :---: | :--- | :--- |
| **`loop-core-utils`** | `1.1.0` | 🟢 Loop | `core_utils.loop` | Utilidades fundamentales de colecciones, parsers JSON y helpers reactivos. |
| **`loop-math-3d`** | `1.2.0` | 🔵 C++ | `loop_math_3d.hpp` | Álgebra lineal acelerada por hardware, cuaterniones y física de proyectiles. |
| **`loop-cpp-snippets`**| `1.0.0` | 🔵 C++ | `cpp_snippets.hpp` | Benchmarking RAII, RingBuffers, hash FNV-1a y colisiones AABB. |
| **`loop-gui-tk`** | `2.0.0` | 🟡 Python | `loop_gui_tk.py` | UI compleja con Tkinter: pestañas, tablas ordenables, árboles, editor monospaced, KPI cards, canvas vectorial 2D y schema declarativo. |
| **`loop-gui-qt`** | `2.0.0` | 🟡 Python | `loop_gui_qt.py` | UI compleja con PyQt6 / PySide6 (con fallback Tkinter): temas QSS oscuros, QTabWidget, tablas ordenables, QTreeWidget, editor y sliders. |
| **`pyloop-requests`** | `1.2.0` | 🟡 Python | `pyloop_requests.py` | Cliente HTTP/HTTPS liviano con soporte TLS, retry logic y JSON. |
| **`pyloop-ai`** | `1.0.0` | 🟡 Python | `pyloop_ai.py` | Puente neuronal para conectar scripts Looping con LLMs e inferencia local. |
| **`loop-node-window`** | `2.0.0` | 🌐 Node/Web | `index.js` | Generador de ventanas dinámicas y escenario de videojuegos 2D con Web Audio y REST. |

---

## 🛠️ Cómo Crear Módulos Manualmente (SIN el CLI de smiledev)

No es obligatorio utilizar la herramienta de línea de comandos `smiledev` para crear o utilizar módulos en Looping. El motor nativo C++ (`looping`) está diseñado para **descubrir y cargar módulos automáticamente directamente desde el sistema de archivos**.

### 1. Estructura de Directorios Requerida

Para que un módulo sea reconocido localmente en tu proyecto, sólo necesitas crear una subcarpeta dentro del directorio `modules/` de tu proyecto con el nombre de tu módulo:

```text
mi_proyecto_looping/
├── mi_script.loop              # Tu código ejecutable
└── modules/                    # Carpeta de módulos local
    └── mi-super-modulo/        # Nombre del módulo (minúsculas y guiones)
        ├── smile.json          # 📄 Manifiesto obligatorio
        ├── main.loop           # 🚀 Código fuente principal (o .hpp, .py, etc.)
        └── README.md           # 📖 Documentación (opcional pero recomendada)
```

---

### 2. Especificación del Manifiesto `smile.json`

Crea un archivo llamado `smile.json` dentro de la carpeta de tu módulo con el siguiente formato JSON estándar:

```json
{
  "name": "mi-super-modulo",
  "version": "1.0.0",
  "language": "loop",
  "entry_point": "main.loop",
  "author_name": "Tu Nombre o CS ID",
  "description": "Módulo de utilidades matemáticas y renderizado cuántico.",
  "license": "MIT",
  "dependencies": {}
}
```

#### Campos Detallados:
* **`name`** *(string, OBLIGATORIO)*: Identificador único del módulo. Debe ser en minúsculas, usando solo caracteres alfanuméricos, guiones `-` o puntos `.`. Ejemplo: `"mi-calculadora"`.
* **`version`** *(string, OBLIGATORIO)*: Versión según Semantic Versioning (`MAJOR.MINOR.PATCH`). Ejemplo: `"1.0.0"`.
* **`language`** *(string, OBLIGATORIO)*: Lenguaje principal del módulo. Opciones válidas:
  * `"loop"`: Código nativo en Looping (`.loop` o `.ruup`).
  * `"cpp"`: Cabecera C++ nativa (`.hpp` o `.h`).
  * `"python"`: Script Python / PyLoop (`.py`).
  * `"node"`: Script JavaScript para utilidades web (`.js`).
  * `"c2"`: Componente declarativo C2 (`.c2`).
* **`entry_point`** *(string, OBLIGATORIO)*: Nombre relativo del archivo que contiene el punto de entrada dentro de la carpeta del módulo. Ejemplo: `"main.loop"`, `"algebra.hpp"`, `"plugin.py"`.
* **`author_name`** *(string, opcional)*: Nombre, pseudónimo o CS ID del autor.
* **`description`** *(string, opcional)*: Breve explicación del propósito del módulo.
* **`license`** *(string, opcional)*: Licencia de uso (ejemplo: `"MIT"`, `"Apache-2.0"`, `"Coki Commercial"`).
* **`dependencies`** *(object, opcional)*: Mapa de dependencias requeridas (ej: `{"loop-core-utils": "^1.1.0"}`).

---

### 3. Plantillas de Código por Lenguaje

#### A. Módulo en Looping Puro (`main.loop`)
Crea el archivo `modules/mi-super-modulo/main.loop`:
```looping
// modules/mi-super-modulo/main.loop
define module "mi-super-modulo" version 1.0:

fn calcular_impulso(fuerza, masa) {
    if (masa <= 0) -> return 0.0;
    return fuerza / masa;
}

fn saludar_piloto(nombre) => $"¡Bienvenido a la cabina, {nombre}!"
```

**Cómo consumirlo en tu script principal (`mi_script.loop`):**
```looping
use module "mi-super-modulo"

val saludo = saludar_piloto("Comandante Jerix")
print(saludo)

val aceleracion = calcular_impulso(500.0, 50.0)
print($"Aceleración resultante: {aceleracion} m/s²")
```

---

#### B. Módulo en C++ Nativo (`vector_math.hpp`)
Crea el manifiesto `smile.json` con `"language": "cpp"`, `"entry_point": "vector_math.hpp"`:
```cpp
// modules/mi-modulo-cpp/vector_math.hpp
#pragma once
#include <cmath>

namespace vector_math {
    struct Vec2 {
        double x, y;
        inline double length() const { return std::sqrt(x * x + y * y); }
        inline Vec2 normalized() const {
            double len = length();
            return len > 0 ? Vec2{x / len, y / len} : Vec2{0, 0};
        }
    };
}
```

---

#### C. Módulo en Python / PyLoop (`ia_helper.py`)
Crea el manifiesto `smile.json` con `"language": "python"`, `"entry_point": "ia_helper.py"`:
```python
# modules/mi-ia/ia_helper.py
def init_module(vars_dict=None):
    return True

def predecir_trayectoria(pos_x, vel_x, tiempo):
    return pos_x + (vel_x * tiempo)
```
Consúmelo en Looping:
```looping
use python "modules/mi-ia/ia_helper.py"

val destino = mi_ia.predecir_trayectoria(100.0, 25.0, 4.0)
print($"Destino predicho: {destino}")
```

---

### 4. ¿Cómo Resuelve Looping los Módulos en el Disco?

Cuando ejecutas `./bin/looping mi_script.loop` y el script contiene `use module "mi-super-modulo"` o `import "mi-super-modulo"`, el motor realiza esta búsqueda automática en cascada **sin necesidad de internet ni CLI**:

1. **Directorio Local de Módulos**: Busca `./modules/mi-super-modulo/smile.json`.
   * Si existe, lee el campo `"entry_point"` (por ejemplo `"main.loop"`).
   * Carga y ejecuta directamente `./modules/mi-super-modulo/main.loop`.
2. **Fallback Local**: Si no hay `smile.json`, busca `./modules/mi-super-modulo/mi-super-modulo.loop` o `./modules/mi-super-modulo/main.loop`.
3. **Caché Global de Usuario**: Si no está en el proyecto local, busca en `~/.smiledev/modules/mi-super-modulo/smile.json`.

---

### 5. Empaquetado Manual para Compartir

Si deseas compartir tu módulo con otro desarrollador sin usar `smiledev pack`:

```bash
# 1. Navega a la carpeta de módulos
cd modules/

# 2. Crea el archivo .tar.gz estándar
tar -czf mi-super-modulo-v1.0.0.tar.gz -C mi-super-modulo .

# 3. Calcula el hash SHA-256 para verificación
shasum -a 256 mi-super-modulo-v1.0.0.tar.gz > mi-super-modulo-v1.0.0.tar.gz.sha256
```

El receptor solo debe descomprimir el archivo dentro de su propia carpeta `modules/mi-super-modulo/`.

---

### 6. Verificación Manual con `smiledev validate`

Si tienes la CLI instalada y quieres comprobar que tu módulo manual cumple con todas las especificaciones antes de subirlo:

```bash
smiledev validate ./modules/mi-super-modulo
```

---

### 7. Publicación Manual vía API REST (con CS ID)

### 4. Módulos Híbridos Políglotas (Multi-Componente en 4 Lenguajes a la Vez)

Looping Engine y smiledev soportan la arquitectura **Híbrida Políglota** (`"language": "hybrid"`). Un solo módulo puede declarar y coordinar sub-archivos implementados en **Looping**, **C++17**, **Python** y **Node.js** simultáneamente.

#### Ejemplo de Estructura de Carpetas (`csid-login-button`):
```text
modules/csid-login-button/
├── smile.json                   # Manifiesto con "language": "hybrid"
├── main.loop                    # Orquestador principal
├── README.md
└── components/
    ├── csid_button.loop         # 1. UI Reactiva y máquina de estados (Loop)
    ├── csid_crypto.hpp          # 2. Criptografía PKCE y SHA-256 nativa (C++17)
    ├── csid_oauth.py            # 3. Verificación de claims y JWT (Python)
    └── csid_window.js           # 4. Callback bridge y runtime interactivo (Node.js)
```

#### Manifiesto `smile.json`:
```json
{
  "name": "csid-login-button",
  "version": "1.0.0",
  "language": "hybrid",
  "entry_point": "main.loop",
  "author_name": "Coki Studios Security & Identity",
  "description": "Componente híbrido políglota para inicio de sesión con CS ID (Loop + C++ + Py + Node).",
  "license": "MIT",
  "components": {
    "loop": "components/csid_button.loop",
    "cpp": "components/csid_crypto.hpp",
    "python": "components/csid_oauth.py",
    "node": "components/csid_window.js"
  },
  "subfiles": [
    "components/csid_button.loop",
    "components/csid_crypto.hpp",
    "components/csid_oauth.py",
    "components/csid_window.js"
  ]
}
```

#### Cómo consumirlo en cualquier script `.loop`:
```looping
use "csid-login-button"

// 1. Renderiza el botón visualmente
csid_login_render(100, 100, "Conectar con CS ID")

// 2. Dispara el flujo de autenticación híbrido (C++ PKCE + Py OAuth + Node Bridge + Looping UI)
val user = csid_login_trigger_auth("Jerix Ortiz", "jerix@cokistudios.com")
out($"Usuario verificado: {user['name']} ({user['email']})")
```

---

Si deseas publicar tu módulo manualmente sin la CLI, puedes hacer una petición HTTP POST directa con `curl` al registro de LoopModules:

```bash
curl -X POST "https://ayxklxciqgqeyuzkziov.supabase.co/rest/v1/loop_modules" \
  -H "apikey: <TU_SUPABASE_ANON_KEY>" \
  -H "Authorization: Bearer <TU_SUPABASE_ANON_KEY>" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates" \
  -d '{
    "name": "mi-super-modulo",
    "version": "1.0.0",
    "language": "loop",
    "author_name": "Mi CS ID",
    "description": "Mi primer módulo manual",
    "entry_point": "main.loop",
    "code_payload": "define module \"mi-super-modulo\" version 1.0:\n    fn hello() => \"Hola\"",
    "license": "MIT"
  }'
```

O aún más fácil: **usa el nuevo Web GUI de smiledev en [`smiledev.html`](../smiledev.html)** para arrastrar tu carpeta o pegar tu código y subirlo autenticándote directamente con tu **CS ID** en un clic.

---
*© 2026 Coki Studios & Holo Entertainment. Ecosistema Abierto y Universal.*
