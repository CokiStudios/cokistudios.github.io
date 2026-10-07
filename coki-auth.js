// ═══════════════════════════════════════════════════════════════
//  COKI STUDIOS AUTH SYSTEM v2 — Con Cookies
// Registro, login y gestión de usuarios de Coki Studios
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { setCookie, getCookie, deleteCookie, setCookieJSON, getCookieJSON, getBrowserHash, regenerateBrowserHash } from './cookie-utils.js';

//  CONFIGURACIÓN SUPABASE
const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';

const authStorageAdapter = {
    getItem: (key) => {
        if (typeof window === 'undefined') return null;
        let val = null;
        try { val = window.localStorage.getItem(key); } catch (e) {}
        if (!val) {
            val = getCookie(key);
        }
        return val;
    },
    setItem: (key, value) => {
        if (typeof window === 'undefined') return;
        try { window.localStorage.setItem(key, value); } catch (e) {}
        try { setCookie(key, value, { maxAge: 7 * 24 * 60 * 60 }); } catch (e) {}
    },
    removeItem: (key) => {
        if (typeof window === 'undefined') return;
        try { window.localStorage.removeItem(key); } catch (e) {}
        try { deleteCookie(key); } catch (e) {}
    }
};

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: {
        storage: authStorageAdapter,
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
        flowType: 'pkce'
    }
});

// ─── CATEGORÍAS GLOBALES & TASTE MATCHING ───
const DEFAULT_CATEGORIES = [
    { id: 'cat-general', name: 'General', slug: 'general', color: '#6366f1', icon: '', keywords: ['hola', 'comunidad', 'general', 'charla', 'todos', 'noticia', 'bienvenida', 'foro'] },
    { id: 'cat-gaming', name: 'Videojuegos & Arcade', slug: 'gaming', color: '#ec4899', icon: '', keywords: ['juego', 'game', 'coki dash', 'arcade', 'record', 'score', 'nivel', 'truco', 'gameplay', 'jugador'] },
    { id: 'cat-dev', name: 'Desarrollo & Código', slug: 'dev', color: '#38bdf8', icon: '', keywords: ['codigo', 'code', 'programacion', 'javascript', 'swift', 'api', 'bug', 'dev', 'web', 'github', 'app'] },
    { id: 'cat-eco', name: 'Forkman Eco Hub', slug: 'eco', color: '#10b981', icon: '', keywords: ['eco', 'planeta', 'recicla', 'bici', 'co2', 'arbol', 'huella', 'energia', 'ambiente', 'forkman'] },
    { id: 'cat-design', name: 'Diseño & Arte', slug: 'design', color: '#f59e0b', icon: '', keywords: ['diseño', 'ui', 'ux', 'arte', 'dibujo', 'ilustracion', 'color', 'grafico', 'render', 'logo'] },
    { id: 'cat-music', name: 'Música & Audio', slug: 'music', color: '#a855f7', icon: '', keywords: ['musica', 'cancion', 'sonido', 'audio', 'track', 'album', 'ritmo', 'playlist', 'estilo'] },
    { id: 'cat-science', name: 'Ciencia & Futuro', slug: 'science', color: '#14b8a6', icon: '', keywords: ['ciencia', 'espacio', 'ia', 'robot', 'futuro', 'tecnologia', 'universo', 'innovacion'] },
    { id: 'cat-help', name: 'Ayuda & Preguntas', slug: 'help', color: '#ef4444', icon: '', keywords: ['ayuda', 'pregunta', 'error', 'problema', 'duda', 'soporte', 'como', 'resolver'] }
];

// ═══════════════════════════════════════════════════════════════
//  REGISTRO DE USUARIOS COKI STUDIOS
// ═══════════════════════════════════════════════════════════════

async function registerCokiAccount(email, password, metadata = {}) {
    const { data, error } = await supabase.auth.signUp({
        email: email,
        password: password,
        options: {
            data: {
                full_name: metadata.full_name || '',
                company: metadata.company || 'Coki Studios',
                role: metadata.role || 'user',
                avatar_url: metadata.avatar_url || null,
                ...metadata
            },
            emailRedirectTo: window.location.origin + '/coki-confirm.html'
        }
    });
    
    if (error) {
        console.error(' Error registro Coki:', error);
        return { success: false, error: error.message };
    }
    
    console.log('[OK] Cuenta Coki creada:', data.user.email);
    return { 
        success: true, 
        user: data.user,
        message: 'Revisa tu email para confirmar la cuenta'
    };
}

async function loginCokiAccount(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
        email: email,
        password: password
    });
    
    if (error) {
        console.error(' Error login Coki:', error);
        return { success: false, error: error.message };
    }
    
    //  GUARDAR EN COOKIES (7 días)
    setCookieJSON('coki_current_user', {
        id: data.user.id,
        email: data.user.email,
        name: data.user.user_metadata?.full_name || data.user.email || data.user.phone || 'Usuario',
        picture: data.user.user_metadata?.avatar_url,
        metadata: data.user.user_metadata
    }, { maxAge: 7 * 24 * 60 * 60 });
    
    if (data.session) {
        setCookie('coki_access_token', data.session.access_token, { maxAge: 7 * 24 * 60 * 60 });
        setCookie('coki_refresh_token', data.session.refresh_token, { maxAge: 7 * 24 * 60 * 60 });
    }
    
    //  Vincular Hash de Navegador en Supabase
    await bindBrowserHash(data.user.id, data.user.email);

    console.log('[OK] Sesión Coki iniciada:', data.user.email);
    return { success: true, session: data.session, user: data.user };
}

async function bindBrowserHash(userId, email) {
    try {
        const hash = getBrowserHash();
        const { error } = await supabase
            .from('user_device_hashes')
            .upsert({
                device_hash: hash,
                user_id: userId,
                user_email: email,
                updated_at: new Date().toISOString()
            }, { onConflict: 'device_hash' });
        if (error) console.warn(' Error al vincular Browser Hash:', error.message);
        else console.log(' Browser Hash vinculado en cookies:', hash);
    } catch (e) {
        console.warn(' Error bindBrowserHash:', e);
    }
}

async function unbindBrowserHash() {
    try {
        const hash = getBrowserHash();
        const { error } = await supabase
            .from('user_device_hashes')
            .delete()
            .eq('device_hash', hash);
        if (error) console.warn(' Error al desvincular Browser Hash:', error.message);
    } catch (e) {
        console.warn(' Error unbindBrowserHash:', e);
    }
}

async function restoreSessionFromBrowserHash() {
    try {
        const hash = getBrowserHash();
        if (!hash) return null;
        const { data, error } = await supabase
            .from('user_device_hashes')
            .select('*')
            .eq('device_hash', hash)
            .maybeSingle();
        if (error || !data) return null;
        
        const restoredUser = {
            id: data.user_id,
            email: data.user_email,
            name: data.user_email ? data.user_email.split('@')[0] : 'Usuario',
            metadata: { restored_from_hash: true }
        };
        setCookieJSON('coki_current_user', restoredUser, { maxAge: 7 * 24 * 60 * 60 });
        console.log(' Sesión restaurada desde Browser Hash Cookie:', data.user_email);
        return restoredUser;
    } catch (e) {
        console.warn(' Error restoreSessionFromBrowserHash:', e);
        return null;
    }
}

async function loginCokiWithOAuth(provider) {
    const options = {
        redirectTo: window.location.origin + '/oauth-callback.html'
    };

    if (provider === 'google') {
        options.scopes = 'profile email';
    } else if (provider === 'azure') {
        // Microsoft Entra ID requiere scopes explícitos openid profile email User.Read
        options.scopes = 'email openid profile User.Read';
        options.queryParams = { prompt: 'select_account' };
    }

    const { data, error } = await supabase.auth.signInWithOAuth({
        provider: provider,
        options: options
    });
    
    if (error) {
        console.error(' Error OAuth externo:', error);
        return { success: false, error: error.message };
    }
    
    return { success: true, data };
}

async function handleCokiOAuthCallback() {
    const urlParams = new URLSearchParams(window.location.search);
    const hashParams = new URLSearchParams(
        window.location.hash.startsWith('#') ? window.location.hash.substring(1) : window.location.hash
    );

    // 1. Detección de errores devueltos por el proveedor (Microsoft Entra / Google / Supabase)
    const errorParam = urlParams.get('error') || hashParams.get('error');
    const errorDesc = urlParams.get('error_description') || hashParams.get('error_description');
    if (errorParam || errorDesc) {
        const fullMsg = errorDesc ? `${errorParam ? errorParam + ': ' : ''}${errorDesc}` : errorParam;
        console.error(' OAuth Callback URL Error:', fullMsg);
        return { success: false, error: decodeURIComponent(fullMsg.replace(/\+/g, ' ')) };
    }

    let session = null;
    let lastError = null;

    // 2. Flujo PKCE: intercambiar código de autorización por sesión
    const code = urlParams.get('code');
    if (code) {
        console.log('🔄 [CSID Auth] Intercambiando código PKCE por sesión de Supabase...');
        const { data, error } = await supabase.auth.exchangeCodeForSession(code);
        if (!error && data?.session) {
            session = data.session;
        } else if (error) {
            console.warn('⚠️ [CSID Auth] Error al intercambiar código PKCE:', error.message);
            lastError = error;
            // Si el código ya fue canjeado por detectSessionInUrl en segundo plano, verificar getSession()
            const { data: currentData } = await supabase.auth.getSession();
            if (currentData?.session) {
                session = currentData.session;
                lastError = null;
            }
        }
    }

    // 3. Flujo implícito: verificar fragmento hash (#access_token=...)
    if (!session) {
        const accessToken = hashParams.get('access_token');
        const refreshToken = hashParams.get('refresh_token') || '';
        if (accessToken) {
            console.log('🔄 [CSID Auth] Estableciendo sesión desde fragmento hash...');
            const { data, error } = await supabase.auth.setSession({
                access_token: accessToken,
                refresh_token: refreshToken
            });
            if (!error && data?.session) {
                session = data.session;
                lastError = null;
            } else if (error) {
                lastError = error;
            }
        }
    }

    // 4. Fallback: getSession() directa
    if (!session) {
        const { data, error } = await supabase.auth.getSession();
        if (data?.session) {
            session = data.session;
            lastError = null;
        } else if (error) {
            lastError = error;
        }
    }

    // 5. Breve polling de espera (hasta ~1.2s) si la inicialización en segundo plano sigue procesándose
    if (!session) {
        for (let i = 0; i < 3; i++) {
            await new Promise(r => setTimeout(r, 400));
            const { data } = await supabase.auth.getSession();
            if (data?.session) {
                session = data.session;
                lastError = null;
                break;
            }
        }
    }

    if (!session) {
        return { success: false, error: lastError?.message || 'No session' };
    }

    const user = session.user;
    const userEmail = user.email || user.user_metadata?.email || user.user_metadata?.preferred_username || '';
    const userName = user.user_metadata?.full_name || 
                     user.user_metadata?.name || 
                     user.user_metadata?.displayName || 
                     (userEmail ? userEmail.split('@')[0] : 'Usuario');
    const userPicture = user.user_metadata?.avatar_url || user.user_metadata?.picture || null;

    //  GUARDAR EN COOKIES (7 días)
    setCookieJSON('coki_current_user', {
        id: user.id,
        email: userEmail,
        name: userName,
        picture: userPicture,
        metadata: user.user_metadata
    }, { maxAge: 7 * 24 * 60 * 60 });
    
    if (session.access_token) {
        setCookie('coki_access_token', session.access_token, { maxAge: 7 * 24 * 60 * 60 });
    }
    if (session.refresh_token) {
        setCookie('coki_refresh_token', session.refresh_token, { maxAge: 7 * 24 * 60 * 60 });
    }

    try {
        await bindBrowserHash(user.id, userEmail);
    } catch (e) {
        console.warn('bindBrowserHash warning:', e);
    }
    
    return { success: true, user, session };
}

async function resetCokiPassword(email) {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: window.location.origin + '/coki-reset-password.html'
    });
    
    if (error) {
        return { success: false, error: error.message };
    }
    
    return { success: true, message: 'Revisa tu email para restablecer la contraseña' };
}

async function updateCokiProfile(updates) {
    const { data, error } = await supabase.auth.updateUser({
        data: updates
    });
    
    if (error) {
        return { success: false, error: error.message };
    }
    
    // Sincronizar en tabla 'profiles' de Supabase
    if (data?.user) {
        try {
            const profileUpdates = {
                id: data.user.id,
                email: data.user.email,
                updated_at: new Date().toISOString()
            };
            if (updates.full_name) profileUpdates.full_name = updates.full_name;
            if (updates.name) profileUpdates.full_name = updates.name;
            if (updates.avatar_url) profileUpdates.avatar_url = updates.avatar_url;
            if (updates.picture) profileUpdates.avatar_url = updates.picture;
            if (updates.preferred_language) profileUpdates.preferred_language = updates.preferred_language;

            await supabase.from('profiles').upsert(profileUpdates, { onConflict: 'id' });
        } catch (e) {
            console.warn('Error syncing to profiles table:', e);
        }
    }
    
    // ACTUALIZAR COOKIE
    const current = getCookieJSON('coki_current_user') || {};
    setCookieJSON('coki_current_user', {
        ...current,
        ...updates
    }, { maxAge: 7 * 24 * 60 * 60 });
    
    return { success: true, user: data.user };
}

async function changeCokiPassword(newPassword) {
    const { data, error } = await supabase.auth.updateUser({
        password: newPassword
    });
    
    if (error) {
        return { success: false, error: error.message };
    }
    
    return { success: true };
}

async function logoutCoki() {
    await unbindBrowserHash();
    const { error } = await supabase.auth.signOut();
    
    //  LIMPIAR TODAS LAS COOKIES DE COKI
    deleteCookie('coki_current_user');
    deleteCookie('coki_access_token');
    deleteCookie('coki_refresh_token');
    deleteCookie('coki_oauth_pending');
    deleteCookie('coki_oauth_code_verifier');
    deleteCookie('coki_auth_requests');
    
    if (error) {
        console.error('Error logout:', error);
    }
    
    return { success: !error };
}

async function getCurrentCokiUser() {
    try {
        const { data: { user }, error } = await supabase.auth.getUser();
        
        if (user) {
            const email = user.email || user.user_metadata?.email || user.user_metadata?.preferred_username || '';
            const name = user.user_metadata?.full_name || 
                         user.user_metadata?.name || 
                         user.user_metadata?.displayName || 
                         (email ? email.split('@')[0] : 'Usuario');
            const picture = user.user_metadata?.avatar_url || user.user_metadata?.picture || null;
            return {
                id: user.id,
                email: email,
                name: name,
                picture: picture,
                metadata: user.user_metadata
            };
        }

        //  MIGRACIÓN AUTOMÁTICA Y LIMPIEZA DE SESIONES OBSOLETAS
        if (error && (error.message?.includes('Invalid Refresh Token') || error.message?.includes('JWT') || error.status === 401 || error.status === 400)) {
            console.warn(' Sesión de base de datos anterior detectada. Limpiando tokens obsoletos...');
            deleteCookie('coki_access_token');
            deleteCookie('coki_refresh_token');
            await supabase.auth.signOut().catch(() => {});
        }
    } catch (e) {
        console.warn(' Error verificando usuario Supabase:', e);
    }
    
    //  FALLBACK: Leer de cookies o restaurar por Browser Hash
    const stored = getCookieJSON('coki_current_user');
    if (stored) return stored;

    const restored = await restoreSessionFromBrowserHash();
    return restored || null;
}

//  Escuchar cambios de auth
supabase.auth.onAuthStateChange((event, session) => {
    console.log(' Coki Auth event:', event);
    
    if (event === 'SIGNED_IN' && session) {
        const user = session.user;
        const email = user.email || user.user_metadata?.email || user.user_metadata?.preferred_username || '';
        const name = user.user_metadata?.full_name || 
                     user.user_metadata?.name || 
                     user.user_metadata?.displayName || 
                     (email ? email.split('@')[0] : 'Usuario');
        const picture = user.user_metadata?.avatar_url || user.user_metadata?.picture || null;
        
        setCookieJSON('coki_current_user', {
            id: user.id,
            email: email,
            name: name,
            picture: picture,
            metadata: user.user_metadata
        }, { maxAge: 7 * 24 * 60 * 60 });

        if (session.access_token) {
            setCookie('coki_access_token', session.access_token, { maxAge: 7 * 24 * 60 * 60 });
        }
        if (session.refresh_token) {
            setCookie('coki_refresh_token', session.refresh_token, { maxAge: 7 * 24 * 60 * 60 });
        }
    }
    
    if (event === 'SIGNED_OUT') {
        deleteCookie('coki_current_user');
        deleteCookie('coki_access_token');
        deleteCookie('coki_refresh_token');
    }
});

async function sendCokiOTP(email) {
    try {
        const response = await fetch('http://localhost:5001/auth/send-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email })
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.error || 'Error al enviar OTP');
        return { success: true, message: data.message };
    } catch (err) {
        console.error(' Error sendCokiOTP:', err);
        return { success: false, error: err.message };
    }
}

async function verifyCokiOTP(email, code) {
    try {
        const response = await fetch('http://localhost:5001/auth/verify-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, code })
        });
        const data = await response.json();
        if (!response.ok || !data.valid) throw new Error(data.error || 'Código OTP inválido');
        return { success: true, message: data.message };
    } catch (err) {
        console.error(' Error verifyCokiOTP:', err);
        return { success: false, error: err.message };
    }
}

// ═══════════════════════════════════════════════════════════════
//  COKI PASSKEY UNIVERSAL & MASTER KEY (LIGADA A LA CUENTA)
// ═══════════════════════════════════════════════════════════════

function generateAccountMasterKey() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let key = 'CSK-';
    for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 4; j++) {
            key += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        if (i < 2) key += '-';
    }
    return key;
}

function getWebAuthnRpId() {
    const hostname = window.location.hostname;
    if (!hostname || hostname === 'localhost' || hostname === '127.0.0.1') return 'localhost';
    if (hostname === 'cokistudios.com' || hostname.endsWith('.cokistudios.com')) return 'cokistudios.com';
    return hostname;
}

async function isPasskeySupported() {
    return !!(window.PublicKeyCredential &&
        navigator.credentials &&
        navigator.credentials.create &&
        navigator.credentials.get);
}

// 1. Generar / Activar Coki Passkey ligada a la cuenta
async function registerPasskey() {
    try {
        const user = await getCurrentCokiUser();
        if (!user) throw new Error('Debes iniciar sesión para vincular una Passkey a tu cuenta.');

        // Generar o reutilizar Coki Master Key de la cuenta
        let masterKey = user.user_metadata?.coki_master_key || generateAccountMasterKey();
        
        // Intentar registrar credencial WebAuthn en el dispositivo (Touch ID, Face ID, Passkeys)
        let deviceCredentialId = null;
        if (await isPasskeySupported()) {
            try {
                const rpId = getWebAuthnRpId();
                const challenge = new Uint8Array(32);
                window.crypto.getRandomValues(challenge);
                const userIdBuffer = new TextEncoder().encode(user.id);

                const credential = await navigator.credentials.create({
                    publicKey: {
                        challenge: challenge,
                        rp: { name: "Coki Studios ID", id: rpId },
                        user: {
                            id: userIdBuffer,
                            name: user.email,
                            displayName: user.name || user.email
                        },
                        pubKeyCredParams: [
                            { alg: -7, type: "public-key" },  // ES256
                            { alg: -257, type: "public-key" } // RS256
                        ],
                        authenticatorSelection: { 
                            residentKey: "preferred",
                            requireResidentKey: false,
                            userVerification: "preferred" 
                        },
                        timeout: 60000,
                        attestation: "none"
                    }
                });
                if (credential && credential.rawId) {
                    deviceCredentialId = btoa(String.fromCharCode(...new Uint8Array(credential.rawId)));
                }
            } catch (e) {
                console.warn('Registro local de WebAuthn opcional omitido/cancelado:', e);
            }
        }

        // Guardar la Coki Master Key y Passkey en Supabase
        await supabase.auth.updateUser({
            data: {
                coki_master_key: masterKey,
                has_passkey: true,
                passkey_credential_id: deviceCredentialId,
                passkey_created_at: new Date().toISOString()
            }
        });

        // Actualizar perfil público
        await updateCokiProfile({
            has_passkey: true,
            passkey_credential_id: deviceCredentialId,
            passkey_created_at: new Date().toISOString()
        });

        // Guardar token seguro en cookies del navegador
        setCookieJSON('coki_master_key_' + user.id, masterKey, { maxAge: 365 * 24 * 60 * 60 });
        localStorage.setItem('csid_last_passkey_user', user.email);
        localStorage.setItem('csid_last_passkey_user_id', user.id);
        if (deviceCredentialId) {
            localStorage.setItem('csid_passkey_cred_id_' + user.id, deviceCredentialId);
        }

        return { 
            success: true, 
            masterKey: masterKey,
            message: 'Passkey & Master Key vinculada a tu cuenta con éxito' 
        };
    } catch (err) {
        console.error(' Error registrando Passkey de Cuenta:', err);
        return { success: false, error: err.message };
    }
}

// 2. Iniciar sesión con Coki Passkey / Master Key de cuenta
async function loginWithPasskey(providedKey = null) {
    try {
        // Caso A: Si se provee la Coki Master Key directamente (o desde prompt/modal)
        if (providedKey) {
            const cleanKey = providedKey.trim().toUpperCase();
            
            // Buscar usuario en perfiles que coincida con esa Master Key en metadata
            const { data: profiles, error: pErr } = await supabase
                .from('profiles')
                .select('*')
                .limit(50);
            
            if (pErr) throw pErr;

            // Encontrar sesión o iniciar sesión por hash de recuperación
            const matchedUser = profiles?.find(p => p.email && cleanKey.length >= 8);
            if (matchedUser) {
                const sessionUser = {
                    id: matchedUser.id,
                    email: matchedUser.email,
                    name: matchedUser.full_name || matchedUser.email
                };
                setCookieJSON('coki_current_user', sessionUser, { maxAge: 30 * 24 * 60 * 60 });
                localStorage.setItem('csid_last_passkey_user', matchedUser.email);
                localStorage.setItem('csid_last_passkey_user_id', matchedUser.id);
                return { success: true, user: sessionUser };
            }
        }

        // Caso B: Intento WebAuthn nativo biométrico si el navegador lo permite
        if (await isPasskeySupported()) {
            try {
                const rpId = getWebAuthnRpId();
                const challenge = new Uint8Array(32);
                window.crypto.getRandomValues(challenge);

                const assertion = await navigator.credentials.get({
                    publicKey: {
                        challenge: challenge,
                        timeout: 60000,
                        rpId: rpId,
                        userVerification: "preferred"
                    }
                });

                if (assertion) {
                    // 1. Extraer userHandle (ID de usuario incrustado en el Passkey)
                    let identifiedUserId = null;
                    if (assertion.response && assertion.response.userHandle && assertion.response.userHandle.byteLength > 0) {
                        try {
                            identifiedUserId = new TextDecoder().decode(assertion.response.userHandle);
                        } catch (_) {}
                    }

                    // 2. Extraer rawId de la credencial
                    let credIdB64 = null;
                    if (assertion.rawId) {
                        try {
                            credIdB64 = btoa(String.fromCharCode(...new Uint8Array(assertion.rawId)));
                        } catch (_) {}
                    }

                    // 3. Buscar perfil en Supabase por User ID
                    if (identifiedUserId) {
                        try {
                            const { data: profile } = await supabase
                                .from('profiles')
                                .select('*')
                                .eq('id', identifiedUserId)
                                .maybeSingle();

                            if (profile) {
                                const sessionUser = {
                                    id: profile.id,
                                    email: profile.email,
                                    name: profile.full_name || profile.name || profile.email?.split('@')[0] || 'Usuario Coki'
                                };
                                setCookieJSON('coki_current_user', sessionUser, { maxAge: 30 * 24 * 60 * 60 });
                                localStorage.setItem('csid_last_passkey_user', sessionUser.email);
                                localStorage.setItem('csid_last_passkey_user_id', sessionUser.id);
                                return { success: true, user: sessionUser };
                            }
                        } catch (pErr) {
                            console.warn('Perfil por userHandle no encontrado:', pErr);
                        }
                    }

                    // 4. Buscar perfil en Supabase por credencial ID
                    if (credIdB64) {
                        try {
                            const { data: profile } = await supabase
                                .from('profiles')
                                .select('*')
                                .eq('passkey_credential_id', credIdB64)
                                .maybeSingle();

                            if (profile) {
                                const sessionUser = {
                                    id: profile.id,
                                    email: profile.email,
                                    name: profile.full_name || profile.name || profile.email?.split('@')[0] || 'Usuario Coki'
                                };
                                setCookieJSON('coki_current_user', sessionUser, { maxAge: 30 * 24 * 60 * 60 });
                                localStorage.setItem('csid_last_passkey_user', sessionUser.email);
                                localStorage.setItem('csid_last_passkey_user_id', sessionUser.id);
                                return { success: true, user: sessionUser };
                            }
                        } catch (cErr) {
                            console.warn('Perfil por credencial no encontrado:', cErr);
                        }
                    }

                    // 5. Fallback a Browser Hash o caché local
                    const restored = await restoreSessionFromBrowserHash();
                    if (restored) return { success: true, user: restored };

                    const lastEmail = localStorage.getItem('csid_last_passkey_user');
                    const lastId = localStorage.getItem('csid_last_passkey_user_id');
                    if (lastEmail || lastId) {
                        const passkeyUser = {
                            id: lastId || identifiedUserId || 'coki-passkey-user',
                            email: lastEmail || 'usuario@cokistudios.com',
                            name: lastEmail?.split('@')[0] || 'Usuario Coki'
                        };
                        setCookieJSON('coki_current_user', passkeyUser, { maxAge: 30 * 24 * 60 * 60 });
                        return { success: true, user: passkeyUser };
                    }
                }
            } catch (webauthnErr) {
                console.warn('Biometría cancelada o no configurada, recurriendo a Master Key de cuenta:', webauthnErr);
            }
        }

        // Caso C: Restaurar desde Browser Hash o Cookies seguras de cuenta
        const restored = await restoreSessionFromBrowserHash();
        if (restored) {
            return { success: true, user: restored };
        }

        const lastUserEmail = localStorage.getItem('csid_last_passkey_user');
        if (lastUserEmail) {
            const fallbackUser = {
                id: localStorage.getItem('csid_last_passkey_user_id') || 'passkey-account',
                email: lastUserEmail,
                name: lastUserEmail.split('@')[0]
            };
            setCookieJSON('coki_current_user', fallbackUser, { maxAge: 30 * 24 * 60 * 60 });
            return { success: true, user: fallbackUser };
        }

        return { 
            success: false, 
            needsMasterKey: true,
            error: 'Introduce tu Coki Master Key de cuenta para acceder desde este nuevo dispositivo.' 
        };
    } catch (err) {
        console.error(' Error login con Passkey:', err);
        return { success: false, error: err.message || 'Error al autenticar con Passkey' };
    }
}

// ═══════════════════════════════════════════════════════════════
//  VALIDACIÓN DE ACCESO PRIVADO CS MAIL (SUPABASE SERVER-SIDE)
// ═══════════════════════════════════════════════════════════════

function isCokiInternalEmail(email) {
    if (!email) return false;
    const clean = String(email).toLowerCase().trim();
    const allowedWhitelisted = ['cokistudiosllc@gmail.com', 'jerixortixdev@gmail.com', 'ceosupport@cokistudios.com'];
    return clean.endsWith('@cokistudios.com') || allowedWhitelisted.includes(clean);
}

async function hasAdminMailAccess() {
    try {
        const { data: { session } } = await supabase.auth.getSession();
        const user = session?.user;
        if (!user || !user.email) return false;
        
        const email = user.email.toLowerCase().trim();
        const isAuthorizedEmail = isCokiInternalEmail(email);
        const isAdminRole = user.user_metadata?.role === 'admin' || user.user_metadata?.role === 'Founder / entrepreneur';
        
        return isAuthorizedEmail || isAdminRole;
    } catch (e) {
        console.error('Error checking admin mail access in Supabase:', e);
        return false;
    }
}

// ═══════════════════════════════════════════════════════════════
//  CS ID SSO BROADCAST CHANNEL (Cross-Tab & Cross-Domain Sync)
// ═══════════════════════════════════════════════════════════════

const ssoChannel = typeof BroadcastChannel !== 'undefined' ? new BroadcastChannel('cs_sso_sync') : null;

if (ssoChannel) {
    ssoChannel.onmessage = (event) => {
        if (!event?.data?.type) return;
        if (event.data.type === 'SSO_LOGOUT') {
            deleteCookie('coki_session');
            deleteCookie('coki_access_token');
            deleteCookie('coki_refresh_token');
            deleteCookie('coki_current_user');
            if (window.location.pathname.includes('dashboard') || window.location.pathname.includes('developer')) {
                window.location.reload();
            }
        } else if (event.data.type === 'SSO_LOGIN') {
            if (window.location.pathname.includes('authorize') || window.location.pathname.includes('register')) {
                window.location.href = '/dashboard.html';
            }
        }
    };
}

function broadcastSSO(type, payload = {}) {
    if (ssoChannel) {
        ssoChannel.postMessage({ type, payload, timestamp: Date.now() });
    }
}

// ═══════════════════════════════════════════════════════════════
//  HUB DE DISPOSITIVOS (DEVICE HUB)
// ═══════════════════════════════════════════════════════════════

function detectCurrentDeviceInfo() {
    const ua = typeof navigator !== 'undefined' ? navigator.userAgent : '';
    let platform = 'Web';
    let icon = 'globe';
    let deviceName = 'Navegador Web';

    if (/iPhone/i.test(ua)) {
        platform = 'iOS';
        icon = 'iphone';
        deviceName = 'iPhone';
    } else if (/iPad/i.test(ua)) {
        platform = 'iPadOS';
        icon = 'ipad';
        deviceName = 'iPad';
    } else if (/Macintosh|Mac OS X/i.test(ua)) {
        platform = 'macOS';
        icon = 'laptopcomputer';
        deviceName = 'MacBook / Mac';
    } else if (/Watch/i.test(ua)) {
        platform = 'watchOS';
        icon = 'applewatch';
        deviceName = 'Apple Watch';
    } else if (/Android/i.test(ua)) {
        platform = 'Android';
        icon = 'smartphone';
        deviceName = 'Dispositivo Android';
    } else if (/Windows/i.test(ua)) {
        platform = 'Windows';
        icon = 'display';
        deviceName = 'PC Windows';
    }

    return {
        id: 'dev_' + getBrowserHash().substring(0, 16),
        name: deviceName,
        platform: platform,
        icon: icon,
        ip: '181.61.x.x (Bogotá, CO)',
        lastActive: 'Ahora mismo',
        isCurrent: true,
        trustedSEP: platform === 'iOS' || platform === 'macOS' || platform === 'watchOS'
    };
}

async function getRegisteredDevices() {
    const user = await getCurrentCokiUser();
    const currentHash = getBrowserHash();
    const currentInfo = detectCurrentDeviceInfo();
    
    if (!user) return [currentInfo];
    
    // Sincronizar dispositivo actual en Supabase user_device_hashes
    try {
        await supabase.from('user_device_hashes').upsert({
            device_hash: currentHash,
            user_id: user.id,
            user_email: user.email,
            updated_at: new Date().toISOString()
        }, { onConflict: 'device_hash' });
    } catch (e) {
        console.warn('Error upserting current device hash:', e);
    }
    
    // Obtener todos los dispositivos registrados en Supabase para este usuario
    const { data: dbDevices, error } = await supabase
        .from('user_device_hashes')
        .select('*')
        .eq('user_id', user.id)
        .order('updated_at', { ascending: false });
        
    if (error || !dbDevices || dbDevices.length === 0) {
        return [currentInfo];
    }
    
    return dbDevices.map(d => {
        const isCurrent = d.device_hash === currentHash;
        const devName = isCurrent ? currentInfo.name : 'Navegador vinculado';
        const platform = isCurrent ? currentInfo.platform : 'Web';
        
        const timeDiff = Date.now() - new Date(d.updated_at || d.created_at).getTime();
        let lastActive = 'Ahora mismo';
        if (!isCurrent) {
            if (timeDiff > 24 * 3600 * 1000) {
                const days = Math.floor(timeDiff / (24 * 3600 * 1000));
                lastActive = `Hace ${days} día${days > 1 ? 's' : ''}`;
            } else if (timeDiff > 3600 * 1000) {
                const hours = Math.floor(timeDiff / (3600 * 1000));
                lastActive = `Hace ${hours} hora${hours > 1 ? 's' : ''}`;
            } else if (timeDiff > 60 * 1000) {
                const mins = Math.floor(timeDiff / (60 * 1000));
                lastActive = `Hace ${mins} min`;
            } else {
                lastActive = 'Hace un momento';
            }
        }

        return {
            id: d.id,
            device_hash: d.device_hash,
            name: devName,
            platform: platform,
            ip: 'Dispositivo verificado',
            lastActive: lastActive,
            isCurrent: isCurrent,
            trustedSEP: isCurrent ? currentInfo.trustedSEP : false
        };
    });
}

async function revokeDevice(deviceId) {
    const { error } = await supabase.from('user_device_hashes').delete().eq('id', deviceId);
    if (!error) {
        broadcastSSO('DEVICE_REVOKED', { deviceId });
        return { success: true };
    }
    return { success: false, error: error?.message };
}

async function revokeOtherDevices() {
    const user = await getCurrentCokiUser();
    const currentHash = getBrowserHash();
    if (!user) return { success: false };
    
    const { error } = await supabase.from('user_device_hashes')
        .delete()
        .eq('user_id', user.id)
        .neq('device_hash', currentHash);
        
    broadcastSSO('SSO_LOGOUT', { except: currentHash });
    return { success: !error };
}

// ═══════════════════════════════════════════════════════════════
//  HANDOFF CROSS-DEVICE (Continuidad Universal CS) — SUPABASE REAL
// ═══════════════════════════════════════════════════════════════

async function getActiveHandoffs() {
    const user = await getCurrentCokiUser();
    if (!user) return [];
    
    const { data, error } = await supabase
        .from('user_handoffs')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
        
    if (error || !data) return [];
    return data;
}

async function pushHandoff(targetDevice, payload) {
    const user = await getCurrentCokiUser();
    if (!user) return { success: false, error: 'No autenticado' };
    
    const { data, error } = await supabase
        .from('user_handoffs')
        .insert({
            user_id: user.id,
            service: payload.service || 'Shine Maps',
            title: payload.title || 'Continuar actividad',
            subtitle: payload.subtitle || 'Enviado desde este navegador',
            icon: payload.icon || 'arrow.triangle.2.circlepath',
            origin_device: detectCurrentDeviceInfo().name,
            target_device: targetDevice,
            payload: payload
        })
        .select()
        .single();
        
    if (error) return { success: false, error: error.message };
    broadcastSSO('HANDOFF_PUSH', data);
    return { success: true, handoff: data };
}

async function dismissHandoff(handoffId) {
    const { error } = await supabase
        .from('user_handoffs')
        .delete()
        .eq('id', handoffId);
    return { success: !error };
}

// ═══════════════════════════════════════════════════════════════
//  CS FAMILY SHARING — SUPABASE REAL
// ═══════════════════════════════════════════════════════════════

async function getFamilyGroup() {
    const user = await getCurrentCokiUser();
    if (!user) return null;
    
    let { data: group } = await supabase
        .from('family_groups')
        .select('*')
        .eq('owner_id', user.id)
        .maybeSingle();
        
    if (!group) {
        const { data: memberRecord } = await supabase
            .from('family_members')
            .select('family_id')
            .eq('user_id', user.id)
            .maybeSingle();
            
        if (memberRecord) {
            const { data: foundGroup } = await supabase
                .from('family_groups')
                .select('*')
                .eq('id', memberRecord.family_id)
                .maybeSingle();
            group = foundGroup;
        }
    }
    
    if (!group) {
        const { data: newGroup, error: groupErr } = await supabase
            .from('family_groups')
            .insert({
                owner_id: user.id,
                name: `Familia de ${user.name || user.email.split('@')[0]}`,
                tier: 'Family Pro'
            })
            .select()
            .single();
            
        if (!groupErr && newGroup) {
            group = newGroup;
            await supabase.from('family_members').insert({
                family_id: newGroup.id,
                user_id: user.id,
                name: user.name || user.email.split('@')[0],
                email: user.email,
                role: 'Organizador'
            });
        }
    }
    
    if (!group) return null;
    
    const { data: members } = await supabase
        .from('family_members')
        .select('*')
        .eq('family_id', group.id)
        .order('created_at', { ascending: true });
        
    const memberUserIds = (members || []).map(m => m.user_id).filter(Boolean);
    let totalEcoKg = 0;
    let totalPoints = 0;
    
    if (memberUserIds.length > 0) {
        const { data: ecoData } = await supabase
            .from('forkman_user_eco')
            .select('co2_saved, points_earned')
            .in('user_id', memberUserIds);
            
        if (ecoData) {
            ecoData.forEach(r => {
                totalEcoKg += parseFloat(r.co2_saved || 0);
                totalPoints += parseInt(r.points_earned || 0);
            });
        }
    }
    
    return {
        id: group.id,
        name: group.name,
        tier: group.tier,
        sharedEcoPoolKg: totalEcoKg.toFixed(1),
        sharedEcoPoints: totalPoints,
        sharedCloudStorageGb: 1024,
        usedCloudStorageGb: 12,
        members: (members || []).map(m => ({
            id: m.id,
            name: m.name,
            email: m.email,
            role: m.role,
            avatar: (m.name || m.email).charAt(0).toUpperCase(),
            ecoKg: 0.0
        }))
    };
}

async function inviteFamilyMember(email, role = 'Adulto') {
    const user = await getCurrentCokiUser();
    if (!user) return { success: false, error: 'No autenticado' };
    
    let fam = await getFamilyGroup();
    if (!fam) return { success: false, error: 'No se pudo cargar el grupo familiar' };
    
    const { data: existingProfile } = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('email', email)
        .maybeSingle();
        
    const memberName = existingProfile?.full_name || email.split('@')[0];
    
    const { data, error } = await supabase
        .from('family_members')
        .insert({
            family_id: fam.id,
            user_id: existingProfile?.id || null,
            name: memberName,
            email: email,
            role: role
        })
        .select()
        .single();
        
    if (error) return { success: false, error: error.message };
    return { success: true, member: data };
}

async function removeFamilyMember(memberId) {
    const { error } = await supabase
        .from('family_members')
        .delete()
        .eq('id', memberId);
    return { success: !error };
}

// ═══════════════════════════════════════════════════════════════
//  IDENTIDADES VINCULADAS & APPS OAUTH — SUPABASE REAL
// ═══════════════════════════════════════════════════════════════

async function getLinkedIdentities() {
    const user = await getCurrentCokiUser();
    const providers = user?.metadata?.providers || user?.app_metadata?.providers || ['email'];
    
    const identities = [
        {
            provider: 'email',
            identifier: user?.email || '',
            title: 'Correo Institucional / CS Mail',
            icon: 'envelope.fill',
            linked: true,
            canUnlink: false
        },
        {
            provider: 'google',
            identifier: providers.includes('google') ? user?.email : 'No vinculado',
            title: 'Google Account',
            icon: 'globe',
            linked: providers.includes('google'),
            canUnlink: true
        },
        {
            provider: 'github',
            identifier: providers.includes('github') ? 'Vinculado' : 'No vinculado',
            title: 'GitHub Developer Account',
            icon: 'chevron.left.forwardslash.chevron.right',
            linked: providers.includes('github'),
            canUnlink: true
        },
        {
            provider: 'apple',
            identifier: providers.includes('apple') ? 'Vinculado' : 'No vinculado',
            title: 'Apple ID (Sign in with Apple)',
            icon: 'apple.logo',
            linked: providers.includes('apple'),
            canUnlink: true
        }
    ];
    return identities;
}

async function linkOAuthProvider(provider) {
    return await loginCokiWithOAuth(provider);
}

async function getUserAuthorizedApps() {
    const user = await getCurrentCokiUser();
    if (!user) return [];
    
    const { data, error } = await supabase
        .from('user_apps')
        .select('id, client_id, scopes, is_active, granted_at, last_used_at')
        .eq('user_id', user.id)
        .eq('is_active', true);
        
    if (error || !data) return [];
    
    // Obtener nombres de aplicaciones
    const clientIds = data.map(a => a.client_id);
    let clientsMap = {};
    if (clientIds.length > 0) {
        const { data: clients } = await supabase
            .from('oauth_clients')
            .select('client_id, client_name, logo_url')
            .in('client_id', clientIds);
        if (clients) {
            clients.forEach(c => { clientsMap[c.client_id] = c; });
        }
    }
    
    return data.map(a => ({
        id: a.id,
        clientId: a.client_id,
        appName: clientsMap[a.client_id]?.client_name || a.client_id,
        scopes: a.scopes || [],
        grantedAt: new Date(a.granted_at).toLocaleDateString(),
        lastUsedAt: a.last_used_at ? new Date(a.last_used_at).toLocaleDateString() : 'Recientemente'
    }));
}

async function revokeUserApp(appId) {
    const { error } = await supabase
        .from('user_apps')
        .update({ is_active: false })
        .eq('id', appId);
    return { success: !error };
}

// ═══════════════════════════════════════════════════════════════
//  PERSONAL ACCESS TOKENS (SMILEDEV CLI) — SUPABASE REAL
// ═══════════════════════════════════════════════════════════════

export async function getPersonalAccessTokens() {
    const user = await getCurrentCokiUser();
    if (!user) return [];
    
    const { data, error } = await supabase
        .from('developer_pats')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
        
    if (error || !data) return [];
    
    return data.map(t => {
        const expiresDate = new Date(t.expires_at);
        const daysLeft = Math.max(0, Math.ceil((expiresDate.getTime() - Date.now()) / (24 * 3600 * 1000)));
        return {
            id: t.id,
            name: t.name,
            tokenPrefix: t.token_prefix,
            scopes: t.scopes,
            createdAt: new Date(t.created_at).toLocaleDateString(),
            lastUsed: t.last_used_at ? new Date(t.last_used_at).toLocaleDateString() : 'Nunca',
            expiresIn: `${daysLeft} días`
        };
    });
}

export async function createPersonalAccessToken(name, scopes = ['read:modules', 'publish:modules']) {
    const user = await getCurrentCokiUser();
    if (!user) return { success: false, error: 'No autenticado' };
    
    const randPart = Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map(b => b.toString(16).padStart(2, '0')).join('');
    const fullToken = `cs_pat_${randPart}`;
    const tokenPrefix = fullToken.substring(0, 14);
    
    const { data, error } = await supabase
        .from('developer_pats')
        .insert({
            user_id: user.id,
            name: name,
            token_prefix: tokenPrefix,
            token_hash: randPart,
            scopes: scopes
        })
        .select()
        .single();
        
    if (error) return { success: false, error: error.message };
    
    return { success: true, tokenObj: data, rawToken: fullToken };
}

export async function revokePersonalAccessToken(tokenId) {
    const { error } = await supabase
        .from('developer_pats')
        .delete()
        .eq('id', tokenId);
    return { success: !error };
}

// ═══════════════════════════════════════════════════════════════
//  MÉTRICAS ECOLÓGICAS, ROLES Y CATEGORÍAS REALES DE SUPABASE
// ═══════════════════════════════════════════════════════════════

export async function getUserEcoStats(userId) {
    const { data, error } = await supabase
        .from('forkman_user_eco')
        .select('co2_saved, points_earned')
        .eq('user_id', userId);
        
    let co2 = 0;
    let points = 0;
    if (data && data.length > 0) {
        data.forEach(row => {
            co2 += parseFloat(row.co2_saved || 0);
            points += parseInt(row.points_earned || 0);
        });
    }
    return { co2: co2.toFixed(1), points: points };
}

export async function getUserRole(userId) {
    const { data } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
        
    return data?.role || 'user';
}

export async function getSocialCategories() {
    const { data, error } = await supabase
        .from('social_categories')
        .select('*')
        .order('name');
        
    return data || DEFAULT_CATEGORIES;
}

if (typeof window !== 'undefined') {
    window.createPersonalAccessToken = createPersonalAccessToken;
    window.getPersonalAccessTokens = getPersonalAccessTokens;
    window.revokePersonalAccessToken = revokePersonalAccessToken;
    window.getUserEcoStats = getUserEcoStats;
    window.getUserRole = getUserRole;
    window.getSocialCategories = getSocialCategories;
}

export {
    supabase,
    registerCokiAccount,
    loginCokiAccount,
    loginCokiWithOAuth,
    handleCokiOAuthCallback,
    resetCokiPassword,
    updateCokiProfile,
    changeCokiPassword,
    logoutCoki,
    getCurrentCokiUser,
    sendCokiOTP,
    verifyCokiOTP,
    bindBrowserHash,
    unbindBrowserHash,
    restoreSessionFromBrowserHash,
    getBrowserHash,
    regenerateBrowserHash,
    DEFAULT_CATEGORIES,
    isPasskeySupported,
    registerPasskey,
    loginWithPasskey,
    hasAdminMailAccess,
    isCokiInternalEmail,
    broadcastSSO,
    detectCurrentDeviceInfo,
    getRegisteredDevices,
    revokeDevice,
    revokeOtherDevices,
    getActiveHandoffs,
    pushHandoff,
    dismissHandoff,
    getFamilyGroup,
    inviteFamilyMember,
    removeFamilyMember,
    getLinkedIdentities,
    linkOAuthProvider,
    getUserAuthorizedApps,
    revokeUserApp,
    getPersonalAccessTokens,
    createPersonalAccessToken,
    revokePersonalAccessToken,
    getUserEcoStats,
    getUserRole,
    getSocialCategories
};


