# 🚗 Forkar for PC (macOS Native Client) & Extensión CSMS

Aplicación de escritorio 100% nativa desarrollada en **SwiftUI** para macOS / PC (Apple Silicon & Intel x86_64). Incluye la suite completa de **Forkar** (Muro social de publicaciones, Eco Hub con métricas ecológicas, Estaciones de Reciclaje) junto con la **Extensión Nativa CSMS (Coki Studios Messenger Service)** para chat en tiempo real.

---

## 🌟 Características Principales

1. **Muro de Publicaciones (Feed Principal)**:
   - Diseño moderno con estética *Liquid Glass* y tema oscuro curado.
   - Filtros por categoría: *General, Código & Dev, Eco Hub, Gaming, Diseño*.
   - Buscador en tiempo real de publicaciones y tags.
   - Creación de posts con categorías y URLs multimedia.
   - **Acción Rápida CSMS**: Cada publicación incluye el botón `💬 Abrir en CSMS` / `Chatear en CSMS` para conectar de inmediato con el autor o debatir el tema en una sala.

2. **Extensión CSMS (Coki Studios Messenger Service)**:
   - Panel de canales y salas canónicas sincronizadas con Supabase:
     - `💬 Comunidad Global`
     - `🚗 Forkar Carpooling & Rutas`
     - `🌿 Eco Hub & Sostenibilidad`
   - Historial de mensajes en tiempo real con scroll automático (`ScrollViewReader`).
   - Envío instantáneo con autenticación por Bearer Token.

3. **Forkar Eco Hub**:
   - Tablero de impacto ambiental: Kg de CO2 evitado, Puntos Verdes y Viajes Compartidos.
   - Directorio de EcoEstaciones y puntos limpios con estado operativo y distancias.
   - Enlace directo a la sala temática `🌿 Eco Hub` en CSMS.

4. **Perfil & Autenticación**:
   - Conexión nativa con Supabase Auth (correo y contraseña).
   - Modo Invitado instantáneo para pruebas locales.

---

## 🛠️ Compilación y Distribución Universal

El script `build_universal.sh` compila la aplicación para arquitecturas `arm64` (Apple Silicon M1/M2/M3/M4/M5) y `x86_64` (Intel Macs y Hackintosh), generando un binario **Universal Mach-O** firmado ad-hoc y empaquetado en zip:

```bash
chmod +x Forkar.macOS/build_universal.sh
./Forkar.macOS/build_universal.sh
```

El resultado se genera en:
- Bundle: `Forkar.macOS/build/Forkar.app`
- Zip Universal: `Forkar.macOS/Forkar-macOS-Universal.zip`
