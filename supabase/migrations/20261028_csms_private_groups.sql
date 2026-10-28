-- 1. Agregar columna is_public a chat_rooms
ALTER TABLE public.chat_rooms 
ADD COLUMN IF NOT EXISTS is_public boolean NOT NULL DEFAULT false;

-- 2. Declarar canales canónicos oficiales como públicos
UPDATE public.chat_rooms
SET is_public = true
WHERE id IN (
    '00000000-0000-4000-8000-000000000001'::uuid,
    '00000000-0000-4000-8000-000000000002'::uuid,
    '00000000-0000-4000-8000-000000000003'::uuid
);

-- 3. Trigger atómico para registrar al creador en chat_room_members
CREATE OR REPLACE FUNCTION public.handle_new_chat_room()
RETURNS TRIGGER AS $$
DECLARE
    creator_name text;
    creator_avatar text;
BEGIN
    IF NEW.created_by IS NOT NULL AND NEW.created_by != '00000000-0000-4000-8000-000000000000'::uuid THEN
        SELECT full_name, avatar_url INTO creator_name, creator_avatar
        FROM public.profiles
        WHERE id = NEW.created_by;

        IF creator_name IS NULL OR creator_name = '' THEN
            creator_name := 'Usuario';
        END IF;

        INSERT INTO public.chat_room_members (room_id, user_id, user_name, user_avatar)
        VALUES (NEW.id, NEW.created_by, creator_name, creator_avatar)
        ON CONFLICT (room_id, user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_chat_room_creator ON public.chat_rooms;
CREATE TRIGGER trg_chat_room_creator 
AFTER INSERT ON public.chat_rooms 
FOR EACH ROW EXECUTE FUNCTION public.handle_new_chat_room();

-- 4. Actualizar Políticas RLS de Aislamiento
ALTER POLICY chat_rooms_select_member ON public.chat_rooms 
USING ((is_public = true) OR (created_by = auth.uid()) OR check_user_in_room(id, auth.uid()));

ALTER POLICY chat_messages_select_member ON public.chat_messages 
USING (
    (EXISTS (SELECT 1 FROM public.chat_rooms WHERE chat_rooms.id = chat_messages.room_id AND chat_rooms.is_public = true)) 
    OR check_user_in_room(room_id, auth.uid()) 
    OR (EXISTS (SELECT 1 FROM public.chat_rooms WHERE chat_rooms.id = chat_messages.room_id AND chat_rooms.created_by = auth.uid()))
);

ALTER POLICY chat_messages_insert_member ON public.chat_messages 
WITH CHECK (
    (auth.uid() = user_id) 
    AND (
        (EXISTS (SELECT 1 FROM public.chat_rooms WHERE chat_rooms.id = chat_messages.room_id AND chat_rooms.is_public = true)) 
        OR check_user_in_room(room_id, auth.uid()) 
        OR (EXISTS (SELECT 1 FROM public.chat_rooms WHERE chat_rooms.id = chat_messages.room_id AND chat_rooms.created_by = auth.uid()))
    )
);

ALTER POLICY chat_members_select_member ON public.chat_room_members 
USING (
    (user_id = auth.uid()) 
    OR check_user_in_room(room_id, auth.uid()) 
    OR (EXISTS (
        SELECT 1 FROM public.chat_rooms 
        WHERE chat_rooms.id = chat_room_members.room_id 
        AND (chat_rooms.is_public = true OR chat_rooms.created_by = auth.uid())
    ))
);

ALTER POLICY chat_members_insert_auth ON public.chat_room_members 
WITH CHECK (
    (auth.uid() = user_id AND EXISTS (
        SELECT 1 FROM public.chat_rooms 
        WHERE chat_rooms.id = chat_room_members.room_id AND chat_rooms.is_public = true
    ))
    OR (EXISTS (
        SELECT 1 FROM public.chat_rooms 
        WHERE chat_rooms.id = chat_room_members.room_id AND chat_rooms.created_by = auth.uid()
    ))
    OR check_user_in_room(room_id, auth.uid())
);
