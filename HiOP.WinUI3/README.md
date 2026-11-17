# hiOP Studio — WinUI 3 Native (`HiOP.WinUI3`)

Aplicación nativa **WinUI 3 (Windows App SDK 1.8 / Fluent 2 / Mica)** de **hiOP Studio** para Windows 10 y Windows 11, alineada con **Looping v1.1 / Alpha! 1.1A / Architecture 3.0A** y el ecosistema de [Coki Studios](https://cokistudios.github.io).

## Características Principales

- **IDE Studio Nativo**: Explorador del workspace, pestañas múltiples, editor monoespacio con numeración sincronizada e indentación Tab/F5/Ctrl+S, inspector en vivo de **AST**, verificación estática (**Check**), extracción políglota (**C# `cs!` + Python `pysnippet`**) y consola integrada.
- **Quantum 3D & 2D Live Stage (`WebView2`)**: Ejecución en tiempo real de gráficos 3D (`spawn3d`, Wavefront `.obj`, `loopize++`, `CSharpMiniVM`) y 2D con `LoopingEngine/looping_core.js`.
- **Toolchain Arch 3.0A**: Compilación binaria **Invis. Compile (`LPBN v3.0A`)**, formateador (`FMT`), transpilador declarativo **SwiftUI / Component 2 (`.c2`)**, `bench`, `test`, `compile --target` (`shine_ui`, `xui`, `flui`) y diagnóstico **Doctor** de subsistemas Windows.
- **Smiledev Nativo + Descargador Directo de Paquetes**:
  - Consulta en vivo **LoopModules (Supabase PostgreSQL REST)**, índices HTTP (`index.json` / `registry.json`), directorios HTTP directos (`smile.json`), repositorios **GitHub Raw** y carpetas locales.
  - Descarga, verifica e instala paquetes `.tar.gz` (`System.Formats.Tar` + `GZipStream`), `.zip`, bundles JSON multi-archivo y subarchivos en `./modules` y `~/.smiledev/modules`, actualizando `./smile.json` y detectando dependencias faltantes.
  - Creador, validador estricto y empaquetador `.tar.gz` con publicación directa en LoopModules.
- **Actualizador y Auto-Updater**: Consulta `engine/latest.json` (`raw.githubusercontent.com`, `repo.cokistudios.com/engine`, `cokistudios.github.io/engine`) y GitHub Releases, cambia canales (`prod`, `omega`, `alpha` / `1.1A`) en `~/.smiledev/channel`, sincroniza WebCore/Smiledev/Engine y soporta auto-actualización de paquetes Windows de la app con verificación **SHA-256**.
- **CS ID & Configuración**: Inicio de sesión PAT compartido con `~/.smiledev/auth.json`, selector de carpeta workspace y materiales `Mica Alt`, `Mica` y `Desktop Acrylic`.

## Compilación

Requiere **.NET 8 SDK / .NET 10 SDK**, **Windows 10/11 SDK (`10.0.26100.0`)** y restauración NuGet de `Microsoft.WindowsAppSDK`:

```powershell
dotnet restore HiOP.WinUI3.csproj -p:Platform=x64
dotnet build HiOP.WinUI3.csproj -c Release -p:Platform=x64 --no-restore
```
