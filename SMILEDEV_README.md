# 🌟 smiledev — The Official Looping Universal Package Manager
> **Looping Commercial Production Edition v1.0.0 (Architecture 2.8A)** • *Coki Studios & Holo Entertainment © 2026*  
> *Target Ecosystem: Looping Engine • Loop OS • Shine Console • macOS / Linux / POSIX*

---

## 📖 ¿Qué es smiledev?

**`smiledev`** es el gestor oficial de paquetes, módulos y dependencias del lenguaje de programación **Looping** y del ecosistema **Loop OS**.

Diseñado bajo la filosofía **Universal Multiplatform**, `smiledev` permite a desarrolladores crear, empaquetar, compartir, enlazar y publicar módulos políglotas en:
* 🟢 **Looping Puro (`.loop`)**: Módulos nativos interpretados con tipado dinámico, sintaxis de flecha `=>`, pipelines `|>` y cero dependencias externas.
* 🟡 **Python / PyLoop (`.py`)**: Interoperabilidad bidireccional con librerías de IA, requests HTTP y machine learning.
* 🔵 **C++ Nativo (`.hpp`)**: Cabeceras de alto rendimiento compiladas directamente para el subsistema APU y gráficos nativos.
* 🟣 **C2 Declarativo (`.c2`)**: Componentes de interfaz gráfica reactiva para perfiles Shine UI, XUI (240Hz Direct-to-Vulkan) y flUI (pantallas plegables).
* 🌐 **Híbrido Políglota (`hybrid`)**: Módulos multi-componente que coordinan subarchivos en Looping, C++17, Python y Node.js simultáneamente (ejemplo: `csid-login-button`).

Respaldado por el registro en la nube **LoopModules** (PostgreSQL / Supabase) con autenticación universal mediante **CS ID** (Coki Studios Identity).

---

## ⚡ Instalación y Actualización

### 1. Vía Homebrew (Recomendado en macOS)
```bash
# Agregar el tap oficial de Coki Studios
brew tap cokistudios/tap

# Instalar el motor Looping y el gestor smiledev
brew install looping smiledev

# Actualizar a la versión más reciente (v2.8.0)
brew update
brew upgrade smiledev looping
```

### 2. Vía Script de Instalación Directo (macOS / Linux)
```bash
curl -fsSL https://repo.cokistudios.com/engine/install.sh | bash
```

### 3. Verificación de Salud con Doctor
```bash
smiledev doctor
```
Verifica la presencia del ejecutable C++ `looping`, la versión de la CLI, el compilador `clang++`, la versión de Python, el estado del tap de Homebrew y la conectividad con el registro en la nube.

---

## 🔍 Arquitectura del Sistema de Módulos

El motor Looping (`looping`) y `smiledev` resuelven módulos de manera inteligente siguiendo un orden de precedencia estricto:

```
[Import en Looping: use "loop-core-utils" ó import "math"]
                    │
                    ▼
     ¿Es módulo built-in del Stdlib?
     (math, crypto, sys, csv, datetime, regex, ui, swiftui, json, file)
     ├── SÍ ──► Enlaza funciones internas en C++17 (<0.01 ms)
     └── NO
          │
          ▼
     1. Ruta relativa directa o archivo en directorio actual (./modulo, ./modulo.loop)
     2. Manifiesto local: ./modules/<nombre>/smile.json ──► Extrae "entry_point"
     3. Fallback local: ./modules/<nombre>/<nombre>.loop ó main.loop
     4. Módulos de motor heredados: ./loop_modules/<nombre>.loop
     5. Manifiesto global: ~/.smiledev/modules/<nombre>/smile.json
     6. Fallback global: ~/.smiledev/modules/<nombre>/main.loop
     7. Python Bridge: ./modules/<nombre>/<nombre>.py ó main.py
```

Al resolver un archivo `.loop`, el motor ejecuta automáticamente las definiciones del módulo en el entorno del intérprete, haciendo disponibles sus funciones y variables de inmediato.

---

## 🛠️ Referencia de Comandos CLI

| Comando | Descripción | Ejemplo |
| :--- | :--- | :--- |
| `smiledev install [modulo]` | Instala un módulo del registro o resuelve todas las `dependencies` de `smile.json` | `smiledev install loop-core-utils` |
| `smiledev uninstall <modulo>` | Desinstala un módulo local (`./modules`) o global (`--global`) | `smiledev uninstall loop-gui-tk` |
| `smiledev update [modulo]` | Actualiza un módulo, todos los locales (`--all`) o el motor (`--self`) | `smiledev update --all` |
| `smiledev list` | Lista los módulos locales (`./modules`) y globales (`~/.smiledev/modules`) | `smiledev list` |
| `smiledev search <query>` | Busca módulos en la nube de LoopModules por nombre o palabra clave | `smiledev search gui` |
| `smiledev view <modulo>` | Muestra información detallada (autor, versión, lenguaje, entry point) | `smiledev view loop-math-3d` |
| `smiledev init <nombre> [--lang]` | Inicializa un nuevo módulo con manifiesto, boilerplate, README y gitignore | `smiledev init mi-plugin --lang loop` |
| `smiledev pack [dir]` | Empaqueta un módulo en un archivo `.tar.gz` para distribución | `smiledev pack ./modules/mi-plugin` |
| `smiledev validate [dir]` | Verifica la integridad, formato de `smile.json` y archivos del módulo | `smiledev validate ./modules/mi-plugin` |
| `smiledev link [dir]` | Enlaza simbólicamente un módulo local en la caché global para desarrollo | `smiledev link ./modules/mi-plugin` |
| `smiledev unlink <nombre>` | Elimina el enlace simbólico del entorno global | `smiledev unlink mi-plugin` |
| `smiledev test [modulo]` | Ejecuta los tests del módulo usando el motor Looping | `smiledev test loop-core-utils` |
| `smiledev run <archivo\|modulo>` | Ejecuta un script o el punto de entrada de un módulo | `smiledev run mi-script.loop` |
| `smiledev doctor` | Diagnóstico completo del entorno, compilador, PATH y registro | `smiledev doctor` |
| `smiledev upgrade [--force]` | Actualiza automáticamente smiledev y Looping a la última versión | `smiledev upgrade` |
| `smiledev clean` | Limpia archivos temporales y caché de descargas | `smiledev clean` |
| `smiledev login [--token]` | Inicia sesión con un Personal Access Token (PAT) de CS ID | `smiledev login --token cs_pat_...` |
| `smiledev whoami` | Muestra la identidad del desarrollador autenticado | `smiledev whoami` |
| `smiledev logout` | Cierra la sesión activa en la máquina local | `smiledev logout` |
| `smiledev publish [dir]` | Publica el módulo en el registro LoopModules usando tu CS ID | `smiledev publish ./modules/mi-plugin` |
| `smiledev upload-module [dir]` | Alias para `publish` | `smiledev upload-module ./modules/mi-plugin` |

---

## 📋 Especificación del Manifiesto `smile.json`

Todo módulo de Looping incluye un archivo `smile.json` que define sus metadatos y dependencias:

```json
{
  "name": "loop-core-utils",
  "version": "1.1.0",
  "language": "loop",
  "entry_point": "core_utils.loop",
  "author_name": "Coki Studios Foundation",
  "description": "Colección de utilidades fundamentales escritas en sintaxis Loop pura.",
  "license": "MIT",
  "dependencies": {
    "loop-math-3d": "^1.2.0"
  }
}
```

### Campos:
* `name` *(string, requerido)*: Nombre único del módulo (ej. `mi-modulo`, minúsculas y guiones).
* `version` *(string, requerido)*: Versión semántica (ej. `1.0.0`).
* `language` *(string, requerido)*: Lenguaje del módulo: `"loop"`, `"python"`, `"cpp"`, `"c2"`.
* `entry_point` *(string, requerido)*: Archivo principal de ejecución (ej. `main.loop`, `plugin.py`, `header.hpp`).
* `author_name` *(string)*: Nombre o seudónimo del desarrollador u organización.
* `description` *(string)*: Breve resumen funcional del módulo.
* `license` *(string)*: Licencia de código abierto (`"MIT"`, `"Apache-2.0"`, etc.).
* `dependencies` *(object)*: Diccionario con nombres de otros módulos de smiledev requeridos.

---

## 💻 Guía de Desarrollo de Módulos Políglotas

### 1. Módulo en Looping Puro (`--lang loop`)
Crea funciones de utilidad o componentes en sintaxis `.loop`:
```looping
// modules/mi-util/main.loop
define module "mi-util" version 1.0:

fn saludo(nombre) => $"¡Hola, {nombre}! Bienvenido a Looping."

fn duplicar(x) => x * 2
```
Para consumirlo desde cualquier script:
```looping
use module "mi-util"

val mensaje = saludo("Alex")
print(mensaje)
print(duplicar(21))
```

### 2. Módulo en Python / PyLoop (`--lang python`)
Interopera de forma transparente con el ecosistema de Python:
```python
# modules/py-ai/main.py
def init_module(vars_dict=None):
    return True

def predecir_score(valor):
    return valor * 1.5 + 42
```
Consúmelo en Looping:
```looping
use python "modules/py-ai/main.py"

val prediccion = py_ai.predecir_score(10)
print($"Resultado IA: {prediccion}")
```

### 3. Módulo en C++ Nativo (`--lang cpp`)
Para cálculos matemáticos de máximo rendimiento:
```cpp
// modules/loop-physics/main.hpp
#pragma once

namespace loop_physics {
    inline double kinetic_energy(double m, double v) {
        return 0.5 * m * v * v;
    }
}
```

### 4. Módulo Declarativo C2 (`--lang c2`)
Componentes visuales multi-plataforma compilables para Shine UI, XUI y flUI:
```
component CyberDeckHUD {
    theme "cyber_neon_xui"
    pipeline "Direct-to-Vulkan"
    
    view TelemetryPanel {
        title: "FPS APU Monitor"
        refresh_rate: 240
    }
}
```

---

## 🔐 Autenticación y Publicación en LoopModules Cloud

1. Genera tu **Personal Access Token (PAT)** en la consola de desarrolladores:  
   👉 [https://cokistudios.github.io/developer](https://cokistudios.github.io/developer)
2. Inicia sesión en la terminal:
   ```bash
   smiledev login --token cs_pat_tu_token_aqui
   ```
3. Verifica tu estado:
   ```bash
   smiledev whoami
   ```
4. Publica tu módulo:
   ```bash
   smiledev upload-module ./modules/mi-plugin
   ```
El módulo pasará a estar disponible globalmente en la nube de LoopModules y cualquier usuario del mundo podrá instalarlo con:
```bash
smiledev install mi-plugin
```

---

## 🚀 Enlace Local para Desarrollo (`smiledev link`)

Si estás desarrollando un módulo localmente y quieres usarlo en múltiples proyectos sin publicarlo en la nube:
```bash
# Dentro de la carpeta del módulo:
cd ./modules/mi-plugin
smiledev link

# En tu otro proyecto:
smiledev list   # Aparecerá como (linked) en el entorno global
```
Para removerlo cuando termines:
```bash
smiledev unlink mi-plugin
```

---

## 🛠️ Creación de Módulos Manualmente (Sin el CLI de smiledev)

El motor nativo de Looping no exige el uso del CLI para utilizar o crear módulos. Puedes estructurar tus módulos a mano:

1. **Crea el directorio**: `./modules/<nombre-modulo>/` dentro de tu proyecto.
2. **Crea `smile.json`**:
   ```json
   {
     "name": "mi-modulo",
     "version": "1.0.0",
     "language": "loop",
     "entry_point": "main.loop",
     "author_name": "Tu Nombre",
     "description": "Módulo creado manualmente",
     "license": "MIT"
   }
   ```
3. **Crea tu código fuente** (ej. `main.loop`):
   ```looping
   define module "mi-modulo" version 1.0:
       fn saludar(usuario) => $"Hola {usuario} desde mi módulo manual!"
   ```
4. **Úsalo directamente en tu código**:
   ```looping
   use module "mi-modulo"
   print(saludar("Mundo"))
   ```
5. **Verifica la conformidad del manifiesto**:
   ```bash
   smiledev validate ./modules/mi-modulo
   ```

---

## 🌐 Web GUI de smiledev & Publicación con CS ID

Si prefieres una interfaz gráfica visual en lugar de la terminal, accede a **[`smiledev.html`](smiledev.html)**:
* **Explorador Visual de Módulos**: Busca e inspecciona módulos en tiempo real en la base de datos LoopModules.
* **Autenticación Universal con CS ID**: Inicia sesión con tu cuenta de Coki Studios directamente en el navegador.
* **Publicador Visual de Módulos**: Sube o edita código fuente, valida en vivo el manifiesto `smile.json` y publica módulos firmados con tu identidad CS ID en un solo clic.
* **Generador de Manifiestos**: Crea archivos `smile.json` visualmente con validación de sintaxis y recomendaciones de buenas prácticas.

---

*© 2026 Coki Studios & Holo Entertainment. Making the world Shine, together.*
