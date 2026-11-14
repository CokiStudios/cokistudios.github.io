#!/usr/bin/env bash
set -euo pipefail

# Coki AI — 100% Local Apple Silicon MLX LoRA Training Pipeline
# Base model: mlx-community/Qwen2.5-Coder-7B-Instruct-4bit (tuned safely for 16 GB RAM)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_env.sh"

ITERS="${COKI_AI_ITERS:-300}"
BATCH_SIZE="${COKI_AI_BATCH_SIZE:-1}"
GRAD_ACCUM="${COKI_AI_GRAD_ACCUM:-4}"
NUM_LAYERS="${COKI_AI_NUM_LAYERS:-8}"
MAX_SEQ_LEN="${COKI_AI_MAX_SEQ_LEN:-1280}"
LR="${COKI_AI_LR:-5e-6}"
OPTIMIZER="${COKI_AI_OPTIMIZER:-adamw}"
SETUP_ONLY=0
FUSE_ONLY=0

mkdir -p "$STORAGE_ROOT" "$HF_HOME"

for arg in "$@"; do
  case "$arg" in
    --setup-only) SETUP_ONLY=1 ;;
    --fuse-only)  FUSE_ONLY=1 ;;
    --help|-h)
      echo "Usage: $0 [--setup-only] [--fuse-only]"
      echo "Env overrides: COKI_AI_BASE_MODEL, COKI_AI_ITERS, COKI_AI_BATCH_SIZE, COKI_AI_GRAD_ACCUM, COKI_AI_NUM_LAYERS, COKI_AI_MAX_SEQ_LEN, COKI_AI_LR, COKI_AI_OPTIMIZER"
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
  echo "🧠 [Coki AI] Starting stabilized MLX LoRA fine-tuning on $BASE_MODEL (iters=$ITERS, opt=$OPTIMIZER, lr=$LR, grad_accum=$GRAD_ACCUM)..."
  # Remove stale checkpoints so an old divergent run never lingers in $ADAPTER_DIR
  rm -f "$ADAPTER_DIR"/*_adapters.safetensors "$ADAPTER_DIR"/adapters.safetensors
  "$VENV_PY" -m mlx_lm lora \
    --model "$BASE_MODEL" \
    --train \
    --data "$DATA_DIR" \
    --adapter-path "$ADAPTER_DIR" \
    --optimizer "$OPTIMIZER" \
    --mask-prompt \
    --batch-size "$BATCH_SIZE" \
    --grad-accumulation-steps "$GRAD_ACCUM" \
    --num-layers "$NUM_LAYERS" \
    --iters "$ITERS" \
    --learning-rate "$LR" \
    --max-seq-length "$MAX_SEQ_LEN" \
    --steps-per-eval 50 \
    --save-every 50 \
    --grad-checkpoint
fi

echo "🩺 [Coki AI] Checking LoRA adapters for NaN/Inf divergence before fusing..."
"$VENV_PY" - "$ADAPTER_DIR" <<'PYEOF'
import glob, os, shutil, sys
import mlx.core as mx

adapter_dir = sys.argv[1]
final_path = os.path.join(adapter_dir, "adapters.safetensors")

def is_finite(path):
    if not os.path.exists(path):
        return False
    weights = mx.load(path)
    return all(not bool(mx.any(mx.isnan(v) | mx.isinf(v)).item()) for v in weights.values())

if is_finite(final_path):
    print(f"✔ [OK] {final_path} has finite weights.")
    sys.exit(0)

print(f"⚠️  Warning: {final_path} contains NaN/Inf or is missing; scanning finite checkpoints...")
ckpts = sorted(glob.glob(os.path.join(adapter_dir, "*_adapters.safetensors")), reverse=True)
for ckpt in ckpts:
    if is_finite(ckpt):
        shutil.copy2(ckpt, final_path)
        print(f"✔ [RECOVERED] Copied latest valid finite checkpoint {os.path.basename(ckpt)} -> adapters.safetensors")
        sys.exit(0)

print("❌ [ERROR] No valid finite LoRA adapters found. Lower COKI_AI_LR and re-run training.", file=sys.stderr)
sys.exit(1)
PYEOF

echo "🔗 [Coki AI] Fusing LoRA adapters into standalone local MLX model at $MODEL_OUT_DIR..."
"$VENV_PY" -m mlx_lm fuse \
  --model "$BASE_MODEL" \
  --adapter-path "$ADAPTER_DIR" \
  --save-path "$MODEL_OUT_DIR"

cp "$COKI_AI_DIR/MODEL_CARD_TEMPLATE.md" "$MODEL_OUT_DIR/README.md"

echo "🧪 [Coki AI] Running quick post-fuse sanity generation..."
"$VENV_PY" - "$MODEL_OUT_DIR" <<'PYEOF'
import sys
from mlx_lm import load, generate
model_dir = sys.argv[1]
model, tok = load(model_dir)
prompt = tok.apply_chat_template([{"role": "user", "content": "Responde OK en una palabra."}], tokenize=False, add_generation_prompt=True)
out = generate(model, tok, prompt=prompt, max_tokens=20)
print("Sample output:", repr(out))
if not out.strip() or out.count("!") > 10:
    print("❌ [ERROR] Fused model failed coherence sanity check!", file=sys.stderr)
    sys.exit(1)
PYEOF

echo ""
echo "✔ [Coki AI] Entrenamiento y fusión completados en local."
echo "   Para iniciar tu servidor local (127.0.0.1:8080): bash coki-ai/scripts/run_local.sh"
echo "   Para publicar en https://huggingface.co/CokiStudios: bash coki-ai/scripts/publish_huggingface.sh"
