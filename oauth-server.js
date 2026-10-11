// ═══════════════════════════════════════════════════════════════
//  COKI STUDIOS OAUTH SERVER v4 — Con Cookies
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { setCookie, getCookie, deleteCookie, setCookieJSON, getCookieJSON } from './cookie-utils.js';

const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ═══════════════════════════════════════════════════════════════
//  UTILIDADES CRYPTO (PKCE + Tokens)
// ═══════════════════════════════════════════════════════════════

function generateCode(length = 32) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    let result = '';
    const randomValues = new Uint8Array(length);
    crypto.getRandomValues(randomValues);
    for (let i = 0; i < length; i++) {
        result += chars[randomValues[i] % chars.length];
    }
    return result;
}

async function sha256(plain) {
    const encoder = new TextEncoder();
    const data = encoder.encode(plain);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return btoa(String.fromCharCode(...hashArray))
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
}

async function generateJWE(payload, secretKeyStr = 'coki_studios_super_secret_jwe_key_2026') {
    const encoder = new TextEncoder();
    const payloadStr = JSON.stringify({
        ...payload,
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        iss: 'https://csid.cokistudios.com'
    });

    // 1. Derivar clave simétrica AES-GCM (256-bit)
    const keyData = encoder.encode(secretKeyStr.padEnd(32, '0').slice(0, 32));
    const cryptoKey = await crypto.subtle.importKey(
        'raw', keyData, { name: 'AES-GCM' }, false, ['encrypt']
    );

    // 2. Generar IV (Initialization Vector) de 12 bytes
    const iv = crypto.getRandomValues(new Uint8Array(12));

    // 3. Cifrar payload
    const encryptedBuffer = await crypto.subtle.encrypt(
        { name: 'AES-GCM', iv },
        cryptoKey,
        encoder.encode(payloadStr)
    );

    // 4. Formatear como JWE Compact Serialization (Header.EncryptedKey.IV.Ciphertext.Tag)
    const jweHeader = btoa(JSON.stringify({ alg: 'dir', enc: 'A256GCM', typ: 'JWE' }))
        .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

    const base64Iv = btoa(String.fromCharCode(...iv))
        .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

    const encryptedArray = new Uint8Array(encryptedBuffer);
    // Extraer ciphertext y auth tag (últimos 16 bytes de AES-GCM)
    const ciphertext = encryptedArray.slice(0, encryptedArray.length - 16);
    const tag = encryptedArray.slice(encryptedArray.length - 16);

    const base64Ciphertext = btoa(String.fromCharCode(...ciphertext))
        .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    const base64Tag = btoa(String.fromCharCode(...tag))
        .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

    // JWE Compact Serialization con Direct Encryption (Key Encrypted vacía)
    return `${jweHeader}..${base64Iv}.${base64Ciphertext}.${base64Tag}`;
}

async function decryptJWE(jweToken, secretKeyStr = 'coki_studios_super_secret_jwe_key_2026') {
    if (!jweToken || typeof jweToken !== 'string') return null;
    const parts = jweToken.split('.');
    if (parts.length !== 5) {
        if (parts.length === 3) {
            try {
                return JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
            } catch (_) { return null; }
        }
        return null;
    }
    try {
        const [, , ivB64, cipherB64, tagB64] = parts;
        const b64Decode = (str) => {
            let padded = str.replace(/-/g, '+').replace(/_/g, '/');
            while (padded.length % 4) padded += '=';
            const binary = atob(padded);
            const bytes = new Uint8Array(binary.length);
            for (let i = 0; i < binary.length; i++) {
                bytes[i] = binary.charCodeAt(i);
            }
            return bytes;
        };
        const iv = b64Decode(ivB64);
        const ciphertext = b64Decode(cipherB64);
        const tag = b64Decode(tagB64);

        const combined = new Uint8Array(ciphertext.length + tag.length);
        combined.set(ciphertext, 0);
        combined.set(tag, ciphertext.length);

        const encoder = new TextEncoder();
        const keyData = encoder.encode(secretKeyStr.padEnd(32, '0').slice(0, 32));
        const cryptoKey = await crypto.subtle.importKey(
            'raw', keyData, { name: 'AES-GCM' }, false, ['decrypt']
        );

        const decryptedBuffer = await crypto.subtle.decrypt(
            { name: 'AES-GCM', iv },
            cryptoKey,
            combined
        );

        const decoder = new TextDecoder();
        return JSON.parse(decoder.decode(decryptedBuffer));
    } catch (e) {
        console.warn('decryptJWE error:', e);
        return null;
    }
}

// ═══════════════════════════════════════════════════════════════
// [OK] VALIDAR CLIENTE desde Supabase
// ═══════════════════════════════════════════════════════════════

const BUILTIN_OAUTH_CLIENTS = {
    'demo-app-123': {
        client_id: 'demo-app-123',
        client_name: 'App Demo (CS ID Connect)',
        redirect_uris: [
            'https://cokistudios.com/client-demo',
            'https://cokistudios.com/client-demo.html',
            'https://www.cokistudios.com/client-demo',
            'https://www.cokistudios.com/client-demo.html',
            'https://cokistudios.github.io/client-demo',
            'https://cokistudios.github.io/client-demo.html',
            'https://cokistudios.github.io/oauth-callback.html',
            'http://localhost:3000/client-demo',
            'http://localhost:3000/client-demo.html',
            'http://127.0.0.1:3000/client-demo',
            'http://127.0.0.1:3000/client-demo.html',
            'http://localhost:8080/client-demo',
            'http://localhost:8080/client-demo.html',
            'http://127.0.0.1:8080/client-demo',
            'http://127.0.0.1:8080/client-demo.html'
        ],
        allowed_scopes: ['openid', 'profile', 'email', 'offline_access'],
        logo_url: 'https://cokistudios.com/assets/images/logo.png',
        is_active: true
    },
    'csid-connect-demo': {
        client_id: 'csid-connect-demo',
        client_name: 'CS ID Connect Playground',
        redirect_uris: [
            'https://cokistudios.com/client-demo',
            'https://cokistudios.com/client-demo.html',
            'https://www.cokistudios.com/client-demo',
            'https://www.cokistudios.com/client-demo.html',
            'https://cokistudios.github.io/client-demo',
            'https://cokistudios.github.io/client-demo.html',
            'https://cokistudios.github.io/oauth-callback.html',
            'http://localhost:3000/client-demo',
            'http://localhost:3000/client-demo.html',
            'http://127.0.0.1:3000/client-demo',
            'http://127.0.0.1:3000/client-demo.html',
            'http://localhost:8080/client-demo',
            'http://localhost:8080/client-demo.html',
            'http://127.0.0.1:8080/client-demo',
            'http://127.0.0.1:8080/client-demo.html'
        ],
        allowed_scopes: ['openid', 'profile', 'email', 'offline_access'],
        logo_url: 'https://cokistudios.com/assets/images/logo.png',
        is_active: true
    },
    'ourcommonhome': {
        client_id: 'ourcommonhome',
        client_name: 'OurCommonHome',
        redirect_uris: [
            'https://anonymus-devop.github.io/OurCommonHome/',
            'https://anonymus-devop.github.io/OurCommonHome/index.html',
            'https://anonymus-devop.github.io/OurCommonHome/oauth-callback.html',
            'http://localhost:3000/oauth-callback.html'
        ],
        allowed_scopes: ['openid', 'profile', 'email'],
        is_active: true
    }
};

// Normalizar URIs para comparación flexible en todo el ecosystem
function normalizeOAuthUri(u) {
    if (!u) return '';
    try {
        const parsed = new URL(u);
        let host = parsed.host.toLowerCase();
        // Unificar dominios hermanos del ecosistema Coki Studios
        if (host === 'cokistudios.github.io' || host === 'www.cokistudios.com') {
            host = 'cokistudios.com';
        }
        let pathname = parsed.pathname.replace(/\/+$/, '');
        if (pathname.endsWith('.html')) {
            pathname = pathname.slice(0, -5);
        }
        return `${parsed.protocol}//${host}${pathname}`.toLowerCase();
    } catch (_) {
        let s = (u || '').replace(/\/+$/, '');
        if (s.endsWith('.html')) s = s.slice(0, -5);
        return s.toLowerCase();
    }
}

async function validateClient(clientId, redirectUri) {
    console.log(' validateClient:', { clientId, redirectUri });
    
    let client = null;
    try {
        const { data, error } = await supabase
            .from('oauth_clients')
            .select('*')
            .eq('client_id', clientId)
            .eq('is_active', true)
            .single();
        if (!error && data) {
            client = data;
        }
    } catch (e) {
        console.warn('Supabase oauth_clients query failed:', e);
    }

    if (!client && BUILTIN_OAUTH_CLIENTS[clientId]) {
        client = BUILTIN_OAUTH_CLIENTS[clientId];
    } else if (client && BUILTIN_OAUTH_CLIENTS[clientId]) {
        // Enriquecer cliente de Supabase con redirect_uris del ecosistema
        const builtinUris = BUILTIN_OAUTH_CLIENTS[clientId].redirect_uris || [];
        const existingUris = Array.isArray(client.redirect_uris) ? client.redirect_uris : [];
        client.redirect_uris = Array.from(new Set([...existingUris, ...builtinUris]));
    }
    
    if (!client) {
        console.log(' Cliente no encontrado:', clientId);
        return { valid: false, error: 'invalid_client', error_description: 'Client not registered or inactive' };
    }
    
    console.log(' Cliente encontrado:', client.client_name);
    console.log(' Redirect URIs registrados:', client.redirect_uris);

    const normRedirectUri = normalizeOAuthUri(redirectUri);
    const isAllowed = (client.redirect_uris || []).some(registeredUri => {
        return normalizeOAuthUri(registeredUri) === normRedirectUri;
    });
    
    if (!isAllowed) {
        console.log(' Redirect URI no coincide:', redirectUri);
        return { valid: false, error: 'invalid_redirect_uri', error_description: 'Redirect URI not allowed: ' + redirectUri };
    }
    
    return { valid: true, client, cleanRedirectUri: redirectUri };
}

// ═══════════════════════════════════════════════════════════════
//  FUNCIONES PÚBLICAS DEL OAUTH SERVER
// ═══════════════════════════════════════════════════════════════

async function handleAuthorizeRequest(urlParams) {
    const clientId = urlParams.get('client_id');
    let redirectUri = urlParams.get('redirect_uri');
    const responseType = urlParams.get('response_type');
    const scope = urlParams.get('scope') || 'openid';
    const codeChallenge = urlParams.get('code_challenge');
    const codeChallengeMethod = urlParams.get('code_challenge_method') || 'S256';
    const state = urlParams.get('state');
    
    console.log(' handleAuthorizeRequest:', { clientId, redirectUri, responseType, scope, codeChallenge });
    
    if (!clientId || !redirectUri || !codeChallenge) {
        return { error: 'invalid_request', error_description: 'Missing parameters' };
    }
    if (responseType !== 'code') {
        return { error: 'unsupported_response_type', error_description: 'Only code flow supported' };
    }
    
    redirectUri = decodeURIComponent(redirectUri);
    console.log(' redirect_uri decodificado:', redirectUri);
    
    const validation = await validateClient(clientId, redirectUri);
    if (!validation.valid) return validation;
    
    //  GUARDAR REQUEST EN COOKIE (10 minutos)
    const requests = getCookieJSON('coki_auth_requests') || {};
    requests[codeChallenge] = {
        client_id: clientId,
        redirect_uri: redirectUri,
        scope,
        code_challenge: codeChallenge,
        code_challenge_method: codeChallengeMethod,
        state,
        client_name: validation.client.client_name,
        client_logo: validation.client.logo_url
    };
    setCookieJSON('coki_auth_requests', requests, { maxAge: 600 });
    
    console.log(' Request guardado en cookie:', requests[codeChallenge]);
    
    return { valid: true, client_name: validation.client.client_name, client_logo: validation.client.logo_url };
}

async function approveAuthorization(codeChallenge, userData) {
    console.log('[APP] approveAuthorization:', { codeChallenge, userId: userData.id });
    
    //  LEER REQUEST DE COOKIE
    const requests = getCookieJSON('coki_auth_requests') || {};
    const request = requests[codeChallenge];
    
    if (!request) {
        console.log(' Request no encontrado en cookies');
        return { error: 'request_expired', error_description: 'Authorization request expired' };
    }
    
    console.log(' Request encontrado:', request);
    
    const authCode = 'coki_' + Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
    
    console.log(' Code generado:', authCode);
    console.log(' redirect_uri a guardar:', request.redirect_uri);
    
    const { data, error } = await supabase.from('oauth_codes').insert({
        code: authCode,
        user_id: userData.id,
        client_id: request.client_id,
        code_challenge: request.code_challenge,
        redirect_uri: request.redirect_uri,
        scopes: request.scope.split(' '),
        expires_at: new Date(Date.now() + 600000).toISOString()
    });
    
    if (error) {
        console.error(' Error guardando code:', error);
        return { error: 'server_error', error_description: 'Could not create authorization code: ' + error.message };
    }
    
    console.log('[OK] Code guardado en Supabase');
    
    //  LIMPIAR REQUEST
    delete requests[codeChallenge];
    setCookieJSON('coki_auth_requests', requests, { maxAge: 600 });
    
    const redirectUrl = new URL(request.redirect_uri);
    redirectUrl.searchParams.set('code', authCode);
    if (request.state) redirectUrl.searchParams.set('state', request.state);
    
    console.log('[APP] Redirigiendo a:', redirectUrl.toString());
    
    return { success: true, redirect_url: redirectUrl.toString() };
}

async function exchangeCodeForToken(code, redirectUri, codeVerifier) {
    console.log(' exchangeCodeForToken:', { code, redirectUri });
    
    const { data: codeData, error: findError } = await supabase
        .from('oauth_codes')
        .select('*')
        .eq('code', code)
        .is('used_at', null)
        .gt('expires_at', new Date().toISOString())
        .single();
    
    if (findError || !codeData) {
        console.log(' Code no encontrado o expirado:', findError);
        return { error: 'invalid_grant', error_description: 'Code invalid or expired' };
    }

    // Fetch client relation manually to avoid PostgREST foreign key cache issues (PGRST200)
    const { data: clientData, error: clientError } = await supabase
        .from('oauth_clients')
        .select('*')
        .eq('client_id', codeData.client_id)
        .single();

    if (clientError || !clientData) {
        console.log(' Client not found for code:', clientError);
        return { error: 'invalid_client', error_description: 'Client not found' };
    }

    codeData.oauth_clients = clientData;
    
    console.log(' Code encontrado:', codeData.code);
    
    let storedRedirectUri = codeData.redirect_uri;
    let receivedRedirectUri = redirectUri;
    
    if (storedRedirectUri !== receivedRedirectUri && normalizeOAuthUri(storedRedirectUri) !== normalizeOAuthUri(receivedRedirectUri)) {
        console.log(' Redirect URI mismatch:', { stored: storedRedirectUri, received: receivedRedirectUri });
        return { error: 'invalid_grant', error_description: 'Redirect URI mismatch' };
    }
    
    const expectedChallenge = await sha256(codeVerifier);
    if (expectedChallenge !== codeData.code_challenge) {
        console.log(' PKCE verification failed');
        return { error: 'invalid_grant', error_description: 'PKCE verification failed' };
    }
    
    await supabase.from('oauth_codes')
        .update({ used_at: new Date().toISOString() })
        .eq('id', codeData.id);
    
    let user = null;
    try {
        const { data: authUser } = await supabase.auth.getUser();
        if (authUser?.user && authUser.user.id === codeData.user_id) {
            user = authUser.user;
        }
    } catch (_) {}

    if (!user) {
        const cachedUser = getCookieJSON('coki_current_user');
        if (cachedUser && (cachedUser.id === codeData.user_id || !codeData.user_id)) {
            user = {
                id: cachedUser.id || codeData.user_id,
                email: cachedUser.email || 'user@coki.com',
                user_metadata: {
                    full_name: cachedUser.name,
                    avatar_url: cachedUser.picture,
                    company: cachedUser.company
                }
            };
        }
    }

    if (!user) {
        user = {
            id: codeData.user_id,
            email: 'user@coki.com',
            user_metadata: { full_name: 'Usuario CS ID' }
        };
    }
    
    const accessToken = await generateJWE({ 
        sub: user.id, 
        email: user.email,
        client_id: codeData.client_id
    });
    
    const idToken = await generateJWE({ 
        sub: user.id, 
        email: user.email,
        name: user.user_metadata?.full_name || user.email || user.phone || 'Usuario',
        picture: user.user_metadata?.avatar_url,
        company: user.user_metadata?.company
    });
    
    return {
        access_token: accessToken,
        token_type: 'Bearer',
        expires_in: 3600,
        id_token: idToken,
        scope: codeData.scopes.join(' ')
    };
}

async function getUserConnectedApps(userId) {
    const { data: appsData, error: appsError } = await supabase
        .from('user_apps')
        .select('id, scopes, granted_at, last_used_at, client_id')
        .eq('user_id', userId)
        .eq('is_active', true);
    
    if (appsError) {
        console.error('Error fetching apps:', appsError);
        return [];
    }
    
    if (!appsData || appsData.length === 0) return [];

    // Fetch client relations manually to avoid PostgREST foreign key cache issues (PGRST200)
    const clientIds = appsData.map(a => a.client_id);
    const { data: clientsData, error: clientsError } = await supabase
        .from('oauth_clients')
        .select('client_name, logo_url, website_url, client_id')
        .in('client_id', clientIds);

    if (clientsError) {
        console.error('Error fetching clients:', clientsError);
        return [];
    }

    return appsData.map(app => ({
        ...app,
        oauth_clients: clientsData.find(c => c.client_id === app.client_id)
    }));
}

async function revokeConnectedApp(userId, clientId) {
    const { error } = await supabase.rpc('revoke_app', {
        p_client_id: clientId
    });
    
    if (error) {
        console.error('Error revoking app:', error);
        return false;
    }
    
    return true;
}

export {
    supabase,
    validateClient,
    handleAuthorizeRequest,
    approveAuthorization,
    exchangeCodeForToken,
    getUserConnectedApps,
    revokeConnectedApp,
    generateCode,
    sha256,
    generateJWE,
    decryptJWE
};
