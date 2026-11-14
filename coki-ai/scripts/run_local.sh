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

if command -v lsof >/dev/null 2>&1; then
  EXISTING_PIDS="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
  for pid in $EXISTING_PIDS; do
    CMD_LINE="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    if [[ "$CMD_LINE" == *"mlx_lm"* ]]; then
      echo "♻️  [Coki AI] Deteniendo servidor MLX previo (PID $pid) en puerto $PORT..."
      kill "$pid" 2>/dev/null || true
      sleep 1
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
        sleep 1
      fi
    else
      echo "❌ El puerto $PORT ya está ocupado por otro proceso (PID $pid): $CMD_LINE"
      echo "   Usa otro puerto con: COKI_AI_PORT=8081 bash coki-ai/scripts/run_local.sh"
      exit 1
    fi
  done
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
