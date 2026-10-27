# 📦 Looping Modules Directory (`./modules`)

Bienvenido al directorio de módulos del ecosistema **Looping & Loop OS**, gestionado por **`smiledev`**.

---

## 🌟 Módulos Oficiales Incluidos

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

## ⚡ Comandos Rápidos con `smiledev`

```bash
# Listar módulos instalados
smiledev list

# Instalar un nuevo módulo desde la nube
smiledev install <nombre-modulo>

# Desinstalar un módulo
smiledev uninstall <nombre-modulo>

# Inicializar un nuevo módulo
smiledev init mi-modulo --lang loop

# Probar un módulo
smiledev test loop-core-utils

# Ver información detallada
smiledev view loop-core-utils
```

Para consultar la documentación completa de `smiledev`, revisa [`SMILEDEV_README.md`](../SMILEDEV_README.md).

---
*© 2026 Coki Studios & Holo Entertainment*
