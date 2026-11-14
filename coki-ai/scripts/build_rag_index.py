#!/usr/bin/env python3
"""
Builds a lightweight static RAG knowledge index (`assets/data/coki-rag-index.json`)
from official Looping & Coki Studios documentation and sample `.loop` code.

Used locally by `coki-ai/chat.py` (and optionally in-browser/widget) so Coki AI
always grounds its answers in real Looping syntax and up-to-date docs.

Usage:
  python3 coki-ai/scripts/build_rag_index.py
  python3 coki-ai/scripts/build_rag_index.py --verify
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Dict, List

REPO_ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = REPO_ROOT / "assets" / "data" / "coki-rag-index.json"

STOPWORDS = {
    "de", "la", "el", "en", "y", "a", "los", "las", "un", "una", "con", "por", "para",
    "que", "se", "del", "al", "es", "o", "su", "the", "of", "and", "to", "in", "for",
    "is", "with", "on", "as", "from", "by", "this", "that", "an", "or", "be",
}


def tokenize_keywords(text: str, limit: int = 16) -> List[str]:
    tokens = re.findall(r"[a-zA-Z0-9_+.!]{2,}", text.lower())
    filtered = [t for t in tokens if t not in STOPWORDS and not t.isdigit()]
    counts = Counter(filtered)
    return [tok for tok, _ in counts.most_common(limit)]


def chunk_markdown(path: Path, max_chars: int = 1200) -> List[Dict]:
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8", errors="ignore")
    chunks: List[Dict] = []
    current_title = path.name
    buf: List[str] = []

    def push_chunk(raw_body: str, part: int = 0) -> None:
        clean = raw_body.strip()
        if len(clean) < 70:
            return
        suffix = f" (part {part})" if part > 0 else ""
        title = f"{current_title}{suffix}"
        chunks.append(
            {
                "id": f"{path.stem}-{len(chunks)+1}",
                "title": title,
                "source": path.relative_to(REPO_ROOT).as_posix(),
                "keywords": tokenize_keywords(f"{title} {clean}"),
                "content": clean,
            }
        )

    def flush_buf() -> None:
        raw = "\n".join(buf).strip()
        if not raw:
            return
        if len(raw) <= max_chars:
            push_chunk(raw)
            return
        paragraphs = raw.split("\n\n")
        cur = ""
        part = 1
        for p in paragraphs:
            if len(cur) + len(p) + 2 > max_chars and cur:
                push_chunk(cur, part)
                part += 1
                cur = p
            else:
                cur = f"{cur}\n\n{p}".strip() if cur else p
        if cur:
            push_chunk(cur, part)

    in_fence = False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            in_fence = not in_fence
            buf.append(line)
            continue
        if not in_fence and re.match(r"^#{1,3}\s+", line):
            flush_buf()
            buf.clear()
            current_title = re.sub(r"^#+\s+", "", line).strip()
        else:
            buf.append(line)
    flush_buf()
    return chunks


def extract_html_chunks(path: Path, max_chars: int = 1100) -> List[Dict]:
    raw = path.read_text(encoding="utf-8", errors="ignore")
    # Strip scripts & style tags cleanly
    stripped = re.sub(r"<(script|style|svg)\b[^>]*>.*?</\1>", " ", raw, flags=re.DOTALL | re.IGNORECASE)
    title_m = re.search(r"<title>(.*?)</title>", stripped, re.IGNORECASE | re.DOTALL)
    doc_title = html.unescape(re.sub(r"\s+", " ", title_m.group(1))).strip() if title_m else path.parent.name
    main_text = html.unescape(re.sub(r"<[^>]+>", "\n", stripped))
    lines = [re.sub(r"[ \t]+", " ", ln).strip() for ln in main_text.splitlines()]
    compact = "\n".join(ln for ln in lines if ln)
    if len(compact) < 100:
        return []
    excerpt = compact[:max_chars].strip()
    rel = path.relative_to(REPO_ROOT).as_posix()
    return [
        {
            "id": f"docs-{path.parent.name}-1",
            "title": doc_title,
            "source": rel,
            "keywords": tokenize_keywords(f"{doc_title} {excerpt}"),
            "content": excerpt,
        }
    ]


def extract_sample_chunks() -> List[Dict]:
    samples_dir = REPO_ROOT / "sample_loop_projects"
    if not samples_dir.exists():
        return []
    chunks: List[Dict] = []
    for fpath in sorted(samples_dir.glob("*.loop")):
        code = fpath.read_text(encoding="utf-8", errors="ignore").strip()
        if not code:
            continue
        excerpt = code[:1100].strip()
        rel = fpath.relative_to(REPO_ROOT).as_posix()
        title = f"Sample `.loop`: {fpath.name}"
        chunks.append(
            {
                "id": f"sample-{fpath.stem}",
                "title": title,
                "source": rel,
                "keywords": tokenize_keywords(f"{fpath.stem} looping {excerpt}"),
                "content": excerpt,
            }
        )
    return chunks


def verify_index() -> int:
    if not INDEX_PATH.exists():
        print(f"[FAIL] Missing RAG index: {INDEX_PATH}", file=sys.stderr)
        return 1
    try:
        payload = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"[FAIL] Invalid JSON in {INDEX_PATH}: {exc}", file=sys.stderr)
        return 1

    chunks = payload.get("chunks")
    if not isinstance(chunks, list) or len(chunks) < 20:
        print(f"[FAIL] RAG index chunk count too small: {len(chunks) if isinstance(chunks, list) else 0}", file=sys.stderr)
        return 1

    for idx, ch in enumerate(chunks):
        for key in ("id", "title", "source", "keywords", "content"):
            if not ch.get(key):
                print(f"[FAIL] Chunk #{idx} missing field '{key}'", file=sys.stderr)
                return 1

    size_kb = INDEX_PATH.stat().st_size / 1024.0
    if size_kb > 2048:
        print(f"[FAIL] RAG index exceeds 2 MB cap ({size_kb:.1f} KB)", file=sys.stderr)
        return 1

    all_kw = {kw for ch in chunks for kw in ch["keywords"]}
    for expected in ("spawn3d", "looping", "smiledev"):
        if not any(expected in k for k in all_kw):
            print(f"[FAIL] Expected keyword '{expected}' missing from RAG index", file=sys.stderr)
            return 1

    print(f"[RAG INDEX OK] {INDEX_PATH.relative_to(REPO_ROOT)} | {len(chunks)} chunks | {size_kb:.1f} KB")
    return 0


def build() -> int:
    chunks: List[Dict] = []
    for doc_name in ("LOOPING_USE.md", "LOOPING_LEARNING_GUIDE.md", "SMILEDEV_README.md", "modules/README.md", "SUPABASE_SCHEMA.md"):
        chunks.extend(chunk_markdown(REPO_ROOT / doc_name))

    docs_dir = REPO_ROOT / "docs"
    if docs_dir.exists():
        for html_file in sorted(docs_dir.rglob("index.html")):
            chunks.extend(extract_html_chunks(html_file))

    chunks.extend(extract_sample_chunks())

    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "schema": "coki-ai-rag-v1",
        "huggingface": "https://huggingface.co/CokiStudios",
        "chunk_count": len(chunks),
        "chunks": chunks,
    }
    INDEX_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return verify_index()


def main() -> int:
    parser = argparse.ArgumentParser(description="Build & verify static Looping RAG index.")
    parser.add_argument("--verify", action="store_true", help="Verify existing assets/data/coki-rag-index.json.")
    args = parser.parse_args()
    if args.verify:
        return verify_index()
    return build()


if __name__ == "__main__":
    raise SystemExit(main())
