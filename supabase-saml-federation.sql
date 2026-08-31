-- ═══════════════════════════════════════════════════════════════
-- 🏢 COKI STUDIOS SAML 2.0 FEDERATION & SSO IDENTITY SYSTEM
-- Schema for Enterprise Identity Providers & Service Providers
-- ═══════════════════════════════════════════════════════════════

-- 1. Tabla de Proveedores de Identidad SAML Federados (IdP)
CREATE TABLE IF NOT EXISTS saml_identity_providers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id text UNIQUE NOT NULL, -- e.g. https://auth.cokistudios.com/saml/metadata
    provider_name text NOT NULL, -- e.g. "Coki Studios Enterprise SSO"
    sso_url text NOT NULL, -- Single Sign-On HTTP-POST / HTTP-Redirect URL
    slo_url text, -- Single Log-Out URL
    x509_certificate text NOT NULL, -- Public Certificate for Signature Verification
    metadata_xml text, -- Complete SAML 2.0 XML Metadata
    allowed_domains text[] DEFAULT array['cokistudios.com'],
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 2. Tabla de Proveedores de Servicio (SP / Apps que consumen la federación SAML)
CREATE TABLE IF NOT EXISTS saml_service_providers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sp_entity_id text UNIQUE NOT NULL, -- e.g. "https://app.cokistudios.com/saml/sp"
    sp_name text NOT NULL,
    acs_url text NOT NULL, -- Assertion Consumer Service URL (donde se envía el SAMLResponse)
    slo_url text,
    name_id_format text DEFAULT 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
    attribute_mapping jsonb DEFAULT '{"email": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", "name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);

-- 3. Tabla de Sesiones y Assertions SAML Emitidas
CREATE TABLE IF NOT EXISTS saml_assertions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    assertion_id text UNIQUE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    sp_entity_id text REFERENCES saml_service_providers(sp_entity_id) ON DELETE CASCADE NOT NULL,
    session_index text NOT NULL,
    issue_instant timestamp with time zone DEFAULT now(),
    not_on_or_after timestamp with time zone NOT NULL,
    attributes jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- RLS & Políticas de Seguridad
ALTER TABLE saml_identity_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE saml_service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE saml_assertions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read of active SAML IdP" ON saml_identity_providers
    FOR SELECT USING (is_active = true);

CREATE POLICY "Allow public read of active SAML SP" ON saml_service_providers
    FOR SELECT USING (is_active = true);
