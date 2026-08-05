-- ═══════════════════════════════════════════════════════════════
-- 🛡️ SISTEMA DE MODERACIÓN COKI STUDIOS — SCHEMA PARA SUPABASE
-- Ejecuta esto en el SQL Editor de tu proyecto Supabase
-- ═══════════════════════════════════════════════════════════════

-- 1. Añadir columnas de visibilidad a Posts y Comentarios
ALTER TABLE social_posts ADD COLUMN IF NOT EXISTS is_hidden boolean DEFAULT false;
ALTER TABLE social_comments ADD COLUMN IF NOT EXISTS is_hidden boolean DEFAULT false;

-- 2. Crear tabla de Reportes/Denuncias
CREATE TABLE IF NOT EXISTS social_reports (
    id uuid primary key default gen_random_uuid(),
    reporter_id uuid not null, -- Usuario que reporta
    post_id uuid references social_posts(id) on delete cascade,
    comment_id uuid references social_comments(id) on delete cascade,
    reason text not null, -- 'spam', 'harassment', 'inappropriate', 'other'
    details text, -- Detalles escritos opcionales
    status text not null default 'pending', -- 'pending', 'reviewed', 'dismissed'
    created_at timestamp with time zone default now(),
    -- Asegurar que al menos se reporte un post o un comentario, no ambos vacíos
    constraint report_target check (
        (post_id is not null and comment_id is null) or 
        (post_id is null and comment_id is not null)
    )
);

-- 3. Crear tabla de moderadores y roles de usuario (si no existe una)
-- Usaremos una tabla sencilla para mapear quién es admin/moderador.
CREATE TABLE IF NOT EXISTS user_roles (
    user_id uuid primary key,
    role text not null default 'user', -- 'user', 'moderator', 'admin'
    created_at timestamp with time zone default now()
);

-- Registrar automáticamente al creador o añadir un moderador de prueba
-- (Puedes insertar usuarios manualmente aquí usando su UUID de Supabase Auth)

-- 4. Habilitar RLS en la tabla de reportes y roles
ALTER TABLE social_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 5. Crear políticas RLS para Moderación

-- user_roles: Leer todos pueden (para verificar roles). Las modificaciones se hacen por SQL Editor.
CREATE POLICY "roles_select_all" ON user_roles FOR SELECT USING (true);

-- social_reports: 
-- Crear: cualquier usuario autenticado puede insertar un reporte
CREATE POLICY "reports_insert_auth" ON social_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
-- Leer/Modificar: solo moderadores o admins
CREATE POLICY "reports_mod_all" ON social_reports FOR ALL USING (
    exists (
        select 1 from user_roles 
        where user_roles.user_id = auth.uid() and (user_roles.role = 'moderator' or user_roles.role = 'admin')
    )
);

-- 6. Actualizar las políticas existentes de posts y comentarios para filtrar contenido ocultado
-- Borramos las políticas select anteriores y las creamos filtrando is_hidden
DROP POLICY IF EXISTS "posts_select_all" ON social_posts;
CREATE POLICY "posts_select_visible" ON social_posts FOR SELECT USING (
    is_hidden = false or 
    auth.uid() = user_id or
    exists (
        select 1 from user_roles 
        where user_roles.user_id = auth.uid() and (user_roles.role = 'moderator' or user_roles.role = 'admin')
    )
);

DROP POLICY IF EXISTS "comments_select_all" ON social_comments;
CREATE POLICY "comments_select_visible" ON social_comments FOR SELECT USING (
    is_hidden = false or 
    auth.uid() = user_id or
    exists (
        select 1 from user_roles 
        where user_roles.user_id = auth.uid() and (user_roles.role = 'moderator' or user_roles.role = 'admin')
    )
);

-- Permisos de ocultar (UPDATE) posts y comentarios para moderadores
-- Permitimos que los moderadores actualicen la columna is_hidden
CREATE POLICY "posts_moderator_update" ON social_posts FOR UPDATE USING (
    exists (
        select 1 from user_roles 
        where user_roles.user_id = auth.uid() and (user_roles.role = 'moderator' or user_roles.role = 'admin')
    )
);

CREATE POLICY "comments_moderator_update" ON social_comments FOR UPDATE USING (
    exists (
        select 1 from user_roles 
        where user_roles.user_id = auth.uid() and (user_roles.role = 'moderator' or user_roles.role = 'admin')
    )
);
