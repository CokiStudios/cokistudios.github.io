#!/usr/bin/env bash
set -euo pipefail

# Starts Coki AI local OpenAI-compatible MLX server on 127.0.0.1:8080 (zero cloud servers).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_env.sh"
VENV_PY="$VENV_DIR/bin/python"

HOST="${COKI_AI_HOST:-127.0.0.1}"
PORT="${COKI_AI_PORT:-8080}"
FUSED_MODEL="$MODEL_OUT_DIR"

if [[ ! -x "$VENV_PY" ]]; then
  echo "❌ Falta el entorno virtual local en $VENV_DIR."
  echo "   Ejecuta primero: bash coki-ai/scripts/setup_and_train.sh"
  exit 1
fi

if [[ -d "$FUSED_MODEL" && -f "$FUSED_MODEL/config.json" ]]; then
  echo "♾️  [Coki AI] Serving fused local 7B MLX model on http://$HOST:$PORT"
  exec "$VENV_PY" -m mlx_lm server \
    --model "$FUSED_MODEL" \
    --host "$HOST" \
    --port "$PORT"
elif [[ -d "$ADAPTER_DIR" && -f "$ADAPTER_DIR/adapters.safetensors" ]]; then
  echo "♾️  [Coki AI] Serving base model + LoRA adapters on http://$HOST:$PORT"
  exec "$VENV_PY" -m mlx_lm server \
    --model "$BASE_MODEL" \
    --adapter-path "$ADAPTER_DIR" \
    --host "$HOST" \
    --port "$PORT"
else
  echo "⚠️  Aún no existe un modelo entrenado en $FUSED_MODEL."
  echo "   Ejecuta primero: bash coki-ai/scripts/setup_and_train.sh"
  echo "   O descarga un modelo ya publicado desde: https://huggingface.co/CokiStudios"
  exit 1
fi
