// ═══════════════════════════════════════════════════════════════
// 🏢 COKI STUDIOS AUTH SYSTEM
// Registro, login y gestión de usuarios de Coki Studios
// ═══════════════════════════════════════════════════════════════

// 🔧 CONFIGURACIÓN SUPABASE (ya configurado con tus credenciales)
const SUPABASE_URL = 'https://dwtqcvixrzmgdsetrzbm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3dHFjdml4cnptZ2RzZXRyemJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MjM2ODcsImV4cCI6MjA5Mjk5OTY4N30.3wxZGaQcuwNYIUVR7EBzB3XXsx3_sbvoSpNCv33FwLU';

// Importar Supabase
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ═══════════════════════════════════════════════════════════════
// 📝 REGISTRO DE USUARIOS COKI STUDIOS
// ═══════════════════════════════════════════════════════════════

/**
 * Crear cuenta nueva en Coki Studios
 */
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

/**
 * Login con email + password en Coki Studios
 */
async function loginCokiAccount(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
        email: email,
        password: password
    });
    
    if (error) {
        console.error('❌ Error login Coki:', error);
        return { success: false, error: error.message };
    }
    
    sessionStorage.setItem('coki_current_user', JSON.stringify({
        id: data.user.id,
        email: data.user.email,
        name: data.user.user_metadata?.full_name || data.user.email.split('@')[0],
        picture: data.user.user_metadata?.avatar_url,
        metadata: data.user.user_metadata
    }));
    
    console.log('✅ Sesión Coki iniciada:', data.user.email);
    return { success: true, session: data.session, user: data.user };
}

/**
 * Login con OAuth externo (Google/GitHub) pero vinculado a Coki
 */
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

/**
 * Procesar callback de OAuth externo (Google/GitHub → Coki)
 */
async function handleCokiOAuthCallback() {
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error || !session) {
        return { success: false, error: error?.message || 'No session' };
    }
    
    const user = session.user;
    sessionStorage.setItem('coki_current_user', JSON.stringify({
        id: user.id,
        email: user.email,
        name: user.user_metadata?.full_name || user.user_metadata?.name || user.email.split('@')[0],
        picture: user.user_metadata?.avatar_url || user.user_metadata?.picture,
        metadata: user.user_metadata
    }));
    
    return { success: true, user };
}

/**
 * Recuperar contraseña
 */
async function resetCokiPassword(email) {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: window.location.origin + '/coki-reset-password.html'
    });
    
    if (error) {
        return { success: false, error: error.message };
    }
    
    return { success: true, message: 'Revisa tu email para restablecer la contraseña' };
}

/**
 * Actualizar perfil del usuario Coki
 */
async function updateCokiProfile(updates) {
    const { data, error } = await supabase.auth.updateUser({
        data: updates
    });
    
    if (error) {
        return { success: false, error: error.message };
    }
    
    const current = JSON.parse(sessionStorage.getItem('coki_current_user') || '{}');
    sessionStorage.setItem('coki_current_user', JSON.stringify({
        ...current,
        ...updates
    }));
    
    return { success: true, user: data.user };
}

/**
 * Cambiar contraseña
 */
async function changeCokiPassword(newPassword) {
    const { data, error } = await supabase.auth.updateUser({
        password: newPassword
    });
    
    if (error) {
        return { success: false, error: error.message };
    }
    
    return { success: true };
}

/**
 * 🚪 Cerrar sesión Coki
 */
async function logoutCoki() {
    const { error } = await supabase.auth.signOut();
    sessionStorage.removeItem('coki_current_user');
    
    if (error) {
        console.error('Error logout:', error);
    }
    
    return { success: !error };
}

/**
 * 👤 Obtener usuario Coki actual
 */
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
    
    const stored = sessionStorage.getItem('coki_current_user');
    return stored ? JSON.parse(stored) : null;
}

/**
 * 🎧 Escuchar cambios de auth
 */
supabase.auth.onAuthStateChange((event, session) => {
    console.log('🔔 Coki Auth event:', event);
    
    if (event === 'SIGNED_IN' && session) {
        const user = session.user;
        sessionStorage.setItem('coki_current_user', JSON.stringify({
            id: user.id,
            email: user.email,
            name: user.user_metadata?.full_name || user.email.split('@')[0],
            picture: user.user_metadata?.avatar_url,
            metadata: user.user_metadata
        }));
    }
    
    if (event === 'SIGNED_OUT') {
        sessionStorage.removeItem('coki_current_user');
    }
});

// ═══════════════════════════════════════════════════════════════
// 📦 EXPORTAR
// ═══════════════════════════════════════════════════════════════
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
