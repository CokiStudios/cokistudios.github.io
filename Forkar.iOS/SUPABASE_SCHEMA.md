# Esquema de Base de Datos Supabase & Mapeo Swift - Forkar

Este documento define la estructura oficial de las tablas de Supabase en PostgreSQL y su mapeo directo con los modelos de datos en Swift (`Models.swift`) y los métodos de API en `SupabaseManager.swift`.

---

## 1. Mapeo General de Tablas

| Tabla Supabase | Modelo Swift | Propósito Principal en Forkar | Archivos / Vistas Asociadas |
|---|---|---|---|
| `profiles` | `SupabaseUser` / `UserProfile` | Perfil de usuario, nombre, avatar y configuración de idioma. | `ProfileView.swift`, `SetupWizardView.swift`, `LoginView.swift` |
| `social_categories` | `Category` | Categorías temáticas para filtrar y clasificar publicaciones. | `HomeView.swift`, `CreatePostView.swift` |
| `social_posts` | `Post` | Publicaciones del feed social con conteo de likes y comentarios. | `HomeView.swift`, `PostDetailView.swift`, `ProfileView.swift` |
| `social_comments` | `Comment` | Comentarios en publicaciones. | `PostDetailView.swift` |
| `social_likes` | `SocialLike` | Registro de likes por usuario y post. | `HomeView.swift`, `PostDetailView.swift` |
| `social_follows` | `SocialFollow` | Relación de seguidores y seguidos entre usuarios. | `ProfileView.swift` |
| `chat_rooms` | `ChatRoom` | Canales y conversaciones directas o grupales. | `ChatsView.swift`, `ChatRoomDetailView.swift` |
| `chat_room_members` | `ChatRoomMember` | Miembros asignados a cada sala de chat. | `ChatsView.swift`, `ChatRoomDetailView.swift` |
| `chat_messages` | `ChatMessage` | Mensajes en tiempo real con soporte multimedia y cifrado E2E. | `ChatRoomDetailView.swift` |
| `forkman_eco_actions` | `ForkmanEcoAction` | Catálogo de retos ecológicos diarios y su impacto en CO₂. | `ForkarEcoView.swift` |
| `forkman_eco_map_points` | `ForkmanEcoMapPoint` | Puntos verdes y estaciones ecológicas georreferenciadas. | `ForkarEcoView.swift` |
| `forkman_user_eco` | `ForkmanUserEco` | Historial de puntos y CO₂ ahorrado por usuario. | `ForkarEcoView.swift`, Dynamic Island, Widgets |
| `oauth_clients` | `OAuthClient` | Clientes OAuth2 / SSO registrados para el ecosistema. | Autenticación federada / Integraciones |
| `oauth_codes` | `OAuthCode` | Códigos de intercambio y autorización OAuth PKCE. | Flujo de autenticación externa |

---

## 2. Detalle de Tablas y Columnas

### 2.1. `profiles`
Contiene la información de perfil asociada al `auth.users` de Supabase.
- `id` (`uuid`, PK, NO NULL): Clave primaria que coincide con `auth.uid()`.
- `email` (`text`, NULL): Correo electrónico del usuario.
- `full_name` (`text`, NULL): Nombre completo visible.
- `avatar_url` (`text`, NULL): URL de la imagen de perfil.
- `preferred_language` (`varchar`, default `'es'`): Idioma preferido del usuario.
- `created_at` (`timestamptz`, default `now()`): Fecha de registro.
- `updated_at` (`timestamptz`, default `now()`): Fecha de última actualización.

**Métodos de acceso:**
- `authManager.fetchProfile(userId:)` $\to$ `GET /rest/v1/profiles?id=eq.{id}`
- `authManager.updateProfile(fullName:avatarUrl:)` $\to$ `PATCH /rest/v1/profiles?id=eq.{id}`

---

### 2.2. `social_categories`
Clasificación de las publicaciones en el feed comunitario.
- `id` (`uuid`, PK, default `gen_random_uuid()`): Identificador único de la categoría.
- `name` (`text`, NO NULL): Nombre visible (ej. "Tecnología", "Movilidad", "Comunidad").
- `slug` (`text`, NO NULL): Identificador en minúsculas para URLs/filtros.
- `description` (`text`, NULL): Descripción de la categoría.
- `color` (`text`, default `'#0077e6'`): Código hexadecimal del color temático.
- `created_at` (`timestamptz`, default `now()`).

**Métodos de acceso:**
- `authManager.fetchCategories()` $\to$ `GET /rest/v1/social_categories?select=*`

---

### 2.3. `social_posts`
Publicaciones compartidas por la comunidad.
- `id` (`uuid`, PK, default `gen_random_uuid()`).
- `user_id` (`uuid`, NO NULL, FK `profiles.id`).
- `author_name` (`text`, NO NULL, default `'Usuario'`).
- `author_avatar` (`text`, NULL).
- `category_id` (`uuid`, NULL, FK `social_categories.id`).
- `title` (`text`, NO NULL).
- `content` (`text`, NO NULL).
- `likes_count` (`integer`, default `0`).
- `comments_count` (`integer`, default `0`).

**Métodos de acceso:**
- `authManager.fetchPosts(categoryId:)` $\to$ `GET /rest/v1/social_posts?select=*&order=created_at.desc`
- `authManager.createPost(title:content:categoryId:)` $\to$ `POST /rest/v1/social_posts`

---

### 2.4. `social_comments`
Interacciones y respuestas en las publicaciones.
- `id` (`uuid`, PK, default `gen_random_uuid()`).
- `post_id` (`uuid`, NO NULL, FK `social_posts.id`).
- `user_id` (`uuid`, NO NULL, FK `profiles.id`).
- `author_name` (`text`, NO NULL, default `'Usuario'`).
- `author_avatar` (`text`, NULL).
- `content` (`text`, NO NULL).
- `created_at` (`timestamptz`, default `now()`).
- `is_hidden` (`boolean`, default `false`).

**Métodos de acceso:**
- `authManager.fetchComments(postId:)` $\to$ `GET /rest/v1/social_comments?post_id=eq.{postId}&is_hidden=eq.false`
- `authManager.createComment(postId:content:)` $\to$ `POST /rest/v1/social_comments`

---

### 2.5. `social_likes` & `social_follows`
- **`social_likes`**: `id`, `post_id`, `user_id`, `created_at`.
- **`social_follows`**: `id`, `follower_id`, `following_id`, `created_at`.

---

### 2.6. `chat_rooms`, `chat_room_members` & `chat_messages`
Sistema de mensajería en tiempo real y cifrado.
- **`chat_rooms`**: `id`, `name`, `is_group`, `created_at`, `created_by`.
- **`chat_room_members`**: `id`, `room_id`, `user_id`, `user_name`, `user_avatar`, `joined_at`.
- **`chat_messages`**: `id`, `room_id`, `user_id`, `author_name`, `author_avatar`, `content`, `media_url`, `media_type`, `created_at`.

**Salas Canónicas Protegidas (`CSMSCanonicalRooms`):**
- `00000000-0000-0000-0000-000000000001`: Comunidad Global
- `00000000-0000-0000-0000-000000000002`: Eco Hub
- `00000000-0000-0000-0000-000000000003`: Forkar Carpool

---

### 2.7. `forkman_eco_actions`
Catálogo de retos ecológicos que el usuario puede realizar.
- `id` (`uuid`, PK, default `gen_random_uuid()`).
- `title` (`text`, NO NULL): Nombre del reto (ej. "Transporte Sostenible").
- `description` (`text`, NO NULL): Instrucciones del reto.
- `co2_impact` (`numeric`, default `1.00`): Reducción estimada en kg de CO₂.
- `category` (`text`, default `'General'`).
- `created_at` (`timestamptz`, default `now()`).

**Método de acceso:**
- `authManager.fetchEcoActions()` $\to$ `GET /rest/v1/forkman_eco_actions?select=*`

---

### 2.8. `forkman_eco_map_points`
Puntos verdes, ciclorrutas y estaciones de reciclaje del municipio.
- `id` (`uuid`, PK, default `gen_random_uuid()`).
- `name` (`text`, NO NULL): Nombre del punto verde o estación.
- `description` (`text`, NULL): Materiales aceptados o detalles.
- `latitude` (`double precision`, NO NULL).
- `longitude` (`double precision`, NO NULL).
- `point_type` (`text`, default `'verde'`): `verde`, `bici`, `raee`, `acopio`.
- `color` (`text`, default `'#10b981'`): Color representativo del pin.
- `created_at` (`timestamptz`, default `now()`).

**Método de acceso:**
- `authManager.fetchEcoMapPoints()` $\to$ `GET /rest/v1/forkman_eco_map_points?select=*`

---

### 2.9. `forkman_user_eco`
Registro del balance de puntos y ahorro de CO₂ de cada usuario.
- `id` (`uuid`, PK, default `gen_random_uuid()`).
- `user_id` (`uuid`, NO NULL, FK `profiles.id`).
- `action_id` (`uuid`, NULL, FK `forkman_eco_actions.id`).
- `co2_saved` (`numeric`, default `0.00`).
- `points_earned` (`integer`, default `0`).
- `created_at` (`timestamptz`, default `now()`).

**Métodos de acceso:**
- `authManager.fetchUserEcoImpact(userId:)` $\to$ Calcula la suma acumulada de CO₂ y puntos.
- `authManager.logUserEcoImpact(actionId:co2Saved:pointsEarned:)` $\to$ Registra una nueva acción ecológica validada.
- Sincroniza con **Dynamic Island** física y **WidgetCenter**.
