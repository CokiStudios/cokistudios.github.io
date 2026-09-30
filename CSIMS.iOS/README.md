# CSIMS iOS & macOS — Coki Studios Internal Messaging Service

**CSIMS** es el cliente nativo de mensajería interna de Coki Studios, protegido por políticas de **Cloudflare Zero Trust** y cifrado de extremo a extremo (E2EE) con respaldo por hardware en **Secure Enclave (Apple SEP)** y **Apple T2 / Apple Silicon**.

---

## 🛡️ Reglas Zero Trust & Seguridad

1. **Restricción de Dominio**: Únicamente identidades y correos terminados en `@cokistudios.com` pueden autenticarse y transmitir mensajes.
2. **Cifrado E2EE por Hardware**: Algoritmo **AES-256-GCM** con vector de inicialización de 12 bytes y tag de autenticación de 128 bits.
3. **Derivación de Clave de Sala**: `SHA256("\(roomId):CSIMS_E2EE_COKI_STUDIOS_v1_SALT_INTERNAL")`.
4. **Soporte Multiplataforma**: Funciona de forma unificada en iPhone, iPad y macOS con `NavigationSplitView`.

---

## 🚀 Canales Canónicos Internos

- `#general-coki` (`10000000-0000-0000-0000-000000000001`): Anuncios y coordinación de equipo.
- `#eng-forkar` (`10000000-0000-0000-0000-000000000002`): Desarrollo Core, Swift, Kotlin y Cloudflare Workers.
- `#security-ops` (`10000000-0000-0000-0000-000000000003`): Políticas Zero Trust, Access y auditorías de seguridad.
- `#design-system` (`10000000-0000-0000-0000-000000000004`): Sistema de diseño Liquid Glass.
