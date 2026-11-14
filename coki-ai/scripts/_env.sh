#!/usr/bin/env bash
# Shared environment/storage resolver for Coki AI scripts.
# Prefers /Volumes/Support HD/CokiAI when mounted & writable so heavy MLX weights
# and caches stay off Macintosh HD.

_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COKI_AI_DIR="$(cd "$_ENV_DIR/.." && pwd)"
REPO_ROOT="$(cd "$COKI_AI_DIR/.." && pwd)"

if [[ -n "${COKI_AI_STORAGE_DIR:-}" ]]; then
  STORAGE_ROOT="$COKI_AI_STORAGE_DIR"
elif [[ -d "/Volumes/Support HD" && -w "/Volumes/Support HD" ]]; then
  STORAGE_ROOT="/Volumes/Support HD/CokiAI"
else
  STORAGE_ROOT="$COKI_AI_DIR"
fi

BASE_MODEL="${COKI_AI_BASE_MODEL:-mlx-community/Qwen2.5-Coder-7B-Instruct-4bit}"
DATA_DIR="$COKI_AI_DIR/data"
VENV_DIR="${COKI_AI_VENV_DIR:-$STORAGE_ROOT/.venv}"
ADAPTER_DIR="${COKI_AI_ADAPTER_DIR:-$STORAGE_ROOT/adapters/looping-7b}"
MODEL_OUT_DIR="${COKI_AI_MODEL_DIR:-$STORAGE_ROOT/models/coki-looping-7b-mlx}"
MODEL_DIR="$MODEL_OUT_DIR"

if [[ -z "${HF_HOME:-}" ]]; then
  if [[ "$STORAGE_ROOT" == "$COKI_AI_DIR" ]]; then
    export HF_HOME="$COKI_AI_DIR/.cache/huggingface"
  else
    export HF_HOME="$STORAGE_ROOT/hf_cache"
  fi
else
  export HF_HOME
fi
