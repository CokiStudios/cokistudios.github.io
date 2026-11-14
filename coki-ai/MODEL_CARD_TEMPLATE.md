---
language:
- es
- en
license: apache-2.0
library_name: mlx
tags:
- mlx
- mlx-lm
- looping
- coki-studios
- code
- apple-silicon
- lora
base_model: mlx-community/Qwen2.5-Coder-7B-Instruct-4bit
---

# Coki AI · Looping Coder 7B (MLX 4-bit)

Model card oficial de **Coki Studios**: **Coki AI (`CokiStudios/coki-looping-7b-mlx`)**, un modelo local de 7B parámetros entrenado con LoRA sobre Apple Silicon MLX (`mlx-community/Qwen2.5-Coder-7B-Instruct-4bit`) para escribir, explicar y corregir código en **Looping** (motores 2D/3D Quantum, mallas `.obj`, puente C# `cs!`, `loopize++`, `pyloop`, directivas `ui.*` y módulos `smiledev`).

- **Organización**: [huggingface.co/CokiStudios](https://huggingface.co/CokiStudios)
- **Web oficial**: [cokistudios.com](https://cokistudios.com)
- **Hardware objetivo**: Apple Silicon con 16 GB+ de memoria unificada, 100% local sin servidores externos.

## Uso rápido con MLX (macOS)

```bash
pip install mlx-lm
python -m mlx_lm.server \
  --model CokiStudios/coki-looping-7b-mlx \
  --host 127.0.0.1 \
  --port 8080
```

## Integración directa con Looping CLI

Con el servidor local corriendo en `127.0.0.1:8080`, puedes consultar o reparar archivos `.loop` desde la terminal:

```bash
./bin/looping ai "Crea un minijuego 3D en Looping con spawn3d.player y sky cyber_night"
./bin/looping ai --fix mi_juego.loop
./bin/looping ai --chat
```

## Capacidades principales

- Generación de scripts `.loop` modernos (`let`, `mut`, `val`, `:=`, `fn =>`, `|>`, `match`, `try/catch`).
- Videojuegos **2D Quantum** (`define game`, `spawn.player`, `spawn.platform`, `spawn.moving_platform`, `spawn.enemy`, `spawn.portal`) y **3D Quantum** (`define game3d`, `scene3d.world`, `camera3d.set`, `light3d`, `physics3d.config`, `spawn3d.*`).
- Modelos Wavefront `.obj` (`obj3d.load`, `spawn3d.obj`), scripting C# embebido (`cs! { ... }`, `csharp.export`) y adiciones de juego **`loopize++`** (`lz_wave_rush`, `lz_fsm`, `lz_hit_combo`, `loopize.ecs_spawn`).
- Interoperabilidad Python (`py!`, `pysnippet`), bridge SwiftUI (`swiftui.*`) y manifiestos `smile.json` para `smiledev`.

## Atribución y licencia

- Modelo base: `mlx-community/Qwen2.5-Coder-7B-Instruct-4bit` (derivado de Qwen2.5-Coder-7B-Instruct, Apache-2.0).
- Adaptación LoRA, dataset de Looping y herramientas CLI/RAG: Coki Studios (`CokiStudios`).
