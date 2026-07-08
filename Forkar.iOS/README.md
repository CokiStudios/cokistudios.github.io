# Forkar iOS App — SwiftUI Native Client

Este directorio contiene el código fuente nativo en **SwiftUI** para la aplicación iOS de **Forkar**, la comunidad de Coki Studios.

## Estructura del Código

Todos los archivos están optimizados para compilar sin dependencias de terceros externas (utilizan la API REST de Supabase directamente sobre `URLSession` de Apple):

1. **[ForkarApp.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ForkarApp.swift)**: Punto de entrada de la aplicación de iOS.
2. **[ContentView.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ContentView.swift)**: Vista contenedora principal con barra de pestañas (Tab Bar) y configuración visual premium.
3. **[ForkarTheme.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ForkarTheme.swift)**: Sistema de diseño (colores hex, gradientes, tarjetas glassmorphic, modificadores de estilo y botones interactivos).
4. **[Models.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/Models.swift)**: Modelos de datos decodificables (`Post`, `Category`, `Comment` y extensiones de color).
5. **[SupabaseManager.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/SupabaseManager.swift)**: Gestor de conexiones. Implementa autenticación (Login/Registro/Cierre de sesión), consultas filtradas (Posts, Categorías, Comentarios) y mutaciones de datos (Likes, Seguidores, Posts, Comentarios).
6. **[LoginView.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/LoginView.swift)**: Formulario interactivo y animado de login/registro nativo.
7. **[HomeView.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/HomeView.swift)**: Feed principal con barra de búsqueda reactiva, pills de categorías horizontales, post cards personalizadas y botón flotante de publicación.
8. **[PostDetailView.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/PostDetailView.swift)**: Detalle del post completo con botón de me gusta (Like), seguir al autor (Follow), listado de comentarios y barra inferior para escribir nuevos comentarios.
9. **[CreatePostView.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/CreatePostView.swift)**: Selector de categorías horizontal, campo de entrada para título y editor de texto para contenido.
10. **[ProfileView.swift](file:///Users/jerix/cokistudios.github.io/Forkar.iOS/ProfileView.swift)**: Perfil de usuario con avatar, estadísticas nativas de seguidores/siguiendo/publicaciones y listado dinámico de posts del usuario logueado.

---

## Cómo Integrar y Ejecutar en Xcode

Sigue estos pasos para compilar la aplicación en tu simulador de iOS o dispositivo físico:

### Paso 1: Crear el proyecto en Xcode
1. Abre **Xcode** en tu Mac.
2. Haz clic en **File > New > Project...** (o selecciona `Create New Project` en la pantalla de bienvenida).
3. Selecciona **iOS** y elige la plantilla **App**. Presiona *Next*.
4. Configura los detalles del proyecto:
   * **Product Name**: `Forkar`
   * **Organization Identifier**: `com.cokistudios`
   * **Interface**: `SwiftUI`
   * **Language**: `Swift`
5. Guarda el proyecto en tu máquina.

### Paso 2: Importar los archivos de Forkar
1. En Xcode, expande la carpeta principal en el navegador del proyecto (a la izquierda).
2. **Elimina** los archivos por defecto:
   * `ContentView.swift`
   * `ForkarApp.swift` (o la que tenga el atributo `@main`)
3. Arrastra y suelta todos los archivos `.swift` de este directorio (`Forkar.iOS/`) dentro de tu proyecto en Xcode.
4. Asegúrate de marcar **"Copy items if needed"** y verificar que tu target `Forkar` esté seleccionado en la casilla de Target Membership.

### Paso 3: Compilar y Ejecutar
1. Selecciona un Simulador (por ejemplo, *iPhone 15* o *iPhone 16*) en la parte superior central de Xcode.
2. Presiona el botón de **Run** (el triángulo de Play) o presiona `Cmd + R` en tu teclado.
3. ¡Listo! Verás la app nativa de Forkar iniciándose con un diseño premium en modo oscuro y cargando datos reales de la base de datos de Supabase.

### Paso 4: Configurar URL Scheme para Google y GitHub (OAuth)
Para que los inicios de sesión con Google y GitHub puedan redirigir de vuelta a la aplicación de forma segura:
1. En Xcode, selecciona la raíz del proyecto **Forkar** en la barra lateral izquierda.
2. Selecciona el target de tu aplicación y ve a la pestaña **Info** (al lado de *Build Settings*).
3. Desplázate hacia abajo del todo hasta la sección **URL Types** y haz clic en el botón **+** para expandirla.
4. Rellena los campos:
   * **Identifier**: `com.cokistudios.forkar`
   * **URL Schemes**: `forkar`
   * **Role**: `Viewer` (o déjalo en blanco/Editor)
5. Al pulsar "Continuar con Google" o "GitHub", se iniciará una sesión web segura (`ASWebAuthenticationSession`) y te devolverá a la app guardando el perfil.
