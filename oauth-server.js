// ═══════════════════════════════════════════════════════════════
// 🏢 COKI STUDIOS OAUTH SERVER v2 — Conectado a Supabase real (FIXED)
// ═══════════════════════════════════════════════════════════════

const SUPABASE_URL = 'https://dwtqcvixrzmgdsetrzbm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3dHFjdml4cnptZ2RzZXRyemJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MjM2ODcsImV4cCI6MjA5Mjk5OTY4N30.3wxZGaQcuwNYIUVR7EBzB3XXsx3_sbvoSpNCv33FwLU';

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ═══════════════════════════════════════════════════════════════
// 🔐 UTILIDADES CRYPTO
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

function generateJWT(payload, secret) {
    const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const body = btoa(JSON.stringify({
        ...payload,
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        iss: 'coki-studios'
    }));
    return `${header}.${body}.${generateCode(16)}`;
}

// ═══════════════════════════════════════════════════════════════
// ✅ VALIDAR CLIENTE desde Supabase
// ═══════════════════════════════════════════════════════════════

async function validateClient(clientId, redirectUri) {
    console.log('🔍 Validando cliente:', { clientId, redirectUri });

    const { data: client, error } = await supabase
        .from('oauth_clients')
        .select('*')
        .eq('client_id', clientId)
        .eq('is_active', true)
        .single();

    console.log('📊 Resultado DB:', { client, error });

    if (error || !client) {
        return { 
            valid: false, 
            error: 'invalid_client', 
            error_description: 'Client not registered or inactive. Client ID: ' + clientId 
        };
    }

    if (!client.redirect_uris.includes(redirectUri)) {
        return { 
            valid: false, 
            error: 'invalid_redirect_uri', 
            error_description: 'Redirect URI not allowed. Got: ' + redirectUri + ', expected one of: ' + client.redirect_uris.join(', ')
        };
    }

    return { valid: true, client };
}

// ═══════════════════════════════════════════════════════════════
// 🔑 FUNCIONES PÚBLICAS
// ═══════════════════════════════════════════════════════════════

/**
 * 🚀 PASO 1: App externa redirige aquí
 */
async function handleAuthorizeRequest(urlParams) {
    console.log('📥 handleAuthorizeRequest called with:', Object.fromEntries(urlParams));

    const clientId = urlParams.get('client_id');
    const redirectUri = urlParams.get('redirect_uri');
    const responseType = urlParams.get('response_type');
    const scope = urlParams.get('scope') || 'openid';
    const codeChallenge = urlParams.get('code_challenge');
    const codeChallengeMethod = urlParams.get('code_challenge_method') || 'S256';
    const state = urlParams.get('state');

    // Validar parámetros obligatorios
    if (!clientId) {
        return { valid: false, error: 'invalid_request', error_description: 'Missing client_id parameter' };
    }
    if (!redirectUri) {
        return { valid: false, error: 'invalid_request', error_description: 'Missing redirect_uri parameter' };
    }
    if (!codeChallenge) {
        return { valid: false, error: 'invalid_request', error_description: 'Missing code_challenge parameter' };
    }
    if (responseType !== 'code') {
        return { valid: false, error: 'unsupported_response_type', error_description: 'Only code flow supported. Got: ' + responseType };
    }

    // Validar cliente
    const validation = await validateClient(clientId, redirectUri);
    if (!validation.valid) return validation;

    // Guardar request
    const requests = JSON.parse(sessionStorage.getItem('coki_auth_requests') || '{}');
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
    sessionStorage.setItem('coki_auth_requests', JSON.stringify(requests));

    return { valid: true, client_name: validation.client.client_name, client_logo: validation.client.logo_url };
}

/**
 * ✅ PASO 2: Usuario aprueba el login
 */
async function approveAuthorization(codeChallenge, userData) {
    console.log('✅ approveAuthorization called');

    const requests = JSON.parse(sessionStorage.getItem('coki_auth_requests') || '{}');
    const request = requests[codeChallenge];

    if (!request) {
        return { error: 'request_expired', error_description: 'Authorization request expired or invalid' };
    }

    const authCode = generateCode(24);

    const { error } = await supabase.from('oauth_codes').insert({
        code: authCode,
        user_id: userData.id,
        client_id: request.client_id,
        code_challenge: request.code_challenge,
        redirect_uri: request.redirect_uri,
        scopes: request.scope.split(' '),
        expires_at: new Date(Date.now() + 600000).toISOString()
    });

    if (error) {
        console.error('❌ Error saving code:', error);
        return { error: 'server_error', error_description: 'Could not create authorization code: ' + error.message };
    }

    // Registrar app conectada
    try {
        await supabase.rpc('connect_app', {
            p_client_id: request.client_id,
            p_scopes: request.scope.split(' ')
        });
    } catch (e) {
        console.warn('⚠️ connect_app RPC failed (table may not exist):', e);
        // No es crítico, continuar
    }

    delete requests[codeChallenge];
    sessionStorage.setItem('coki_auth_requests', JSON.stringify(requests));

    const redirectUrl = new URL(request.redirect_uri);
    redirectUrl.searchParams.set('code', authCode);
    if (request.state) redirectUrl.searchParams.set('state', request.state);

    return { success: true, redirect_url: redirectUrl.toString() };
}

/**
 * 🔄 PASO 3: Intercambiar code por token
 */
async function exchangeCodeForToken(code, redirectUri, codeVerifier) {
    console.log('🔄 exchangeCodeForToken called');

    const { data: codeData, error: findError } = await supabase
        .from('oauth_codes')
        .select('*')
        .eq('code', code)
        .is('used_at', null)
        .gt('expires_at', new Date().toISOString())
        .single();

    if (findError || !codeData) {
        console.error('❌ Code not found:', findError);
        return { error: 'invalid_grant', error_description: 'Code invalid or expired' };
    }

    if (codeData.redirect_uri !== redirectUri) {
        return { error: 'invalid_grant', error_description: 'Redirect URI mismatch' };
    }

    const expectedChallenge = await sha256(codeVerifier);
    if (expectedChallenge !== codeData.code_challenge) {
        return { error: 'invalid_grant', error_description: 'PKCE verification failed' };
    }

    await supabase.from('oauth_codes')
        .update({ used_at: new Date().toISOString() })
        .eq('id', codeData.id);

    // Obtener usuario de Supabase
    const { data: { user }, error: userError } = await supabase.auth.admin.getUserById(codeData.user_id);

    if (userError || !user) {
        // Fallback: usar datos del token de sesión
        console.warn('⚠️ Could not get user from admin API, using fallback');
        const { data: { session } } = await supabase.auth.getSession();
        if (!session?.user) {
            return { error: 'invalid_grant', error_description: 'User not found' };
        }

        const fallbackUser = session.user;
        const accessToken = generateJWT({ 
            sub: fallbackUser.id, 
            email: fallbackUser.email,
            client_id: codeData.client_id
        }, 'secret');

        const idToken = generateJWT({ 
            sub: fallbackUser.id, 
            email: fallbackUser.email,
            name: fallbackUser.user_metadata?.full_name || fallbackUser.email.split('@')[0],
            picture: fallbackUser.user_metadata?.avatar_url
        }, 'secret');

        return {
            access_token: accessToken,
            token_type: 'Bearer',
            expires_in: 3600,
            id_token: idToken,
            scope: codeData.scopes?.join(' ') || 'openid profile email'
        };
    }

    const accessToken = generateJWT({ 
        sub: user.id, 
        email: user.email,
        client_id: codeData.client_id
    }, 'secret');

    const idToken = generateJWT({ 
        sub: user.id, 
        email: user.email,
        name: user.user_metadata?.full_name || user.email.split('@')[0],
        picture: user.user_metadata?.avatar_url,
        company: user.user_metadata?.company
    }, 'secret');

    return {
        access_token: accessToken,
        token_type: 'Bearer',
        expires_in: 3600,
        id_token: idToken,
        scope: codeData.scopes?.join(' ') || 'openid profile email'
    };
}

/**
 * 📋 Obtener apps conectadas
 */
async function getUserConnectedApps(userId) {
    const { data, error } = await supabase
        .from('user_apps')
        .select(`
            id,
            scopes,
            granted_at,
            last_used_at,
            oauth_clients (client_name, logo_url, website_url, client_id)
        `)
        .eq('user_id', userId)
        .eq('is_active', true);

    if (error) {
        console.error('Error fetching apps:', error);
        return [];
    }

    return data || [];
}

/**
 * ❌ Revocar app
 */
async function revokeConnectedApp(userId, clientId) {
    try {
        const { error } = await supabase.rpc('revoke_app', {
            p_client_id: clientId
        });

        if (error) {
            console.error('Error revoking app:', error);
            return false;
        }

        return true;
    } catch (e) {
        console.warn('revoke_app RPC failed:', e);
        return false;
    }
}

// ═══════════════════════════════════════════════════════════════
// 📦 EXPORTAR
// ═══════════════════════════════════════════════════════════════
export {
    supabase,
    handleAuthorizeRequest,
    approveAuthorization,
    exchangeCodeForToken,
    getUserConnectedApps,
    revokeConnectedApp,
    generateCode,
    sha256
};
