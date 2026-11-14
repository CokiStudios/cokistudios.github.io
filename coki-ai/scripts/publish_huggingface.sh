#!/usr/bin/env bash
set -euo pipefail

# Publishes fused Coki AI 7B MLX model artifacts directly to Hugging Face (https://huggingface.co/CokiStudios).
# No external inference servers — Hugging Face hosts open weights only.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COKI_AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODEL_DIR="${COKI_AI_MODEL_DIR:-$COKI_AI_DIR/models/coki-looping-7b-mlx}"
HF_REPO_ID="${HF_REPO_ID:-CokiStudios/coki-looping-7b-mlx}"

pick_hf_cli() {
  for cand in "$COKI_AI_DIR/.venv/bin/hf" "$(command -v hf 2>/dev/null || true)" /Users/jerix/Library/Python/3.9/bin/hf; do
    if [[ -n "$cand" && -x "$cand" ]]; then
      echo "$cand"
      return 0
    fi
  done
  return 1
}

if [[ ! -d "$MODEL_DIR" || ! -f "$MODEL_DIR/config.json" ]]; then
  echo "❌ No se encontró el modelo fusionado en $MODEL_DIR."
  echo "   Ejecuta primero: bash coki-ai/scripts/setup_and_train.sh"
  exit 1
fi

HF_CLI="$(pick_hf_cli || true)"
if [[ -z "$HF_CLI" ]]; then
  echo "❌ No se encontró el CLI 'hf' (huggingface_hub). Instálalo con: pip install huggingface_hub"
  exit 1
fi

if ! "$HF_CLI" auth whoami >/dev/null 2>&1; then
  echo "🔐 Inicia sesión primero con Hugging Face:"
  echo "   $HF_CLI auth login"
  exit 1
fi

cp "$COKI_AI_DIR/MODEL_CARD_TEMPLATE.md" "$MODEL_DIR/README.md"

echo "🚀 [Coki AI] Creating/verifying repo https://huggingface.co/$HF_REPO_ID..."
"$HF_CLI" repo create "$HF_REPO_ID" --repo-type model --exist-ok

echo "📦 [Coki AI] Uploading MLX weights & Model Card from $MODEL_DIR..."
"$HF_CLI" upload "$HF_REPO_ID" "$MODEL_DIR" . \
  --repo-type model \
  --commit-message "Release Coki AI Looping 7B MLX (Apple Silicon 4-bit)"

echo ""
echo "✔ Publicado correctamente en: https://huggingface.co/$HF_REPO_ID"
echo "  Perfil oficial de la organización: https://huggingface.co/CokiStudios"
