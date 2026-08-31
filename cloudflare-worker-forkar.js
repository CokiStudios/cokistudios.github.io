/**
 * ═══════════════════════════════════════════════════════════════
 *  CLOUDFLARE WORKER: FORKAR SUBDOMAIN ROUTER & PROXY
 * Subdominio: forkar.cokistudios.com
 * Destino Origen: cokistudios.com / cokistudios.github.io
 * ═══════════════════════════════════════════════════════════════
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const targetOrigin = "https://cokistudios.com";

    // 1. Ruta Principal: https://forkar.cokistudios.com/ -> cokistudios.com/forkar.html
    if (url.pathname === "/" || url.pathname === "") {
      const targetUrl = new URL("/forkar.html", targetOrigin);
      targetUrl.search = url.search;
      return fetch(new Request(targetUrl.toString(), request));
    }

    // 2. Ruta de Post: https://forkar.cokistudios.com/post?id=xxx o /post/xxx -> /forkar-post.html
    if (url.pathname === "/post" || url.pathname.startsWith("/post/")) {
      const targetUrl = new URL("/forkar-post.html", targetOrigin);

      // Si la URL es de tipo /post/123-abc, extraer el id como query param
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
