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
    regenerateBrowserHash
};

