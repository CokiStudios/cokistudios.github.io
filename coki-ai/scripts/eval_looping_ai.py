#!/usr/bin/env python3
"""
Evaluates Coki AI (local MLX server or held-out JSONL test split) by verifying
that generated `.loop` code blocks pass balanced-delimiter & `./bin/looping check`.

Usage:
  # Verify curated prompts against a running local MLX server (127.0.0.1:8080):
  python3 coki-ai/scripts/eval_looping_ai.py

  # Offline smoke validation on coki-ai/data/test.jsonl + evaluator pipeline:
  python3 coki-ai/scripts/eval_looping_ai.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path
from typing import Dict, List, Tuple

COKI_AI_DIR = Path(__file__).resolve().parents[1]
if str(COKI_AI_DIR) not in sys.path:
    sys.path.insert(0, str(COKI_AI_DIR))

from loop_validator import check_loop_with_cli, extract_loop_blocks, resolve_openai_model  # noqa: E402

TEST_JSONL = COKI_AI_DIR / "data" / "test.jsonl"
DEFAULT_ENDPOINT = os.environ.get("COKI_AI_ENDPOINT", "http://127.0.0.1:8080/v1/chat/completions")
DEFAULT_MODEL = os.environ.get("COKI_AI_MODEL", "auto")

BENCH_PROMPTS: List[Tuple[str, List[str]]] = [
    (
        "Crea un nivel 2D en Looping con spawn.player, spawn.moving_platform, spawn.coin y spawn.portal.",
        ["spawn.player", "spawn.portal"],
    ),
    (
        "Crea una escena 3D en Looping usando define game3d, scene3d.world, spawn3d.player y spawn3d.box.",
        ["define game3d", "spawn3d.player"],
    ),
    (
        "Escribe un snippet Looping que use use \"loopize++\", obj3d.load y lz_wave_rush.",
        ["loopize++", "obj3d.load"],
    ),
    (
        "Crea una función arrow `fn` y un `match` con rangos en Looping, más una tarjeta `ui.card`.",
        ["fn ", "match ", "ui.card"],
    ),
    (
        "Corrige este Looping roto:\n```looping\nvar x = 10\nif (x > 5 {\n  print(x)\n```",
        ["print"],
    ),
]


def query_endpoint(endpoint: str, model: str, prompt: str) -> str:
    payload = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": "Eres Coki AI, experto en Looping. Responde con un bloque ```looping ... ``` válido.",
            },
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
        "max_tokens": 900,
    }
    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120.0) as res:
        data = json.loads(res.read().decode("utf-8"))
    return data["choices"][0]["message"]["content"]


def evaluate_live(endpoint: str, model: str) -> int:
    active_model = resolve_openai_model(endpoint, model)
    print(f"[eval] Querying local MLX endpoint: {endpoint} (model={active_model})")
    passed = 0
    for idx, (prompt, required_tokens) in enumerate(BENCH_PROMPTS, 1):
        try:
            answer = query_endpoint(endpoint, active_model, prompt)
        except Exception as exc:
            print(f"  [ERROR #{idx}] Could not reach local server: {exc}")
            return 1

        blocks = extract_loop_blocks(answer, allow_generic=True)
        if not blocks:
            print(f"  [FAIL #{idx}] No ```looping``` block returned.")
            continue

        code = blocks[0]
        ok, diag = check_loop_with_cli(code, require_binary=True)
        missing = [tok for tok in required_tokens if tok not in code]
        if ok and not missing:
            passed += 1
            print(f"  [PASS #{idx}] AST check OK & required tokens present.")
        else:
            print(f"  [FAIL #{idx}] ok={ok}, missing={missing}, diag={diag}")

    total = len(BENCH_PROMPTS)
    print(f"\n[EVAL RESULT] {passed}/{total} prompts passed AST + semantic checks ({(passed/total)*100:.0f}%).")
    return 0 if passed >= max(1, total - 1) else 1


def evaluate_dry_run() -> int:
    if not TEST_JSONL.exists():
        print(f"[FAIL] Missing test split: {TEST_JSONL}", file=sys.stderr)
        return 1

    checked = 0
    passed = 0
    for line in TEST_JSONL.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        ans = row["messages"][2]["content"]
        for blk in extract_loop_blocks(ans):
            checked += 1
            ok, diag = check_loop_with_cli(blk, require_binary=True)
            if ok:
                passed += 1
            else:
                print(f"  [FAIL] test sample block failed: {diag}", file=sys.stderr)

    print(f"[EVAL DRY-RUN OK] Verified {passed}/{checked} .loop blocks in test.jsonl with ./bin/looping check.")
    return 0 if passed == checked and checked > 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate Coki AI Looping code generation.")
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT, help="Local MLX server chat completions URL.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Model name for OpenAI-compatible payload.")
    parser.add_argument("--dry-run", action="store_true", help="Validate evaluator & test.jsonl without running local LLM.")
    args = parser.parse_args()

    if args.dry_run:
        return evaluate_dry_run()
    return evaluate_live(args.endpoint, args.model)


if __name__ == "__main__":
    raise SystemExit(main())
