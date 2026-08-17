// ═══════════════════════════════════════════════════════════════
// 🏢 COKI STUDIOS AUTH SYSTEM v2 — Con Cookies
// Registro, login y gestión de usuarios de Coki Studios
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { setCookie, getCookie, deleteCookie, setCookieJSON, getCookieJSON, getBrowserHash, regenerateBrowserHash } from './cookie-utils.js';

// 🔧 CONFIGURACIÓN SUPABASE
const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ─── CATEGORÍAS GLOBALES & TASTE MATCHING ───
const DEFAULT_CATEGORIES = [
    { id: 'cat-general', name: 'General', slug: 'general', color: '#6366f1', icon: '💬', keywords: ['hola', 'comunidad', 'general', 'charla', 'todos', 'noticia', 'bienvenida', 'foro'] },
    { id: 'cat-gaming', name: 'Videojuegos & Arcade', slug: 'gaming', color: '#ec4899', icon: '🎮', keywords: ['juego', 'game', 'coki dash', 'arcade', 'record', 'score', 'nivel', 'truco', 'gameplay', 'jugador'] },
    { id: 'cat-dev', name: 'Desarrollo & Código', slug: 'dev', color: '#38bdf8', icon: '💻', keywords: ['codigo', 'code', 'programacion', 'javascript', 'swift', 'api', 'bug', 'dev', 'web', 'github', 'app'] },
    { id: 'cat-eco', name: 'Forkman Eco Hub', slug: 'eco', color: '#10b981', icon: '🌱', keywords: ['eco', 'planeta', 'recicla', 'bici', 'co2', 'arbol', 'huella', 'energia', 'ambiente', 'forkman'] },
    { id: 'cat-design', name: 'Diseño & Arte', slug: 'design', color: '#f59e0b', icon: '🎨', keywords: ['diseño', 'ui', 'ux', 'arte', 'dibujo', 'ilustracion', 'color', 'grafico', 'render', 'logo'] },
    { id: 'cat-music', name: 'Música & Audio', slug: 'music', color: '#a855f7', icon: '🎵', keywords: ['musica', 'cancion', 'sonido', 'audio', 'track', 'album', 'ritmo', 'playlist', 'estilo'] },
    { id: 'cat-science', name: 'Ciencia & Futuro', slug: 'science', color: '#14b8a6', icon: '🔬', keywords: ['ciencia', 'espacio', 'ia', 'robot', 'futuro', 'tecnologia', 'universo', 'innovacion'] },
    { id: 'cat-help', name: 'Ayuda & Preguntas', slug: 'help', color: '#ef4444', icon: '❓', keywords: ['ayuda', 'pregunta', 'error', 'problema', 'duda', 'soporte', 'como', 'resolver'] }
];

// ═══════════════════════════════════════════════════════════════
// 📝 REGISTRO DE USUARIOS COKI STUDIOS
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
        console.error('❌ Error registro Coki:', error);
        return { success: false, error: error.message };
    }
    
    console.log('✅ Cuenta Coki creada:', data.user.email);
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
        console.error('❌ Error login Coki:', error);
        return { success: false, error: error.message };
    }
    
    // 🍪 GUARDAR EN COOKIES (7 días)
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
    
    // 🔑 Vincular Hash de Navegador en Supabase
    await bindBrowserHash(data.user.id, data.user.email);

    console.log('✅ Sesión Coki iniciada:', data.user.email);
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
        if (error) console.warn('⚠️ Error al vincular Browser Hash:', error.message);
        else console.log('🔑 Browser Hash vinculado en cookies:', hash);
    } catch (e) {
        console.warn('⚠️ Error bindBrowserHash:', e);
    }
}

async function unbindBrowserHash() {
    try {
        const hash = getBrowserHash();
        const { error } = await supabase
            .from('user_device_hashes')
            .delete()
            .eq('device_hash', hash);
        if (error) console.warn('⚠️ Error al desvincular Browser Hash:', error.message);
    } catch (e) {
        console.warn('⚠️ Error unbindBrowserHash:', e);
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
        console.log('🔄 Sesión restaurada desde Browser Hash Cookie:', data.user_email);
        return restoredUser;
    } catch (e) {
        console.warn('⚠️ Error restoreSessionFromBrowserHash:', e);
        return null;
    }
}

async function loginCokiWithOAuth(provider) {
    const { data, error } = await supabase.auth.signInWithOAuth({
        provider: provider,
        options: {
            redirectTo: window.location.origin + '/coki-oauth-callback.html',
            scopes: provider === 'google' ? 'profile email' : undefined
        }
    });
    
    if (error) {
        console.error('❌ Error OAuth externo:', error);
        return { success: false, error: error.message };
    }
    
    return { success: true };
}

async function handleCokiOAuthCallback() {
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error || !session) {
        return { success: false, error: error?.message || 'No session' };
    }
    
    const user = session.user;
    
    // 🍪 GUARDAR EN COOKIES
    setCookieJSON('coki_current_user', {
        id: user.id,
        email: user.email,
        name: user.user_metadata?.full_name || user.user_metadata?.name || user.email || user.phone || 'Usuario',
        picture: user.user_metadata?.avatar_url || user.user_metadata?.picture,
        metadata: user.user_metadata
    }, { maxAge: 7 * 24 * 60 * 60 });
    
    if (session) {
        setCookie('coki_access_token', session.access_token, { maxAge: 7 * 24 * 60 * 60 });
        setCookie('coki_refresh_token', session.refresh_token, { maxAge: 7 * 24 * 60 * 60 });
    }

    await bindBrowserHash(user.id, user.email);
    
    return { success: true, user };
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
    
    // 🍪 ACTUALIZAR COOKIE
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
    
    // 🍪 LIMPIAR TODAS LAS COOKIES DE COKI
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
            return {
                id: user.id,
                email: user.email,
                name: user.user_metadata?.full_name || user.email || user.phone || 'Usuario',
                picture: user.user_metadata?.avatar_url,
                metadata: user.user_metadata
            };
        }

        // 🔄 MIGRACIÓN AUTOMÁTICA Y LIMPIEZA DE SESIONES OBSOLETAS
        if (error && (error.message?.includes('Invalid Refresh Token') || error.message?.includes('JWT') || error.status === 401 || error.status === 400)) {
            console.warn('⚠️ Sesión de base de datos anterior detectada. Limpiando tokens obsoletos...');
            deleteCookie('coki_access_token');
            deleteCookie('coki_refresh_token');
            await supabase.auth.signOut().catch(() => {});
        }
    } catch (e) {
        console.warn('⚠️ Error verificando usuario Supabase:', e);
    }
    
    // 🍪 FALLBACK: Leer de cookies o restaurar por Browser Hash
    const stored = getCookieJSON('coki_current_user');
    if (stored) return stored;

    const restored = await restoreSessionFromBrowserHash();
    return restored || null;
}

// 🎧 Escuchar cambios de auth
supabase.auth.onAuthStateChange((event, session) => {
    console.log('🔔 Coki Auth event:', event);
    
    if (event === 'SIGNED_IN' && session) {
        const user = session.user;
        setCookieJSON('coki_current_user', {
            id: user.id,
            email: user.email,
            name: user.user_metadata?.full_name || user.email || user.phone || 'Usuario',
            picture: user.user_metadata?.avatar_url,
            metadata: user.user_metadata
        }, { maxAge: 7 * 24 * 60 * 60 });
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
        console.error('❌ Error sendCokiOTP:', err);
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
        console.error('❌ Error verifyCokiOTP:', err);
        return { success: false, error: err.message };
    }
}

// ═══════════════════════════════════════════════════════════════
// 🔑 WEBAUTHN / PASSKEYS INTEGRATION (Face ID, Touch ID, Windows Hello)
// ═══════════════════════════════════════════════════════════════

async function isPasskeySupported() {
    return window.PublicKeyCredential !== undefined &&
           typeof window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable === 'function' &&
           await window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
}

async function registerPasskey() {
    try {
        const user = await getCurrentCokiUser();
        if (!user) throw new Error('Debes iniciar sesión para vincular una Passkey');

        if (!await isPasskeySupported()) {
            throw new Error('Tu dispositivo o navegador no soporta Passkeys / Biometría.');
        }

        const challenge = new Uint8Array(32);
        window.crypto.getRandomValues(challenge);

        const userIdBytes = new TextEncoder().encode(user.id);

        const hostname = window.location.hostname;
        const rpId = (hostname === 'cokistudios.com' || hostname.endsWith('.cokistudios.com')) ? 'cokistudios.com' : hostname;

        const publicKeyCredentialCreationOptions = {
            challenge: challenge,
            rp: {
                name: "CSID - Coki Studios",
                id: rpId
            },
            user: {
                id: userIdBytes,
                name: user.email || 'usuario',
                displayName: user.name || user.email || 'Usuario'
            },
            pubKeyCredParams: [{ alg: -7, type: "public-key" }, { alg: -257, type: "public-key" }],
            authenticatorSelection: {
                authenticatorAttachment: "platform",
                userVerification: "preferred"
            },
            timeout: 60000,
            attestation: "none"
        };

        const credential = await navigator.credentials.create({
            publicKey: publicKeyCredentialCreationOptions
        });

        if (!credential) throw new Error('No se pudo crear la Passkey');

        // Guardar identificador de Passkey en el perfil del usuario
        const passkeyId = btoa(String.fromCharCode(...new Uint8Array(credential.rawId)));
        
        // Almacenar en metadata y localStorage
        localStorage.setItem(`csid_passkey_${user.id}`, passkeyId);
        localStorage.setItem('csid_last_passkey_user', user.email);
        localStorage.setItem('csid_last_passkey_user_id', user.id);

        await updateCokiProfile({
            has_passkey: true,
            passkey_created_at: new Date().toISOString()
        });

        return { success: true, credentialId: passkeyId };
    } catch (err) {
        console.error('❌ Error registrando Passkey:', err);
        return { success: false, error: err.message };
    }
}

async function loginWithPasskey() {
    try {
        if (!await isPasskeySupported()) {
            throw new Error('Passkeys no están soportadas en este navegador o app.');
        }

        const hostname = window.location.hostname;
        const rpId = (hostname === 'cokistudios.com' || hostname.endsWith('.cokistudios.com')) ? 'cokistudios.com' : hostname;

        const challenge = new Uint8Array(32);
        window.crypto.getRandomValues(challenge);

        const publicKeyCredentialRequestOptions = {
            challenge: challenge,
            timeout: 60000,
            rpId: rpId,
            userVerification: "preferred"
        };

        const assertion = await navigator.credentials.get({
            publicKey: publicKeyCredentialRequestOptions
        });

        if (!assertion) throw new Error('Autenticación con Passkey cancelada');

        // Restaurar sesión o vincular cookie activa
        const storedUser = getCookieJSON('coki_current_user');
        if (storedUser) {
            return { success: true, user: storedUser };
        }

        const restored = await restoreSessionFromBrowserHash();
        if (restored) {
            return { success: true, user: restored };
        }

        const lastUserId = localStorage.getItem('csid_last_passkey_user_id');
        const lastUserEmail = localStorage.getItem('csid_last_passkey_user');
        if (lastUserId || lastUserEmail) {
            const fallbackUser = {
                id: lastUserId || 'passkey-user',
                email: lastUserEmail || 'passkey@cokistudios.com',
                name: lastUserEmail?.split('@')[0] || 'Usuario Passkey'
            };
            setCookieJSON('coki_current_user', fallbackUser, { maxAge: 7 * 24 * 60 * 60 });
            return { success: true, user: fallbackUser };
        }

        return { success: true, message: 'Passkey verificada con éxito' };
    } catch (err) {
        console.error('❌ Error login con Passkey:', err);
        const msg = err.name === 'NotAllowedError' ? 'No se encontró una Passkey registrada en este dispositivo o la operación fue cancelada.' : (err.message || 'Error al autenticar');
        return { success: false, error: msg };
    }
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
    loginWithPasskey
};

