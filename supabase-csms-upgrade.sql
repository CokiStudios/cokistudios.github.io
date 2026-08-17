-- ═══════════════════════════════════════════════════════════════
-- 💬 CSMS UPGRADE — ADJUNTOS MULTIMEDIA & NUEVO BUCKET STORAGE
-- Ejecuta este script en Supabase -> SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- 1. Añadir columnas de archivos adjuntos a chat_messages (si no existen)
ALTER TABLE public.chat_messages
ADD COLUMN IF NOT EXISTS media_url TEXT,
ADD COLUMN IF NOT EXISTS media_type TEXT; -- 'image', 'video', 'file', 'audio'

-- 2. Crear Bucket de Storage dedicado para CSMS: 'csms-media'
INSERT INTO storage.buckets (id, name, public)
VALUES ('csms-media', 'csms-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 3. Políticas de seguridad RLS para el Bucket 'csms-media'
-- Permitir lectura pública de archivos adjuntos
DROP POLICY IF EXISTS "Lectura publica de adjuntos CSMS" ON storage.objects;
CREATE POLICY "Lectura publica de adjuntos CSMS"
ON storage.objects FOR SELECT
USING (bucket_id = 'csms-media');

-- Permitir a usuarios autenticados subir adjuntos
DROP POLICY IF EXISTS "Subida de adjuntos CSMS para usuarios autenticados" ON storage.objects;
CREATE POLICY "Subida de adjuntos CSMS para usuarios autenticados"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'csms-media' 
    AND auth.role() = 'authenticated'
);

-- Permitir a los usuarios eliminar sus propios adjuntos
DROP POLICY IF EXISTS "Eliminar propios adjuntos CSMS" ON storage.objects;
CREATE POLICY "Eliminar propios adjuntos CSMS"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'csms-media' 
    AND auth.uid() = owner
);
