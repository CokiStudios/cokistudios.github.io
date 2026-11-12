#!/usr/bin/env python3
"""
Coki Studios — .c2 Package Factory
Builds signed Component 2 (.c2) packages for Shine OS & Forkar Services.
"""
import os
import sys
import json
import zipfile
import hashlib

MODULES = [
    {
        "id": "com.cokistudios.c2.cyber_neon",
        "filename": "cyber_neon_xui.c2",
        "manifest": {
            "c2_version": "2.0",
            "component_id": "com.cokistudios.c2.cyber_neon",
            "name": "Cyber Neon XUI Pro",
            "author": "Coki Studios Engine Team",
            "target_device": "Shine X1 / Xa1",
            "target_family": "xui",
            "target_fps": 240,
            "theme": "cyber_neon_xui",
            "primary_color": "#38bdf8",
            "accent_color": "#082f49",
            "entrypoint": "source.loop"
        },
        "tokens": {
            "primary": "#38bdf8",
            "accent": "#0284c7",
            "background": "#07090e",
            "surface": "rgba(15, 23, 42, 0.85)",
            "text": "#f8fafc",
            "text_muted": "#94a3b8",
            "fps": 240,
            "layout_mode": "Pro Gamer Esports HUD (Direct-to-Vulkan 240Hz)",
            "corner_radius": 16,
            "elevation_dp": 8
        },
        "layout": {
            "version": "2.0",
            "type": "modular_surface",
            "title": "Cyber Neon XUI",
            "components": [
                {"id": "bubbly_dot", "type": "status_pill", "position": "top", "glow": True},
                {"id": "apu_telemetry", "type": "widget", "source": "forkar.apu.frequency", "fps_meter": True},
                {"id": "modern_dock", "type": "dock", "position": "bottom", "apps": ["phone", "messages", "shinemaps", "camera", "settings"]},
                {"id": "game_boost_card", "type": "card", "title": "Direct APU Boost", "stat": "240 FPS LOCKED"}
            ]
        },
        "source": """# Cyber Neon XUI Pro — 240Hz Gaming HUD for Shine X1/Xa1
import loop.ui as ui
import loop.system as sys

fn on_init() {
    print "[XUI CORE] Initializing 240Hz Direct-to-Vulkan surface..."
    play tone at 880 Hz for 60 ms
    play tone at 1174 Hz for 90 ms
}

fn on_gesture_swipe_up() {
    print "[XUI] App Drawer summoned with sub-millisecond latency"
}
"""
    },
    {
        "id": "com.cokistudios.c2.aurora_fold",
        "filename": "aurora_fold_flui.c2",
        "manifest": {
            "c2_version": "2.0",
            "component_id": "com.cokistudios.c2.aurora_fold",
            "name": "Aurora Indigo Fold flUI",
            "author": "Coki Studios Design Lab",
            "target_device": "Shine f1 / fW1 / i1",
            "target_family": "flui",
            "target_fps": 120,
            "theme": "aurora_indigo_fold",
            "primary_color": "#c084fc",
            "accent_color": "#581c87",
            "entrypoint": "source.loop"
        },
        "tokens": {
            "primary": "#c084fc",
            "accent": "#9333ea",
            "background": "#0b0714",
            "surface": "rgba(30, 16, 50, 0.85)",
            "text": "#faf5ff",
            "text_muted": "#c084fc",
            "fps": 120,
            "layout_mode": "Dual-Screen & Flex-Hinge Adaptive Foldable Surface",
            "corner_radius": 24,
            "elevation_dp": 12
        },
        "layout": {
            "version": "2.0",
            "type": "modular_surface",
            "title": "Aurora Fold flUI",
            "components": [
                {"id": "dual_notch", "type": "hinge_status_bar", "position": "top"},
                {"id": "screen_left_dock", "type": "app_cluster", "screen": "primary", "columns": 4},
                {"id": "screen_right_widgets", "type": "widget_stack", "screen": "secondary", "widgets": ["forkar_maps", "eco_power"]},
                {"id": "floating_coki_bar", "type": "curved_nav", "position": "bottom"}
            ]
        },
        "source": """# Aurora Fold flUI — Adaptive Foldable Interface for Shine f1/i1/fW1
import loop.ui as ui

fn on_hinge_angle_change(angle_deg) {
    if (angle_deg < 100 and angle_deg > 75) {
        print $"[flUI] Flex Mode 90° engaged! Repositioning controls to bottom half."
    }
}
"""
    },
    {
        "id": "com.cokistudios.c2.vintage_amber",
        "filename": "vintage_amber.c2",
        "manifest": {
            "c2_version": "2.0",
            "component_id": "com.cokistudios.c2.vintage_amber",
            "name": "Vintage Monospace Amber",
            "author": "Coki Studios Retro Division",
            "target_device": "Shine Vintage (niminticos)",
            "target_family": "vintage",
            "target_fps": 60,
            "theme": "vintage_amber_monochrome",
            "primary_color": "#f59e0b",
            "accent_color": "#78350f",
            "entrypoint": "source.loop"
        },
        "tokens": {
            "primary": "#f59e0b",
            "accent": "#d97706",
            "background": "#140e05",
            "surface": "rgba(40, 24, 8, 0.92)",
            "text": "#fef3c7",
            "text_muted": "#b45309",
            "fps": 60,
            "layout_mode": "Ergonomic Curved tUIlbar with Retro Monospace Typography",
            "corner_radius": 8,
            "elevation_dp": 4
        },
        "layout": {
            "version": "2.0",
            "type": "modular_surface",
            "title": "Vintage Amber tUIlbar",
            "components": [
                {"id": "vintage_curved_toolbar", "type": "tuilbar", "position": "bottom", "curved": True},
                {"id": "mono_clock", "type": "terminal_card", "font": "monospace", "amber_glow": True},
                {"id": "analog_dial", "type": "gauge", "label": "BATTERY / FUEL"}
            ]
        },
        "source": """# Vintage Monospace Amber — Retro Hardware Engine
fn on_init() {
    print "[VINTAGE] Curved tUIlbar hardware engine engaged."
    play tone at 440 Hz for 100 ms
}
"""
    },
    {
        "id": "com.cokistudios.c2.aqua_nomad",
        "filename": "aqua_nomad_ui.c2",
        "manifest": {
            "c2_version": "2.0",
            "component_id": "com.cokistudios.c2.aqua_nomad",
            "name": "Nomad Aqua All-Terrain",
            "author": "Coki Studios Outdoor Lab",
            "target_device": "Shine Nomad 1",
            "target_family": "ui",
            "target_fps": 90,
            "theme": "aqua_nomad_rugged",
            "primary_color": "#00f5d4",
            "accent_color": "#005f73",
            "entrypoint": "source.loop"
        },
        "tokens": {
            "primary": "#00f5d4",
            "accent": "#0ea5e9",
            "background": "#051315",
            "surface": "rgba(10, 30, 35, 0.90)",
            "text": "#e0fbf7",
            "text_muted": "#5eead4",
            "fps": 90,
            "layout_mode": "Ultra-Durable High-Contrast 3-Day Battery Interface",
            "corner_radius": 14,
            "elevation_dp": 6
        },
        "layout": {
            "version": "2.0",
            "type": "modular_surface",
            "title": "Nomad Aqua Rugged",
            "components": [
                {"id": "rugged_compass", "type": "sensor_widget", "source": "forkar.compass.azimuth"},
                {"id": "satellite_sos_pill", "type": "action_pill", "color": "#ef4444"},
                {"id": "nomad_dock", "type": "dock", "apps": ["maps", "radio", "flashlight", "camera"]}
            ]
        },
        "source": """# Nomad Aqua All-Terrain Interface
fn on_outdoor_mode() {
    print "[NOMAD] Sunlight boost display + GPS telemetry engaged."
}
"""
    },
    {
        "id": "com.cokistudios.c2.feather_hiui",
        "filename": "feather_lite_hiui.c2",
        "manifest": {
            "c2_version": "2.0",
            "component_id": "com.cokistudios.c2.feather_hiui",
            "name": "Feather Lite hiUI",
            "author": "Coki Studios Core Team",
            "target_device": "Shine A1",
            "target_family": "hiui",
            "target_fps": 60,
            "theme": "feather_lite",
            "primary_color": "#06b6d4",
            "accent_color": "#164e63",
            "entrypoint": "source.loop"
        },
        "tokens": {
            "primary": "#06b6d4",
            "accent": "#0891b2",
            "background": "#080d12",
            "surface": "rgba(14, 23, 33, 0.95)",
            "text": "#f1f5f9",
            "text_muted": "#64748b",
            "fps": 60,
            "layout_mode": "Ultra-Efficient Low-RAM Engine (<30MB RAM footprint)",
            "corner_radius": 10,
            "elevation_dp": 2
        },
        "layout": {
            "version": "2.0",
            "type": "modular_surface",
            "title": "Feather Lite hiUI",
            "components": [
                {"id": "simple_status", "type": "minimal_bar", "position": "top"},
                {"id": "feather_list", "type": "vertical_app_list", "fast_scroll": True}
            ]
        },
        "source": """# Feather Lite hiUI for Shine A1
fn on_init() {
    print "[hiUI] Running in ultra-efficient 30MB mode."
}
"""
    }
]

def build_all(output_dir="c2-modules"):
    os.makedirs(output_dir, exist_ok=True)
    built_paths = []

    for mod in MODULES:
        fname = mod["filename"]
        out_path = os.path.join(output_dir, fname)

        # Prepare payload strings
        manifest_str = json.dumps(mod["manifest"], indent=2)
        tokens_str = json.dumps(mod["tokens"], indent=2)
        layout_str = json.dumps(mod["layout"], indent=2)
        source_str = mod["source"]

        # Calculate signatures
        sig_data = {
            "manifest.json": hashlib.sha256(manifest_str.encode("utf-8")).hexdigest(),
            "tokens.json": hashlib.sha256(tokens_str.encode("utf-8")).hexdigest(),
            "layout.json": hashlib.sha256(layout_str.encode("utf-8")).hexdigest(),
            "source.loop": hashlib.sha256(source_str.encode("utf-8")).hexdigest()
        }
        sig_str = json.dumps(sig_data, indent=2)

        # Write ZIP archive (.c2)
        with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("manifest.json", manifest_str)
            zf.writestr("tokens.json", tokens_str)
            zf.writestr("layout.json", layout_str)
            zf.writestr("source.loop", source_str)
            zf.writestr("signature.sha256", sig_str)

        size_kb = os.path.getsize(out_path) / 1024.0
        print(f"✔ [{mod['manifest']['target_family'].upper()}] Built {fname} ({size_kb:.1f} KB) -> {out_path}")
        built_paths.append(out_path)

    print(f"\n✨ Successfully assembled {len(built_paths)} production .c2 packages in '{output_dir}/'.")
    return built_paths

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "c2-modules"
    build_all(out)
