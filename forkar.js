// ═══════════════════════════════════════════════════════════════
// 🌐 COKI SOCIAL — Sistema de foro/comunidad con CS ID
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ─── CATEGORÍAS ───

async function getCategories() {
    const { data, error } = await supabase
        .from('social_categories')
        .select('*')
        .order('name');
    if (error) { console.error('Error categorías:', error); return []; }
    return data || [];
}

// ─── POSTS ───

async function getPosts(options = {}) {
    const { category, limit = 20, offset = 0 } = options;
    
    let query = supabase
        .from('social_posts')
        .select(`
            *,
            category:social_categories(id, name, slug, color)
        `)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);
    
    if (category) {
        query = query.eq('category_id', category);
    }
    
    const { data, error } = await query;
    if (error) { console.error('Error posts:', error); return []; }
    return data || [];
}

async function getPostById(postId) {
    const { data, error } = await supabase
        .from('social_posts')
        .select(`
            *,
            category:social_categories(id, name, slug, color)
        `)
        .eq('id', postId)
        .single();
    
    if (error) { console.error('Error post:', error); return null; }
    return data;
}

async function createPost(title, content, categoryId = null, mediaOptions = {}) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Debes iniciar sesión' };
    
    const meta = user.user_metadata || {};
    const authorName = meta.full_name || meta.name || user.email || user.phone || 'Usuario';
    const authorAvatar = meta.avatar_url || meta.picture || null;
    
    const insertPayload = {
        user_id: user.id,
        author_name: authorName,
        author_avatar: authorAvatar,
        title,
        content,
        category_id: categoryId
    };

    if (mediaOptions.imageUrl) insertPayload.image_url = mediaOptions.imageUrl;
    if (mediaOptions.videoUrl) insertPayload.video_url = mediaOptions.videoUrl;
    
    const { data, error } = await supabase
        .from('social_posts')
        .insert(insertPayload)
        .select()
        .single();
    
    if (error) return { success: false, error: error.message };
    return { success: true, post: data };
}

async function deletePost(postId) {
    const { error } = await supabase
        .from('social_posts')
        .delete()
        .eq('id', postId);
    
    if (error) return { success: false, error: error.message };
    return { success: true };
}

// ─── COMENTARIOS ───

async function getComments(postId) {
    const { data, error } = await supabase
        .from('social_comments')
        .select('*')
        .eq('post_id', postId)
        .order('created_at', { ascending: true });
    
    if (error) { console.error('Error comentarios:', error); return []; }
    return data || [];
}

async function createComment(postId, content) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Debes iniciar sesión' };
    
    const meta = user.user_metadata || {};
    const authorName = meta.full_name || meta.name || user.email || user.phone || 'Usuario';
    const authorAvatar = meta.avatar_url || meta.picture || null;
    
    const { data, error } = await supabase
        .from('social_comments')
        .insert({
            post_id: postId,
            user_id: user.id,
            author_name: authorName,
            author_avatar: authorAvatar,
            content
        })
        .select()
        .single();
    
    if (error) return { success: false, error: error.message };
    return { success: true, comment: data };
}

async function deleteComment(commentId) {
    const { error } = await supabase
        .from('social_comments')
        .delete()
        .eq('id', commentId);
    
    if (error) return { success: false, error: error.message };
    return { success: true };
}

// ─── LIKES ───

async function getUserLike(postId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;
    
    const { data, error } = await supabase
        .from('social_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();
    
    if (error) return null;
    return data;
}

async function toggleLikePost(postId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Debes iniciar sesión' };
    
    const existing = await getUserLike(postId);
    
    if (existing) {
        const { error } = await supabase
            .from('social_likes')
            .delete()
            .eq('id', existing.id);
        return { success: !error, liked: false, error: error?.message };
    } else {
        const { error } = await supabase
            .from('social_likes')
            .insert({ post_id: postId, user_id: user.id });
        return { success: !error, liked: true, error: error?.message };
    }
}

// ─── SEGUIDORES ───

async function getFollowStats(userId) {
    const { count: followers } = await supabase
        .from('social_follows')
        .select('id', { count: 'exact', head: true })
        .eq('following_id', userId);
    
    const { count: following } = await supabase
        .from('social_follows')
        .select('id', { count: 'exact', head: true })
        .eq('follower_id', userId);
    
    return {
        followers: followers ?? 0,
        following: following ?? 0
    };
}

async function isFollowing(userId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user || user.id === userId) return false;
    
    const { data } = await supabase
        .from('social_follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', userId)
        .maybeSingle();
    
    return !!data;
}

async function toggleFollow(userId) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Debes iniciar sesión' };
    if (user.id === userId) return { success: false, error: 'No puedes seguirte a ti mismo' };
    
    const following = await isFollowing(userId);
    
    if (following) {
        const { error } = await supabase
            .from('social_follows')
            .delete()
            .eq('follower_id', user.id)
            .eq('following_id', userId);
        return { success: !error, following: false, error: error?.message };
    } else {
        const { error } = await supabase
            .from('social_follows')
            .insert({ follower_id: user.id, following_id: userId });
        return { success: !error, following: true, error: error?.message };
    }
}

// ─── PERFILES / POSTS POR USUARIO ───

async function getUserPosts(userId, limit = 10) {
    const { data, error } = await supabase
        .from('social_posts')
        .select(`
            *,
            category:social_categories(id, name, slug, color)
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(limit);
    
    if (error) return [];
    return data || [];
}

// ─── UTILIDADES ───

function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diff = (now - date) / 1000;
    
    if (diff < 60) return 'hace un momento';
    if (diff < 3600) return `hace ${Math.floor(diff / 60)} min`;
    if (diff < 86400) return `hace ${Math.floor(diff / 3600)} h`;
    if (diff < 604800) return `hace ${Math.floor(diff / 86400)} d`;
    return date.toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' });
}

function getUserDisplayName(user) {
    if (!user) return 'Anónimo';
    const meta = user.user_metadata || {};
    return meta.full_name || meta.name || user.email || user.phone || 'Usuario';
}

function getUserAvatar(user) {
    const meta = user?.user_metadata || {};
    return meta.avatar_url || meta.picture || null;
}

function getInitials(name) {
    return name?.charAt(0).toUpperCase() || '?';
}

async function getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
}

// ─── FORKAR ECO HUB ───

async function getEcoActions() {
    const { data, error } = await supabase
        .from('forkman_eco_actions')
        .select('*')
        .order('created_at', { ascending: false });
    if (error) { console.error('Error eco actions:', error); return []; }
    return data || [];
}

async function getUserEcoImpact(userId) {
    let uid = userId;
    if (!uid) {
        const { data: { user } } = await supabase.auth.getUser();
        uid = user?.id;
    }
    if (!uid) return { co2Saved: 0, pointsEarned: 0, totalActions: 0, history: [] };

    const { data, error } = await supabase
        .from('forkman_user_eco')
        .select('*, action:forkman_eco_actions(title, co2_impact, category)')
        .eq('user_id', uid)
        .order('created_at', { ascending: false });

    if (error) { console.error('Error user eco:', error); return { co2Saved: 0, pointsEarned: 0, totalActions: 0, history: [] }; }

    const co2Saved = (data || []).reduce((acc, curr) => acc + (parseFloat(curr.co2_saved) || 0), 0);
    const pointsEarned = (data || []).reduce((acc, curr) => acc + (parseInt(curr.points_earned) || 0), 0);

    return {
        co2Saved: co2Saved.toFixed(2),
        pointsEarned,
        totalActions: (data || []).length,
        history: data || []
    };
}

async function logUserEcoImpact(actionId, co2Saved = 1.00, pointsEarned = 10) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Debes iniciar sesión para registrar impacto ecológico' };

    // Validar redención única por día
    const todayMidnight = new Date();
    todayMidnight.setHours(0,0,0,0);
    const { data: existingToday } = await supabase
        .from('forkman_user_eco')
        .select('id')
        .eq('user_id', user.id)
        .gte('created_at', todayMidnight.toISOString());

    if (existingToday && existingToday.length > 0) {
        return { success: false, error: 'Solo puedes redimir 1 reto ecológico por día. ¡Vuelve mañana!' };
    }

    // Validar si actionId es un UUID válido (36 caracteres con guiones)
    const isUUID = typeof actionId === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(actionId);

    const payload = {
        user_id: user.id,
        co2_saved: co2Saved,
        points_earned: pointsEarned
    };
    if (isUUID) {
        payload.action_id = actionId;
    }

    const { data, error } = await supabase
        .from('forkman_user_eco')
        .insert(payload)
        .select()
        .single();

    if (error) return { success: false, error: error.message };
    return { success: true, record: data };
}

async function getEcoMapPoints() {
    const { data, error } = await supabase
        .from('forkman_eco_map_points')
        .select('*')
        .order('name');
    if (error) { console.error('Error map points:', error); return []; }
    return data || [];
}

// ─── CSMS (COKI MESSAGING SERVICE) API ───

async function getCSMSRooms() {
    const { data, error } = await supabase
        .from('chat_rooms')
        .select('*')
        .order('created_at', { ascending: false });
    if (error) return [];
    return data || [];
}

async function createCSMSGroup(name) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Inicia sesión para crear salas' };

    const { data, error } = await supabase
        .from('chat_rooms')
        .insert({ name, is_group: true, created_by: user.id })
        .select()
        .single();
    if (error) return { success: false, error: error.message };
    return { success: true, room: data };
}

async function getCSMSMessages(roomId) {
    const { data, error } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('room_id', roomId)
        .order('created_at', { ascending: true });
    if (error) return [];
    return data || [];
}

async function sendCSMSMessage(roomId, content) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: 'Inicia sesión para enviar mensajes' };

    const { data, error } = await supabase
        .from('chat_messages')
        .insert({ room_id: roomId, sender_id: user.id, content })
        .select()
        .single();
    if (error) return { success: false, error: error.message };
    return { success: true, message: data };
}

// ─── EXPORTAR ───

export {
    supabase,
    getCategories,
    getPosts,
    getPostById,
    createPost,
    deletePost,
    getComments,
    createComment,
    deleteComment,
    getUserLike,
    toggleLikePost,
    getFollowStats,
    isFollowing,
    toggleFollow,
    getUserPosts,
    getCurrentUser,
    formatDate,
    getUserDisplayName,
    getUserAvatar,
    getInitials,
    getEcoActions,
    getUserEcoImpact,
    logUserEcoImpact,
    getEcoMapPoints,
    getCSMSRooms,
    createCSMSGroup,
    getCSMSMessages,
    sendCSMSMessage
};

