-- ═══════════════════════════════════════════════════════════════
-- 💬 SISTEMA DE CHATS PRIVADOS Y GRUPOS — COKI STUDIOS
-- Ejecuta esto en el SQL Editor de tu proyecto Supabase
-- ═══════════════════════════════════════════════════════════════

-- 1. Tabla de salas de chat (chat_rooms)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id uuid primary key default gen_random_uuid(),
    name text, -- Nombre del grupo (ej: "Equipo Coki", null para chats directos 1-on-1)
    is_group boolean default false, -- true si es un grupo con múltiples miembros, false para chat 1-on-1
    created_at timestamp with time zone default now(),
    created_by uuid not null default auth.uid() -- Creador del grupo
);

-- 2. Tabla de miembros de salas de chat (chat_room_members)
CREATE TABLE IF NOT EXISTS chat_room_members (
    id uuid primary key default gen_random_uuid(),
    room_id uuid references chat_rooms(id) on delete cascade,
    user_id uuid not null, -- ID del usuario miembro
    user_name text not null, -- Nombre del usuario
    user_avatar text, -- Avatar del usuario
    joined_at timestamp with time zone default now(),
    unique (room_id, user_id)
);

-- 3. Tabla de mensajes de chat (chat_messages)
CREATE TABLE IF NOT EXISTS chat_messages (
    id uuid primary key default gen_random_uuid(),
    room_id uuid references chat_rooms(id) on delete cascade,
    user_id uuid not null default auth.uid(), -- ID del autor del mensaje
    author_name text not null, -- Nombre visible del autor
    author_avatar text, -- Avatar del autor
    content text not null, -- Contenido del mensaje
    created_at timestamp with time zone default now()
);

-- 4. Habilitar Seguridad RLS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- 5. Políticas RLS para salas de chat (chat_rooms)
-- 5. Función Auxiliar (SECURITY DEFINER) para evitar recursión infinita en las políticas
CREATE OR REPLACE FUNCTION check_user_in_room(room_uuid uuid, user_uuid uuid) 
RETURNS boolean SECURITY DEFINER AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.chat_room_members 
        WHERE room_id = room_uuid AND user_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql;

-- 5.1 Políticas RLS para salas de chat (chat_rooms)
CREATE POLICY "chat_rooms_select_member" ON chat_rooms FOR SELECT USING (
    created_by = auth.uid() or
    check_user_in_room(id, auth.uid())
);

CREATE POLICY "chat_rooms_insert_auth" ON chat_rooms FOR INSERT WITH CHECK (
    auth.uid() = created_by
);

-- 6. Políticas RLS para miembros de salas (chat_room_members)
CREATE POLICY "chat_members_select_member" ON chat_room_members FOR SELECT USING (
    user_id = auth.uid() or
    check_user_in_room(room_id, auth.uid())
);

CREATE POLICY "chat_members_insert_auth" ON chat_room_members FOR INSERT WITH CHECK (
    true -- Permitir insertar miembros al crear la sala o unirse
);

-- 7. Políticas RLS para mensajes (chat_messages)
CREATE POLICY "chat_messages_select_member" ON chat_messages FOR SELECT USING (
    check_user_in_room(room_id, auth.uid())
);

CREATE POLICY "chat_messages_insert_member" ON chat_messages FOR INSERT WITH CHECK (
    auth.uid() = user_id and check_user_in_room(room_id, auth.uid())
);

-- 8. Política de eliminación de comentarios para moderadores
-- Permite que los moderadores y administradores puedan eliminar comentarios en la moderación física
DROP POLICY IF EXISTS "comments_moderator_delete" ON social_comments;
CREATE POLICY "comments_moderator_delete" ON social_comments FOR DELETE USING (
    exists (
        select 1 from user_roles 
        where user_roles.user_id = auth.uid() and (user_roles.role = 'moderator' or user_roles.role = 'admin')
    )
);
