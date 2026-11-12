#!/usr/bin/env python3
"""
Coki Studios — Mobile Looping (.c2) Code Fragment Generator
Generates declarative .c2 code fragments in Looping syntax adapted for mobile Shine UI.
"""
import os

MODULES = {
    "cyber_neon_xui.c2": """# ═══════════════════════════════════════════════════════════════════════════════
# ✦ SHINE OS MOBILE UI COMPONENT 2 (.c2) ✦
# Adaptado para Shine X1 / Xa1 (240Hz Direct-APU Esports HUD)
# Desarrollado por Coki Studios Engine Team
# ═══════════════════════════════════════════════════════════════════════════════

component "CyberNeonXUI" target "xui" {
    device: "Shine X1 / Xa1"
    family: "xui"
    fps: 240
    theme: "cyber_neon_xui"
    primary: "#38bdf8"
    accent: "#082f49"
    background: "#07090e"
    surface: "rgba(15, 23, 42, 0.85)"
    corner_radius: 16
    elevation: 8

    # Variables reactivas en memoria del celular Shine
    state {
        mut boost_active = true
        mut apu_frequency_ghz = 3.4
        mut fps_counter = 240
    }

    # Barra superior con píldora de telemetría y resplandor
    draw status_pill at (center, top) with text "● SHINE OS • 240Hz APU BOOST" and glow true

    # Tarjeta de telemetría y rendimiento
    draw card at (20, 80) with title "DIRECT APU PERFORMANCE":
        text $"Frecuencia APU: {apu_frequency_ghz} GHz | Latencia: <0.2ms"
        badge $"LOCKED: {fps_counter} FPS" color "#38bdf8"
        button "TURBO BOOST APU" action "boost_apu"

    # Tarjeta de modos de juego y refrigeración
    draw card at (20, 200) with title "GAMING HUD MODES":
        button "LOW LATENCY VULKAN" action "enable_vulkan"
        button "COOLING FAN MAX" action "fan_max"

    # Dock inferior de apps móviles
    draw dock at bottom with apps ["phone", "messages", "shinemaps", "camera", "settings"]

    # Métodos y eventos del componente
    fn boost_apu() {
        play tone at 880 Hz for 60 ms
        play tone at 1174 Hz for 90 ms
        print "[C2 XUI] APU Turbo Boost 240Hz activado en Shine X1!"
    }

    fn enable_vulkan() {
        print "[C2 XUI] Vulkan Subpass Direct-Rendering activo."
    }

    fn fan_max() {
        print "[C2 XUI] Refrigeración activa a máxima potencia."
    }
}
""",

    "aurora_fold_flui.c2": """# ═══════════════════════════════════════════════════════════════════════════════
# ✦ SHINE OS MOBILE UI COMPONENT 2 (.c2) ✦
# Adaptado para Shine f1 / fW1 / i1 (120Hz Plegable Dual-Screen & Flex Mode)
# Desarrollado por Coki Studios Design Lab
# ═══════════════════════════════════════════════════════════════════════════════

component "AuroraFold" target "flui" {
    device: "Shine f1 / fW1 / i1"
    family: "flui"
    fps: 120
    theme: "aurora_indigo_fold"
    primary: "#c084fc"
    accent: "#581c87"
    background: "#0b0714"
    surface: "rgba(30, 16, 50, 0.85)"
    corner_radius: 24
    elevation: 12

    state {
        mut hinge_angle = 180
        mut is_flex_mode = false
        mut dual_screen_active = true
    }

    draw status_pill at (center, top) with text "● SHINE FOLD • 120Hz DUAL-SCREEN" and glow true

    draw card at (20, 80) with title "FLEX HINGE TELEMETRY":
        text $"Ángulo de bisagra: {hinge_angle}° | Flex Mode: {is_flex_mode}"
        button "CALIBRAR BISAGRA" action "calibrate_hinge"

    draw card at (20, 200) with title "DUAL DISPLAY WORKSPACE":
        text "Pantalla Izquierda: Apps Principales | Pantalla Derecha: Widgets"
        button "SINCRONIZAR PANTALLAS" action "sync_screens"

    draw dock at bottom with apps ["phone", "messages", "shinemaps", "camera", "settings"]

    fn on_hinge_change(angle) {
        hinge_angle = angle
        if (angle > 75 and angle < 105) {
            is_flex_mode = true
            print "[C2 flUI] Flex Mode 90° activado automáticamente."
        } else {
            is_flex_mode = false
        }
    }

    fn calibrate_hinge() {
        play tone at 587 Hz for 80 ms
        play tone at 880 Hz for 100 ms
        print "[C2 flUI] Sensor Hall y bisagra calibrados."
    }
}
""",

    "vintage_amber.c2": """# ═══════════════════════════════════════════════════════════════════════════════
# ✦ SHINE OS MOBILE UI COMPONENT 2 (.c2) ✦
# Adaptado para Shine Vintage (Barra ergonómica inferior curvada tUIlbar)
# Desarrollado por Coki Studios Retro Division
# ═══════════════════════════════════════════════════════════════════════════════

component "VintageAmber" target "vintage" {
    device: "Shine Vintage"
    family: "vintage"
    fps: 60
    theme: "vintage_amber_monochrome"
    primary: "#f59e0b"
    accent: "#78350f"
    background: "#140e05"
    surface: "rgba(40, 24, 8, 0.92)"
    corner_radius: 8
    elevation: 4

    state {
        mut mono_clock = "18:55"
        mut analog_battery = 98
    }

    draw status_pill at (center, top) with text "✦ SHINE VINTAGE • tUIlbar ENGINE ✦" and glow false

    draw card at (20, 80) with title "RETRO MONOSPACE TERMINAL":
        text $"Reloj Cuarzo: {mono_clock} | Energía: {analog_battery}%"
        button "SONIDO ARPEGIO 440Hz" action "play_chime"

    draw card at (20, 200) with title "BARRA INFERIOR CURVADA":
        text "tUIlbar activa con atajos físicos ergonómicos [1]..[4]"

    draw dock at bottom with apps ["phone", "messages", "shinemaps", "settings"]

    fn play_chime() {
        play tone at 440 Hz for 120 ms
        play tone at 659 Hz for 140 ms
        print "[C2 VINTAGE] Tono retro reproducido en altavoz DAC."
    }
}
""",

    "aqua_nomad_ui.c2": """# ═══════════════════════════════════════════════════════════════════════════════
# ✦ SHINE OS MOBILE UI COMPONENT 2 (.c2) ✦
# Adaptado para Shine Nomad 1 (90Hz Ultra-Durabilidad & Batería 3 Días)
# Desarrollado por Coki Studios Outdoor Lab
# ═══════════════════════════════════════════════════════════════════════════════

component "NomadAqua" target "ui" {
    device: "Shine Nomad 1"
    family: "ui"
    fps: 90
    theme: "aqua_nomad_rugged"
    primary: "#00f5d4"
    accent: "#0ea5e9"
    background: "#051315"
    surface: "rgba(10, 30, 35, 0.90)"
    corner_radius: 14
    elevation: 6

    state {
        mut battery_days_left = 3.2
        mut gps_satellite_count = 14
        mut altitude_meters = 2640
    }

    draw status_pill at (center, top) with text "● SHINE NOMAD 1 • GPS SATELLITE OK" and glow true

    draw card at (20, 80) with title "TELEMETRÍA TODO-TERRENO":
        text $"Autonomía estimada: {battery_days_left} Días | Altitud: {altitude_meters}m"
        badge "OUTDOOR HIGH-CONTRAST" color "#00f5d4"
        button "MODO LUZ SOLAR" action "sunlight_boost"

    draw card at (20, 200) with title "SEGURIDAD & S.O.S. SATELITAL":
        text $"Satélites conectados: {gps_satellite_count} (Red Iridium)"
        button "TRANSMITIR PING SOS" action "satellite_ping"

    draw dock at bottom with apps ["maps", "radio", "flashlight", "camera"]

    fn sunlight_boost() {
        print "[C2 NOMAD] Brillo ultra-alto a 2500 nits activado."
    }

    fn satellite_ping() {
        play tone at 987 Hz for 80 ms
        print "[C2 NOMAD] Baliza de rescate enviada a satélite."
    }
}
""",

    "feather_lite_hiui.c2": """# ═══════════════════════════════════════════════════════════════════════════════
# ✦ SHINE OS MOBILE UI COMPONENT 2 (.c2) ✦
# Adaptado para Shine A1 (60Hz Eficiencia Ultra-ligera <30MB RAM)
# Desarrollado por Coki Studios Core Team
# ═══════════════════════════════════════════════════════════════════════════════

component "FeatherLite" target "hiui" {
    device: "Shine A1"
    family: "hiui"
    fps: 60
    theme: "feather_lite"
    primary: "#06b6d4"
    accent: "#164e63"
    background: "#080d12"
    surface: "rgba(14, 23, 33, 0.95)"
    corner_radius: 10
    elevation: 2

    state {
        mut ram_footprint_mb = 18.4
        mut cpu_usage_pct = 2.1
    }

    draw status_pill at (center, top) with text "● SHINE A1 • EFICIENCIA MÁXIMA" and glow false

    draw card at (20, 80) with title "MEMORIA Y BATERÍA OPTIMIZADA":
        text $"Uso de RAM: {ram_footprint_mb} MB / 2048 MB | CPU: {cpu_usage_pct}%"
        button "LIMPIEZA ULTRA-RÁPIDA" action "flush_cache"

    draw dock at bottom with apps ["phone", "messages", "browser", "settings"]

    fn flush_cache() {
        print "[C2 hiUI] Limpieza de caché completada en 0.4ms."
    }
}
"""
}

def generate_fragments(out_dir="c2-modules"):
    os.makedirs(out_dir, exist_ok=True)
    for fname, code in MODULES.items():
        path = os.path.join(out_dir, fname)
        with open(path, "w", encoding="utf-8") as f:
            f.write(code.strip() + "\n")
        print(f"✔ Generated Mobile Looping .c2 fragment: {fname}")

if __name__ == "__main__":
    generate_fragments()
