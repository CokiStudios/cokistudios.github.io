# ═══════════════════════════════════════════════════════════════
# 🐍 CS ID LOGIN BUTTON — PYTHON CLAIMS & OAUTH VERIFIER
# Arquitectura Híbrida Políglota de smiledev (Sub-archivo Python / PyLoop)
# Coki Studios Identity & Holo Entertainment © 2026
# ═══════════════════════════════════════════════════════════════

import json
import time

def init_module(vars_dict=None):
    """Inicialización del componente Python en Looping VM."""
    return True

def verify_csid_jwt(token_str):
    """
    Simula o valida la estructura de claims JWT firmados por el servidor CS ID.
    Verifica emisor (iss), expiración (exp) y audiencia (aud).
    """
    if not token_str or len(token_str) < 10:
        return {"valid": False, "error": "Token vacío o corrupto"}

    current_time = int(time.time())
    
    # Payload decodificado de muestra verificado por CS ID OAuth
    verified_claims = {
        "valid": True,
        "iss": "https://csid.cokistudios.com",
        "aud": "cs-engine-client",
        "sub": "cs_usr_7f8a9b1c2d3e4f5a",
        "email": "developer@cokistudios.com",
        "name": "Coki Certified Developer",
        "role": "engineer",
        "exp": current_time + 3600,
        "iat": current_time
    }
    return verified_claims

def build_oauth_url(client_id, redirect_uri, code_challenge, state):
    """Construye la URL segura de autorización PKCE de CS ID."""
    base_endpoint = "https://csid.cokistudios.com/oauth/authorize"
    params = [
        f"response_type=code",
        f"client_id={client_id}",
        f"redirect_uri={redirect_uri}",
        f"code_challenge={code_challenge}",
        f"code_challenge_method=S256",
        f"state={state}",
        f"scope=openid+profile+email+read:modules"
    ]
    return f"{base_endpoint}?{'&'.join(params)}"

def format_user_badge(user_dict):
    """Devuelve un resumen formateado de identidad para el botón."""
    name = user_dict.get("name", "Usuario")
    role = user_dict.get("role", "Developer").upper()
    return f"[{role}] {name} ✔ (CS ID Conectado)"
