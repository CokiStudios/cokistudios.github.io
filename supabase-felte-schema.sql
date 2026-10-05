-- ═══════════════════════════════════════════════════════════════
-- FELTE APP STORE — SCHEMA PARA SUPABASE
-- Ejecuta esto una vez en el SQL Editor del proyecto cmkumxprmmhuinxfppxl
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS felte_apps (
    id uuid primary key default gen_random_uuid(),
    developer_id uuid not null references auth.users(id) on delete cascade,
    developer_name text not null,
    name text not null check (char_length(name) between 2 and 60),
    category text not null check (category in ('juegos', 'dev', 'redes', 'sistema')),
    description text not null default '' check (char_length(description) <= 600),
    version text not null default '1.0.0',
    targets text[] not null default array['loop_os'],
    source_code text check (source_code is null or char_length(source_code) <= 100000),
    download_url text check (download_url is null or download_url ~* '^https://'),
    web_url text check (web_url is null or web_url ~* '^https://'),
    status text not null default 'published' check (status in ('published', 'hidden')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

CREATE INDEX IF NOT EXISTS felte_apps_status_created_idx ON felte_apps (status, created_at desc);
CREATE INDEX IF NOT EXISTS felte_apps_developer_idx ON felte_apps (developer_id);

ALTER TABLE felte_apps ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede ver el catálogo publicado
CREATE POLICY "Felte: public read published" ON felte_apps
    FOR SELECT USING (status = 'published');

-- El desarrollador ve todas sus apps (incluidas las ocultas)
CREATE POLICY "Felte: developer reads own" ON felte_apps
    FOR SELECT USING (auth.uid() = developer_id);

-- Solo usuarios autenticados publican, y siempre a su nombre
CREATE POLICY "Felte: developer inserts own" ON felte_apps
    FOR INSERT WITH CHECK (auth.uid() = developer_id);

CREATE POLICY "Felte: developer updates own" ON felte_apps
    FOR UPDATE USING (auth.uid() = developer_id) WITH CHECK (auth.uid() = developer_id);

CREATE POLICY "Felte: developer deletes own" ON felte_apps
    FOR DELETE USING (auth.uid() = developer_id);

-- Mantener updated_at al día
CREATE OR REPLACE FUNCTION felte_touch_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS felte_apps_touch ON felte_apps;
CREATE TRIGGER felte_apps_touch BEFORE UPDATE ON felte_apps
    FOR EACH ROW EXECUTE FUNCTION felte_touch_updated_at();
