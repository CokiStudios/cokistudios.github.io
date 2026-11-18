# hiOP Studio & hiOP Builder (`HiOP.Apple`)

Port nativo multiplataforma en **SwiftUI + C++17 (`CLoopingStageCore`) + Assembly (`ARM64/x86_64`)** de **hiOP Studio** (`HiOP.WinUI3`) para **macOS** y **iPadOS**, sin WebView y sin Python.

## Targets incluidos en `HiOPApple.xcodeproj`

1. **`HiOPStudio` (macOS + iPadOS)**:
   - IDE Studio con plantillas Arch 3.1A, apertura de archivos, editor monoespacio, inspector AST/diagnósticos y consola en vivo.
   - **Quantum Stage Nativo**: Renderizado 3D Z-Buffer y 2D ASM directo a `CGImage` a 60 FPS con controles táctiles y botones interactivos.
   - **Toolchain 3.1A**: Doctor, SelfTest C++17, Benchmark VM e Invis Compile (`LPBN v3.0A`).
   - **Smiledev & Actualizaciones**: Conexión en vivo a `repo.cokistudios.com/modules` y `engine.cokistudios.com/latest.json`.

2. **`HiOPBuilder` (iPadOS + macOS — Programación por Bloques)**:
   - Constructor visual por bloques con categorías (`Programa & Lógica`, `Ventana & UI`, `Juego 2D`, `Quantum 3D`, `Ecosistema CS`), parámetros editables en línea, bloques anidados (`Repetir`, `Si`), kits iniciales y compilador en vivo a `.loop` ejecutado al instante en `CLoopingStageCore`.

## Verificación

```bash
swift test --package-path HiOP.Apple/Packages/HiOPCore
xcodebuild -project HiOP.Apple/HiOPApple.xcodeproj -scheme HiOPStudio -destination 'platform=macOS' build
xcodebuild -project HiOP.Apple/HiOPApple.xcodeproj -scheme HiOPBuilder -destination 'generic/platform=iOS Simulator' build
```
