#!/usr/bin/env bash
set -euo pipefail

# Coki AI — 100% Local Apple Silicon MLX LoRA Training Pipeline
# Base model: mlx-community/Qwen2.5-Coder-7B-Instruct-4bit (tuned safely for 16 GB RAM)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COKI_AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$COKI_AI_DIR/.." && pwd)"

BASE_MODEL="${COKI_AI_BASE_MODEL:-mlx-community/Qwen2.5-Coder-7B-Instruct-4bit}"
DATA_DIR="$COKI_AI_DIR/data"
ADAPTER_DIR="$COKI_AI_DIR/adapters/looping-7b"
MODEL_OUT_DIR="$COKI_AI_DIR/models/coki-looping-7b-mlx"
VENV_DIR="$COKI_AI_DIR/.venv"

ITERS="${COKI_AI_ITERS:-600}"
BATCH_SIZE="${COKI_AI_BATCH_SIZE:-1}"
NUM_LAYERS="${COKI_AI_NUM_LAYERS:-8}"
MAX_SEQ_LEN="${COKI_AI_MAX_SEQ_LEN:-1536}"
LR="${COKI_AI_LR:-1e-5}"
SETUP_ONLY=0
FUSE_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --setup-only) SETUP_ONLY=1 ;;
    --fuse-only)  FUSE_ONLY=1 ;;
    --help|-h)
      echo "Usage: $0 [--setup-only] [--fuse-only]"
      echo "Env overrides: COKI_AI_BASE_MODEL, COKI_AI_ITERS, COKI_AI_BATCH_SIZE, COKI_AI_NUM_LAYERS, COKI_AI_MAX_SEQ_LEN, COKI_AI_LR"
      exit 0
      ;;
  esac
done

pick_python() {
  for cand in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3 /usr/local/bin/python3 python3; do
    if command -v "$cand" >/dev/null 2>&1; then
      local arch
      arch="$("$cand" -c 'import platform; print(platform.machine())' 2>/dev/null || true)"
      if [[ "$arch" == "arm64" ]]; then
        command -v "$cand"
        return 0
      fi
    fi
  done
  command -v python3
}

PY_HOST="$(pick_python)"
echo "♾️  [Coki AI] Host Python: $PY_HOST ($("$PY_HOST" --version))"

if [[ ! -d "$VENV_DIR" ]]; then
  echo "📦 [Coki AI] Creating isolated Apple Silicon venv in $VENV_DIR..."
  "$PY_HOST" -m venv "$VENV_DIR"
fi

VENV_PY="$VENV_DIR/bin/python"
"$VENV_PY" -m pip install --upgrade pip wheel >/dev/null
"$VENV_PY" -m pip install --upgrade "mlx-lm>=0.22.0" "huggingface_hub>=0.25.0"

echo "📚 [Coki AI] Building & verifying Looping ChatML dataset and RAG index..."
"$VENV_PY" "$SCRIPT_DIR/build_dataset.py"
"$VENV_PY" "$SCRIPT_DIR/build_rag_index.py"

if [[ "$SETUP_ONLY" -eq 1 ]]; then
  echo "✔ [Coki AI] Setup & dataset verification complete (--setup-only)."
  exit 0
fi

mkdir -p "$ADAPTER_DIR" "$MODEL_OUT_DIR"

if [[ "$FUSE_ONLY" -eq 0 ]]; then
  echo "🧠 [Coki AI] Starting MLX LoRA fine-tuning on $BASE_MODEL (iters=$ITERS, layers=$NUM_LAYERS, batch=$BATCH_SIZE)..."
  "$VENV_PY" -m mlx_lm lora \
    --model "$BASE_MODEL" \
    --train \
    --data "$DATA_DIR" \
    --adapter-path "$ADAPTER_DIR" \
    --batch-size "$BATCH_SIZE" \
    --num-layers "$NUM_LAYERS" \
    --iters "$ITERS" \
    --learning-rate "$LR" \
    --max-seq-length "$MAX_SEQ_LEN" \
    --steps-per-eval 100 \
    --save-every 100 \
    --grad-checkpoint
fi

echo "🔗 [Coki AI] Fusing LoRA adapters into standalone local MLX model at $MODEL_OUT_DIR..."
"$VENV_PY" -m mlx_lm fuse \
  --model "$BASE_MODEL" \
  --adapter-path "$ADAPTER_DIR" \
  --save-path "$MODEL_OUT_DIR"

cp "$COKI_AI_DIR/MODEL_CARD_TEMPLATE.md" "$MODEL_OUT_DIR/README.md"

echo ""
echo "✔ [Coki AI] Entrenamiento y fusión completados en local."
echo "   Para iniciar tu servidor local (127.0.0.1:8080): bash coki-ai/scripts/run_local.sh"
echo "   Para publicar en https://huggingface.co/CokiStudios: bash coki-ai/scripts/publish_huggingface.sh"
