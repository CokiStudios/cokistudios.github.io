#!/usr/bin/env python3
"""
Shared static & CLI syntax validator for Looping (.loop) snippets.
Combines balanced delimiter/quote checks with `./bin/looping check` AST parsing.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path
from typing import List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parents[1]
LOOPING_BIN = REPO_ROOT / "bin" / "looping"
LOCAL_MODEL_DIR = REPO_ROOT / "coki-ai" / "models" / "coki-looping-7b-mlx"


def resolve_openai_model(endpoint: str, preferred: str = "auto") -> str:
    """Resolve active model ID from `/v1/models` so `mlx_lm.server` doesn't fetch missing HF repos."""
    if preferred and preferred != "auto":
        return preferred
    parsed = urllib.parse.urlsplit(endpoint)
    if parsed.scheme and parsed.netloc:
        models_url = f"{parsed.scheme}://{parsed.netloc}/v1/models"
        try:
            with urllib.request.urlopen(models_url, timeout=2.0) as resp:
                payload = json.loads(resp.read().decode("utf-8"))
            items = [m.get("id", "") for m in payload.get("data", []) if isinstance(m, dict) and m.get("id")]
            for mid in items:
                if "coki-looping" in mid:
                    return mid
            if "default_model" in items:
                return "default_model"
            if items:
                return items[-1]
        except Exception:
            pass
    if LOCAL_MODEL_DIR.exists():
        return str(LOCAL_MODEL_DIR)
    return "default_model"


def extract_loop_blocks(text: str, allow_generic: bool = False) -> List[str]:
    """Extract ```loop``` / ```looping``` fenced code blocks from model output."""
    blocks = re.findall(r"```(?:loop|looping)\s*\n(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if blocks or not allow_generic:
        return [b.strip() for b in blocks if b.strip()]
    generic = re.findall(r"```\s*\n(.*?)```", text, re.DOTALL)
    return [b.strip() for b in generic if b.strip()]


def has_balanced_delimiters(code: str) -> bool:
    stack: List[str] = []
    pairs = {"{": "}", "(": ")", "[": "]"}
    closing = set(pairs.values())
    in_quote: Optional[str] = None
    escaped = False
    i = 0
    n = len(code)
    while i < n:
        ch = code[i]
        nxt = code[i + 1] if i + 1 < n else ""
        if in_quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == in_quote:
                in_quote = None
            i += 1
            continue
        if ch == "/" and nxt == "/":
            nl = code.find("\n", i)
            i = n if nl == -1 else nl + 1
            continue
        if ch == "#" and (i == 0 or code[i - 1] in " \t\n("):
            if i + 1 < n and code[i + 1] not in "0123456789abcdefABCDEF":
                nl = code.find("\n", i)
                i = n if nl == -1 else nl + 1
                continue
        if ch in ('"', "'"):
            in_quote = ch
        elif ch in pairs:
            stack.append(pairs[ch])
        elif ch in closing:
            if not stack or stack[-1] != ch:
                return False
            stack.pop()
        i += 1
    return not stack and in_quote is None


def check_loop_with_cli(code: str, require_binary: bool = False) -> Tuple[bool, str]:
    """Validate Looping source for balanced syntax and valid C++ AST parsing."""
    stripped = code.strip()
    if not stripped:
        return False, "empty code snippet"
    if not has_balanced_delimiters(stripped):
        return False, "unbalanced delimiters/quotes"
    if not LOOPING_BIN.exists():
        if require_binary:
            return False, f"binary missing at {LOOPING_BIN}"
        return True, "balanced (cli skipped: binary missing)"

    with tempfile.NamedTemporaryFile("w", suffix=".loop", delete=False, encoding="utf-8") as tmp:
        tmp.write(stripped)
        tmp_path = tmp.name
    try:
        proc = subprocess.run(
            [str(LOOPING_BIN), "check", tmp_path],
            capture_output=True,
            text=True,
            timeout=10,
            cwd=str(REPO_ROOT),
        )
        out = ((proc.stdout or "") + "\n" + (proc.stderr or "")).strip()
        if proc.returncode != 0:
            return False, f"cli rc={proc.returncode}: {out}"
        if "AST CHECK OK" not in out:
            return False, f"missing AST CHECK OK: {out}"
        m = re.search(r"Total AST Nodes:\s*(\d+)", out)
        if m and int(m.group(1)) == 0:
            return False, "parsed 0 AST nodes"
        return True, out
    except Exception as exc:
        return False, str(exc)
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
