// ═══════════════════════════════════════════════════════════════
// 🏢 COKI STUDIOS OAUTH SERVER v2 — Conectado a Supabase real
// ═══════════════════════════════════════════════════════════════

const SUPABASE_URL = 'https://dwtqcvixrzmgdsetrzbm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3dHFjdml4cnptZ2RzZXRyemJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MjM2ODcsImV4cCI6MjA5Mjk5OTY4N30.3wxZGaQcuwNYIUVR7EBzB3XXsx3_sbvoSpNCv33FwLU';

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ═══════════════════════════════════════════════════════════════
// 🔐 UTILIDADES CRYPTO (PKCE + Tokens)
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
    const { data: client, error } = await supabase
        .from('oauth_clients')
        .select('*')
        .eq('client_id', clientId)
        .eq('is_active', true)
        .single();
    
    if (error || !client) {
        return { valid: false, error: 'invalid_client', error_description: 'Client not registered or inactive' };
    }
    
    if (!client.redirect_uris.includes(redirectUri)) {
        return { valid: false, error: 'invalid_redirect_uri', error_description: 'Redirect URI not allowed' };
    }
    
    return { valid: true, client };
}

// ═══════════════════════════════════════════════════════════════
// 🔑 FUNCIONES PÚBLICAS DEL OAUTH SERVER
// ═══════════════════════════════════════════════════════════════

/**
 * 🚀 PASO 1: App externa redirige aquí
 */
async function handleAuthorizeRequest(urlParams) {
    const clientId = urlParams.get('client_id');
    const redirectUri = urlParams.get('redirect_uri');
    const responseType = urlParams.get('response_type');
    const scope = urlParams.get('scope') || 'openid';
    const codeChallenge = urlParams.get('code_challenge');
    const codeChallengeMethod = urlParams.get('code_challenge_method') || 'S256';
    const state = urlParams.get('state');
    
    if (!clientId || !redirectUri || !codeChallenge) {
        return { error: 'invalid_request', error_description: 'Missing parameters' };
    }
    if (responseType !== 'code') {
        return { error: 'unsupported_response_type', error_description: 'Only code flow supported' };
    }
    
    const validation = await validateClient(clientId, redirectUri);
    if (!validation.valid) return validation;
    
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
    const requests = JSON.parse(sessionStorage.getItem('coki_auth_requests') || '{}');
    const request = requests[codeChallenge];
    
    if (!request) return { error: 'request_expired', error_description: 'Authorization request expired' };
    
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
        console.error('Error saving code:', error);
        return { error: 'server_error', error_description: 'Could not create authorization code' };
    }
    
    await supabase.rpc('connect_app', {
        p_client_id: request.client_id,
        p_scopes: request.scope.split(' ')
    });
    
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
    const { data: codeData, error: findError } = await supabase
        .from('oauth_codes')
        .select('*, oauth_clients(*)')
        .eq('code', code)
        .is('used_at', null)
        .gt('expires_at', new Date().toISOString())
        .single();
    
    if (findError || !codeData) {
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
    
    const { data: { user }, error: userError } = await supabase.auth.admin.getUserById(codeData.user_id);
    
    if (userError || !user) {
        return { error: 'invalid_grant', error_description: 'User not found' };
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
    
    await supabase.from('user_apps')
        .update({ last_used_at: new Date().toISOString() })
        .eq('user_id', user.id)
        .eq('client_id', codeData.client_id);
    
    return {
        access_token: accessToken,
        token_type: 'Bearer',
        expires_in: 3600,
        id_token: idToken,
        scope: codeData.scopes.join(' ')
    };
}

/**
 * 📋 Obtener apps conectadas del usuario
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
 * ❌ Revocar app conectada
 */
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
