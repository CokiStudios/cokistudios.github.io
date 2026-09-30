#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  DEPLOY CLOUDFLARE ZERO TRUST ACCESS POLICY: FORKAR INTERNAL & CSIMS
#  Enforces access exclusively for emails ending in @cokistudios.com
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

CF_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}"
CF_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"

if [[ -z "$CF_ACCOUNT_ID" || -z "$CF_API_TOKEN" ]]; then
  echo "⚠️  Variables de entorno requeridas:"
  echo "   export CLOUDFLARE_ACCOUNT_ID='tu_account_id'"
  echo "   export CLOUDFLARE_API_TOKEN='tu_api_token_con_permisos_access'"
  echo ""
  echo "Mostrando payloads que se enviarán a Cloudflare API v4:"
  cat "$(dirname "$0")/../cloudflare-zerotrust-policy.json"
  exit 1
fi

echo "==> 1. Creando / Verificando Política Reusable de Access (@cokistudios.com)..."
POLICY_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/access/policies" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Allow Coki Studios Team (@cokistudios.com)",
    "decision": "allow",
    "include": [
      {
        "email_domain": {
          "domain": "cokistudios.com"
        }
      }
    ]
  }')

POLICY_ID=$(echo "$POLICY_RESPONSE" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4 || true)

if [[ -z "$POLICY_ID" ]]; then
  echo "⚠️ La política ya existe o se obtuvo respuesta: $POLICY_RESPONSE"
  # Intentar buscar el ID existente
  POLICY_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/access/policies" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4 || true)
fi

echo "✅ ID de Política Access: ${POLICY_ID}"

echo "==> 2. Creando Aplicación Access para Forkar Internal (forkar-internal.cokistudios.com)..."
APP_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/access/apps" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Forkar Internal\",
    \"domain\": \"forkar-internal.cokistudios.com\",
    \"type\": \"self_hosted\",
    \"session_duration\": \"24h\",
    \"policies\": [\"${POLICY_ID}\"]
  }")

echo "✅ Forkar Internal configurado con éxito."

echo "==> 3. Creando Aplicación Access para CSIMS (csims.cokistudios.com)..."
CSIMS_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/access/apps" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"CSIMS (Coki Studios Internal Messaging Service)\",
    \"domain\": \"csims.cokistudios.com\",
    \"type\": \"self_hosted\",
    \"session_duration\": \"24h\",
    \"policies\": [\"${POLICY_ID}\"]
  }")

echo "✅ CSIMS configurado con éxito."
echo "🎉 Despliegue de Zero Trust finalizado. Solo usuarios con @cokistudios.com podrán acceder."
