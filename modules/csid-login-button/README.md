# 🔐 csid-login-button (Módulo Híbrido Políglota)

> **Módulo Oficial de Autenticación Universal CS ID para Looping Engine**  
> *Arquitectura Multi-Componente de smiledev (Looping + C++17 + Python + Node.js)*  
> *Coki Studios Identity & Holo Entertainment © 2026*

---

## 🌟 ¿Qué es este módulo?

`csid-login-button` es el primer **módulo híbrido de 4 lenguajes** diseñado para el ecosistema Looping. En lugar de limitarse a un solo lenguaje, utiliza sub-archivos especializados para aprovechar lo mejor de cada tecnología:

```text
modules/csid-login-button/
├── smile.json                       # 📄 Manifiesto políglota ("language": "hybrid")
├── main.loop                        # 🚀 Orquestador unificado de punto de entrada
├── README.md                        # 📖 Documentación técnica
└── components/                      # 📂 Sub-archivos especializados
    ├── csid_button.loop             # 🟢 UI Button reactivo y máquina de estados
    ├── csid_crypto.hpp              # 🔵 Generador nativo C++17 de PKCE y SHA-256 S256
    ├── csid_oauth.py                # 🟡 Verificador de claims JWT y OAuth en Python
    └── csid_window.js               # 🌐 Servidor local de callback y ventana en Node.js
```

---

## 🧩 Componentes y Responsabilidades

| Componente | Lenguaje | Archivo | Responsabilidad |
| :--- | :---: | :--- | :--- |
| **Interfaz & Estado** | 🟢 Looping | `components/csid_button.loop` | Renderizado declarativo del botón, transiciones de estado (`IDLE` ➔ `AUTHENTICATING` ➔ `AUTHENTICATED`) y feedback háptico/audio. |
| **Criptografía PKCE** | 🔵 C++17 | `components/csid_crypto.hpp` | Generación de entropía para el `code_verifier`, cálculo de `code_challenge` S256 y tokens anti-CSRF sin overhead. |
| **OAuth & Claims** | 🟡 Python | `components/csid_oauth.py` | Verificación de claims JWT, cálculo de expiración de sesión y construcción de la URL de autorización de CS ID. |
| **Callback & Window** | 🌐 Node.js | `components/csid_window.js` | Inicio del micro-servidor local de loopback (`localhost:8089/callback`) para capturar el código de retorno del navegador. |
| **Orquestador Central** | 🟢 Looping | `main.loop` | Punto de entrada unificado que expone la API pública al desarrollador. |

---

## 🚀 Uso en tu Proyecto

### 1. Consumir desde Looping

```looping
// mi_app.loop
use "csid-login-button"

// 1. Inicializar
csid_login_init()

// 2. Renderizar el botón en pantalla
val label = csid_login_render(100, 150, "Iniciar Sesión con CS ID")

// 3. Simular clic de usuario
val user = csid_login_trigger_auth("Jerix Ortiz", "jerix@cokistudios.com")

print($"Usuario activo: {user[\"name\"]} | Estado: {user[\"verified\"]}")
```

### 2. Probar la Demo Interactiva

```bash
./bin/looping run sample_loop_projects/demo_csid_hybrid_button.loop
```

---

## 📋 Manifiesto `smile.json` Híbrido

```json
{
  "name": "csid-login-button",
  "version": "1.0.0",
  "language": "hybrid",
  "entry_point": "main.loop",
  "components": {
    "loop": "components/csid_button.loop",
    "cpp": "components/csid_crypto.hpp",
    "py": "components/csid_oauth.py",
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

---
*© 2026 Coki Studios & Holo Entertainment*
