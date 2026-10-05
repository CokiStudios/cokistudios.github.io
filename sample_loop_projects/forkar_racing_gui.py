#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════
# 🏎️ FORKAR RACING 3D — INTERACTIVE TKINTER DESKTOP GUI
# Dynamic Physics Engine & CSID Telemetry for Looping v2.5.0
# Holo Entertainment & Coki Studios
# ═══════════════════════════════════════════════════════════════

import os
os.environ['TK_SILENCE_DEPRECATION'] = '1'

import sys
import math
import time
import random
import json
import tkinter as tk
from tkinter import ttk, messagebox


class ForkarRacing3DApp:
    def __init__(self, root, player="JeriX Ortiz Android", email="jerixortixdev@gmail.com", csid_token="CSID-750D7EBDBA73CD76"):
        self.root = root
        self.root.title("🏎️ Forkar Racing 3D — CSID & Looping Dynamic Engine")
        self.root.geometry("880x700")
        self.root.minsize(860, 680)
        self.root.configure(bg="#06090f")

        # Configuración de Piloto CSID
        self.player_name = player
        self.player_email = email
        self.csid_token = csid_token
        self.eco_score = 985
        self.kers_wh = 92.4

        # Físicas y Estado de Carrera
        self.speed = 0.0          # km/h
        self.max_speed = 340.0    # km/h
        self.accel = 1.2
        self.brake_decel = 2.4
        self.friction = 0.4
        self.nitro_active = False
        self.nitro_fuel = 100.0   # %
        self.kers_battery = 85.0  # %
        self.gear = 1
        self.rpm = 1000

        # Posición y Trazado 3D
        self.player_x = 0.0       # -1.0 (izq) a 1.0 (der)
        self.track_pos = 0.0      # Distancia recorrida
        self.track_curve = 0.0    # Curvatura actual de la pista
        self.curve_target = 0.0
        self.steer_input = 0.0    # -1 a 1

        # Tráfico de karts competidores
        self.opponents = [
            {"pos": 250, "x": -0.35, "speed": 160, "color": "#f59e0b"},
            {"pos": 520, "x": 0.45, "speed": 195, "color": "#c084fc"},
            {"pos": 880, "x": -0.20, "speed": 210, "color": "#10b981"},
        ]

        # Cronómetro
        self.race_active = True
        self.start_time = time.time()
        self.lap = 1
        self.best_lap = "0:53.97"
        self.current_lap_time = "0:00.00"

        # Teclas activas
        self.keys = {"up": False, "down": False, "left": False, "right": False, "space": False}

        # Estilo TTK Moderno
        self.style = ttk.Style()
        try:
            self.style.theme_use("clam")
        except Exception:
            pass

        self._configure_styles()
        self._build_header()
        self._build_canvas()
        self._build_controls()
        self._bind_events()

        # Iniciar Game Loop a 60 FPS (~16ms)
        self.game_loop()

    def _configure_styles(self):
        self.style.configure(".", background="#06090f", foreground="#f1f5f9", font=("Helvetica", 10))
        self.style.configure("TFrame", background="#06090f")
        self.style.configure("Header.TLabel", font=("Helvetica", 14, "bold"), foreground="#00f5d4", background="#06090f")
        self.style.configure("SubHeader.TLabel", font=("Helvetica", 9), foreground="#94a3b8", background="#06090f")
        self.style.configure("Badge.TLabel", font=("Helvetica", 8, "bold"), foreground="#6366f1", background="#06090f")

        self.style.configure("Cyber.TButton", font=("Helvetica", 10, "bold"), background="#6366f1", foreground="#ffffff", padding=6)
        self.style.map("Cyber.TButton",
            background=[("active", "#4f46e5"), ("pressed", "#4338ca")],
            foreground=[("active", "#ffffff")]
        )

        self.style.configure("Nitro.TButton", font=("Helvetica", 10, "bold"), background="#f43f5e", foreground="#ffffff", padding=6)
        self.style.map("Nitro.TButton",
            background=[("active", "#e11d48"), ("pressed", "#be123c")],
            foreground=[("active", "#ffffff")]
        )

        self.style.configure("Eco.TButton", font=("Helvetica", 10, "bold"), background="#10b981", foreground="#ffffff", padding=6)
        self.style.map("Eco.TButton",
            background=[("active", "#059669"), ("pressed", "#047857")],
            foreground=[("active", "#ffffff")]
        )

    def _build_header(self):
        header_frame = ttk.Frame(self.root, padding="12 8 12 6")
        header_frame.pack(fill=tk.X)

        title_box = ttk.Frame(header_frame)
        title_box.pack(side=tk.LEFT)

        lbl_title = ttk.Label(title_box, text="🏎️ FORKAR RACING 3D", style="Header.TLabel")
        lbl_title.pack(anchor="w")

        info_text = f"Piloto: {self.player_name}  •  CSID Token: {self.csid_token[:13]}...  •  Motor: Looping C++ v2.5.0 + Python Bridge"
        lbl_sub = ttk.Label(title_box, text=info_text, style="SubHeader.TLabel")
        lbl_sub.pack(anchor="w")

        stats_box = ttk.Frame(header_frame)
        stats_box.pack(side=tk.RIGHT)

        lbl_eco = ttk.Label(stats_box, text=f"🌱 ECO SCORE: {self.eco_score} PTS", font=("Helvetica", 10, "bold"), foreground="#10b981")
        lbl_eco.pack(anchor="e")

        lbl_tier = ttk.Label(stats_box, text="⭐ CSID FOUNDER VIP • E2EE VERIFIED", font=("Helvetica", 8, "bold"), foreground="#c084fc")
        lbl_tier.pack(anchor="e")

    def _build_canvas(self):
        canvas_frame = ttk.Frame(self.root, padding="10 0 10 0")
        canvas_frame.pack(fill=tk.BOTH, expand=True)

        self.canvas_width = 860
        self.canvas_height = 450
        self.canvas = tk.Canvas(
            canvas_frame,
            width=self.canvas_width,
            height=self.canvas_height,
            bg="#020408",
            highlightthickness=1,
            highlightbackground="#1e293b"
        )
        self.canvas.pack(fill=tk.BOTH, expand=True)

    def _build_controls(self):
        bottom_frame = ttk.Frame(self.root, padding="12 8 12 12")
        bottom_frame.pack(fill=tk.X)

        # Barra de botones y acciones interactivas
        btn_box = ttk.Frame(bottom_frame)
        btn_box.pack(fill=tk.X, pady=(0, 6))

        btn_nitro = ttk.Button(btn_box, text="💥 NITRO TURBO (Espacio)", style="Nitro.TButton", command=self.activate_nitro)
        btn_nitro.pack(side=tk.LEFT, padx=(0, 8))

        btn_kers = ttk.Button(btn_box, text="⚡ RECARGA KERS (S)", style="Eco.TButton", command=self.regenerate_kers)
        btn_kers.pack(side=tk.LEFT, padx=(0, 8))

        btn_compile = ttk.Button(btn_box, text="📦 COMPILAR CIRCUITO XUI", style="Cyber.TButton", command=self.compile_custom_circuit)
        btn_compile.pack(side=tk.LEFT, padx=(0, 8))

        btn_profile = ttk.Button(btn_box, text="🛡️ CREDENCIALES CSID", command=self.show_csid_profile)
        btn_profile.pack(side=tk.LEFT, padx=(0, 8))

        btn_horn = ttk.Button(btn_box, text="🔊 CLAXON TONE", command=self.play_chime)
        btn_horn.pack(side=tk.RIGHT)

        # Barra de instrucciones de control
        inst_label = ttk.Label(
            bottom_frame,
            text="🎮 CONTROLES: [W / ↑] Acelerar  •  [S / ↓] Frenar & KERS  •  [A / ←] Girar Izq  •  [D / →] Girar Der  •  [Espacio] Nitro  •  [C] Compilar Circuito",
            font=("Helvetica", 9),
            foreground="#64748b"
        )
        inst_label.pack(anchor="center")

    def _bind_events(self):
        self.root.bind("<KeyPress-Up>", lambda e: self._set_key("up", True))
        self.root.bind("<KeyRelease-Up>", lambda e: self._set_key("up", False))
        self.root.bind("<KeyPress-w>", lambda e: self._set_key("up", True))
        self.root.bind("<KeyRelease-w>", lambda e: self._set_key("up", False))

        self.root.bind("<KeyPress-Down>", lambda e: self._set_key("down", True))
        self.root.bind("<KeyRelease-Down>", lambda e: self._set_key("down", False))
        self.root.bind("<KeyPress-s>", lambda e: self._set_key("down", True))
        self.root.bind("<KeyRelease-s>", lambda e: self._set_key("down", False))

        self.root.bind("<KeyPress-Left>", lambda e: self._set_key("left", True))
        self.root.bind("<KeyRelease-Left>", lambda e: self._set_key("left", False))
        self.root.bind("<KeyPress-a>", lambda e: self._set_key("left", True))
        self.root.bind("<KeyRelease-a>", lambda e: self._set_key("left", False))

        self.root.bind("<KeyPress-Right>", lambda e: self._set_key("right", True))
        self.root.bind("<KeyRelease-Right>", lambda e: self._set_key("right", False))
        self.root.bind("<KeyPress-d>", lambda e: self._set_key("right", True))
        self.root.bind("<KeyRelease-d>", lambda e: self._set_key("right", False))

        self.root.bind("<KeyPress-space>", lambda e: self._set_key("space", True))
        self.root.bind("<KeyRelease-space>", lambda e: self._set_key("space", False))

        self.root.bind("<KeyPress-c>", lambda e: self.compile_custom_circuit())
        self.root.bind("<KeyPress-p>", lambda e: self.show_csid_profile())

    def _set_key(self, name, val):
        self.keys[name] = val
        if name == "space" and val:
            self.activate_nitro()

    def activate_nitro(self):
        if self.nitro_fuel > 10 and self.speed > 50:
            self.nitro_active = True
        else:
            self.nitro_active = False

    def regenerate_kers(self):
        if self.speed > 30:
            recovered = round(random.uniform(1.2, 3.5), 1)
            self.kers_wh += recovered
            self.kers_battery = min(100.0, self.kers_battery + 8.0)
            self.speed = max(20.0, self.speed - self.brake_decel * 2.5)

    def play_chime(self):
        # Efecto visual de claxon / flash en HUD
        self.canvas.create_text(
            self.canvas_width // 2, 220,
            text="🔊 BIP BIP! VÍA LIBRE FORKAR",
            font=("Helvetica", 18, "bold"),
            fill="#00f5d4",
            tags="chime_text"
        )
        self.root.after(400, lambda: self.canvas.delete("chime_text"))

    def show_csid_profile(self):
        msg = (
            f"👤 PILOTO AUTENTICADO POR CSID\n\n"
            f"• Nombre: {self.player_name}\n"
            f"• Correo: {self.player_email}\n"
            f"• Nivel: Founder VIP (Coki Studios)\n"
            f"• Token de Sesión: {self.csid_token}\n"
            f"• Enclave Criptográfico: Apple SEP / T2 Hardware Backed\n"
            f"• Eco-Score Puntos: {self.eco_score} PTS\n"
            f"• Energía KERS Recuperada: {round(self.kers_wh, 1)} Wh\n"
            f"• Récord de Vuelta: {self.best_lap}\n"
        )
        messagebox.showinfo("Perfil de Piloto CSID — Forkar 3D", msg)

    def compile_custom_circuit(self):
        # Simula compilación dinámica con el compilador Looping
        circuit_names = ["Circuito Neón Kyoto 3D", "Aqua Laguna Grand Prix", "Cyber Highlands Drift"]
        choice = random.choice(circuit_names)
        hz = random.choice([120, 240, 360])
        self.eco_score += 25
        self.nitro_fuel = 100.0

        messagebox.showinfo(
            "Compilador Dinámico Looping C++",
            f"✅ ¡Nuevo circuito compilado con éxito!\n\n"
            f"• Nombre: {choice}\n"
            f"• Target UI: XUI Direct-to-Vulkan ({hz}Hz Low-Latency)\n"
            f"• Tiempo de compilación: 0.82 ms\n"
            f"• Bonus Piloto: +25 Puntos Eco & Tanque Nitro 100% ⚡"
        )

    # ═══════════════════════════════════════════════════════════════
    #  BUCLE DE JUEGO (60 FPS) Y MOTOR DE RENDERIZADO 3D
    # ═══════════════════════════════════════════════════════════════
    def game_loop(self):
        if self.race_active:
            self._update_physics()
            self._render_scene()

        # Próximo frame en ~16ms (~60 FPS)
        self.root.after(16, self.game_loop)

    def _update_physics(self):
        # Aceleración y Freno
        target_max = self.max_speed
        if self.keys["space"] and self.nitro_fuel > 0:
            target_max = 345.0
            self.nitro_fuel = max(0.0, self.nitro_fuel - 0.4)
            self.speed = min(target_max, self.speed + self.accel * 2.2)
        elif self.keys["up"]:
            self.speed = min(target_max, self.speed + self.accel)
        elif self.keys["down"]:
            # Frenado con recuperación KERS
            self.speed = max(0.0, self.speed - self.brake_decel)
            if self.speed > 20:
                self.kers_wh += 0.05
                self.kers_battery = min(100.0, self.kers_battery + 0.08)
        else:
            # Fricción natural
            self.speed = max(0.0, self.speed - self.friction)

        # Marchas y RPM
        if self.speed < 40: self.gear = 1
        elif self.speed < 90: self.gear = 2
        elif self.speed < 150: self.gear = 3
        elif self.speed < 210: self.gear = 4
        elif self.speed < 270: self.gear = 5
        else: self.gear = 6

        gear_base = [0, 20, 70, 130, 190, 250, 310][self.gear]
        gear_range = [1, 40, 50, 60, 60, 60, 45][self.gear]
        progress_in_gear = max(0.0, min(1.0, (self.speed - gear_base) / gear_range))
        self.rpm = int(3000 + progress_in_gear * 11500)

        # Giro y Dirección
        steer_speed = 0.045 * (self.speed / 120.0)
        steer_speed = max(0.015, min(0.05, steer_speed))
        if self.keys["left"]:
            self.player_x = max(-1.2, self.player_x - steer_speed)
            self.steer_input = max(-1.0, self.steer_input - 0.2)
        elif self.keys["right"]:
            self.player_x = min(1.2, self.player_x + steer_speed)
            self.steer_input = min(1.0, self.steer_input + 0.2)
        else:
            self.steer_input *= 0.65  # Auto-centrado

        # Actualizar posición en pista y curvas dinámicas
        self.track_pos += self.speed * 0.03
        curve_phase = (self.track_pos / 150.0)
        self.track_curve = math.sin(curve_phase) * 1.4

        # Fuerza centrífuga empuja al kart si hay curva
        if self.speed > 60:
            self.player_x -= (self.track_curve * (self.speed / 300.0) * 0.012)
            self.player_x = max(-1.25, min(1.25, self.player_x))

        # Cronómetro y vueltas
        elapsed = time.time() - self.start_time
        mins = int(elapsed // 60)
        secs = elapsed % 60
        self.current_lap_time = f"{mins}:{secs:05.2f}"

        # Actualizar tráfico
        for op in self.opponents:
            op["pos"] -= (self.speed - op["speed"]) * 0.03
            if op["pos"] < -100:
                op["pos"] = 800 + random.randint(50, 200)
                op["x"] = random.uniform(-0.6, 0.6)
            elif op["pos"] > 1000:
                op["pos"] = -50

    def _render_scene(self):
        w = self.canvas_width
        h = self.canvas_height
        horizon_y = int(h * 0.42)

        self.canvas.delete("all")

        # ── 1. Cielo Cyberpunk y Gradiente ──
        self.canvas.create_rectangle(0, 0, w, horizon_y, fill="#040711", outline="")
        self.canvas.create_rectangle(0, horizon_y - 25, w, horizon_y, fill="#0c1126", outline="")

        # Estrellas fijas
        random.seed(42)
        for _ in range(35):
            sx = random.randint(10, w - 10)
            sy = random.randint(10, horizon_y - 30)
            self.canvas.create_oval(sx, sy, sx + 2, sy + 2, fill="#38bdf8", outline="")

        # Rascacielos / Skyline Neón en el horizonte (desplazamiento con curvas)
        skyline_offset = int(self.track_curve * -35)
        for i, (bx, bw, bh, bcol) in enumerate([
            (60, 40, 75, "#1e1b4b"), (110, 65, 110, "#311042"), (190, 50, 85, "#18182b"),
            (260, 70, 130, "#271249"), (340, 80, 65, "#111827"), (440, 60, 120, "#1e1b4b"),
            (520, 75, 95, "#2e1065"), (610, 55, 140, "#19163b"), (690, 70, 80, "#311042"),
            (780, 60, 105, "#111827")
        ]):
            actual_x = (bx + skyline_offset) % (w + 100) - 50
            self.canvas.create_rectangle(actual_x, horizon_y - bh, actual_x + bw, horizon_y, fill=bcol, outline="#38bdf8", width=1)
            # Luces de ventanas
            for wy in range(horizon_y - bh + 15, horizon_y - 10, 20):
                self.canvas.create_rectangle(actual_x + 8, wy, actual_x + bw - 8, wy + 4, fill="#00f5d4", outline="")

        # Logo central en el horizonte
        self.canvas.create_text(w // 2, horizon_y - 45, text="🌟 COKI STUDIOS // NEON GRAND PRIX 🌟", font=("Helvetica", 11, "bold"), fill="#00f5d4")

        # ── 2. Pista 3D y Efecto de Perspectiva (OutRun Pseudo-3D) ──
        steps = 42
        road_lines = []
        center_x = w // 2

        # Pinta el suelo / césped cyberpunk
        self.canvas.create_rectangle(0, horizon_y, w, h, fill="#06090f", outline="")

        for i in range(steps, 0, -1):
            t1 = (i - 1) / float(steps)
            t2 = i / float(steps)

            y1 = horizon_y + int((h - horizon_y) * (t1 ** 1.9))
            y2 = horizon_y + int((h - horizon_y) * (t2 ** 1.9))

            # Ancho de la pista en cada corte horizontal
            w1 = int(18 + (w * 0.76) * (t1 ** 1.8))
            w2 = int(18 + (w * 0.76) * (t2 ** 1.8))

            # Desplazamiento de curva y posición del jugador
            curve_disp1 = int((self.track_curve * 120.0) * (t1 ** 2.0) - (self.player_x * w1 * 0.48))
            curve_disp2 = int((self.track_curve * 120.0) * (t2 ** 2.0) - (self.player_x * w2 * 0.48))

            x1_left = center_x - (w1 // 2) + curve_disp1
            x1_right = center_x + (w1 // 2) + curve_disp1

            x2_left = center_x - (w2 // 2) + curve_disp2
            x2_right = center_x + (w2 // 2) + curve_disp2

            # Textura alternada del asfalto y los bordillos (kerbs)
            segment_idx = int((self.track_pos * 1.5) + i) % 4
            asphalt_col = "#0f172a" if segment_idx < 2 else "#131c35"
            kerb_col = "#f43f5e" if segment_idx < 2 else "#ffffff"
            grass_col = "#06090f" if segment_idx < 2 else "#080d19"

            # Césped a los lados
            self.canvas.create_polygon(0, y1, w, y1, w, y2, 0, y2, fill=grass_col, outline="")

            # Asfalto central
            self.canvas.create_polygon(x1_left, y1, x1_right, y1, x2_right, y2, x2_left, y2, fill=asphalt_col, outline="")

            # Bordillo Izquierdo (Kerb)
            kw1 = max(4, int(w1 * 0.08))
            kw2 = max(4, int(w2 * 0.08))
            self.canvas.create_polygon(x1_left - kw1, y1, x1_left, y1, x2_left, y2, x2_left - kw2, y2, fill=kerb_col, outline="")

            # Bordillo Derecho (Kerb)
            self.canvas.create_polygon(x1_right, y1, x1_right + kw1, y1, x2_right + kw2, y2, x2_right, y2, fill=kerb_col, outline="")

            # Línea central divisoria punteada
            if segment_idx % 2 == 0 and w1 > 35:
                cw1 = max(2, int(w1 * 0.015))
                cw2 = max(2, int(w2 * 0.015))
                mid1 = center_x + curve_disp1
                mid2 = center_x + curve_disp2
                self.canvas.create_polygon(mid1 - cw1, y1, mid1 + cw1, y1, mid2 + cw2, y2, mid2 - cw2, y2, fill="#00f5d4", outline="")

            road_lines.append((y2, center_x + curve_disp2, w2))

        # ── 3. Tráfico de Competidores 3D ──
        for op in self.opponents:
            dist = op["pos"]
            if 10 < dist < 700:
                t = 1.0 - (dist / 700.0)
                py = horizon_y + int((h - horizon_y) * (t ** 1.9))
                pw = int(18 + (w * 0.76) * (t ** 1.8))
                curve_disp = int((self.track_curve * 120.0) * (t ** 2.0) - (self.player_x * pw * 0.48))
                px = center_x + curve_disp + int(op["x"] * pw * 0.4)

                car_w = max(16, int(85 * t))
                car_h = max(10, int(45 * t))

                # Chasis del rival
                self.canvas.create_rectangle(px - car_w//2, py - car_h, px + car_w//2, py, fill=op["color"], outline="#ffffff", width=1)
                # Luces traseras
                self.canvas.create_rectangle(px - car_w//2 + 2, py - 6, px - car_w//2 + 6, py - 2, fill="#f43f5e", outline="")
                self.canvas.create_rectangle(px + car_w//2 - 6, py - 6, px + car_w//2 - 2, py - 6, fill="#f43f5e", outline="")

        # ── 4. CyberKart GT del Jugador en Primer Plano ──
        player_screen_x = center_x + int(self.steer_input * 25)
        player_screen_y = h - 22

        self._draw_cyberkart(player_screen_x, player_screen_y)

        # ── 5. HUD de Cabina Transparente (Estilo Esports XUI) ──
        self._draw_hud(w, h)

    def _draw_cyberkart(self, cx, cy):
        # Efecto de inclinación al girar
        lean = self.steer_input * 14.0
        kw = 120
        kh = 65

        # Flamas de Nitro (si está activo)
        if self.keys["space"] and self.nitro_fuel > 0 and self.speed > 40:
            flame_h = random.randint(24, 42)
            self.canvas.create_polygon(
                cx - 18, cy + 4, cx - 10, cy + 4 + flame_h, cx - 2, cy + 4,
                fill="#f43f5e", outline="#fb7185", width=2
            )
            self.canvas.create_polygon(
                cx + 2, cy + 4, cx + 10, cy + 4 + flame_h, cx + 18, cy + 4,
                fill="#00f5d4", outline="#38bdf8", width=2
            )

        # Ruedas Eléctricas con llantas neón
        # Izquierda
        self.canvas.create_rectangle(cx - kw//2 - 4, cy - 22, cx - kw//2 + 18, cy + 8, fill="#0f172a", outline="#00f5d4", width=2)
        # Derecha
        self.canvas.create_rectangle(cx + kw//2 - 18, cy - 22, cx + kw//2 + 4, cy + 8, fill="#0f172a", outline="#00f5d4", width=2)

        # Alerón Trasero de Fibra de Carbono
        self.canvas.create_polygon(
            cx - kw//2 + 6 + lean, cy - kh - 12,
            cx + kw//2 - 6 + lean, cy - kh - 12,
            cx + kw//2 - 14 + lean, cy - kh + 4,
            cx - kw//2 + 14 + lean, cy - kh + 4,
            fill="#1e1b4b", outline="#6366f1", width=2
        )

        # Chasis Central CyberKart GT
        body_points = [
            cx - kw//2 + 12 + lean, cy - kh + 8,
            cx + kw//2 - 12 + lean, cy - kh + 8,
            cx + kw//2 - 4, cy,
            cx - kw//2 + 4, cy
        ]
        self.canvas.create_polygon(body_points, fill="#090d16", outline="#38bdf8", width=2)

        # Cabina de Piloto / Parabrisas Holográfico
        cockpit_points = [
            cx - 24 + lean, cy - kh + 14,
            cx + 24 + lean, cy - kh + 14,
            cx + 34 + lean, cy - 16,
            cx - 34 + lean, cy - 16
        ]
        self.canvas.create_polygon(cockpit_points, fill="#0284c7", outline="#00f5d4", width=2)

        # Luz Neón de Barra Trasera (Freno / Aceleración)
        bar_col = "#f43f5e" if self.keys["down"] else "#00f5d4"
        self.canvas.create_line(cx - 32, cy - 8, cx + 32, cy - 8, fill=bar_col, width=4)

        # Placa / Logo Forkar GT
        self.canvas.create_text(cx, cy - 14, text="⚡ FORKAR GT-3D ⚡", font=("Helvetica", 8, "bold"), fill="#ffffff")

    def _draw_hud(self, w, h):
        # 1. Tacómetro y Velocímetro (Esquina Inferior Izquierda)
        sp_box_x = 24
        sp_box_y = h - 130
        self.canvas.create_rectangle(sp_box_x, sp_box_y, sp_box_x + 190, sp_box_y + 115, fill="#090d16", outline="#1e293b", width=1.5)

        # Valor de Velocidad
        speed_int = int(self.speed)
        col_speed = "#00f5d4" if speed_int < 260 else ("#f59e0b" if speed_int < 310 else "#f43f5e")
        self.canvas.create_text(sp_box_x + 95, sp_box_y + 36, text=f"{speed_int}", font=("Helvetica", 36, "bold"), fill=col_speed)
        self.canvas.create_text(sp_box_x + 95, sp_box_y + 64, text="KM / H", font=("Helvetica", 10, "bold"), fill="#64748b")

        # Marcha y RPM
        self.canvas.create_text(sp_box_x + 35, sp_box_y + 92, text=f"GEAR: {self.gear}ª", font=("Helvetica", 11, "bold"), fill="#ffffff")
        self.canvas.create_text(sp_box_x + 125, sp_box_y + 92, text=f"{self.rpm} RPM", font=("Helvetica", 10), fill="#94a3b8")

        # 2. Barra KERS & Nitro (Esquina Inferior Derecha)
        st_box_x = w - 214
        st_box_y = h - 130
        self.canvas.create_rectangle(st_box_x, st_box_y, st_box_x + 190, st_box_y + 115, fill="#090d16", outline="#1e293b", width=1.5)

        # Nitro Bar
        self.canvas.create_text(st_box_x + 40, st_box_y + 22, text="NITRO 💥", font=("Helvetica", 9, "bold"), fill="#f43f5e")
        bar_w = int(120 * (self.nitro_fuel / 100.0))
        self.canvas.create_rectangle(st_box_x + 80, st_box_y + 16, st_box_x + 80 + 95, st_box_y + 26, fill="#1e1b4b", outline="")
        self.canvas.create_rectangle(st_box_x + 80, st_box_y + 16, st_box_x + 80 + int(95 * (self.nitro_fuel / 100.0)), st_box_y + 26, fill="#f43f5e", outline="")

        # KERS Battery Bar
        self.canvas.create_text(st_box_x + 40, st_box_y + 48, text="KERS ⚡", font=("Helvetica", 9, "bold"), fill="#10b981")
        self.canvas.create_rectangle(st_box_x + 80, st_box_y + 42, st_box_x + 80 + 95, st_box_y + 52, fill="#064e3b", outline="")
        self.canvas.create_rectangle(st_box_x + 80, st_box_y + 42, st_box_x + 80 + int(95 * (self.kers_battery / 100.0)), st_box_y + 52, fill="#10b981", outline="")

        # Energía Regenerada acumulada
        self.canvas.create_text(st_box_x + 95, st_box_y + 85, text=f"+{round(self.kers_wh, 1)} Wh Regenerados", font=("Helvetica", 10, "bold"), fill="#10b981")

        # 3. Cronómetro de Carrera y Vuelta (Arriba Centro)
        self.canvas.create_rectangle(w//2 - 130, 14, w//2 + 130, 56, fill="#090d16", outline="#1e293b", width=1.5)
        self.canvas.create_text(w//2, 26, text=f"TIEMPO: {self.current_lap_time}", font=("Helvetica", 13, "bold"), fill="#ffffff")
        self.canvas.create_text(w//2, 44, text=f"RÉCORD CSID: {self.best_lap} • VUELTA: {self.lap}/3", font=("Helvetica", 8, "bold"), fill="#00f5d4")


def launch_racing_gui(player="JeriX Ortiz Android", email="jerixortixdev@gmail.com", csid_token="CSID-750D7EBDBA73CD76"):
    root = tk.Tk()
    app = ForkarRacing3DApp(root, player=player, email=email, csid_token=csid_token)
    root.mainloop()


if __name__ == "__main__":
    launch_racing_gui()
