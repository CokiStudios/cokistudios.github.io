# Coki Account Manager iOS App — SwiftUI Native Client

Este directorio contiene el código fuente nativo en **SwiftUI** para la aplicación iOS de **Coki Account Manager (CS ID Manager)**, el gestor de cuentas de Coki Studios.

## Estructura del Código

Todos los archivos están desarrollados en Swift nativo y optimizados para compilar sin dependencias externas:

1. **[CokiAccountManagerApp.swift](file:///Users/jerix/cokistudios.github.io/CokiAccountManager.iOS/CokiAccountManagerApp.swift)**: Punto de entrada del ciclo de vida de la aplicación.
2. **[ContentView.swift](file:///Users/jerix/cokistudios.github.io/CokiAccountManager.iOS/ContentView.swift)**: Panel de control de la cuenta que permite editar el perfil (nombre y empresa) en tiempo real, visualizar estadísticas y listar o revocar aplicaciones conectadas (RPC).
3. **[CokiTheme.swift](file:///Users/jerix/cokistudios.github.io/CokiAccountManager.iOS/CokiTheme.swift)**: Sistema de diseño unificado de Coki Studios ID (fondo oscuro `#06090f`, acentos índigo y morado, botones e inputs interactivos).
4. **[Models.swift](file:///Users/jerix/cokistudios.github.io/CokiAccountManager.iOS/Models.swift)**: Estructuras de datos decodificables (`CokiUser`, `ConnectedApp`, `OAuthClient`).
5. **[SupabaseManager.swift](file:///Users/jerix/cokistudios.github.io/CokiAccountManager.iOS/SupabaseManager.swift)**: Gestor de conexiones que implementa REST Auth (Login, Registro con redirección), OAuth seguro (Google y GitHub) usando `ASWebAuthenticationSession` y llamadas REST para consultar bases de datos e invocar el RPC `revoke_app`.
6. **[LoginView.swift](file:///Users/jerix/cokistudios.github.io/CokiAccountManager.iOS/LoginView.swift)**: Formulario interactivo de login/registro (con campo de empresa) y botones para Google/GitHub que omiten el aviso de cancelación manual.

---

## Cómo Integrar y Ejecutar en Xcode

### Paso 1: Crear el proyecto en Xcode
1. Abre **Xcode** en tu Mac.
2. Ve a **File > New > Project...** y selecciona la plantilla **App** bajo la pestaña de **iOS**.
3. Rellena los datos:
   * **Product Name**: `CokiAccountManager`
   * **Organization Identifier**: `com.cokistudios`
   * **Interface**: `SwiftUI`
   * **Language**: `Swift`
4. Guarda el proyecto.

### Paso 2: Importar los archivos
1. Elimina los archivos `ContentView.swift` y `CokiAccountManagerApp.swift` (o la que tenga el atributo `@main`) generados por defecto en Xcode.
2. Arrastra y suelta todos los archivos `.swift` de este directorio (`CokiAccountManager.iOS/`) dentro de tu proyecto en Xcode.
3. Asegúrate de marcar la casilla **"Copy items if needed"** al importarlos.

### Paso 3: Configurar URL Scheme para Google y GitHub (OAuth)
Para que los inicios de sesión sociales puedan redirigir correctamente de vuelta al gestor de cuentas:
1. En Xcode, selecciona el nodo raíz de **CokiAccountManager** en la barra lateral izquierda.
2. Selecciona el target de tu aplicación y ve a la pestaña **Info** (al lado de *Build Settings*).
3. Desplázate hacia abajo del todo hasta la sección **URL Types** y haz clic en el botón **+**.
4. Rellena los campos:
   * **Identifier**: `com.cokistudios.id`
   * **URL Schemes**: `coki`
5. *Nota adicional: Asegúrate de registrar `coki://oauth` en la sección "Redirect URLs" de tu Supabase Dashboard para habilitar la redirección.*

### Paso 4: Compilar y Ejecutar
1. Selecciona un simulador en la barra superior.
2. Presiona `Cmd + R` para construir e iniciar la aplicación.
