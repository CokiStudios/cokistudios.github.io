// ═══════════════════════════════════════════════════════════════
// 🍪 COOKIE UTILITIES — Reemplaza localStorage/sessionStorage
// Escalable para 1K+ usuarios con expiración y seguridad
// ═══════════════════════════════════════════════════════════════

const COOKIE_CONFIG = {
    secure: true,      // Solo HTTPS (GitHub Pages lo soporta)
    sameSite: 'Lax',   // Protección CSRF básica
    path: '/',         // Disponible en todo cokistudios.github.io
    maxAge: 7 * 24 * 60 * 60  // 7 días por defecto
};

function setCookie(name, value, options = {}) {
    const opts = { ...COOKIE_CONFIG, ...options };
    let cookieString = `${encodeURIComponent(name)}=${encodeURIComponent(value)}`;
    if (opts.maxAge) cookieString += `; max-age=${opts.maxAge}`;
    if (opts.expires) cookieString += `; expires=${opts.expires.toUTCString()}`;
    if (opts.path) cookieString += `; path=${opts.path}`;
    if (opts.secure) cookieString += '; secure';
    if (opts.sameSite) cookieString += `; samesite=${opts.sameSite}`;
    document.cookie = cookieString;
}

function getCookie(name) {
    const cookies = document.cookie.split(';');
    for (let cookie of cookies) {
        const [cookieName, cookieValue] = cookie.trim().split('=');
        if (decodeURIComponent(cookieName) === name) {
            return decodeURIComponent(cookieValue);
        }
    }
    return null;
}

function deleteCookie(name) {
    document.cookie = `${encodeURIComponent(name)}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
}

function setCookieJSON(name, obj, options = {}) {
    setCookie(name, JSON.stringify(obj), options);
}

function getCookieJSON(name) {
    const val = getCookie(name);
    if (!val) return null;
    try { return JSON.parse(val); } catch (e) { return null; }
}

function clearAllCookies() {
    const cookies = document.cookie.split(';');
    for (let cookie of cookies) {
        const [cookieName] = cookie.trim().split('=');
        if (cookieName) {
            deleteCookie(decodeURIComponent(cookieName));
        }
    }
}

function getBrowserHash() {
    let hash = getCookie('coki_browser_hash');
    if (!hash) {
        hash = 'web_br_' + Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
        setCookie('coki_browser_hash', hash, { maxAge: 30 * 24 * 60 * 60 });
    }
    return hash;
}

function regenerateBrowserHash() {
    const newHash = 'web_br_' + Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
    setCookie('coki_browser_hash', newHash, { maxAge: 30 * 24 * 60 * 60 });
    return newHash;
}

export {
    setCookie,
    getCookie,
    deleteCookie,
    setCookieJSON,
    getCookieJSON,
    clearAllCookies,
    getBrowserHash,
    regenerateBrowserHash,
    COOKIE_CONFIG
};

