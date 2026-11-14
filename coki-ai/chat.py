#!/usr/bin/env python3
"""
Coki AI Local CLI Assistant (100% Local Apple Silicon MLX + Static RAG + Looping Check).

Connects to the local OpenAI-compatible MLX server (`http://127.0.0.1:8080/v1/chat/completions`),
optionally checks local Ollama (`127.0.0.1:11434`) if MLX is offline, grounds answers using
`assets/data/coki-rag-index.json`, and validates/fixes `.loop` files via `./bin/looping check`.

Usage:
  python3 coki-ai/chat.py "Crea un nivel 3D con spawn3d.player y sky cyber_night"
  python3 coki-ai/chat.py --fix sample_loop_projects/cyber_odyssey_3d.loop
  python3 coki-ai/chat.py --chat
  python3 coki-ai/chat.py --rag-only "como funciona loopize++"
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional, Tuple

COKI_AI_DIR = Path(__file__).resolve().parent
REPO_ROOT = COKI_AI_DIR.parent
RAG_INDEX_PATH = REPO_ROOT / "assets" / "data" / "coki-rag-index.json"

if str(COKI_AI_DIR) not in sys.path:
    sys.path.insert(0, str(COKI_AI_DIR))

from loop_validator import check_loop_with_cli, extract_loop_blocks, resolve_openai_model  # noqa: E402

DEFAULT_MLX_ENDPOINT = os.environ.get("COKI_AI_ENDPOINT", "http://127.0.0.1:8080/v1/chat/completions")
DEFAULT_MODEL = os.environ.get("COKI_AI_MODEL", "auto")
HUGGINGFACE_URL = "https://huggingface.co/CokiStudios"

RAG_STOPWORDS = {
    "hola", "como", "sirve", "para", "con", "que", "sobre", "una", "uno", "unos", "unas",
    "explicame", "explica", "dame", "quiero", "puedo", "hacer", "usa", "usar", "funciona",
    "del", "las", "los", "por", "the", "and", "how", "what", "with", "for", "does",
}

SYSTEM_PROMPT = (
    "Eres Coki AI, asistente experto en el lenguaje Looping de Coki Studios "
    "(sintaxis v2.8–v3.0, motor 2D/3D Quantum, mallas .obj, C# cs!, loopize++, pyloop, ui.*, smiledev). "
    "Usa el contexto documental provisto para responder con código .loop válido y conciso."
)


def load_rag_chunks() -> List[Dict]:
    if not RAG_INDEX_PATH.exists():
        return []
    try:
        payload = json.loads(RAG_INDEX_PATH.read_text(encoding="utf-8"))
        return payload.get("chunks", []) if isinstance(payload, dict) else []
    except Exception:
        return []


def search_rag(query: str, chunks: List[Dict], top_k: int = 3) -> List[Dict]:
    if not chunks or not query.strip():
        return []
    raw_tokens = re.findall(r"[a-zA-Z0-9_+.!]{2,}", query.lower())
    q_tokens = [t for t in raw_tokens if t not in RAG_STOPWORDS] or raw_tokens
    # Map bare "loop" shorthand in casual Spanish questions to Looping language docs too
    expanded = list(q_tokens)
    if "loop" in expanded and "looping" not in expanded:
        expanded.append("looping")

    scored: List[Tuple[float, Dict]] = []
    for ch in chunks:
        title = str(ch.get("title", "")).lower()
        kw = {str(k).lower() for k in ch.get("keywords", [])}
        body = str(ch.get("content", "")).lower()
        score = 0.0
        for tok in expanded:
            whole_re = rf"\b{re.escape(tok)}\b"
            if re.search(whole_re, title):
                score += 6.0
            elif tok in title:
                score += 3.0
            if tok in kw:
                score += 2.5
            hits = body.count(tok)
            if hits:
                score += min(hits, 4) * 1.0
        if score > 0:
            scored.append((score, ch))
    scored.sort(key=lambda item: item[0], reverse=True)
    return [item[1] for item in scored[:top_k]]


def format_rag_context(matches: List[Dict]) -> str:
    if not matches:
        return ""
    blocks = []
    for ch in matches:
        blocks.append(f"[{ch.get('source')} — {ch.get('title')}]\n{str(ch.get('content', ''))[:950]}")
    return "\n\n---\n\n".join(blocks)


def _post_json(url: str, payload: Dict, timeout: float = 45.0) -> Tuple[Optional[Dict], Optional[str]]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8")), None
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="ignore") if exc.fp else ""
        return None, f"HTTP {exc.code}: {body[:200]}"
    except Exception as exc:
        return None, str(exc)


def _first_local_ollama_model() -> Optional[str]:
    try:
        with urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=1.5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        models = data.get("models") or []
        return models[0].get("name") if models else None
    except Exception:
        return None


def query_local_llm(
    user_prompt: str,
    rag_context: str,
    endpoint: str = DEFAULT_MLX_ENDPOINT,
    model: str = DEFAULT_MODEL,
    allow_cloud: bool = False,
) -> Tuple[Optional[str], str, Optional[str]]:
    sys_content = SYSTEM_PROMPT
    if rag_context:
        sys_content += "\n\n### Documentación Looping relevante:\n" + rag_context

    messages = [
        {"role": "system", "content": sys_content},
        {"role": "user", "content": user_prompt},
    ]

    # 1. Local Apple Silicon MLX Server (127.0.0.1:8080)
    resolved_model = resolve_openai_model(endpoint, model)
    resp, err = _post_json(
        endpoint,
        {"model": resolved_model, "messages": messages, "temperature": 0.25, "max_tokens": 1100},
        timeout=60.0,
    )
    if resp and resp.get("choices"):
        content = resp["choices"][0].get("message", {}).get("content", "").strip()
        if content:
            model_label = Path(resolved_model).name if ("/" in resolved_model or "\\" in resolved_model) else resolved_model
            return content, f"MLX Local ({model_label})", None

    # 2. Optional local Ollama fallback (if running on 127.0.0.1:11434)
    ollama_model = _first_local_ollama_model()
    if ollama_model:
        oresp, _ = _post_json(
            "http://127.0.0.1:11434/v1/chat/completions",
            {"model": ollama_model, "messages": messages, "temperature": 0.25},
            timeout=60.0,
        )
        if oresp and oresp.get("choices"):
            content = oresp["choices"][0].get("message", {}).get("content", "").strip()
            if content:
                return content, f"Ollama Local ({ollama_model})", None

    # 3. Optional cloud fallback only when explicitly enabled (--cloud)
    if allow_cloud:
        cresp, _ = _post_json(
            "https://cokistudios.com/api/coki",
            {"query": user_prompt, "context": rag_context[:1500]},
            timeout=20.0,
        )
        if cresp and (cresp.get("answer") or cresp.get("response")):
            return (cresp.get("answer") or cresp.get("response")).strip(), cresp.get("engine", "Cloud Fallback"), None

    return None, "offline", err


def run_ask(
    query: str,
    chunks: List[Dict],
    endpoint: str,
    model: str,
    rag_only: bool = False,
    allow_cloud: bool = False,
    verify_code: bool = True,
) -> int:
    matches = search_rag(query, chunks, top_k=3)
    rag_ctx = format_rag_context(matches)

    if rag_only:
        print(f"🔎 [Coki AI RAG Offline] {len(matches)} coincidencias en docs:\n")
        for idx, ch in enumerate(matches, 1):
            print(f"--- {idx}. {ch['title']} ({ch['source']}) ---")
            print(ch["content"][:700].strip())
            print()
        return 0

    answer, backend, err = query_local_llm(query, rag_ctx, endpoint=endpoint, model=model, allow_cloud=allow_cloud)
    if answer:
        print(f"🤖 [Coki AI · {backend}]\n")
        print(answer)
        if verify_code:
            blocks = extract_loop_blocks(answer)
            for idx, blk in enumerate(blocks, 1):
                ok, report = check_loop_with_cli(blk)
                tag = "✔ VERIFICADO" if ok else "⚠ REVISIÓN"
                summary = report.splitlines()[0] if report else ""
                print(f"\n[{tag} bloque #{idx}] {summary}")
        return 0

    print("⚠️  Servidor MLX local no detectado en", endpoint)
    print(f"   Motivo: {err}")
    print("   Inicia tu modelo local con:  bash coki-ai/scripts/run_local.sh")
    print(f"   O descarga pesos publicados: {HUGGINGFACE_URL}\n")
    if matches:
        print("📚 Referencia documental local encontrada mientras tanto:")
        for ch in matches[:2]:
            print(f"\n• {ch['title']} ({ch['source']}):")
            print(ch["content"][:480].strip())
    return 1


def run_fix(
    file_path: Path,
    chunks: List[Dict],
    endpoint: str,
    model: str,
    allow_cloud: bool = False,
) -> int:
    if not file_path.exists():
        print(f"Error: no existe el archivo '{file_path}'.", file=sys.stderr)
        return 1

    code = file_path.read_text(encoding="utf-8", errors="ignore")
    ok, diag = check_loop_with_cli(code)
    status_label = "SIN ERRORES GRAVES DE PARSEO" if ok else f"PROBLEMA DETECTADO: {diag}"
    print(f"🩺 Diagnóstico inicial de `{file_path}` -> {status_label}")

    prompt = (
        f"Analiza y corrige este archivo Looping (`{file_path.name}`) asegurando sintaxis válida "
        f"de Coki Studios, llaves/paréntesis balanceados y mejores prácticas v2.8–v3.0.\n"
        f"Diagnóstico CLI actual: {status_label}\n\n"
        f"```looping\n{code}\n```"
    )
    matches = search_rag(prompt, chunks, top_k=3)
    answer, backend, err = query_local_llm(
        prompt, format_rag_context(matches), endpoint=endpoint, model=model, allow_cloud=allow_cloud
    )
    if not answer:
        print(f"\n⚠️  No hay servidor LLM local activo ({err}).")
        print("   Ejecuta `bash coki-ai/scripts/run_local.sh` para activar `--fix` asistido por MLX.")
        return 0 if ok else 1

    print(f"\n🤖 [Propuesta de corrección · {backend}]\n")
    print(answer)
    blocks = extract_loop_blocks(answer)
    if blocks:
        fix_ok, fix_diag = check_loop_with_cli(blocks[0])
        if fix_ok:
            print("\n✔ Código corregido verificado con `./bin/looping check`.")
        else:
            print(f"\n⚠️ Advertencia de verificación sobre la propuesta: {fix_diag}")
    return 0


def run_chat(chunks: List[Dict], endpoint: str, model: str, allow_cloud: bool = False) -> int:
    print("♾️  Coki AI · Chat Local para Looping (MLX)")
    print(f"    Endpoint: {endpoint} | Hugging Face: {HUGGINGFACE_URL}")
    print("    Comandos: /rag <tema>, /fix <archivo.loop>, /exit\n")
    while True:
        try:
            line = input("coki-ai> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nHasta pronto.")
            return 0
        if not line:
            continue
        if line in ("/exit", "/quit", "exit", "quit"):
            return 0
        if line.startswith("/rag "):
            run_ask(line[5:].strip(), chunks, endpoint, model, rag_only=True)
            print()
            continue
        if line.startswith("/fix "):
            run_fix(Path(line[5:].strip()), chunks, endpoint, model, allow_cloud=allow_cloud)
            print()
            continue
        run_ask(line, chunks, endpoint, model, allow_cloud=allow_cloud)
        print()


def main() -> int:
    parser = argparse.ArgumentParser(description="Coki AI Local Looping Assistant (Apple Silicon MLX + RAG).")
    parser.add_argument("query", nargs="*", help="Pregunta o prompt de programación Looping.")
    parser.add_argument("--ask", dest="ask_text", default="", help="Consulta directa para Coki AI.")
    parser.add_argument("--fix", dest="fix_file", default="", help="Analiza y repara un archivo .loop.")
    parser.add_argument("--chat", action="store_true", help="Inicia sesión interactiva en terminal.")
    parser.add_argument("--rag-only", action="store_true", help="Solo consulta el índice documental local sin LLM.")
    parser.add_argument("--cloud", action="store_true", help="Permite respaldo opcional a cokistudios.com/api/coki si MLX local está apagado.")
    parser.add_argument("--endpoint", default=DEFAULT_MLX_ENDPOINT, help="Endpoint OpenAI-compatible local (MLX).")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Nombre del modelo configurado.")
    args = parser.parse_args()

    chunks = load_rag_chunks()

    if args.fix_file:
        return run_fix(Path(args.fix_file), chunks, args.endpoint, args.model, allow_cloud=args.cloud)

    if args.chat:
        return run_chat(chunks, args.endpoint, args.model, allow_cloud=args.cloud)

    query_text = (args.ask_text or " ".join(args.query)).strip()
    if not query_text:
        parser.print_help()
        return 0

    return run_ask(
        query_text,
        chunks,
        endpoint=args.endpoint,
        model=args.model,
        rag_only=args.rag_only,
        allow_cloud=args.cloud,
    )


if __name__ == "__main__":
    raise SystemExit(main())
