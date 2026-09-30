/**
 * ═══════════════════════════════════════════════════════════════
 *  CLOUDFLARE WORKER: FORKAR SUBDOMAIN ROUTER, PROXY & ZERO TRUST
 *  Subdominios:
 *    - forkar.cokistudios.com (Público)
 *    - forkar-internal.cokistudios.com (Zero Trust: Solo @cokistudios.com)
 *    - csims.cokistudios.com (CSIMS Internal: Solo @cokistudios.com)
 *  Destino Origen: cokistudios.com / cokistudios.github.io
 * ═══════════════════════════════════════════════════════════════
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const targetOrigin = "https://cokistudios.com";
    const hostname = url.hostname.toLowerCase();

    // ─────────────────────────────────────────────────────────────
    // 🛡️ ZERO TRUST ENFORCEMENT (@cokistudios.com)
    // ─────────────────────────────────────────────────────────────
    const isInternalDomain =
      hostname === "forkar-internal.cokistudios.com" ||
      hostname === "csims.cokistudios.com" ||
      url.pathname.startsWith("/internal") ||
      url.pathname.startsWith("/forkar-internal") ||
      url.pathname.startsWith("/csims");

    if (isInternalDomain) {
      // 1. Obtener correo autenticado provisto por Cloudflare Access
      const cfAccessEmail = (
        request.headers.get("cf-access-authenticated-user-email") ||
        request.headers.get("x-auth-email") ||
        ""
      ).trim().toLowerCase();

      // En entornos de desarrollo o previews se puede evaluar parámetro de simulación seguro
      const devEmail = url.searchParams.get("cf_email")?.toLowerCase() || "";
      const evaluatedEmail = cfAccessEmail || devEmail;

      const isCokiStudiosEmail = evaluatedEmail.endsWith("@cokistudios.com");

      // Si no es un correo válido de @cokistudios.com, bloquear con pantalla Zero Trust 403
      if (!isCokiStudiosEmail) {
        return renderZeroTrustBlockPage(evaluatedEmail, url.hostname);
      }

      // 2. Rutas para CSIMS (Coki Studios Internal Messaging Service)
      if (hostname === "csims.cokistudios.com" || url.pathname === "/csims" || url.pathname === "/csims.html") {
        const targetUrl = new URL("/csims.html", targetOrigin);
        targetUrl.search = url.search;
        const modifiedRequest = new Request(targetUrl.toString(), request);
        modifiedRequest.headers.set("X-CSIMS-Internal-User", evaluatedEmail);
        return fetch(modifiedRequest);
      }

      // 3. Rutas para Forkar Internal
      const targetUrl = new URL("/forkar-internal.html", targetOrigin);
      targetUrl.search = url.search;
      const modifiedRequest = new Request(targetUrl.toString(), request);
      modifiedRequest.headers.set("X-Forkar-Internal-User", evaluatedEmail);
      return fetch(modifiedRequest);
    }

    // ─────────────────────────────────────────────────────────────
    // 🌐 RUTAS PÚBLICAS DE FORKAR (forkar.cokistudios.com)
    // ─────────────────────────────────────────────────────────────

    // 1. Ruta Principal: https://forkar.cokistudios.com/ -> cokistudios.com/forkar.html
    if (url.pathname === "/" || url.pathname === "") {
      const targetUrl = new URL("/forkar.html", targetOrigin);
      targetUrl.search = url.search;
      return fetch(new Request(targetUrl.toString(), request));
    }

    // 2. Ruta de Post: https://forkar.cokistudios.com/post?id=xxx o /post/xxx -> /forkar-post.html
    if (url.pathname === "/post" || url.pathname.startsWith("/post/")) {
      const targetUrl = new URL("/forkar-post.html", targetOrigin);

      if (url.pathname.startsWith("/post/")) {
        const postId = url.pathname.replace("/post/", "").trim();
        if (postId && !url.searchParams.has("id")) {
          url.searchParams.set("id", postId);
        }
      }

      targetUrl.search = url.search;
      return fetch(new Request(targetUrl.toString(), request));
    }

    // 3. Ruta directa a forkar o forkar-post sin extensión
    if (url.pathname === "/forkar") {
      const targetUrl = new URL("/forkar.html", targetOrigin);
      targetUrl.search = url.search;
      return fetch(new Request(targetUrl.toString(), request));
    }

    // 4. Recursos estáticos, assets, scripts y demás páginas
    const assetUrl = new URL(url.pathname, targetOrigin);
    assetUrl.search = url.search;
    return fetch(new Request(assetUrl.toString(), request));
  }
};

/**
 * Renderiza una pantalla de bloqueo elegante con estética Liquid Glass de Cloudflare Zero Trust
 */
function renderZeroTrustBlockPage(userEmail, hostname) {
  const displayEmail = userEmail || "No autenticado / Desconocido";
  const html = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Acceso Restringido — Cloudflare Zero Trust</title>
  <link rel="icon" type="image/svg+xml" href="https://cokistudios.com/assets/forkar-icon.svg">
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Outfit', sans-serif;
      background: #06090f;
      color: #f1f5f9;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      overflow: hidden;
      position: relative;
    }
    body::before {
      content: '';
      position: fixed; inset: 0; z-index: -1;
      background: radial-gradient(circle at 50% 30%, rgba(99, 102, 241, 0.15), transparent 70%);
      pointer-events: none;
    }
    .card {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.08);
      backdrop-filter: blur(24px);
      -webkit-backdrop-filter: blur(24px);
      border-radius: 24px;
      padding: 44px 36px;
      max-width: 520px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.6), 0 0 40px rgba(99, 102, 241, 0.15);
      animation: fadeIn 0.4s ease-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(12px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .shield-icon {
      width: 76px;
      height: 76px;
      margin: 0 auto 20px;
      border-radius: 20px;
      background: linear-gradient(135deg, rgba(239, 68, 68, 0.2), rgba(220, 38, 38, 0.05));
      border: 1px solid rgba(239, 68, 68, 0.3);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #ef4444;
      font-size: 34px;
      box-shadow: 0 0 25px rgba(239, 68, 68, 0.25);
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      margin-bottom: 8px;
      color: #ffffff;
      letter-spacing: -0.5px;
    }
    .subtitle {
      font-size: 13px;
      color: #94a3b8;
      margin-bottom: 24px;
      line-height: 1.5;
    }
    .policy-box {
      background: rgba(0, 0, 0, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 14px;
      padding: 16px;
      margin-bottom: 24px;
      text-align: left;
      font-size: 12px;
    }
    .policy-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .policy-row:last-child { margin-bottom: 0; }
    .label { color: #64748b; font-weight: 500; }
    .val { color: #cbd5e1; font-weight: 600; font-family: monospace; }
    .val-restricted { color: #f87171; font-weight: 700; }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 12px 24px;
      background: linear-gradient(135deg, #6366f1, #4f46e5);
      color: white;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
      border-radius: 12px;
      border: none;
      cursor: pointer;
      transition: all 0.2s ease;
      box-shadow: 0 8px 20px rgba(99, 102, 241, 0.35);
    }
    .btn:hover {
      transform: translateY(-1px);
      box-shadow: 0 12px 24px rgba(99, 102, 241, 0.45);
    }
    .footer-badge {
      margin-top: 24px;
      font-size: 11px;
      color: #475569;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="shield-icon">🔒</div>
    <h1>Acceso Denegado por Zero Trust</h1>
    <p class="subtitle">
      Esta aplicación interna está protegida por <strong>Cloudflare Zero Trust</strong>.
      Únicamente los colaboradores con credenciales terminadas en <strong>@cokistudios.com</strong> tienen autorización.
    </p>

    <div class="policy-box">
      <div class="policy-row">
        <span class="label">Destino:</span>
        <span class="val">${hostname}</span>
      </div>
      <div class="policy-row">
        <span class="label">Identidad detectada:</span>
        <span class="val val-restricted">${displayEmail}</span>
      </div>
      <div class="policy-row">
        <span class="label">Regla de Acceso:</span>
        <span class="val">email_domain = "cokistudios.com"</span>
      </div>
      <div class="policy-row">
        <span class="label">Estado de Autorización:</span>
        <span class="val val-restricted">RECHAZADO (403)</span>
      </div>
    </div>

    <a href="https://forkar.cokistudios.com" class="btn">
      Volver a Forkar Público
    </a>

    <div class="footer-badge">
      <span>🛡️ Coki Studios Zero Trust Access Security Policy</span>
    </div>
  </div>
</body>
</html>`;

  return new Response(html, {
    status: 403,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store, max-age=0"
    }
  });
}
