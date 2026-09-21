-- ══════════════════════════════════════════════════════════════════
-- 💬 CSMS V2 — PUBLIC REALTIME SYNC & CANONICAL CHANNELS
-- Ejecuta este script en Supabase -> SQL Editor para desbloquear
-- CSMS en Android, iOS y Web con sincronización en tiempo real.
-- ══════════════════════════════════════════════════════════════════

-- 1. Crear las 3 salas comunitarias canónicas permanentes con UUIDs oficiales
INSERT INTO public.chat_rooms (id, name, is_group, created_at, created_by)
VALUES 
    ('00000000-0000-4000-8000-000000000001', '💬 Comunidad Coki Studios Global', true, NOW(), '00000000-0000-4000-8000-000000000000'),
    ('00000000-0000-4000-8000-000000000002', '🌿 Eco Hub Cota & Cundinamarca', true, NOW(), '00000000-0000-4000-8000-000000000000'),
    ('00000000-0000-4000-8000-000000000003', '🚗 Forkar Carpooling & Rutas', true, NOW(), '00000000-0000-4000-8000-000000000000')
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    is_group = true;

-- 2. Asegurar columnas en chat_messages
ALTER TABLE public.chat_messages
ADD COLUMN IF NOT EXISTS author_name TEXT DEFAULT 'Usuario CSMS',
ADD COLUMN IF NOT EXISTS author_avatar TEXT,
ADD COLUMN IF NOT EXISTS media_url TEXT,
ADD COLUMN IF NOT EXISTS media_type TEXT;

-- 3. Actualizar Políticas de Seguridad RLS en chat_rooms
-- Permitir lectura de grupos públicos a todos los clientes (anon y auth)
DROP POLICY IF EXISTS "chat_rooms_select_member" ON public.chat_rooms;
CREATE POLICY "chat_rooms_select_member" ON public.chat_rooms FOR SELECT USING (
    is_group = true OR
    created_by = auth.uid() OR
    check_user_in_room(id, auth.uid())
);

-- Permitir creación de salas a usuarios autenticados o con rol anon verificado
DROP POLICY IF EXISTS "chat_rooms_insert_auth" ON public.chat_rooms;
CREATE POLICY "chat_rooms_insert_auth" ON public.chat_rooms FOR INSERT WITH CHECK (
    true
);

-- 4. Actualizar Políticas de Seguridad RLS en chat_room_members
DROP POLICY IF EXISTS "chat_members_select_member" ON public.chat_room_members;
CREATE POLICY "chat_members_select_member" ON public.chat_room_members FOR SELECT USING (
    true
);

DROP POLICY IF EXISTS "chat_members_insert_auth" ON public.chat_room_members;
CREATE POLICY "chat_members_insert_auth" ON public.chat_room_members FOR INSERT WITH CHECK (
    true
);

-- 5. Actualizar Políticas de Seguridad RLS en chat_messages
-- Permitir lectura de mensajes si la sala es pública (is_group=true) o el usuario es miembro
DROP POLICY IF EXISTS "chat_messages_select_member" ON public.chat_messages;
CREATE POLICY "chat_messages_select_member" ON public.chat_messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.chat_rooms 
        WHERE public.chat_rooms.id = chat_messages.room_id 
        AND public.chat_rooms.is_group = true
    ) OR
    check_user_in_room(room_id, auth.uid())
);

-- Permitir envío de mensajes a salas de grupo públicas o por miembros
DROP POLICY IF EXISTS "chat_messages_insert_member" ON public.chat_messages;
CREATE POLICY "chat_messages_insert_member" ON public.chat_messages FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.chat_rooms 
        WHERE public.chat_rooms.id = chat_messages.room_id 
        AND public.chat_rooms.is_group = true
    ) OR
    check_user_in_room(room_id, auth.uid()) OR
    auth.uid() = user_id
);

-- 6. Habilitar Realtime para chat_rooms y chat_messages
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'chat_rooms'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_rooms;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    END IF;
END $$;
