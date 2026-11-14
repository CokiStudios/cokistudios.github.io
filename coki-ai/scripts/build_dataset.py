#!/usr/bin/env python3
"""
Builds deterministic ChatML JSONL datasets (train/valid/test) for training
Coki AI (7B MLX LoRA) to write, explain, and debug Looping (.loop) code.

Extracts verified content from:
  - LOOPING_USE.md, LOOPING_LEARNING_GUIDE.md, SMILEDEV_README.md, modules/README.md
  - docs/*/*.html (stripped HTML documentation & code snippets)
  - sample_loop_projects/*.loop
  - modules/*/ (smile.json manifests + module sources)
  - LoopingEngine/cpp/main.cpp (unit test assertions)
  - Curated bilingual (ES/EN) synthesis & bug-fix pairs verified by AST checks

Usage:
  python3 coki-ai/scripts/build_dataset.py
  python3 coki-ai/scripts/build_dataset.py --check
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import random
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

COKI_AI_DIR = Path(__file__).resolve().parents[1]
if str(COKI_AI_DIR) not in sys.path:
    sys.path.insert(0, str(COKI_AI_DIR))

from loop_validator import check_loop_with_cli  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = COKI_AI_DIR / "data"

SYSTEM_PROMPT = (
    "Eres Coki AI, asistente experto en el lenguaje de programación Looping de Coki Studios "
    "(sintaxis v2.8–v3.0, motor 2D/3D Quantum, mallas .obj, C# embebido cs!, loopize++, "
    "pyloop, SwiftUI bridge, UI glassmorphism y paquetes smiledev). Responde de forma clara, "
    "directa y con código .loop válido listo para ejecutar con ./bin/looping."
)


def make_example(user: str, assistant: str, tag: str = "general") -> Dict:
    return {
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user.strip()},
            {"role": "assistant", "content": assistant.strip()},
        ],
        "_tag": tag,
    }


def split_markdown_sections(text: str, source_name: str) -> List[Tuple[str, str]]:
    sections: List[Tuple[str, str]] = []
    cur_h1 = source_name
    cur_h2 = ""
    buf: List[str] = []
    in_fence = False

    def flush() -> None:
        body = "\n".join(buf).strip()
        if len(body) >= 120:
            title = f"{cur_h1} > {cur_h2}".strip(" >") if cur_h2 else cur_h1
            sections.append((title, body))

    for line in text.splitlines():
        if line.strip().startswith("```"):
            in_fence = not in_fence
            buf.append(line)
            continue
        if not in_fence and line.startswith("# "):
            flush()
            buf.clear()
            cur_h1 = line[2:].strip()
            cur_h2 = ""
        elif not in_fence and line.startswith("## "):
            flush()
            buf.clear()
            cur_h2 = line[3:].strip()
        elif not in_fence and line.startswith("### ") and len("\n".join(buf)) > 900:
            flush()
            buf.clear()
            buf.append(line)
        else:
            buf.append(line)
    flush()
    return sections


def trim_preserving_fences(text: str, limit: int = 2400) -> str:
    if len(text) <= limit:
        return text.strip()
    cut = text[:limit]
    # Avoid leaving an unclosed ``` block
    if cut.count("```") % 2 == 1:
        last_open = cut.rfind("```")
        if last_open > 150:
            cut = cut[:last_open]
        else:
            cut = cut + "\n```"
    return cut.strip()


def extract_markdown_qa(path: Path) -> List[Dict]:
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8", errors="ignore")
    examples: List[Dict] = []
    sections = split_markdown_sections(text, path.name)

    prompts_es = [
        "Explícame con claridad qué cubre la sección «{title}» en Looping y muestra su sintaxis.",
        "¿Cómo funciona «{title}» según la documentación oficial de Coki Studios?",
        "Dame una guía práctica sobre «{title}» en el ecosistema Looping.",
    ]
    prompts_en = [
        "Explain «{title}» in Looping with the exact syntax shown in official docs.",
    ]

    for idx, (title, body) in enumerate(sections):
        clean_title = re.sub(r"[`*#]+", "", title).strip()
        answer = trim_preserving_fences(body, 2400)
        if idx % 4 == 3:
            q = prompts_en[0].format(title=clean_title)
        else:
            q = prompts_es[idx % len(prompts_es)].format(title=clean_title)
        examples.append(make_example(q, answer, tag=f"doc:{path.name}"))

    # Also extract standalone loop code fences for "write an example" tasks
    fence_re = re.compile(r"```(?:loop|looping)\n(.*?)```", re.DOTALL)
    for idx, match in enumerate(fence_re.finditer(text)):
        snippet = match.group(1).strip()
        if len(snippet) < 40 or len(snippet) > 3200:
            continue
        ok, _ = check_loop_with_cli(snippet)
        if not ok:
            continue
        # Find nearest heading before match
        prefix = text[: match.start()]
        headings = re.findall(r"^#{1,3}\s+(.+)$", prefix, flags=re.MULTILINE)
        topic = headings[-1].strip() if headings else path.stem
        q = f"Escribe un ejemplo válido en Looping sobre: {topic}."
        a = f"Aquí tienes un ejemplo funcional en Looping para **{topic}**:\n\n```looping\n{snippet}\n```"
        examples.append(make_example(q, a, tag=f"fence:{path.name}"))

    return examples


def extract_sample_projects() -> List[Dict]:
    samples_dir = REPO_ROOT / "sample_loop_projects"
    if not samples_dir.exists():
        return []
    examples: List[Dict] = []
    for fpath in sorted(samples_dir.glob("*.loop")):
        code = fpath.read_text(encoding="utf-8", errors="ignore").strip()
        if not code or len(code) > 4500:
            # For extra-long demos, include an explanatory summary + key excerpt
            lines = code.splitlines()
            excerpt = "\n".join(lines[:75]).strip()
            ok, _ = check_loop_with_cli(code)
            if not ok:
                continue
            q = f"¿Cómo está estructurado el proyecto de ejemplo `{fpath.name}` en Looping?"
            a = (
                f"El archivo `sample_loop_projects/{fpath.name}` ({len(lines)} líneas) implementa una "
                f"escena completa de Looping. Este es su bloque principal inicial:\n\n```looping\n{excerpt}\n```"
            )
            examples.append(make_example(q, a, tag="sample-excerpt"))
            continue

        ok, _ = check_loop_with_cli(code)
        if not ok:
            continue

        stem = fpath.stem.replace("_", " ")
        kind = "3D" if ("spawn3d." in code or "define game3d" in code) else "2D/UI"
        q1 = f"Muéstrame un programa completo en Looping ({kind}) inspirado en `{fpath.name}` ({stem})."
        a1 = (
            f"Este script completo está basado en `sample_loop_projects/{fpath.name}` "
            f"y pasa verificación de sintaxis con `./bin/looping check`:\n\n```looping\n{code}\n```"
        )
        examples.append(make_example(q1, a1, tag="sample-full"))
    return examples


def extract_modules_examples() -> List[Dict]:
    mod_dir = REPO_ROOT / "modules"
    if not mod_dir.exists():
        return []
    examples: List[Dict] = []
    for pkg_dir in sorted(p for p in mod_dir.iterdir() if p.is_dir()):
        manifest_path = pkg_dir / "smile.json"
        if not manifest_path.exists():
            continue
        manifest_raw = manifest_path.read_text(encoding="utf-8", errors="ignore").strip()
        try:
            manifest = json.loads(manifest_raw)
        except Exception:
            continue
        name = manifest.get("name", pkg_dir.name)
        lang = manifest.get("language", "loop")
        entry = manifest.get("entry") or manifest.get("main") or ""
        desc = manifest.get("description", "")

        q = f"¿Cómo se configura el manifiesto `smile.json` del módulo `{name}` para smiledev?"
        a = (
            f"El paquete `{name}` (lenguaje `{lang}`) define su manifiesto en `modules/{pkg_dir.name}/smile.json`:\n\n"
            f"```json\n{json.dumps(manifest, indent=2, ensure_ascii=False)}\n```\n\n"
            f"Se instala localmente o desde registro con `smiledev install {name}`."
        )
        if desc:
            a = f"{desc}\n\n" + a
        examples.append(make_example(q, a, tag="smiledev-manifest"))

        if entry:
            entry_file = pkg_dir / entry
            if entry_file.exists() and entry_file.stat().st_size < 3500:
                code = entry_file.read_text(encoding="utf-8", errors="ignore").strip()
                fence_lang = "looping" if entry.endswith(".loop") else ("python" if entry.endswith(".py") else "")
                q2 = f"Muestra el punto de entrada `{entry}` del módulo `{name}` en smiledev."
                a2 = f"Archivo `modules/{pkg_dir.name}/{entry}`:\n\n```{fence_lang}\n{code}\n```"
                examples.append(make_example(q2, a2, tag="smiledev-entry"))
    return examples


def extract_cpp_tests() -> List[Dict]:
    main_cpp = REPO_ROOT / "LoopingEngine" / "cpp" / "main.cpp"
    if not main_cpp.exists():
        return []
    text = main_cpp.read_text(encoding="utf-8", errors="ignore")
    examples: List[Dict] = []
    pattern = re.compile(
        r'//\s*(Test \d+:[^\n]+)\n\s*(?:if\s*\([^)]+\)\s*\{\s*\n\s*)?vm\.execute_code\("((?:[^"\\]|\\.)*)"\);',
        re.MULTILINE,
    )
    for title, raw_code in pattern.findall(text):
        code = (
            raw_code.replace("\\n", "\n")
            .replace('\\"', '"')
            .replace("\\\\", "\\")
            .strip()
        )
        ok, _ = check_loop_with_cli(code)
        if not ok:
            continue
        clean_title = re.sub(r"^Test \d+:\s*", "", title).strip()
        q = f"Escribe un snippet breve en Looping que demuestre: {clean_title}."
        a = f"Snippet verificado por la suite C++ de Looping para **{clean_title}**:\n\n```looping\n{code}\n```"
        examples.append(make_example(q, a, tag="cpp-test"))
    return examples


def extract_html_docs() -> List[Dict]:
    docs_dir = REPO_ROOT / "docs"
    if not docs_dir.exists():
        return []
    examples: List[Dict] = []
    for html_path in sorted(docs_dir.rglob("index.html")):
        raw = html_path.read_text(encoding="utf-8", errors="ignore")
        title_m = re.search(r"<title>(.*?)</title>", raw, re.IGNORECASE | re.DOTALL)
        doc_title = html.unescape(re.sub(r"\s+", " ", title_m.group(1))).strip() if title_m else html_path.parent.name
        # Extract code blocks inside <pre><code>...</code></pre>
        blocks = re.findall(r"<pre[^>]*><code[^>]*>(.*?)</code></pre>", raw, re.DOTALL | re.IGNORECASE)
        clean_blocks: List[str] = []
        for blk in blocks:
            txt = html.unescape(re.sub(r"<[^>]+>", "", blk)).strip()
            if 25 <= len(txt) <= 1800:
                clean_blocks.append(txt)
        if clean_blocks:
            joined = "\n\n".join(f"```looping\n{b}\n```" for b in clean_blocks[:3])
            rel = html_path.relative_to(REPO_ROOT).as_posix()
            q = f"Resume los ejemplos clave documentados en `{rel}` ({doc_title})."
            a = f"Ejemplos oficiales de **{doc_title}** (`{rel}`):\n\n{joined}"
            examples.append(make_example(q, a, tag="html-docs"))
    return examples


def curated_synthesis_and_fixes() -> List[Dict]:
    """High-signal hand-verified Looping tasks + bug-fix (--fix) pairs."""
    pairs: List[Tuple[str, str, str]] = [
        (
            "Crea un juego 2D básico en Looping con jugador, plataforma móvil, monedas, enemigo y portal.",
            """Aquí tienes un nivel 2D completo en Looping v2.8+ listo para ejecutar:

```looping
import loop.engine as game

define game "NeonJump2D" version 2.8:
    create window with title "Neon Jump 2D" and size (720, 420)
    set theme to "dark_neon"

    game.world(width: 1200, height: 420)
    game.gravity(980)
    game.friction(0.84)
    game.lives(3)

    spawn.player(name: "Runner", at: (90, 300), speed: 280, jump: 440, health: 100)
    spawn.platform(at: (40, 340), size: (220, 20), color: "#38bdf8")
    spawn.moving_platform(at: (300, 260), size: (150, 18), range: (260, 500), speed: 90, color: "#06b6d4")
    spawn.platform(at: (540, 210), size: (220, 20), color: "#6366f1")

    spawn.coin(at: (360, 200), points: 100)
    spawn.coin(at: (620, 155), points: 150)
    spawn.enemy(name: "Drone2D", at: (640, 168), range: (560, 720), speed: 65, health: 30)
    spawn.portal(at: (980, 290), label: "META")

    print("Nivel NeonJump2D inicializado.")
```""",
            "curated-2d",
        ),
        (
            "Build a 3D Looping game scene using define game3d, a chase camera, Wavefront starfighter.obj, and loopize++ waves.",
            """Here is a complete 3D Quantum scene combining `scene3d`, Wavefront `.obj`, and `loopize++`:

```looping
use "loopize++"
use "csharp"

define game3d "Starfleet Training 3D" version 3.0:
    scene3d.world(name: "Sector Alpha", size: (200, 100, 200), sky: "cyber_night", fog: 0.007, grid: true)
    camera3d.set(mode: "chase", pos: (0, 8.0, -15), target: (0, 2, 12), fov: 64, smooth: 0.14)
    light3d.directional(dir: (-0.4, -0.9, -0.35), color: "#f8fafc", intensity: 1.15)
    physics3d.config(gravity: -26.0, substeps: 4, friction: 0.86, bounce: 0.1)

    spawn3d.player("Pilot", at: (0, 2.2, 2), mesh: "hovercraft", speed: 26, jump: 17.5)
    obj3d.load("assets/models/starfighter.obj", "starfighter")
    spawn3d.obj("Wingman", obj: "assets/models/starfighter.obj", at: (6, 3.0, 10), scale: 1.4, color: "#38bdf8")
    spawn3d.box(at: (0, -0.6, 20), size: (18, 1.2, 40), color: "#4f46e5")
    spawn3d.crystal(at: (0, 2.5, 16), points: 200)
    spawn3d.portal(at: (0, 3.2, 36), radius: 3.0, label: "GATE")

    val wave_cnt = lz_wave_rush(1, "valkyrie", 2, 80, "valkyrie_drone.obj")
    lz_step(0.1)
    out($"Wave spawned: {wave_cnt}")
```""",
            "curated-3d",
        ),
        (
            "¿Cómo incrusto una clase C# MonoBehaviour en Looping y exporto el proyecto?",
            """Usa `use "csharp"` y el bloque `cs! { ... }` junto con `csharp.export(...)`:

```looping
use "csharp"

cs! {
    public class TurretController : MonoBehaviour {
        public float Energy = 100.0f;
        public void Start() => LoopingBridge.Set("turret_online", true);
        public void Update(float dt) {
            Energy = Mathf.Clamp(Energy - dt * 2.5f, 0.0f, 100.0f);
            LoopingBridge.Set("turret_energy", Energy);
        }
    }
}

csharp.new("TurretController", "turret_1", "TurretAlpha")
csharp.step(0.25)
val exported = csharp.export("TurretArena")
out($"Turret online={turret_online} | Energy={turret_energy} | Export={exported.length()}")
```""",
            "curated-cs",
        ),
        (
            "Corrige este código Looping que falla por sintaxis mezclada de Python/JS (`def`, `console.log`, llaves sin cerrar):\n```looping\ndef boost(x) {\n    console.log(x * 2)\n```",
            """En Looping las funciones usan `fn` (o flecha `=>`), la salida en consola es `out(...)` / `print(...)`, y todo bloque `{ ... }` debe cerrarse correctamente. Aquí tienes el código corregido:

```looping
fn boost(x) => x * 2

val resultado = boost(21)
out($"Resultado boost: {resultado}")
```""",
            "curated-fix",
        ),
        (
            "Corrige este script `.loop` donde usaron `ui.button` mal escrito, falta cierre en `if` y `var` de JS:\n```looping\nvar vida = 80\nif (vida < 100 {\n    ui.button(at: (20, 20), text: \"Curar\")\n```",
            """En Looping debes declarar variables mutables con `mut`, cerrar los paréntesis de la condición `if (...) { ... }` y usar la directiva oficial `ui.btn`:

```looping
mut vida = 80
if (vida < 100) {
    vida += 20
    ui.btn(at: (20, 20), text: "Curar", action: "heal_player")
}
out($"Vida actual: {vida}")
```""",
            "curated-fix",
        ),
        (
            "¿Cómo conecto Python con Looping usando `py!`, `pysnippet` y `pyloop-ai`?",
            """Looping incluye el puente directo `py!(...)` para expresiones rápidas en Python y bloques `insert pysnippet`:

```looping
use python "math"

val radio = 5
val area = py!(round(math.pi * 25, 2))
out($"Área calculada en Python: {area}")

insert pysnippet as saludar_py:
def run_greeting(nombre):
    return f"Hola {nombre} desde PyLoop!"
out_msg = run_greeting("Coki Dev")
end

runpy(saludar_py)
```

Y si usas el módulo `pyloop-ai` (`smiledev install pyloop-ai`), apunta por defecto al servidor local MLX (`http://127.0.0.1:8080/v1/chat/completions`) con respaldo opcional a Coki Cloud.""",
            "curated-pyloop",
        ),
        (
            "¿Cómo uso pattern matching (`match`), pipeline (`|>`) y manejo de errores (`try/catch`) en Looping?",
            """Aquí tienes un ejemplo idiomático de Looping v2.6–v2.8 usando `match`, `|>` y `try / catch`:

```looping
fn evaluar_rango(score) {
    match score {
        0..50 => "Novato",
        51..=89 => "Explorador",
        90..=100 => "Maestro",
        _ => "Desconocido"
    }
}

val label = 95 |> evaluar_rango
out($"Rango: {label}")

try {
    val seguro = 144 |> math.sqrt
    out($"Raíz: {seguro}")
} catch (err) {
    out($"Error capturado: {err}")
}
```""",
            "curated-modern",
        ),
        (
            "¿Cómo creo e inspecciono interfaces declarativas estilo SwiftUI en Looping?",
            """Looping permite vistas declarativas compatibles con vista previa en terminal (`./bin/looping preview`) y exportación a Swift/Mach-O:

```looping
ui.card(at: (24, 24), size: (340, 120), title: "Coki Studio Panel", text: "Motor Looping activo")
ui.progress(at: (24, 160), value: 0.85, label: "Compilación")
ui.toggle(at: (24, 200), label: "Modo MLX Local", checked: true)
ui.btn(at: (24, 245), text: "Ejecutar Escena", action: "launch_scene")
```

También puedes previsualizar vistas `VStack` / `HStack` o usar `./bin/looping check archivo.loop` antes de compilar.""",
            "curated-ui",
        ),
        (
            "¿Qué comando uso en terminal para validar sintaxis, previsualizar 3D o consultar a Coki AI local?",
            """Con el CLI nativo `./bin/looping` tienes todo integrado en local:

```bash
# Validar AST y sintaxis del archivo .loop
./bin/looping check mi_juego.loop

# Vista previa 3D Z-Buffer en terminal ANSI
./bin/looping preview3d sample_loop_projects/cyber_odyssey_3d.loop

# Preguntar a Coki AI (MLX local en 127.0.0.1:8080) o reparar un archivo
./bin/looping ai "Crea un enemigo 3D con spawn3d.enemy"
./bin/looping ai --fix mi_juego.loop
./bin/looping ai --chat
```""",
            "curated-cli",
        ),
    ]

    result: List[Dict] = []
    for u, a, tag in pairs:
        # Validate any looping block in the answer!
        fences = re.findall(r"```(?:loop|looping)\n(.*?)```", a, re.DOTALL)
        for blk in fences:
            ok, reason = check_loop_with_cli(blk)
            if not ok:
                raise RuntimeError(f"Curated example ({tag}) failed check: {reason}")
        result.append(make_example(u, a, tag=tag))
    return result


def deduplicate(items: Iterable[Dict]) -> List[Dict]:
    seen = set()
    out: List[Dict] = []
    for item in items:
        key = hashlib.sha256(
            (item["messages"][1]["content"] + "||" + item["messages"][2]["content"]).encode("utf-8")
        ).hexdigest()
        if key not in seen:
            seen.add(key)
            out.append(item)
    return out


def strip_internal_keys(items: Iterable[Dict]) -> List[Dict]:
    return [{"messages": it["messages"]} for it in items]


def write_jsonl(path: Path, rows: List[Dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")


def validate_existing_dataset() -> int:
    required = ["train.jsonl", "valid.jsonl", "test.jsonl"]
    total = 0
    for fname in required:
        fpath = DATA_DIR / fname
        if not fpath.exists():
            print(f"[FAIL] Missing dataset file: {fpath}", file=sys.stderr)
            return 1
        rows = [json.loads(line) for line in fpath.read_text(encoding="utf-8").splitlines() if line.strip()]
        if not rows:
            print(f"[FAIL] Empty dataset split: {fname}", file=sys.stderr)
            return 1
        for idx, row in enumerate(rows):
            msgs = row.get("messages")
            if not isinstance(msgs, list) or len(msgs) != 3:
                print(f"[FAIL] {fname}:{idx+1} invalid ChatML structure", file=sys.stderr)
                return 1
            roles = [m.get("role") for m in msgs]
            if roles != ["system", "user", "assistant"]:
                print(f"[FAIL] {fname}:{idx+1} unexpected roles {roles}", file=sys.stderr)
                return 1
            if any(not isinstance(m.get("content"), str) or not m["content"].strip() for m in msgs):
                print(f"[FAIL] {fname}:{idx+1} empty content", file=sys.stderr)
                return 1
        total += len(rows)
        size_kb = fpath.stat().st_size / 1024.0
        print(f"  [OK] {fname}: {len(rows)} examples ({size_kb:.1f} KB)")

    # Verify a sample of .loop blocks across test & train with ./bin/looping check
    sample_blocks = 0
    for fname in ["test.jsonl", "valid.jsonl"]:
        fpath = DATA_DIR / fname
        for line in fpath.read_text(encoding="utf-8").splitlines():
            row = json.loads(line)
            ans = row["messages"][2]["content"]
            for blk in re.findall(r"```(?:loop|looping)\n(.*?)```", ans, re.DOTALL):
                ok, reason = check_loop_with_cli(blk)
                if not ok:
                    print(f"[FAIL] .loop block validation error in {fname}: {reason}", file=sys.stderr)
                    return 1
                sample_blocks += 1

    print(f"[DATASET CHECK OK] Total={total} ChatML conversations | Verified .loop blocks={sample_blocks}")
    return 0


def build() -> int:
    print("[coki-ai] Collecting Looping corpus from repository...")
    raw: List[Dict] = []
    raw.extend(curated_synthesis_and_fixes())
    raw.extend(extract_markdown_qa(REPO_ROOT / "LOOPING_USE.md"))
    raw.extend(extract_markdown_qa(REPO_ROOT / "LOOPING_LEARNING_GUIDE.md"))
    raw.extend(extract_markdown_qa(REPO_ROOT / "SMILEDEV_README.md"))
    raw.extend(extract_markdown_qa(REPO_ROOT / "modules" / "README.md"))
    raw.extend(extract_sample_projects())
    raw.extend(extract_modules_examples())
    raw.extend(extract_cpp_tests())
    raw.extend(extract_html_docs())

    all_items = deduplicate(raw)
    # Deterministic shuffle for MLX training splits
    rng = random.Random(20261113)
    rng.shuffle(all_items)

    n = len(all_items)
    if n < 20:
        print(f"[FAIL] Dataset too small ({n} items)", file=sys.stderr)
        return 1

    n_valid = max(6, int(round(n * 0.10)))
    n_test = max(4, int(round(n * 0.06)))
    n_train = n - n_valid - n_test

    train_rows = strip_internal_keys(all_items[:n_train])
    valid_rows = strip_internal_keys(all_items[n_train : n_train + n_valid])
    test_rows = strip_internal_keys(all_items[n_train + n_valid :])

    write_jsonl(DATA_DIR / "train.jsonl", train_rows)
    write_jsonl(DATA_DIR / "valid.jsonl", valid_rows)
    write_jsonl(DATA_DIR / "test.jsonl", test_rows)

    print(f"[coki-ai] Wrote {n} deduplicated examples -> train={len(train_rows)}, valid={len(valid_rows)}, test={len(test_rows)}")
    return validate_existing_dataset()


def main() -> int:
    parser = argparse.ArgumentParser(description="Build & validate Coki AI Looping ChatML dataset.")
    parser.add_argument("--check", action="store_true", help="Validate existing train/valid/test JSONL files without rebuilding.")
    args = parser.parse_args()
    if args.check:
        return validate_existing_dataset()
    return build()


if __name__ == "__main__":
    raise SystemExit(main())
