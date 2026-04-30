-- ═══════════════════════════════════════════════════════════════
-- 🌐 COKI SOCIAL — SCHEMA PARA SUPABASE
-- Ejecuta esto en el SQL Editor de tu proyecto Supabase
-- ═══════════════════════════════════════════════════════════════

-- ─── Tabla de categorías ───
create table if not exists social_categories (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    slug text unique not null,
    description text,
    color text default '#0077e6',
    created_at timestamp with time zone default now()
);

-- ─── Tabla de posts ───
-- Guardamos author_name y author_avatar para no depender de auth.users
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

-- ─── Tabla de comentarios ───
CREATE TABLE IF NOT EXISTS social_comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references social_posts(id) on delete cascade,
    user_id uuid not null,
    author_name text not null default 'Usuario',
    author_avatar text,
    content text not null,
    created_at timestamp with time zone default now()
);

-- ─── Tabla de likes ───
CREATE TABLE IF NOT EXISTS social_likes (
    id uuid primary key default gen_random_uuid(),
    post_id uuid references social_posts(id) on delete cascade,
    user_id uuid not null,
    created_at timestamp with time zone default now(),
    unique (post_id, user_id)
);

-- ─── Tabla de seguidores ───
CREATE TABLE IF NOT EXISTS social_follows (
    id uuid primary key default gen_random_uuid(),
    follower_id uuid not null,
    following_id uuid not null,
    created_at timestamp with time zone default now(),
    unique (follower_id, following_id),
    constraint no_self_follow check (follower_id != following_id)
);

-- ─── Políticas RLS ───

alter table social_posts enable row level security;
alter table social_comments enable row level security;
alter table social_likes enable row level security;
alter table social_follows enable row level security;
alter table social_categories enable row level security;

-- Posts: todos pueden leer, solo dueño puede modificar
CREATE POLICY "posts_select_all" ON social_posts FOR SELECT USING (true);
CREATE POLICY "posts_insert_auth" ON social_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts_update_own" ON social_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "posts_delete_own" ON social_posts FOR DELETE USING (auth.uid() = user_id);

-- Comments: todos pueden leer, solo dueño puede insertar/eliminar
CREATE POLICY "comments_select_all" ON social_comments FOR SELECT USING (true);
CREATE POLICY "comments_insert_auth" ON social_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments_delete_own" ON social_comments FOR DELETE USING (auth.uid() = user_id);

-- Likes: todos pueden leer, solo dueño puede insertar/eliminar
CREATE POLICY "likes_select_all" ON social_likes FOR SELECT USING (true);
CREATE POLICY "likes_insert_auth" ON social_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete_own" ON social_likes FOR DELETE USING (auth.uid() = user_id);

-- Follows
CREATE POLICY "follows_select_all" ON social_follows FOR SELECT USING (true);
CREATE POLICY "follows_insert_auth" ON social_follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows_delete_own" ON social_follows FOR DELETE USING (auth.uid() = follower_id);

-- Categories: todos pueden leer
CREATE POLICY "categories_select_all" ON social_categories FOR SELECT USING (true);

-- ─── Funciones para contadores ───
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

-- ─── Categorías por defecto ───
INSERT INTO social_categories (name, slug, description, color) VALUES
    ('General', 'general', 'Discusiones generales sobre cualquier tema', '#0077e6'),
    ('Productos', 'productos', 'Opiniones y soporte sobre productos Coki', '#10b981'),
    ('Ideas', 'ideas', 'Sugerencias y propuestas para mejorar', '#f59e0b'),
    ('Ayuda', 'ayuda', 'Preguntas y respuestas de la comunidad', '#ef4444')
ON CONFLICT (slug) DO NOTHING;
