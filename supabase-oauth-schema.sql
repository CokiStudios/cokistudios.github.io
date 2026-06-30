-- ═══════════════════════════════════════════════════════════════
-- 🏢 COKI STUDIOS OAUTH SYSTEM — SCHEMA FOR SUPABASE
-- Ejecuta esto en el SQL Editor de tu NUEVO proyecto Supabase (cmkumxprmmhuinxfppxl)
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. Tabla oauth_clients ───
CREATE TABLE IF NOT EXISTS oauth_clients (
    id uuid primary key default gen_random_uuid(),
    client_id text unique not null,
    client_name text not null,
    client_secret text,
    redirect_uris text[] not null,
    allowed_scopes text[] default array['openid', 'profile', 'email'],
    logo_url text,
    website_url text,
    is_active boolean default true,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Habilitar RLS para oauth_clients
ALTER TABLE oauth_clients ENABLE ROW LEVEL SECURITY;

-- Permitir lectura pública de clientes activos
CREATE POLICY "Allow public read of active clients" ON oauth_clients 
    FOR SELECT USING (is_active = true);


-- ─── 2. Tabla oauth_codes ───
CREATE TABLE IF NOT EXISTS oauth_codes (
    id uuid primary key default gen_random_uuid(),
    code text unique not null,
    user_id uuid references auth.users(id) on delete cascade not null,
    client_id text references oauth_clients(client_id) on delete cascade not null,
    code_challenge text not null,
    redirect_uri text not null,
    scopes text[] not null,
    expires_at timestamp with time zone not null,
    used_at timestamp with time zone,
    created_at timestamp with time zone default now()
);

-- Habilitar RLS para oauth_codes
ALTER TABLE oauth_codes ENABLE ROW LEVEL SECURITY;

-- Permitir inserciones públicas (requerido para autorizar códigos en el flujo)
CREATE POLICY "Allow public inserts" ON oauth_codes 
    FOR INSERT WITH CHECK (true);

-- Permitir select público de códigos (requerido para intercambiar código por token)
CREATE POLICY "Allow public select of codes" ON oauth_codes 
    FOR SELECT USING (true);

-- Permitir actualización pública de used_at (requerido para intercambiar código)
CREATE POLICY "Allow public update of used_at" ON oauth_codes 
    FOR UPDATE USING (true);


-- ─── 3. Tabla user_apps ───
CREATE TABLE IF NOT EXISTS user_apps (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade not null,
    client_id text references oauth_clients(client_id) on delete cascade not null,
    scopes text[] not null,
    is_active boolean default true,
    granted_at timestamp with time zone default now(),
    last_used_at timestamp with time zone default now(),
    UNIQUE (user_id, client_id)
);

-- Habilitar RLS para user_apps
ALTER TABLE user_apps ENABLE ROW LEVEL SECURITY;

-- Los usuarios pueden ver sus propias apps conectadas activas
CREATE POLICY "Users can select their own apps" ON user_apps
    FOR SELECT USING (auth.uid() = user_id);

-- Los usuarios pueden actualizar/eliminar sus propias asociaciones
CREATE POLICY "Users can update their own apps" ON user_apps
    FOR UPDATE USING (auth.uid() = user_id);


-- ─── 4. Trigger para registrar automáticamente en user_apps al usar un oauth_code ───
CREATE OR REPLACE FUNCTION handle_oauth_code_used()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.used_at IS NOT NULL AND OLD.used_at IS NULL THEN
        INSERT INTO user_apps (user_id, client_id, scopes, is_active, last_used_at)
        VALUES (NEW.user_id, NEW.client_id, NEW.scopes, true, now())
        ON CONFLICT (user_id, client_id) 
        DO UPDATE SET 
            scopes = NEW.scopes,
            is_active = true,
            last_used_at = now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_oauth_code_used
    AFTER UPDATE ON oauth_codes
    FOR EACH ROW
    EXECUTE FUNCTION handle_oauth_code_used();


-- ─── 5. Función RPC para revocar una app ───
CREATE OR REPLACE FUNCTION revoke_app(p_client_id text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE user_apps
    SET is_active = false
    WHERE user_id = auth.uid() AND client_id = p_client_id;
    RETURN true;
END;
$$;


-- ─── 6. Insertar Clientes por defecto (App Demo y OurCommonHome) ───
INSERT INTO oauth_clients (client_id, client_name, redirect_uris, allowed_scopes, is_active)
VALUES 
    (
        'demo-app-123', 
        'App Demo', 
        ARRAY[
            'http://localhost:3000/oauth-callback.html',
            'https://anonymus-devop.github.io/OurCommonHome/oauth-callback.html',
            'https://anonymus-devop.github.io/HorizonMaps/oauth-callback.html',
            'https://cokistudios.github.io/client-demo.html',
            'https://cokistudios.github.io/client-demo-debug.html'
        ],
        ARRAY['openid', 'profile', 'email'],
        true
    ),
    (
        'ourcommonhome', 
        'OurCommonHome', 
        ARRAY[
            'http://localhost:3000/oauth-callback.html',
            'https://anonymus-devop.github.io/OurCommonHome/',
            'https://anonymus-devop.github.io/OurCommonHome/index.html',
            'https://anonymus-devop.github.io/HorizonMaps/oauth-callback.html',
            'https://cokistudios.github.io/client-demo.html',
            'https://cokistudios.github.io/client-demo-debug.html'
        ],
        ARRAY['openid', 'profile', 'email'],
        true
    )
ON CONFLICT (client_id) 
DO UPDATE SET 
    client_name = EXCLUDED.client_name,
    redirect_uris = EXCLUDED.redirect_uris,
    allowed_scopes = EXCLUDED.allowed_scopes;
