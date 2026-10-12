// ═══════════════════════════════════════════════════════════════
//  CS ID CONNECT SDK v2.0 — Coki Studios Federated Identity
//  OAuth 2.0 + PKCE (S256) • One-Tap • Popup & Redirect • Zero Payments
// ═══════════════════════════════════════════════════════════════

import { generateCode, sha256, exchangeCodeForToken, decryptJWE } from './oauth-server.js';
import { getCookie, setCookie, deleteCookie, getCookieJSON, setCookieJSON } from './cookie-utils.js';

// SVG oficial del emblema Coki Studios CS ID
const CS_LOGO_SVG = `
<svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="24" height="24" rx="6" fill="#0A0E17"/>
  <path d="M12 4C7.58172 4 4 7.58172 4 12C4 16.4183 7.58172 20 12 20C15.3137 20 18.1569 17.9853 19.3431 15.0627C19.5314 14.5999 19.1627 14.1 18.6667 14.1H16.8284C16.4526 14.1 16.1265 14.3474 16.024 14.7088C15.2853 17.3147 12.8366 18.2 12 18.2C8.57584 18.2 5.8 15.4242 5.8 12C5.8 8.57584 8.57584 5.8 12 5.8C14.1611 5.8 15.6547 6.94528 16.5147 7.91472C16.8047 8.24156 17.3075 8.27202 17.6366 7.98292L18.9142 6.86274C19.2636 6.55627 19.2743 6.01736 18.9374 5.69608C17.2627 4.09991 14.8633 4 12 4Z" fill="url(#cs-grad-logo)"/>
  <circle cx="12" cy="12" r="2.4" fill="#00F5D4"/>
  <defs>
    <linearGradient id="cs-grad-logo" x1="4" y1="4" x2="20" y2="20" gradientUnits="userSpaceOnUse">
      <stop stop-color="#FBBF24"/>
      <stop offset="0.5" stop-color="#38BDF8"/>
      <stop offset="1" stop-color="#00F5D4"/>
    </linearGradient>
  </defs>
</svg>
`;

const DEFAULT_AUTH_URL = typeof window !== 'undefined'
    ? `${window.location.origin}/authorize.html`
    : 'https://cokistudios.com/authorize.html';

class CSIDConnectClient {
    constructor() {
        this.config = {
            clientId: 'demo-app-123',
            redirectUri: typeof window !== 'undefined' ? window.location.href.split('?')[0] : '',
            scope: 'openid profile email offline_access',
            mode: 'popup', // 'popup' | 'redirect'
            authUrl: DEFAULT_AUTH_URL,
            theme: 'glass', // 'glass' | 'dark' | 'light' | 'outline'
            prompt: 'consent'
        };
        this.popupRef = null;
        this.oneTapActive = false;
        this._injectStyles();
    }

    /**
     * Inicializar configuración de CS ID Connect
     * @param {Object} options 
     */
    init(options = {}) {
        this.config = { ...this.config, ...options };
        if (typeof window !== 'undefined' && !options.redirectUri) {
            this.config.redirectUri = window.location.href.split('?')[0];
        }
        return this;
    }

    /**
     * Renderizar el botón oficial de CS ID Connect en un contenedor
     * @param {string|HTMLElement} target - Selector o elemento DOM
     * @param {Object} opts - Opciones de estilo
     */
    renderButton(target, opts = {}) {
        const el = typeof target === 'string' ? document.querySelector(target) : target;
        if (!el) {
            console.warn('[CSIDConnect] Elemento contenedor no encontrado:', target);
            return;
        }

        const options = {
            theme: opts.theme || this.config.theme || 'glass',
            size: opts.size || 'medium', // 'small' | 'medium' | 'large'
            shape: opts.shape || 'pill', // 'pill' | 'rounded' | 'square'
            text: opts.text || 'continue', // 'continue' | 'signin' | 'connect'
            mode: opts.mode || this.config.mode || 'popup',
            onSuccess: opts.onSuccess || null,
            onError: opts.onError || null
        };

        const textMap = {
            continue: 'Continuar con CS ID',
            signin: 'Iniciar sesión con CS ID',
            connect: 'Conectar con CS ID'
        };

        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = `csid-btn csid-btn-${options.theme} csid-btn-${options.size} csid-shape-${options.shape}`;
        btn.innerHTML = `
            <span class="csid-btn-icon">${CS_LOGO_SVG}</span>
            <span class="csid-btn-text">${textMap[options.text] || textMap.continue}</span>
            <span class="csid-btn-badge">E2EE</span>
        `;

        btn.addEventListener('click', async () => {
            btn.classList.add('csid-btn-loading');
            try {
                const result = await this.signIn({ mode: options.mode });
                if (options.onSuccess) options.onSuccess(result);
            } catch (err) {
                if (options.onError) options.onError(err);
            } finally {
                btn.classList.remove('csid-btn-loading');
            }
        });

        el.innerHTML = '';
        el.appendChild(btn);
    }

    /**
     * Iniciar flujo de autorización (Popup o Redirect)
     * @param {Object} override - Parámetros específicos para esta llamada
     * @returns {Promise<Object>}
     */
    async signIn(override = {}) {
        const mode = override.mode || this.config.mode;
        const clientId = override.clientId || this.config.clientId;
        const redirectUri = override.redirectUri || this.config.redirectUri;
        const scope = override.scope || this.config.scope;
        const authBaseUrl = override.authUrl || this.config.authUrl;

        // 1. Generar PKCE (Code Verifier + Code Challenge S256)
        const codeVerifier = generateCode(128);
        const codeChallenge = await sha256(codeVerifier);
        const state = generateCode(24);

        // Guardar Verifier y State en Cookies seguras
        setCookie('coki_oauth_code_verifier', codeVerifier, { maxAge: 900 });
        setCookie('coki_oauth_state', state, { maxAge: 900 });

        const authUrl = new URL(authBaseUrl, window.location.origin);
        authUrl.searchParams.set('client_id', clientId);
        authUrl.searchParams.set('redirect_uri', redirectUri);
        authUrl.searchParams.set('response_type', 'code');
        authUrl.searchParams.set('scope', scope);
        authUrl.searchParams.set('code_challenge', codeChallenge);
        authUrl.searchParams.set('code_challenge_method', 'S256');
        authUrl.searchParams.set('state', state);
        if (mode === 'popup') {
            authUrl.searchParams.set('mode', 'popup');
        }

        if (mode === 'redirect') {
            window.location.href = authUrl.toString();
            return new Promise(() => {}); // Esperando navegación
        }

        // ── POPUP MODE ──
        return new Promise((resolve, reject) => {
            const width = 480;
            const height = 660;
            const left = Math.max(0, (window.screen.width - width) / 2);
            const top = Math.max(0, (window.screen.height - height) / 2);

            const popup = window.open(
                authUrl.toString(),
                'csid_connect_popup',
                `width=${width},height=${height},top=${top},left=${left},status=no,resizable=yes,scrollbars=yes`
            );

            if (!popup) {
                console.warn('[CSIDConnect] Popup bloqueado por el navegador. Redirigiendo...');
                window.location.href = authUrl.toString();
                return;
            }

            this.popupRef = popup;

            // Escuchar mensaje del popup
            const handleMessage = async (event) => {
                // Verificar tipo de mensaje
                if (!event.data || typeof event.data !== 'object') return;
                const { type, code, state: returnedState, error, error_description } = event.data;

                if (type === 'CSID_AUTH_SUCCESS') {
                    window.removeEventListener('message', handleMessage);
                    clearInterval(checkClosedInterval);

                    if (returnedState !== state) {
                        reject(new Error('State mismatch / Posible ataque CSRF detectado'));
                        return;
                    }

                    // Intercambiar código por token con PKCE
                    try {
                        const tokenResponse = await exchangeCodeForToken(code, redirectUri, codeVerifier);
                        deleteCookie('coki_oauth_code_verifier');
                        deleteCookie('coki_oauth_state');

                        if (tokenResponse.error) {
                            reject(new Error(tokenResponse.error_description || tokenResponse.error));
                            return;
                        }

                        // Resolver y desencriptar perfil de usuario
                        let profile = await decryptJWE(tokenResponse.id_token);
                        if (!profile || !profile.email) {
                            profile = this._decodeJwePayload(tokenResponse.id_token) || this.getCurrentUser();
                        }

                        if (profile) {
                            setCookieJSON('coki_current_user', profile, { maxAge: 7 * 24 * 60 * 60 });
                            // Recordar en lista multi-cuenta
                            try {
                                let known = getCookieJSON('cs_known_accounts') || [];
                                known = known.filter(a => a.email !== profile.email);
                                known.unshift({
                                    id: profile.id || profile.sub,
                                    email: profile.email,
                                    name: profile.name,
                                    picture: profile.picture
                                });
                                setCookieJSON('cs_known_accounts', known.slice(0, 5), { maxAge: 30 * 24 * 60 * 60 });
                            } catch (_) {}
                        }
                        if (tokenResponse.access_token) {
                            setCookie('coki_access_token', tokenResponse.access_token, { maxAge: 7 * 24 * 60 * 60 });
                        }
                        if (tokenResponse.id_token) {
                            setCookie('coki_id_token', tokenResponse.id_token, { maxAge: 7 * 24 * 60 * 60 });
                        }

                        resolve({
                            code,
                            accessToken: tokenResponse.access_token,
                            idToken: tokenResponse.id_token,
                            user: profile,
                            scope: tokenResponse.scope,
                            expiresIn: tokenResponse.expires_in
                        });
                    } catch (e) {
                        reject(e);
                    }
                } else if (type === 'CSID_AUTH_DENIED') {
                    window.removeEventListener('message', handleMessage);
                    clearInterval(checkClosedInterval);
                    reject(new Error(error_description || error || 'Autorización cancelada por el usuario'));
                }
            };

            window.addEventListener('message', handleMessage);

            // Detectar cierre manual de la ventana emergente
            const checkClosedInterval = setInterval(() => {
                if (popup.closed) {
                    clearInterval(checkClosedInterval);
                    window.removeEventListener('message', handleMessage);
                    reject(new Error('Ventana de autenticación cerrada'));
                }
            }, 600);
        });
    }

    /**
     * One-Tap Sign In: Detección instantánea de sesión con tarjeta flotante,
     * soporte multi-cuenta y opción biométrica con Passkey (FIDO2)
     * @param {Object} options 
     */
    promptOneTap(options = {}) {
        if (typeof document === 'undefined' || this.oneTapActive) return;

        const currentUser = this.getCurrentUser();
        const familyAccounts = getCookieJSON('cs_known_accounts') || (currentUser ? [currentUser] : []);

        if (!currentUser && familyAccounts.length === 0) {
            console.log('[CSIDConnect One-Tap] No hay sesión activa previa.');
            return;
        }

        this.oneTapActive = true;
        const banner = document.createElement('div');
        banner.className = 'csid-onetap-banner';
        banner.id = 'csid-onetap-prompt';

        let activeAccount = currentUser || familyAccounts[0];
        const name = activeAccount.name || activeAccount.email.split('@')[0] || 'Usuario';
        const email = activeAccount.email;
        const avatarHtml = activeAccount.picture
            ? `<img src="${activeAccount.picture}" alt="${name}" class="csid-onetap-avatar-img">`
            : `<div class="csid-onetap-avatar-placeholder">${name.charAt(0).toUpperCase()}</div>`;

        const otherAccountsHtml = familyAccounts.length > 1
            ? `<div class="csid-onetap-switch-row" style="margin-top: 8px; font-size: 11px; text-align: center;">
                <span style="color: #64748B;">¿No eres ${name}? </span>
                <button type="button" id="csid-onetap-btn-switch" style="background:none; border:none; color: #38BDF8; cursor:pointer; font-weight:600; text-decoration:underline;">Cambiar de perfil</button>
               </div>`
            : '';

        banner.innerHTML = `
            <div class="csid-onetap-header">
                <div class="csid-onetap-brand">
                    ${CS_LOGO_SVG}
                    <span>CS ID Connect</span>
                </div>
                <button type="button" class="csid-onetap-close" id="csid-onetap-btn-close" aria-label="Cerrar">&times;</button>
            </div>
            <div class="csid-onetap-body">
                <div class="csid-onetap-user">
                    ${avatarHtml}
                    <div class="csid-onetap-info">
                        <div class="csid-onetap-name">${name}</div>
                        <div class="csid-onetap-email">${email}</div>
                    </div>
                </div>
                <p class="csid-onetap-desc">Inicia sesión en <strong>${document.title || 'esta aplicación'}</strong> con tu identidad oficial de Coki Studios.</p>
                <button type="button" class="csid-onetap-submit" id="csid-onetap-btn-submit">
                    Continuar como ${name}
                </button>
                ${otherAccountsHtml}
            </div>
            <div class="csid-onetap-footer">
                <span>🛡️ E2EE por Hardware • Cero Rastreadores • Sin Pagos</span>
            </div>
        `;

        document.body.appendChild(banner);

        // Animación de entrada suave
        setTimeout(() => banner.classList.add('csid-onetap-visible'), 50);

        // Click en continuar
        banner.querySelector('#csid-onetap-btn-submit').addEventListener('click', async () => {
            banner.classList.remove('csid-onetap-visible');
            setTimeout(() => banner.remove(), 300);
            this.oneTapActive = false;

            try {
                const res = await this.signIn({ mode: 'popup' });
                if (options.onAuth) options.onAuth(res);
            } catch (err) {
                if (options.onError) options.onError(err);
            }
        });

        // Click en cambiar de cuenta si hay varias
        const switchBtn = banner.querySelector('#csid-onetap-btn-switch');
        if (switchBtn) {
            switchBtn.addEventListener('click', async () => {
                banner.classList.remove('csid-onetap-visible');
                setTimeout(() => banner.remove(), 300);
                this.oneTapActive = false;
                try {
                    const res = await this.signIn({ mode: 'popup', prompt: 'select_account' });
                    if (options.onAuth) options.onAuth(res);
                } catch (err) {
                    if (options.onError) options.onError(err);
                }
            });
        }

        // Click en cerrar
        banner.querySelector('#csid-onetap-btn-close').addEventListener('click', () => {
            banner.classList.remove('csid-onetap-visible');
            setTimeout(() => banner.remove(), 300);
            this.oneTapActive = false;
            if (options.onDismiss) options.onDismiss();
        });
    }

    /**
     * Procesar retorno si se usó modo redirect (?code=...)
     */
    async handleRedirectCallback() {
        if (typeof window === 'undefined') return null;
        const params = new URLSearchParams(window.location.search);
        const code = params.get('code');
        const state = params.get('state');
        const error = params.get('error');

        if (error) {
            throw new Error(params.get('error_description') || error);
        }

        if (!code) return null;

        const storedState = getCookie('coki_oauth_state');
        const codeVerifier = getCookie('coki_oauth_code_verifier');

        if (!codeVerifier) {
            throw new Error('PKCE Code Verifier no encontrado en cookies.');
        }

        if (storedState && state && storedState !== state) {
            throw new Error('Validación de State CSRF fallida.');
        }

        deleteCookie('coki_oauth_code_verifier');
        deleteCookie('coki_oauth_state');

        const tokenResponse = await exchangeCodeForToken(code, this.config.redirectUri, codeVerifier);
        if (tokenResponse.error) {
            throw new Error(tokenResponse.error_description || tokenResponse.error);
        }

        // Limpiar parámetros de la URL sin recargar
        const cleanUrl = window.location.origin + window.location.pathname;
        window.history.replaceState({}, document.title, cleanUrl);

        // Resolver y desencriptar perfil de usuario
        let profile = await decryptJWE(tokenResponse.id_token);
        if (!profile || !profile.email) {
            profile = this._decodeJwePayload(tokenResponse.id_token) || this.getCurrentUser();
        }

        if (profile) {
            setCookieJSON('coki_current_user', profile, { maxAge: 7 * 24 * 60 * 60 });
            // Recordar en lista multi-cuenta
            try {
                let known = getCookieJSON('cs_known_accounts') || [];
                known = known.filter(a => a.email !== profile.email);
                known.unshift({
                    id: profile.id || profile.sub,
                    email: profile.email,
                    name: profile.name,
                    picture: profile.picture
                });
                setCookieJSON('cs_known_accounts', known.slice(0, 5), { maxAge: 30 * 24 * 60 * 60 });
            } catch (_) {}
        }
        if (tokenResponse.access_token) {
            setCookie('coki_access_token', tokenResponse.access_token, { maxAge: 7 * 24 * 60 * 60 });
        }
        if (tokenResponse.id_token) {
            setCookie('coki_id_token', tokenResponse.id_token, { maxAge: 7 * 24 * 60 * 60 });
        }

        return {
            code,
            accessToken: tokenResponse.access_token,
            idToken: tokenResponse.id_token,
            user: profile,
            scope: tokenResponse.scope,
            expiresIn: tokenResponse.expires_in
        };
    }

    /**
     * Obtener el usuario actual logueado en CS ID
     */
    getCurrentUser() {
        return getCookieJSON('coki_current_user') || null;
    }

    /**
     * Obtener token de acceso actual
     */
    getAccessToken() {
        return getCookie('coki_access_token') || null;
    }

    /**
     * Obtener ID token actual
     */
    getIdToken() {
        return getCookie('coki_id_token') || null;
    }

    /**
     * Verificar si existe sesión autenticada activa
     */
    isAuthenticated() {
        return !!(this.getCurrentUser() && this.getAccessToken());
    }

    /**
     * Desencriptar un JWE token en cliente
     */
    async decryptToken(idToken) {
        return await decryptJWE(idToken);
    }

    /**
     * Cerrar sesión global en el ecosistema
     */
    signOut() {
        deleteCookie('coki_current_user');
        deleteCookie('coki_access_token');
        deleteCookie('coki_id_token');
        deleteCookie('coki_refresh_token');
        deleteCookie('coki_session');
        deleteCookie('coki_oauth_code_verifier');
        deleteCookie('coki_oauth_state');
        if (typeof BroadcastChannel !== 'undefined') {
            try {
                const bc = new BroadcastChannel('cs_sso_sync');
                bc.postMessage({ type: 'SSO_LOGOUT', timestamp: Date.now() });
            } catch (_) {}
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  FIDO2 / WEBAUTHN PASSKEYS — HARDWARE-BACKED BIOMETRICS
    // ═══════════════════════════════════════════════════════════════

    /**
     * Comprueba si el dispositivo soporta Passkeys con biometría de hardware
     */
    async isPasskeySupported() {
        if (typeof window === 'undefined' || !window.PublicKeyCredential) return false;
        try {
            return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
        } catch (_) {
            return false;
        }
    }

    /**
     * Registrar una Passkey biométrica (FIDO2) vinculada a CS ID
     * @param {Object} user - Objeto de usuario CS ID con email y displayName
     */
    async registerPasskey(user = {}) {
        if (!await this.isPasskeySupported()) {
            throw new Error('Este dispositivo no soporta autenticación biométrica de plataforma (Passkeys).');
        }

        const userEmail = user.email || this.getCurrentUser()?.email || 'dev@cokistudios.com';
        const userName = user.name || userEmail.split('@')[0];
        const userIdBytes = new TextEncoder().encode(user.id || userEmail);
        const challengeBytes = crypto.getRandomValues(new Uint8Array(32));

        const createOptions = {
            publicKey: {
                challenge: challengeBytes,
                rp: {
                    name: 'Coki Studios ID',
                    id: window.location.hostname
                },
                user: {
                    id: userIdBytes,
                    name: userEmail,
                    displayName: userName
                },
                pubKeyCredParams: [
                    { alg: -7, type: 'public-key' },  // ES256 (NIST P-256)
                    { alg: -257, type: 'public-key' } // RS256
                ],
                authenticatorSelection: {
                    authenticatorAttachment: 'platform',
                    userVerification: 'required',
                    residentKey: 'preferred'
                },
                timeout: 60000,
                attestation: 'none'
            }
        };

        const credential = await navigator.credentials.create(createOptions);
        if (!credential) {
            throw new Error('Registro de Passkey cancelado');
        }

        const passkeyData = {
            id: credential.id,
            rawId: btoa(String.fromCharCode(...new Uint8Array(credential.rawId))),
            type: credential.type,
            userEmail: userEmail,
            createdAt: new Date().toISOString()
        };

        try {
            localStorage.setItem('csid_passkey_cred_' + userEmail, JSON.stringify(passkeyData));
        } catch (_) {}

        return {
            success: true,
            passkey: passkeyData
        };
    }

    /**
     * Autenticar con Passkey biométrica (Face ID / Touch ID / Sensor Android)
     * @param {string} userEmail - Email opcional para filtrar credenciales
     */
    async signInWithPasskey(userEmail = '') {
        if (!await this.isPasskeySupported()) {
            throw new Error('Passkeys biométricas no disponibles en este navegador o sistema.');
        }

        const challengeBytes = crypto.getRandomValues(new Uint8Array(32));
        const getOptions = {
            publicKey: {
                challenge: challengeBytes,
                timeout: 60000,
                userVerification: 'required',
                rpId: window.location.hostname
            }
        };

        if (userEmail) {
            try {
                const stored = localStorage.getItem('csid_passkey_cred_' + userEmail);
                if (stored) {
                    const parsed = JSON.parse(stored);
                    const rawIdBytes = Uint8Array.from(atob(parsed.rawId), c => c.charCodeAt(0));
                    getOptions.publicKey.allowCredentials = [{
                        id: rawIdBytes,
                        type: 'public-key',
                        transports: ['internal']
                    }];
                }
            } catch (_) {}
        }

        const assertion = await navigator.credentials.get(getOptions);
        if (!assertion) {
            throw new Error('Verificación biométrica no completada.');
        }

        // Simular o resolver token con sesión soberana
        const verifiedEmail = userEmail || this.getCurrentUser()?.email || 'soberano@cokistudios.com';
        const userObj = {
            id: 'csid_fido2_' + assertion.id.substring(0, 16),
            email: verifiedEmail,
            name: verifiedEmail.split('@')[0],
            is_passkey_authenticated: true
        };

        setCookieJSON('coki_current_user', userObj, { maxAge: 7 * 24 * 60 * 60 });
        setCookie('coki_access_token', 'cs_passkey_tok_' + assertion.id, { maxAge: 7 * 24 * 60 * 60 });

        return {
            success: true,
            user: userObj,
            credentialId: assertion.id
        };
    }

    _decodeJwePayload(jweToken) {
        if (!jweToken || typeof jweToken !== 'string') return null;
        try {
            // Si es JWT estándar o payload inspeccionable
            const parts = jweToken.split('.');
            if (parts.length === 5) {
                // JWE Compact - decodificar header y datos si están claros
                const header = JSON.parse(atob(parts[0].replace(/-/g, '+').replace(/_/g, '/')));
                return { isJWE: true, algorithm: header.alg };
            } else if (parts.length === 3) {
                return JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
            }
        } catch (_) {}
        return null;
    }

    _injectStyles() {
        if (typeof document === 'undefined' || document.getElementById('csid-connect-styles')) return;

        const style = document.createElement('style');
        style.id = 'csid-connect-styles';
        style.textContent = `
            .csid-btn {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                gap: 10px;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
                font-weight: 600;
                cursor: pointer;
                border: 1px solid transparent;
                transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
                user-select: none;
                text-decoration: none;
                box-sizing: border-box;
                position: relative;
                overflow: hidden;
            }
            .csid-btn:active { transform: scale(0.98); }
            
            /* Tamaños */
            .csid-btn-small { height: 36px; padding: 0 14px; font-size: 13px; }
            .csid-btn-medium { height: 44px; padding: 0 18px; font-size: 14.5px; }
            .csid-btn-large { height: 50px; padding: 0 24px; font-size: 16px; }

            /* Formas */
            .csid-shape-pill { border-radius: 9999px; }
            .csid-shape-rounded { border-radius: 12px; }
            .csid-shape-square { border-radius: 4px; }

            /* Temas */
            .csid-btn-glass {
                background: rgba(15, 23, 42, 0.75);
                backdrop-filter: blur(12px);
                -webkit-backdrop-filter: blur(12px);
                color: #FFFFFF;
                border-color: rgba(255, 255, 255, 0.12);
                box-shadow: 0 4px 18px rgba(0, 0, 0, 0.25);
            }
            .csid-btn-glass:hover {
                background: rgba(26, 38, 66, 0.85);
                border-color: rgba(0, 245, 212, 0.4);
                box-shadow: 0 6px 24px rgba(0, 245, 212, 0.15);
            }

            .csid-btn-dark {
                background: #090D16;
                color: #F8FAFC;
                border-color: #1E293B;
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
            }
            .csid-btn-dark:hover {
                background: #111827;
                border-color: #38BDF8;
            }

            .csid-btn-light {
                background: #FFFFFF;
                color: #0F172A;
                border-color: #E2E8F0;
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
            }
            .csid-btn-light:hover {
                background: #F8FAFC;
                border-color: #00F5D4;
                box-shadow: 0 4px 14px rgba(0, 0, 0, 0.1);
            }

            .csid-btn-outline {
                background: transparent;
                color: #38BDF8;
                border-color: #38BDF8;
            }
            .csid-btn-outline:hover {
                background: rgba(56, 189, 248, 0.08);
            }

            .csid-btn-badge {
                font-size: 10px;
                font-weight: 700;
                padding: 2px 6px;
                border-radius: 999px;
                background: rgba(0, 245, 212, 0.15);
                color: #00F5D4;
                border: 1px solid rgba(0, 245, 212, 0.3);
                letter-spacing: 0.05em;
            }

            /* Loading spinner */
            .csid-btn-loading { opacity: 0.7; pointer-events: none; }
            .csid-btn-loading .csid-btn-icon {
                animation: csid-spin 0.8s linear infinite;
            }
            @keyframes csid-spin {
                from { transform: rotate(0deg); }
                to { transform: rotate(360deg); }
            }

            /* ── ONE-TAP FLOATING CARD ── */
            .csid-onetap-banner {
                position: fixed;
                top: 20px;
                right: 20px;
                width: 340px;
                background: rgba(13, 19, 33, 0.92);
                backdrop-filter: blur(20px);
                -webkit-backdrop-filter: blur(20px);
                border: 1px solid rgba(255, 255, 255, 0.12);
                border-radius: 20px;
                box-shadow: 0 20px 45px rgba(0, 0, 0, 0.5), 0 0 25px rgba(0, 245, 212, 0.1);
                color: #F8FAFC;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                padding: 16px;
                z-index: 999999;
                opacity: 0;
                transform: translateY(-16px) scale(0.96);
                transition: all 0.28s cubic-bezier(0.16, 1, 0.3, 1);
            }
            .csid-onetap-visible {
                opacity: 1;
                transform: translateY(0) scale(1);
            }
            .csid-onetap-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 12px;
            }
            .csid-onetap-brand {
                display: flex;
                align-items: center;
                gap: 8px;
                font-size: 12px;
                font-weight: 700;
                color: #38BDF8;
                text-transform: uppercase;
                letter-spacing: 0.04em;
            }
            .csid-onetap-close {
                background: none;
                border: none;
                color: #94A3B8;
                font-size: 20px;
                cursor: pointer;
                padding: 0 4px;
                line-height: 1;
            }
            .csid-onetap-close:hover { color: #FFF; }
            .csid-onetap-user {
                display: flex;
                align-items: center;
                gap: 12px;
                background: rgba(255, 255, 255, 0.04);
                border: 1px solid rgba(255, 255, 255, 0.06);
                border-radius: 14px;
                padding: 10px 12px;
                margin-bottom: 10px;
            }
            .csid-onetap-avatar-img {
                width: 36px;
                height: 36px;
                border-radius: 50%;
                object-fit: cover;
            }
            .csid-onetap-avatar-placeholder {
                width: 36px;
                height: 36px;
                border-radius: 50%;
                background: linear-gradient(135deg, #FBBF24, #00F5D4);
                color: #0A0E17;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: 800;
                font-size: 15px;
            }
            .csid-onetap-name { font-size: 13.5px; font-weight: 600; color: #FFF; }
            .csid-onetap-email { font-size: 12px; color: #94A3B8; }
            .csid-onetap-desc {
                font-size: 12.5px;
                color: #94A3B8;
                margin-bottom: 14px;
                line-height: 1.4;
            }
            .csid-onetap-submit {
                width: 100%;
                height: 40px;
                background: linear-gradient(135deg, #0EA5E9, #00F5D4);
                border: none;
                border-radius: 12px;
                color: #0A0E17;
                font-weight: 700;
                font-size: 13.5px;
                cursor: pointer;
                transition: opacity 0.15s ease;
            }
            .csid-onetap-submit:hover { opacity: 0.92; }
            .csid-onetap-footer {
                margin-top: 10px;
                font-size: 11px;
                color: #64748B;
                text-align: center;
            }
        `;
        document.head.appendChild(style);
    }
}

// Singleton global
export const CSIDConnect = new CSIDConnectClient();

// Registrar Web Component opcional <csid-connect-button>
if (typeof customElements !== 'undefined' && !customElements.get('csid-connect-button')) {
    class CSIDConnectButtonElement extends HTMLElement {
        connectedCallback() {
            const clientId = this.getAttribute('client-id') || 'demo-app-123';
            const theme = this.getAttribute('theme') || 'glass';
            const size = this.getAttribute('size') || 'medium';
            const shape = this.getAttribute('shape') || 'pill';
            const text = this.getAttribute('text') || 'continue';
            const mode = this.getAttribute('mode') || 'popup';

            CSIDConnect.init({ clientId });
            CSIDConnect.renderButton(this, {
                theme, size, shape, text, mode,
                onSuccess: (res) => {
                    this.dispatchEvent(new CustomEvent('success', { detail: res }));
                },
                onError: (err) => {
                    this.dispatchEvent(new CustomEvent('error', { detail: err }));
                }
            });
        }
    }
    customElements.define('csid-connect-button', CSIDConnectButtonElement);
}

if (typeof window !== 'undefined') {
    window.CSIDConnect = CSIDConnect;
}
