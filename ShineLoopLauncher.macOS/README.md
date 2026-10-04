# 🌟 Holo Loop OS — Launcher Nativo para Shine Loop Console

> **Launcher y Dashboard Oficial para la consola portátil Shine Loop (Shine Poortloop)**  
> Desarrollado por **Holo Entertainment** & **Coki Studios**

---

## 🎮 1. Visión General del Sistema y la Consola

**Holo Loop OS** es el sistema operativo para videojuegos de ultra baja latencia diseñado exclusivamente para la consola portátil **Shine Loop** (factor de forma Handheld estilo Steam Deck / Nintendo Switch).

Este lanzador nativo para macOS implementa la interfaz visual completa de la consola con gráficos acelerados por Metal, shaders glassmorphism **Frosted Aqua A17**, soporte nativo de mandos físicos (`GCController`) y ejecución directa del motor de compilación nativo C++ de Looping (`bin/looping`).

```
+-------------------------------------------------------------------------+
|                  SHINE LOOP CONSOLE // HOLO LOOP OS 1.0                 |
|                                                                         |
|  [SHINE LOOP OS]  [Angel Helium 💎]     (• Bubbly Dot •)    98% ⚡ 120Hz |
+-------------------------------------------------------------------------+
|                                                                         |
|     [ ◀ ]    [🎮 Holo Arcade 2D]   [🏎️ Forkar 3D]   [⚡ hiOP]    [ ▶ ]  |
|               (60 FPS V-SYNC)       (HOLO 3D MESH)   (MONACO)          |
|                                                                         |
|  ─────────────────────────────────────────────────────────────────────  |
|  🎮 HOLO ARCADE 2D                  ESPECIFICACIONES                    |
|  Plataformero 2D retro optimizado   • Motor: Looping 2D Sprite Core     |
|  con física cuántica a 60Hz.        • Resolución: 1280x800 @ 60 FPS     |
|                                     • Audio: Square Tone DSP            |
|  [▶ INICIAR JUEGO (Botón A)]        • Jugadores: 1P Local               |
+-------------------------------------------------------------------------+
|  🎮 [◀ ▶] Seleccionar  [A] Iniciar  [B] Volver  [X] Cuadrícula  [Tab] Ajustes|
+-------------------------------------------------------------------------+
```

---

## 🚀 2. Características Principales

### 💎 Diseño Visual Frosted Aqua A17
- Interfaz con desenfoque de cristal ultra-fino, reflejos dinámicos y auras de neón que reaccionan al juego o aplicación seleccionada.
- Relación de aspecto de consola portátil **16:10** nativa (1280x800).
- Modo opcional de **Chasis Físico (Handheld Bezel)**: Enmarca la pantalla dentro del cuerpo físico de la consola portátil Shine Loop, con joysticks analógicos, cruceta direccional, botones ABXY iluminados, gatillos L1/R1 y rejillas de altavoces estéreo.
- Filtro opcional **Scanlines CRT Retro** para emular la rejilla de fósforo de las pantallas arcade clásicas.

### 🫧 Bubbly Dot (Dynamic Notch de Coki Studios)
- Isla dinámica animada en la parte superior central.
- Muestra el estado activo del kernel, tasa de refresco, juego en primer plano o proceso C++ en ejecución.
- Al hacer clic o presionar **[Y]**, se expande mostrando detalles de energía, sonido y asistente.

### 🔊 Sintetizador de Audio por Hardware (Tone DSP)
- Generación de formas de onda en tiempo real (16-bit PCM WAV en memoria) reproduciendo fielmente la directiva del lenguaje Looping:
  ```loop
  play tone at 587 Hz for 70 ms
  play tone at 880 Hz for 90 ms
  ```
- Sonidos táctiles de navegación (`playNavTick`), confirmación de inicio de juego (`playLaunchChime`), retroceso (`playBackTick`) y arpegio de arranque oficial.

### 🕹️ Soporte Completo de Gamepad y Teclado
- **Mandos Físicos (`GameController` / `GCController`)**:
  - D-Pad / Stick Analógico Izquierdo: Navegación horizontal y vertical fluida con zona muerta calibrada.
  - Botón A: Iniciar juego / Seleccionar.
  - Botón B: Volver / Cerrar juego en ejecución.
  - Botón X: Alternar entre Carrusel 3D y Cuadrícula.
  - Botón Y: Abrir / Alternar Bubbly Dot.
  - Gatillos L1 / R1: Cambiar categoría de aplicaciones.
  - Botón Menu / Options: Abrir panel de Ajustes de la consola.
- **Teclado**:
  - `◀ / ▶ / ▲ / ▼` o `W / A / S / D`: Mover selector.
  - `Enter` o `Espacio`: Iniciar.
  - `Escape`: Atrás.
  - `X`: Alternar vista.
  - `Y`: Bubbly Dot.
  - `Tab`: Ajustes.
  - `T`: Conmutar Overclock Turbo (120 Hz).

### ⚡ Ejecución en Tiempo Real de Proyectos Looping
- Al seleccionar y pulsar **"INICIAR JUEGO"**, el launcher ejecuta de forma asíncrona `./bin/looping <script.loop>` con streaming en vivo de `stdout` y `stderr`.
- Pantalla HUD en tiempo real con cronómetro de latencia (sub-milisegundos) y terminal de diagnóstico coloreado (`[OK]`, `[UI]`, `[ENTITY]`, `[PYTHON INTEROP]`, `[OUTPUT]`).

### ⚙️ Telemetría y Overclock del Sistema
- Medidores en vivo:
  - Batería: 98% ⚡ con animación de carga.
  - APU Quad-Core Zen: Gráfica de porcentaje de carga en tiempo real.
  - Wi-Fi 5G: Latencia de enlace (8ms).
  - Almacenamiento NVMe: LoopFS v2.0 (64.2 GB usados de 512 GB).
  - Perfiles de energía: **Eco (30 FPS)**, **Equilibrado (60 FPS)** y **Turbo Overclock (120 FPS)**.

---

## 📦 3. Catálogo de Juegos y Aplicaciones Incluidas

1. 🎮 **Holo Arcade 2D** (`sample_loop_projects/arcade.loop`)
   - Plataformero 2D retro con física de 60Hz y sprites cuánticos.
2. 🏎️ **Forkar Racing 3D** (`forkar.html` / `Forkar.app`)
   - Carreras cyberpunk en gravedad cero de Neo-Coki con física 3D y multijugador local.
3. ⚡ **hiOP Studio IDE** (`hiOP.macOS` / `hiop-ide.html`)
   - Entorno de desarrollo para código Looping con motor Monaco integrado y compilador C++.
4. ♾️ **CyberShine Core v2.5** (`sample_loop_projects/signature_demo.loop`)
   - Demostración de las novedades del lenguaje: pipelines `|>`, arrow functions `->`, bucles `loop (N)`, tipado `val/mut`, macro `py!` y audio DSP.
5. 🐍 **Python Interop Bridge** (`sample_loop_projects/python_interop_demo.loop`)
   - Enlace zero-copy con NumPy, SciPy y modelos de Machine Learning.
6. 🦀 **Ruuping Rust Core** (`sample_loop_projects/ruuping_demo.ruup`)
   - Motor de rendimiento en Rust a 1.4 millones de operaciones por segundo y 0.12ms de latencia.
7. 💬 **CSMS Encrypted Chat** (`messenger.html`)
   - Chat de voz para grupos protegido por cifrado por hardware (Secure Enclave / T2).
8. ⚙️ **Ajustes y Hardware de la Consola**
   - Configuración de resolución, DSP de audio, mapeo de mandos y almacenamiento NVMe.

---

## 🛠️ 4. Compilación y Ejecución

### Opción A: Script Automático
Desde la raíz del repositorio:
```bash
./run_launcher.sh
```

### Opción B: Con Xcode o xcodebuild
```bash
xcodebuild -project ShineLoopLauncher.macOS/ShineLoopLauncher.xcodeproj \
           -scheme ShineLoopLauncher \
           -configuration Release \
           -derivedDataPath ShineLoopLauncher.macOS/build \
           build CODE_SIGNING_ALLOWED=NO
```

La aplicación compilada estará disponible en:
`ShineLoopLauncher.macOS/build/Build/Products/Release/ShineLoopLauncher.app`
