-- ═══════════════════════════════════════════════════════════════
-- 🌐 COKI SOCIAL & FORKAR ECO — SCHEMA IDEMPOTENTE PARA SUPABASE
-- Ejecuta esto en el SQL Editor de tu proyecto Supabase
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. TABLAS DE FORKAR ECO & HOGAR COMÚN (NATIVO EN FORKAR) ───

-- Acciones/Retos Ecológicos de Forkar Eco
CREATE TABLE IF NOT EXISTS forkman_eco_actions (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text not null,
    co2_impact decimal(10,2) default 1.00,
    category text default 'General',
    created_at timestamp with time zone default now()
);

-- Impacto guardado por usuario en Forkar
CREATE TABLE IF NOT EXISTS forkman_user_eco (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    action_id uuid references forkman_eco_actions(id) on delete cascade,
    co2_saved decimal(10,2) not null default 0.00,
    points_earned integer not null default 0,
    created_at timestamp with time zone default now()
);

-- Puntos de Acopio / Reciclaje en Mapa Forkar (HorizonMap Eco integration)
CREATE TABLE IF NOT EXISTS forkman_eco_map_points (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    latitude double precision not null,
    longitude double precision not null,
    point_type text default 'verde', -- 'municipal', 'verde', 'raee'
    color text default '#10b981',
    created_at timestamp with time zone default now()
);

-- Habilitar RLS en tablas Forkar Eco
ALTER TABLE forkman_eco_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE forkman_user_eco ENABLE ROW LEVEL SECURITY;
ALTER TABLE forkman_eco_map_points ENABLE ROW LEVEL SECURITY;

-- Limpiar políticas de Eco si existen
DROP POLICY IF EXISTS "Allow public read of eco actions" ON forkman_eco_actions;
DROP POLICY IF EXISTS "Allow public read of eco map points" ON forkman_eco_map_points;
DROP POLICY IF EXISTS "Users can insert their own eco actions" ON forkman_user_eco;
DROP POLICY IF EXISTS "Users can read their own eco impact" ON forkman_user_eco;

CREATE POLICY "Allow public read of eco actions" ON forkman_eco_actions FOR SELECT USING (true);
CREATE POLICY "Allow public read of eco map points" ON forkman_eco_map_points FOR SELECT USING (true);
CREATE POLICY "Users can insert their own eco actions" ON forkman_user_eco FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can read their own eco impact" ON forkman_user_eco FOR SELECT USING (auth.uid() = user_id);

-- ─── TABLA DE HASH DE DISPOSITIVO PARA AUTO-LOGIN PERSISTENTE ───
CREATE TABLE IF NOT EXISTS user_device_hashes (
    id uuid primary key default gen_random_uuid(),
    device_hash text unique not null,
    user_id uuid not null,
    user_email text not null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

ALTER TABLE user_device_hashes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public select device hash" ON user_device_hashes;
DROP POLICY IF EXISTS "Public insert/update device hash" ON user_device_hashes;
DROP POLICY IF EXISTS "Public delete device hash" ON user_device_hashes;

CREATE POLICY "Public select device hash" ON user_device_hashes FOR SELECT USING (true);
CREATE POLICY "Public insert/update device hash" ON user_device_hashes FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update device hash" ON user_device_hashes FOR UPDATE USING (true);
CREATE POLICY "Public delete device hash" ON user_device_hashes FOR DELETE USING (true);

-- ─── 2. TABLAS DE FORO FORKAR ───

CREATE TABLE IF NOT EXISTS social_categories (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    slug text unique not null,
    description text,
    color text default '#0077e6',
    created_at timestamp with time zone default now()
);

CREATE TABLE IF NOT EXISTS social_posts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    author_name text not null default 'Usuario',
    author_avatar text,
    category_id uuid references social_categories(id) on delete set null,
    title text not null,
    content text not null,
    likes_count integer default 0,
    comments_count integer default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

CREATE TABLE IF NOT EXISTS social_comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references social_posts(id) on delete cascade,
    user_id uuid not null,
    author_name text not null default 'Usuario',
    author_avatar text,
    content text not null,
    created_at timestamp with time zone default now()
);

CREATE TABLE IF NOT EXISTS social_likes (
    id uuid primary key default gen_random_uuid(),
    post_id uuid references social_posts(id) on delete cascade,
    user_id uuid not null,
    created_at timestamp with time zone default now(),
    unique (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS social_follows (
    id uuid primary key default gen_random_uuid(),
    follower_id uuid not null,
    following_id uuid not null,
    created_at timestamp with time zone default now(),
    unique (follower_id, following_id),
    constraint no_self_follow check (follower_id != following_id)
);

-- ─── 3. POLÍTICAS RLS IDEMPOTENTES (SAFE FOR RE-RUNNING) ───

ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_categories ENABLE ROW LEVEL SECURITY;

-- Limpieza de políticas previas para evitar error 42710
DROP POLICY IF EXISTS "posts_select_all" ON social_posts;
DROP POLICY IF EXISTS "posts_insert_auth" ON social_posts;
DROP POLICY IF EXISTS "posts_update_own" ON social_posts;
DROP POLICY IF EXISTS "posts_delete_own" ON social_posts;

DROP POLICY IF EXISTS "comments_select_all" ON social_comments;
DROP POLICY IF EXISTS "comments_insert_auth" ON social_comments;
DROP POLICY IF EXISTS "comments_delete_own" ON social_comments;

DROP POLICY IF EXISTS "likes_select_all" ON social_likes;
DROP POLICY IF EXISTS "likes_insert_auth" ON social_likes;
DROP POLICY IF EXISTS "likes_delete_own" ON social_likes;

DROP POLICY IF EXISTS "follows_select_all" ON social_follows;
DROP POLICY IF EXISTS "follows_insert_auth" ON social_follows;
DROP POLICY IF EXISTS "follows_delete_own" ON social_follows;

DROP POLICY IF EXISTS "categories_select_all" ON social_categories;

-- Re-crear Políticas RLS
CREATE POLICY "posts_select_all" ON social_posts FOR SELECT USING (true);
CREATE POLICY "posts_insert_auth" ON social_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts_update_own" ON social_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "posts_delete_own" ON social_posts FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "comments_select_all" ON social_comments FOR SELECT USING (true);
CREATE POLICY "comments_insert_auth" ON social_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments_delete_own" ON social_comments FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "likes_select_all" ON social_likes FOR SELECT USING (true);
CREATE POLICY "likes_insert_auth" ON social_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete_own" ON social_likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "follows_select_all" ON social_follows FOR SELECT USING (true);
CREATE POLICY "follows_insert_auth" ON social_follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows_delete_own" ON social_follows FOR DELETE USING (auth.uid() = follower_id);

CREATE POLICY "categories_select_all" ON social_categories FOR SELECT USING (true);

-- ─── 4. FUNCIONES Y TRIGGERS PARA CONTADORES ───

CREATE OR REPLACE FUNCTION increment_post_likes()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE social_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_post_likes()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE social_posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_post_likes_inc ON social_likes;
DROP TRIGGER IF EXISTS trg_post_likes_dec ON social_likes;

CREATE TRIGGER trg_post_likes_inc
    AFTER INSERT ON social_likes
    FOR EACH ROW EXECUTE FUNCTION increment_post_likes();

CREATE TRIGGER trg_post_likes_dec
    AFTER DELETE ON social_likes
    FOR EACH ROW EXECUTE FUNCTION decrement_post_likes();

CREATE OR REPLACE FUNCTION increment_post_comments()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE social_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_post_comments()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE social_posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_post_comments_inc ON social_comments;
DROP TRIGGER IF EXISTS trg_post_comments_dec ON social_comments;

CREATE TRIGGER trg_post_comments_inc
    AFTER INSERT ON social_comments
    FOR EACH ROW EXECUTE FUNCTION increment_post_comments();

CREATE TRIGGER trg_post_comments_dec
    AFTER DELETE ON social_comments
    FOR EACH ROW EXECUTE FUNCTION decrement_post_comments();

-- ─── 5. CATEGORÍAS POR DEFECTO ───
INSERT INTO social_categories (name, slug, description, color) VALUES
    ('General', 'general', 'Discusiones generales sobre cualquier tema', '#0077e6'),
    ('Productos', 'productos', 'Opiniones y soporte sobre productos Coki', '#10b981'),
    ('Ideas', 'ideas', 'Sugerencias y propuestas para mejorar', '#f59e0b'),
    ('Ayuda', 'ayuda', 'Preguntas y respuestas de la comunidad', '#ef4444')
ON CONFLICT (slug) DO NOTHING;
