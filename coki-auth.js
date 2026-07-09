// ═══════════════════════════════════════════════════════════════
// 🏢 COKI STUDIOS AUTH SYSTEM v2 — Con Cookies
// Registro, login y gestión de usuarios de Coki Studios
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
import { setCookie, getCookie, deleteCookie, setCookieJSON, getCookieJSON } from './cookie-utils.js';

// 🔧 CONFIGURACIÓN SUPABASE
const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const AUTH_HELPER_URL = 'http://localhost:5001';

// ═══════════════════════════════════════════════════════════════
// 📝 REGISTRO DE USUARIOS COKI STUDIOS
// ═══════════════════════════════════════════════════════════════

async function registerCokiAccount(email, password, metadata = {}) {
    try {
        const response = await fetch(`${AUTH_HELPER_URL}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email,
                password,
                metadata: {
                    full_name: metadata.full_name || '',
                    company: metadata.company || 'Coki Studios',
                    role: metadata.role || 'user',
                    avatar_url: metadata.avatar_url || null,
                    redirect_to: window.location.origin + '/coki-confirm.html',
                    ...metadata
                }
            })
        });
        const result = await response.json();
        if (!response.ok) {
            return { success: false, error: result.error || 'Error al registrar' };
        }
        return { success: true, user: result.user, message: result.message };
    } catch (e) {
        return { success: false, error: e.message };
    }
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
        name: data.user.user_metadata?.full_name || data.user.email.split('@')[0],
        picture: data.user.user_metadata?.avatar_url,
        metadata: data.user.user_metadata
    }, { maxAge: 7 * 24 * 60 * 60 });
    
    if (data.session) {
        setCookie('coki_access_token', data.session.access_token, { maxAge: 7 * 24 * 60 * 60 });
        setCookie('coki_refresh_token', data.session.refresh_token, { maxAge: 7 * 24 * 60 * 60 });
    }
    
    console.log('✅ Sesión Coki iniciada:', data.user.email);
    return { success: true, session: data.session, user: data.user };
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
        name: user.user_metadata?.full_name || user.user_metadata?.name || user.email.split('@')[0],
        picture: user.user_metadata?.avatar_url || user.user_metadata?.picture,
        metadata: user.user_metadata
    }, { maxAge: 7 * 24 * 60 * 60 });
    
    if (session) {
        setCookie('coki_access_token', session.access_token, { maxAge: 7 * 24 * 60 * 60 });
        setCookie('coki_refresh_token', session.refresh_token, { maxAge: 7 * 24 * 60 * 60 });
    }
    
    return { success: true, user };
}

async function resetCokiPassword(email) {
    try {
        const response = await fetch(`${AUTH_HELPER_URL}/auth/recovery`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email,
                redirect_to: window.location.origin + '/coki-register.html?tab=reset'
            })
        });
        const result = await response.json();
        if (!response.ok) {
            return { success: false, error: result.error || 'Error en la recuperación' };
        }
        return { success: true, message: result.message };
    } catch (e) {
        return { success: false, error: e.message };
    }
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
            name: user.user_metadata?.full_name || user.email.split('@')[0],
            picture: user.user_metadata?.avatar_url,
            metadata: user.user_metadata
        };
    }
    
    // 🍪 FALLBACK: Leer de cookies
    const stored = getCookieJSON('coki_current_user');
    return stored || null;
}

// 🎧 Escuchar cambios de auth
supabase.auth.onAuthStateChange((event, session) => {
    console.log('🔔 Coki Auth event:', event);
    
    if (event === 'SIGNED_IN' && session) {
        const user = session.user;
        setCookieJSON('coki_current_user', {
            id: user.id,
            email: user.email,
            name: user.user_metadata?.full_name || user.email.split('@')[0],
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
    getCurrentCokiUser
};
