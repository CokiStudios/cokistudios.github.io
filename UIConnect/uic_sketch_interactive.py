#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
═══════════════════════════════════════════════════════════════════════════════
✦ UIC (UI CONNECT) — PRELIMINARY INTERACTIVE SKETCH (UI-ONLY PROTOTYPE) ✦
Basado en los planos originales manuscritos de Coki Studios (10 Nov 2026):
• CS NAND QLC Mem: NS (Normal Storage) vs PS (Protected Storage)
• MRM (Multi Recovery Mode): 3 estados en pantalla (Disconnect, Uic idle, Working)
• Acciones MRM en PS: Restore SUI, Repair SUI, Inject .c2 on PS (Dangerous), Change OS
• Seguridad ("Be careful"): Enable MRM Protect, Add Trust PC, Sign .c2 on UIC
• Rice & Bowls -> .c2 (Uic.transfork + Kernel Shinerien + Malicious Day AI)
• Chips CS: ESC X1 (Lookit), NEX1 / NFC.E 286 (brightsmile 1 + Rotate 1), XR1, XRo G1
═══════════════════════════════════════════════════════════════════════════════
"""

import tkinter as tk
import datetime
import sys

SHINE_PROFILES = [
    {
        "id": "xui",
        "name": "Shine X1 / Xa1",
        "family": "xUI (SUI)",
        "fps": 240,
        "chips": "ESC X1 + XR1 (8 Light / 2 Power) + NEX1",
        "krnl": "Shinerien Krnl (Rice + .c2 Loader)",
        "primary": "#38bdf8",
        "accent": "#0284c7",
        "bg": "#070b14",
        "surface": "#111a2e",
        "pill_text": "● SUI • 240Hz APU • SHINERIEN KRNL",
        "card1_title": "RICE BASE & BOWLS (.c2 LAYER)",
        "card1_body": "Partición PS protegida | ESC X1 Keystore (Lookit)",
        "card1_btn": "UIC.TRANSFORK (RICE -> .C2)",
        "card2_title": "NEX1 (NFC.E 286) TELEMETRY",
        "card2_body": "W1 WiFi + NFC RW + BT • brightsmile 1 + Rotate 1",
        "dock": ["Phone", "Lock", "Lookit", "Felte", "CSMS"],
        "chassis": "standard",
    },
    {
        "id": "flui",
        "name": "Shine f1 / fW1 Fold",
        "family": "flUI (SUI)",
        "fps": 120,
        "chips": "ESC X1 + XRo G1 (6P + 6 Staticker) + NEX1",
        "krnl": "Shinerien Krnl (Dual-Screen Rice)",
        "primary": "#c084fc",
        "accent": "#7e22ce",
        "bg": "#0c0717",
        "surface": "#1e1136",
        "pill_text": "● SHINE FOLD • 120Hz DUAL-SCREEN",
        "card1_title": "BOWLS & FLEX HINGE 90°",
        "card1_body": "Rice Layer + .c2 Layer sincronizados en bisagra",
        "card1_btn": "SIGN .C2 ON UIC",
        "card2_title": "MALICIOUS DAY AI GUARD",
        "card2_body": "Escaneo de exploits en Rice completado (0 alertas)",
        "dock": ["Phone", "Find", "Felte", "C2loader", "Maps"],
        "chassis": "foldable",
    },
    {
        "id": "ui",
        "name": "Shine Nomad 1",
        "family": "UI (SUI)",
        "fps": 90,
        "chips": "ESC X1 + XR1 + NEX1 (Battery Coil)",
        "krnl": "Shinerien Krnl Outdoor",
        "primary": "#00f5d4",
        "accent": "#0d9488",
        "bg": "#041214",
        "surface": "#0b262b",
        "pill_text": "● SHINE NOMAD 1 • NEC SATELLITE",
        "card1_title": "NEC / NEX1 ENHANCED COMM",
        "card1_body": "Mem Advise NEC + Rotate 1 Mem + Battery Coil",
        "card1_btn": "NECWRITER PAIR",
        "card2_title": "CS NAND (NS / PS ISOLATION)",
        "card2_body": "PS bloqueado fuera de MRM • Autonomía 3.2 Días",
        "dock": ["Maps", "Find", "Lookit", "CSMS"],
        "chassis": "rugged",
    },
    {
        "id": "vintage",
        "name": "Shine Vintage",
        "family": "vintage (tUIlbar)",
        "fps": 60,
        "chips": "ESC + NEX1 + DAC Audio",
        "krnl": "Shinerien Lite Krnl",
        "primary": "#f59e0b",
        "accent": "#b45309",
        "bg": "#140e05",
        "surface": "#261908",
        "pill_text": "✦ SHINE VINTAGE • tUIlbar ENGINE ✦",
        "card1_title": "BOWLS TERMINAL & KEYSTORE",
        "card1_body": "ESC Keystore activo • Barra inferior curvada",
        "card1_btn": "LOAD BOWL VIA SMILEDEV",
        "card2_title": "tUIlbar PHYSICAL SHORTCUTS",
        "card2_body": "Botones ergonómicos [1]..[4] enlazados a PS",
        "dock": ["[1] Phone", "[2] CSMS", "[3] Felte", "[4] Lock"],
        "chassis": "vintage",
    },
]


class UICSketchApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("✦ UIC [PRELIMINARY INTERACTIVE SKETCH] — MRM, PS NAND, Rice/Bowls & .c2 Suite ✦")
        self.geometry("1220x800")
        self.minsize(1020, 680)
        self.configure(bg="#07090e")

        # Estado del boceto interactivo basado en el cuaderno de Coki Studios
        self.active_profile_idx = 0
        self.active_tab = "mrm_canvas"  # "mrm_canvas", "nand_ps", "chips_nec", "loop_arm"
        self.mrm_state = "uic_idle"     # "normal_sui", "disconnect", "uic_idle", "working"
        self.mrm_action_label = "Esperando comando desde UIC..."
        self.selected_widget_id = "ps_c2_layer"
        self.hinge_angle = 180
        self.gear_angle = 0

        # Checkboxes de seguridad de la Página 8 ("Be careful")
        self.chk_mrm_protect = tk.BooleanVar(value=True)
        self.chk_trust_pc = tk.BooleanVar(value=True)
        self.chk_sign_c2 = tk.BooleanVar(value=True)
        self.chk_blueprint = tk.BooleanVar(value=True)
        self.chk_wireframe = tk.BooleanVar(value=False)

        self.hit_boxes = []
        self._build_ui()
        self.log_event(
            "Sketch preliminar cargado con los planos del 10 Nov 2026: CS NAND (NS/PS), MRM, Rice/Bowls -> .c2, ESC/NEX1/XR1 y Loopize <eNAND>."
        )

    def _build_ui(self):
        # 1. Cinta Superior de Prototipo
        ribbon = tk.Frame(self, bg="#1e1b4b", height=28)
        ribbon.pack(fill="x", side="top")
        tk.Label(
            ribbon,
            text="📐 UIC INTERACTIVE SKETCH (SIN FUNCIONALIDAD REAL) — Basado en los bocetos de hardware/software CS (MRM • PS NAND • Rice/Bowls • NEX1)",
            bg="#1e1b4b",
            fg="#c084fc",
            font=("Helvetica", 10, "bold"),
            pady=4,
        ).pack(side="left", padx=14)

        self.lbl_mrm_badge = tk.Label(
            ribbon,
            text="⚡ PHONE STATE: MRM [UIC IDLE]",
            bg="#312e81",
            fg="#38bdf8",
            font=("Helvetica", 9, "bold"),
            padx=8,
            pady=2,
        )
        self.lbl_mrm_badge.pack(side="right", padx=14, pady=3)

        # 2. Barra de Cabecera y Pestañas del Cuaderno
        header = tk.Frame(self, bg="#0d1322", height=58, highlightbackground="#1e293b", highlightthickness=1)
        header.pack(fill="x", side="top")

        title_box = tk.Frame(header, bg="#0d1322")
        title_box.pack(side="left", padx=16, pady=10)

        tk.Label(
            title_box,
            text="✦ UI CONNECT (UIC)",
            bg="#0d1322",
            fg="#38bdf8",
            font=("Helvetica", 15, "bold"),
        ).pack(side="left")

        tk.Label(
            title_box,
            text=" SKETCH PRELIMINAR • PS & MRM SUITE ",
            bg="#172554",
            fg="#93c5fd",
            font=("Helvetica", 9, "bold"),
            padx=6,
            pady=2,
        ).pack(side="left", padx=8)

        tab_box = tk.Frame(header, bg="#0d1322")
        tab_box.pack(side="right", padx=14)

        self.tab_buttons = {}
        tabs = [
            ("mrm_canvas", "📱 [01] Lienzo MRM & SUI"),
            ("nand_ps", "💾 [02] CS NAND (NS vs PS) & Rice"),
            ("chips_nec", "🔬 [03] Chips: ESC, NEX1 & XR1"),
            ("loop_arm", "🎮 [04] Loop OoS ARM & Loopize"),
        ]
        for tid, tlabel in tabs:
            btn = tk.Button(
                tab_box,
                text=tlabel,
                command=lambda t=tid: self.switch_tab(t),
                bg="#1e293b" if tid == self.active_tab else "#0d1322",
                fg="#38bdf8" if tid == self.active_tab else "#94a3b8",
                relief="flat",
                font=("Helvetica", 10, "bold"),
                padx=10,
                pady=6,
                cursor="hand2",
            )
            btn.pack(side="left", padx=3)
            self.tab_buttons[tid] = btn

        # 3. Área Principal de 3 Columnas
        workspace = tk.Frame(self, bg="#07090e")
        workspace.pack(fill="both", expand=True, padx=12, pady=10)

        # ── Columna Izquierda: Dispositivo + Estados de Pantalla MRM (Pág. 8) ──
        left_panel = tk.Frame(
            workspace, bg="#0d1322", width=275, highlightbackground="#1e293b", highlightthickness=1, padx=12, pady=12
        )
        left_panel.pack(side="left", fill="y", padx=(0, 10))
        left_panel.pack_propagate(False)

        tk.Label(
            left_panel,
            text="📱 1. FAMILIA SHINE EN LIENZO",
            bg="#0d1322",
            fg="#94a3b8",
            font=("Helvetica", 9, "bold"),
        ).pack(anchor="w", pady=(0, 6))

        self.profile_buttons = []
        for idx, prof in enumerate(SHINE_PROFILES):
            f_box = tk.Frame(left_panel, bg="#151f38", highlightbackground="#22314e", highlightthickness=1)
            f_box.pack(fill="x", pady=3)
            btn = tk.Button(
                f_box,
                text=f"{prof['name']} ({prof['family']})\n{prof['chips'][:34]}...",
                justify="left",
                anchor="w",
                command=lambda i=idx: self.select_profile(i),
                bg="#151f38",
                fg="#f8fafc",
                relief="flat",
                font=("Helvetica", 9, "bold"),
                padx=8,
                pady=5,
                cursor="hand2",
            )
            btn.pack(fill="x")
            self.profile_buttons.append((f_box, btn))

        tk.Frame(left_panel, bg="#1e293b", height=1).pack(fill="x", pady=10)

        tk.Label(
            left_panel,
            text="🔌 2. PANTALLA MRM (MULTI RECOVERY MODE)",
            bg="#0d1322",
            fg="#00f5d4",
            font=("Helvetica", 9, "bold"),
        ).pack(anchor="w", pady=(0, 4))

        tk.Label(
            left_panel,
            text="Combo físico (Pág. 8): Swipe Quick Access -> Power -> Hold Restart + Vol+ + Vol-",
            bg="#0d1322",
            fg="#64748b",
            font=("Helvetica", 8),
            wraplength=245,
            justify="left",
        ).pack(anchor="w", pady=(0, 6))

        self.mrm_state_buttons = {}
        mrm_states = [
            ("normal_sui", "✨ Modo Normal SUI (Rice + .c2 Live)"),
            ("disconnect", "🔌 MRM: Disconnect (Cable suelto !)"),
            ("uic_idle", "💤 MRM: Uic idle (Conectado • • •)"),
            ("working", "⚙️ MRM: Working (NO Disconnect!)"),
        ]
        for sid, slabel in mrm_states:
            sbtn = tk.Button(
                left_panel,
                text=slabel,
                anchor="w",
                command=lambda s=sid: self.set_mrm_state(s),
                bg="#111827",
                fg="#cbd5e1",
                relief="flat",
                font=("Helvetica", 9, "bold"),
                padx=8,
                pady=5,
                cursor="hand2",
            )
            sbtn.pack(fill="x", pady=2)
            self.mrm_state_buttons[sid] = sbtn

        tk.Frame(left_panel, bg="#1e293b", height=1).pack(fill="x", pady=10)

        tk.Label(
            left_panel,
            text="🛡️ 3. BE CAREFUL (REQUISITOS PÁG. 8)",
            bg="#0d1322",
            fg="#f59e0b",
            font=("Helvetica", 9, "bold"),
        ).pack(anchor="w", pady=(0, 4))

        for var, txt in [
            (self.chk_mrm_protect, "Enable MRM Protect on Settings"),
            (self.chk_trust_pc, "Add Trust PC on Settings"),
            (self.chk_sign_c2, "Sign .c2 on UIC (SHA-256)"),
        ]:
            tk.Checkbutton(
                left_panel,
                text=txt,
                variable=var,
                command=self.redraw_canvas,
                bg="#0d1322",
                fg="#e2e8f0",
                selectcolor="#07090e",
                activebackground="#0d1322",
                font=("Helvetica", 8),
            ).pack(anchor="w", pady=1)

        # ── Columna Central: Lienzo Interactivo / Blueprint ──
        center_frame = tk.Frame(workspace, bg="#05070c", highlightbackground="#1e293b", highlightthickness=1)
        center_frame.pack(side="left", fill="both", expand=True, padx=(0, 10))

        self.canvas = tk.Canvas(center_frame, bg="#05070c", highlightthickness=0, cursor="crosshair")
        self.canvas.pack(fill="both", expand=True)
        self.canvas.bind("<Configure>", lambda e: self.redraw_canvas())
        self.canvas.bind("<Button-1>", self.on_canvas_click)

        # ── Columna Derecha: Operaciones MRM en PS + Rice/Bowls Converter ──
        right_panel = tk.Frame(
            workspace, bg="#0d1322", width=315, highlightbackground="#1e293b", highlightthickness=1, padx=14, pady=12
        )
        right_panel.pack(side="right", fill="y")
        right_panel.pack_propagate(False)

        tk.Label(
            right_panel,
            text="🛠️ OPERACIONES MRM EN 'PS' (MOCK)",
            bg="#0d1322",
            fg="#38bdf8",
            font=("Helvetica", 10, "bold"),
        ).pack(anchor="w", pady=(0, 4))

        tk.Label(
            right_panel,
            text="\"The only way to touch PS (Protected Storage) is with UIC and the Phone in MRM\" (Pág. 7-8):",
            bg="#0d1322",
            fg="#94a3b8",
            font=("Helvetica", 8),
            wraplength=285,
            justify="left",
        ).pack(anchor="w", pady=(0, 8))

        mrm_ops = [
            ("🔄 [Sketch] Restore SUI (Shine UI)", "Restore SUI en Protected Storage (PS)", "#0284c7"),
            ("🩹 [Sketch] Repair SUI (Rice + .c2)", "Repair SUI & Shinerien Krnl", "#0f766e"),
            ("⚠️ [Sketch] Inject .c2 on PS (Dangerous)", "Inject .c2 on PS (Protected Storage)", "#b91c1c"),
            ("💿 [Sketch] Change OS (Shinerien / SUI)", "Change OS en partición PS", "#6d28d9"),
            ("🍚 [Sketch] Uic.transfork: Bowl -> .c2", "Convertir Bowl de Rice a Component 2 (.c2)", "#b45309"),
            ("🧠 [Sketch] Malicious Day AI Scan", "Escaneo IA de exploits en Rice", "#047857"),
        ]
        for btxt, bdesc, bcol in mrm_ops:
            tk.Button(
                right_panel,
                text=btxt,
                command=lambda d=bdesc: self.simulate_mrm_operation(d),
                bg=bcol,
                fg="#ffffff",
                relief="flat",
                font=("Helvetica", 9, "bold"),
                pady=5,
                cursor="hand2",
            ).pack(fill="x", pady=3)

        tk.Frame(right_panel, bg="#1e293b", height=1).pack(fill="x", pady=10)

        # Controles de Geometría y Blueprint
        tk.Label(
            right_panel,
            text="📐 AJUSTES DE BOCETO & BISAGRA",
            bg="#0d1322",
            fg="#c084fc",
            font=("Helvetica", 9, "bold"),
        ).pack(anchor="w", pady=(0, 4))

        self.lbl_hinge = tk.Label(
            right_panel,
            text="Ángulo Bisagra (Rotate 1 Sensor): 180°",
            bg="#0d1322",
            fg="#cbd5e1",
            font=("Helvetica", 8, "bold"),
        )
        self.lbl_hinge.pack(anchor="w")
        self.slider_hinge = tk.Scale(
            right_panel,
            from_=45,
            to=180,
            orient="horizontal",
            bg="#0d1322",
            fg="#f8fafc",
            troughcolor="#07090e",
            highlightthickness=0,
            showvalue=0,
            command=self.on_hinge_slider,
        )
        self.slider_hinge.set(180)
        self.slider_hinge.pack(fill="x", pady=(2, 6))

        tk.Checkbutton(
            right_panel,
            text="Cuadrícula Blueprint y Cotas (dp)",
            variable=self.chk_blueprint,
            command=self.redraw_canvas,
            bg="#0d1322",
            fg="#e2e8f0",
            selectcolor="#07090e",
            font=("Helvetica", 8),
        ).pack(anchor="w")

        tk.Checkbutton(
            right_panel,
            text="Modo Boceto Lineal (Wireframe Puro)",
            variable=self.chk_wireframe,
            command=self.redraw_canvas,
            bg="#0d1322",
            fg="#e2e8f0",
            selectcolor="#07090e",
            font=("Helvetica", 8),
        ).pack(anchor="w")

        tk.Frame(right_panel, bg="#1e293b", height=1).pack(fill="x", pady=8)

        tk.Label(
            right_panel,
            text="🔍 INSPECTOR DE ARQUITECTURA CS",
            bg="#0d1322",
            fg="#00f5d4",
            font=("Helvetica", 9, "bold"),
        ).pack(anchor="w", pady=(0, 4))

        self.inspector_box = tk.Label(
            right_panel,
            text="",
            bg="#07090e",
            fg="#cbd5e1",
            font=("Courier", 9),
            justify="left",
            anchor="nw",
            padx=8,
            pady=8,
            relief="solid",
            bd=1,
        )
        self.inspector_box.pack(fill="both", expand=True)

        # 4. Barra de Estado Inferior
        bottom_bar = tk.Frame(self, bg="#090d16", height=38, highlightbackground="#1e293b", highlightthickness=1)
        bottom_bar.pack(fill="x", side="bottom")
        self.lbl_status = tk.Label(
            bottom_bar,
            text="",
            bg="#090d16",
            fg="#10b981",
            font=("Courier", 10),
            anchor="w",
            padx=14,
            pady=6,
        )
        self.lbl_status.pack(fill="x")

        self._update_button_highlights()
        self._update_inspector()

    # ───────────────────────────────────────────────────────────────────────────
    # LÓGICA DE INTERACCIÓN SIMULADA
    # ───────────────────────────────────────────────────────────────────────────
    def log_event(self, msg):
        ts = datetime.datetime.now().strftime("%H:%M:%S")
        self.lbl_status.config(text=f"[{ts}] [UIC SKETCH] {msg}")

    def switch_tab(self, tab_id):
        self.active_tab = tab_id
        for tid, btn in self.tab_buttons.items():
            btn.config(
                bg="#1e293b" if tid == tab_id else "#0d1322",
                fg="#38bdf8" if tid == tab_id else "#94a3b8",
            )
        self.log_event(f"Explorando plano interactivo: '{tab_id.upper()}'")
        self.redraw_canvas()

    def select_profile(self, idx):
        self.active_profile_idx = idx
        prof = SHINE_PROFILES[idx]
        self._update_button_highlights()
        self._update_inspector()
        self.log_event(f"Dispositivo seleccionado: {prof['name']} | Chips: {prof['chips']}")
        self.redraw_canvas()

    def set_mrm_state(self, state_id):
        self.mrm_state = state_id
        badges = {
            "normal_sui": ("✨ PHONE STATE: NORMAL SUI (RICE + .C2)", "#064e3b", "#34d399"),
            "disconnect": ("🔌 PHONE STATE: MRM [DISCONNECT !]", "#451a03", "#f59e0b"),
            "uic_idle": ("💤 PHONE STATE: MRM [UIC IDLE • • •]", "#312e81", "#38bdf8"),
            "working": ("⚙️ PHONE STATE: MRM [WORKING — DO NOT UNPLUG!]", "#7f1d1d", "#f87171"),
        }
        btxt, bbg, bfg = badges.get(state_id, badges["uic_idle"])
        self.lbl_mrm_badge.config(text=btxt, bg=bbg, fg=bfg)
        self._update_button_highlights()
        self._update_inspector()
        self.log_event(f"Estado de pantalla del celular cambiado a: {state_id.upper()}")
        self.redraw_canvas()

    def simulate_mrm_operation(self, op_desc):
        if not (self.chk_mrm_protect.get() and self.chk_trust_pc.get() and self.chk_sign_c2.get()):
            self.log_event(
                "⚠ [BE CAREFUL] Activa las 3 casillas de seguridad (MRM Protect, Trust PC, Sign .c2) antes de tocar PS!"
            )
            return
        self.active_tab = "mrm_canvas"
        self.switch_tab("mrm_canvas")
        self.mrm_action_label = op_desc
        self.set_mrm_state("working")
        self.log_event(f"Simulando en MRM -> '{op_desc}' (NO Disconnect / Not power off)...")
        self._animate_working_gear(0)

    def _animate_working_gear(self, step):
        if self.mrm_state != "working":
            return
        self.gear_angle = (self.gear_angle + 30) % 360
        self.redraw_canvas()
        if step < 12:
            self.after(90, lambda: self._animate_working_gear(step + 1))
        else:
            self.mrm_action_label = "✔ Operación simulada completada en PS"
            self.set_mrm_state("uic_idle")
            self.log_event("✔ Simulación MRM finalizada. Teléfono de vuelta en 'Uic idle'.")

    def on_hinge_slider(self, val):
        self.hinge_angle = int(float(val))
        self.lbl_hinge.config(text=f"Ángulo Bisagra (Rotate 1 Sensor): {self.hinge_angle}°")
        self.redraw_canvas()

    def on_canvas_click(self, event):
        for wid, (x1, y1, x2, y2) in reversed(self.hit_boxes):
            if x1 <= event.x <= x2 and y1 <= event.y <= y2:
                self.selected_widget_id = wid
                self._update_inspector()
                self.log_event(f"Elemento seleccionado en el plano: [{wid}]")
                self.redraw_canvas()
                return

    def _update_button_highlights(self):
        prof = SHINE_PROFILES[self.active_profile_idx]
        for idx, (f_box, btn) in enumerate(self.profile_buttons):
            is_sel = idx == self.active_profile_idx
            f_box.config(highlightbackground=prof["primary"] if is_sel else "#22314e")
            btn.config(
                bg="#1e293b" if is_sel else "#151f38",
                fg=prof["primary"] if is_sel else "#f8fafc",
            )
        for sid, sbtn in self.mrm_state_buttons.items():
            is_s = sid == self.mrm_state
            sbtn.config(
                bg="#1e293b" if is_s else "#111827",
                fg="#00f5d4" if is_s else "#cbd5e1",
            )

    def _update_inspector(self):
        prof = SHINE_PROFILES[self.active_profile_idx]
        safety_ok = self.chk_mrm_protect.get() and self.chk_trust_pc.get() and self.chk_sign_c2.get()
        txt = (
            f"Dispositivo : {prof['name']}\n"
            f"Kernel      : {prof['krnl']}\n"
            f"Chips CS    : {prof['chips']}\n"
            f"Estado MRM  : {self.mrm_state.upper()}\n"
            f"Selección   : {self.selected_widget_id}\n"
            f"PS Safety   : {'✔ VERIFICADO' if safety_ok else '⚠ INCOMPLETO'}\n"
            f"Modo        : SKETCH (SIN BACKEND)"
        )
        self.inspector_box.config(text=txt)

    # ───────────────────────────────────────────────────────────────────────────
    # DIBUJO DE LOS 4 PLANOS INTERACTIVOS DEL CUADERNO
    # ───────────────────────────────────────────────────────────────────────────
    def redraw_canvas(self):
        c = self.canvas
        c.delete("all")
        self.hit_boxes = []

        w = c.winfo_width()
        h = c.winfo_height()
        if w < 50 or h < 50:
            return

        prof = SHINE_PROFILES[self.active_profile_idx]
        if self.chk_blueprint.get():
            for gx in range(0, w, 28):
                c.create_line(gx, 0, gx, h, fill="#0b1322")
            for gy in range(0, h, 28):
                c.create_line(0, gy, w, gy, fill="#0b1322")

        if self.active_tab == "nand_ps":
            self._draw_nand_ps_diagram(c, w, h, prof)
        elif self.active_tab == "chips_nec":
            self._draw_chips_nec_diagram(c, w, h, prof)
        elif self.active_tab == "loop_arm":
            self._draw_loop_arm_diagram(c, w, h, prof)
        else:
            self._draw_phone_and_mrm_canvas(c, w, h, prof)

    # ── PESTAÑA 1: LIENZO DEL CELULAR (MODO SUI NORMAL O LAS 3 PANTALLAS MRM DE PÁG. 8) ──
    def _draw_phone_and_mrm_canvas(self, c, w, h, prof):
        is_wire = self.chk_wireframe.get()
        is_fold = prof["chassis"] == "foldable" and self.hinge_angle > 110
        pw = 380 if is_fold else 284
        ph = 520
        px1 = (w - pw) // 2
        py1 = max(36, (h - ph) // 2 - 10)
        px2 = px1 + pw
        py2 = py1 + ph

        pcol = "#38bdf8" if is_wire else prof["primary"]
        bg_col = "#05070c" if is_wire else prof["bg"]
        surf_col = "#0c1322" if is_wire else prof["surface"]

        # Cota superior Blueprint
        if self.chk_blueprint.get():
            c.create_line(px1, py1 - 14, px2, py1 - 14, fill="#38bdf8", arrow="both")
            c.create_text(
                (px1 + px2) // 2,
                py1 - 24,
                text=f"{prof['name']} [{pw}x{ph} dp] • Estado: {self.mrm_state.upper()}",
                fill="#38bdf8",
                font=("Courier", 9, "bold"),
            )

        # Chasis del teléfono
        c.create_rectangle(px1, py1, px2, py2, fill=bg_col, outline=pcol, width=2)
        cx = (px1 + px2) // 2
        c.create_oval(cx - 6, py1 + 8, cx + 6, py1 + 20, fill="#000000", outline="#334155")

        # Si el teléfono está en uno de los 3 estados MRM de la Página 8:
        if self.mrm_state in ("disconnect", "uic_idle", "working"):
            self._draw_mrm_screen_inside_phone(c, px1, py1, px2, py2, pcol)
            return

        # Modo Normal SUI (Rice + .c2 Live Preview)
        if prof["chassis"] == "foldable":
            c.create_line(cx, py1 + 4, cx, py2 - 4, fill="#c084fc", dash=(3, 5))

        if 75 <= self.hinge_angle <= 105:
            hy = (py1 + py2) // 2
            c.create_line(px1 + 4, hy, px2 - 4, hy, fill="#f59e0b", dash=(6, 4), width=2)
            c.create_text(px2 + 8, hy, text="◀ Rotate 1: FLEX 90°", anchor="w", fill="#f59e0b", font=("Courier", 9, "bold"))

        pad = 16
        # 1. Status Pill
        sp_y1, sp_y2 = py1 + 28, py1 + 54
        self._box(c, "status_pill", px1 + pad, sp_y1, px2 - pad, sp_y2, surf_col, pcol, is_wire)
        c.create_text(cx, (sp_y1 + sp_y2) // 2, text=prof["pill_text"], fill=pcol, font=("Helvetica", 8, "bold"))

        # 2. Card 1 (Rice & Bowls / .c2)
        c1_y1, c1_y2 = sp_y2 + 14, sp_y2 + 150
        self._box(c, "card_rice_c2", px1 + pad, c1_y1, px2 - pad, c1_y2, surf_col, pcol, is_wire)
        c.create_text(px1 + pad + 12, c1_y1 + 20, text=prof["card1_title"], anchor="w", fill=pcol, font=("Helvetica", 9, "bold"))
        c.create_text(px1 + pad + 12, c1_y1 + 46, text=prof["card1_body"], anchor="w", fill="#cbd5e1", font=("Helvetica", 8))

        btn_y1, btn_y2 = c1_y2 - 42, c1_y2 - 12
        self._box(c, "btn_transfork", px1 + pad + 12, btn_y1, px2 - pad - 12, btn_y2, prof["accent"], pcol, is_wire)
        c.create_text(cx, (btn_y1 + btn_y2) // 2, text=f"⚡ {prof['card1_btn']}", fill="#ffffff", font=("Helvetica", 8, "bold"))

        # 3. Card 2 (NEX1 / Malicious Day)
        c2_y1, c2_y2 = c1_y2 + 14, c1_y2 + 114
        self._box(c, "card_hardware_ai", px1 + pad, c2_y1, px2 - pad, c2_y2, surf_col, "#334155", is_wire)
        c.create_text(px1 + pad + 12, c2_y1 + 20, text=prof["card2_title"], anchor="w", fill=pcol, font=("Helvetica", 9, "bold"))
        c.create_text(px1 + pad + 12, c2_y1 + 48, text=prof["card2_body"], anchor="w", fill="#94a3b8", font=("Helvetica", 8))
        c.create_text(px1 + pad + 12, c2_y2 - 16, text=f"Krnl: {prof['krnl']}", anchor="w", fill="#64748b", font=("Courier", 8))

        # 4. Dock de Logos CS (Pág. 6)
        dk_y1, dk_y2 = py2 - 64, py2 - 16
        self._box(c, "cs_dock", px1 + pad, dk_y1, px2 - pad, dk_y2, surf_col, pcol, is_wire)
        slot_w = ((px2 - pad) - (px1 + pad)) / max(1, len(prof["dock"]))
        for i, app_name in enumerate(prof["dock"]):
            ix = (px1 + pad) + int((i + 0.5) * slot_w)
            c.create_text(ix, (dk_y1 + dk_y2) // 2, text=app_name, fill="#f8fafc", font=("Helvetica", 8, "bold"))

    # ── DIBUJO EXACTO DE LAS 3 PANTALLAS MRM DE LA PÁGINA 8 DEL CUADERNO ──
    def _draw_mrm_screen_inside_phone(self, c, px1, py1, px2, py2, pcol):
        cx = (px1 + px2) // 2
        cy = (py1 + py2) // 2

        c.create_text(cx, py1 + 48, text="M R M", fill="#f8fafc", font=("Courier", 20, "bold"))
        c.create_text(
            cx, py1 + 72, text="Multi Recovery Mode • Protected Storage (PS)", fill="#94a3b8", font=("Helvetica", 8)
        )

        # Recuadro central (PC Icon / Gear Icon como en el dibujo de la Pág. 8)
        bx1, by1, bx2, by2 = cx - 58, cy - 85, cx + 58, cy + 15
        self._box(c, f"mrm_{self.mrm_state}", bx1, by1, bx2, by2, "#0d1322", pcol, False)

        if self.mrm_state == "disconnect":
            # Dibujo 1 de Pág. 8: Monitor PC + signo "!" + rayo + cable desconectado
            c.create_rectangle(cx - 32, cy - 65, cx + 18, cy - 25, outline="#f59e0b", width=2)
            c.create_text(cx - 7, cy - 45, text="PC", fill="#f59e0b", font=("Courier", 12, "bold"))
            c.create_text(cx + 34, cy - 45, text="!", fill="#ef4444", font=("Helvetica", 22, "bold"))
            c.create_text(cx - 22, cy + 40, text="⚡", fill="#f59e0b", font=("Helvetica", 16))
            # Cable suelto abajo
            c.create_rectangle(cx - 10, py2 - 90, cx + 10, py2 - 65, fill="#1e293b", outline="#f59e0b", width=2)
            c.create_line(cx, py2 - 65, cx, py2 - 10, fill="#f59e0b", width=3)
            c.create_text(
                cx, py2 - 115, text="Disconnect — Connect to PC with UIC", fill="#f59e0b", font=("Helvetica", 9, "bold")
            )

        elif self.mrm_state == "uic_idle":
            # Dibujo 2 de Pág. 8: Monitor con símbolo Coki + 3 puntos "o o o" + cable conectado ("Uic idle")
            c.create_rectangle(cx - 30, cy - 62, cx + 30, cy - 18, outline="#38bdf8", width=2)
            c.create_text(cx, cy - 40, text="CS • UIC", fill="#38bdf8", font=("Courier", 10, "bold"))
            # Los 3 círculos de espera del boceto
            for dx in (-26, 0, 26):
                c.create_oval(cx + dx - 5, cy + 36, cx + dx + 5, cy + 46, outline="#38bdf8", width=2)
            # Conector enchufado en la base
            c.create_rectangle(cx - 12, py2 - 52, cx + 12, py2 - 26, fill="#0284c7", outline="#38bdf8", width=2)
            c.create_line(cx, py2 - 26, cx, py2, fill="#38bdf8", width=4)
            c.create_text(cx, cy + 72, text="Uic idle (Ready for PS Action)", fill="#38bdf8", font=("Helvetica", 10, "bold"))
            c.create_text(cx, cy + 94, text=self.mrm_action_label, fill="#94a3b8", font=("Helvetica", 8))

        elif self.mrm_state == "working":
            # Dibujo 3 de Pág. 8: Engranaje trabajando + "NO Disconnect / Not power off / Working"
            c.create_oval(cx - 26, cy - 61, cx + 26, cy - 9, outline="#00f5d4", width=3, dash=(6, 4))
            c.create_text(cx, cy - 35, text="⚙️", fill="#00f5d4", font=("Helvetica", 24))
            c.create_text(
                cx, cy + 42, text="NO Disconnect\nNot power off", justify="center", fill="#ef4444", font=("Helvetica", 11, "bold")
            )
            c.create_text(cx, cy + 82, text="Working...", fill="#00f5d4", font=("Courier", 11, "bold"))
            c.create_text(cx, cy + 102, text=self.mrm_action_label, fill="#cbd5e1", font=("Helvetica", 8))
            c.create_rectangle(cx - 12, py2 - 52, cx + 12, py2 - 26, fill="#00f5d4", outline="#ffffff", width=2)
            c.create_line(cx, py2 - 26, cx, py2, fill="#00f5d4", width=4)

    # ── PESTAÑA 2: CS NAND FOR UIs (QLC MEM: NS vs PS) Y RICE / BOWLS (PÁG. 3, 4 Y 7) ──
    def _draw_nand_ps_diagram(self, c, w, h, prof):
        c.create_text(
            w // 2,
            32,
            text="💾 CS NAND FOR UIs (QLC Mem) — NS (Normal Storage) vs PS (Protected Storage)",
            fill="#38bdf8",
            font=("Helvetica", 12, "bold"),
        )

        # Bloque grande QLC Mem (como en la Página 7)
        nx1, ny1, nx2, ny2 = 60, 75, w - 60, 195
        ps_split = nx2 - 190

        # NS = Normal Storage (Userdata)
        self._box(c, "nand_ns", nx1, ny1, ps_split, ny2, "#0d1629", "#38bdf8", False)
        c.create_text(
            (nx1 + ps_split) // 2,
            ny1 + 32,
            text="NS = Normal Storage (QLC Mem)",
            fill="#38bdf8",
            font=("Helvetica", 13, "bold"),
        )
        c.create_text(
            (nx1 + ps_split) // 2,
            ny1 + 65,
            text="Userdata • Apps estándar • Fotos • Captures • Cache",
            fill="#cbd5e1",
            font=("Helvetica", 10),
        )

        # PS = Protected Storage (Solo accesible con UIC + MRM)
        self._box(c, "nand_ps", ps_split + 6, ny1, nx2, ny2, "#231236", "#c084fc", False)
        c.create_text((ps_split + nx2) // 2, ny1 + 28, text="PS = Protected", fill="#c084fc", font=("Helvetica", 11, "bold"))
        c.create_text(
            (ps_split + nx2) // 2,
            ny1 + 58,
            text="Solo accesible con\nUIC + Teléfono en MRM",
            justify="center",
            fill="#f59e0b",
            font=("Helvetica", 9, "bold"),
        )

        # Capas dentro de PS (Página 7: OS, Rice layer, .c2 layer, NEC pair, priv data)
        c.create_text(
            w // 2,
            228,
            text="🔽 CAPAS ALOJADAS DENTRO DE 'PS' (PROTECTED STORAGE) & FLUJO RICE / BOWLS (PÁG. 3, 4 y 7):",
            fill="#00f5d4",
            font=("Helvetica", 10, "bold"),
        )

        layers = [
            ("ps_os_krnl", "1. OS & Shinerien Krnl", "Núcleo del sistema y cargador nativo Shinerien que acelera la carga de archivos Rice y módulos .c2.", "#38bdf8"),
            ("ps_rice_layer", "2. Rice Layer & 'Bowls'", "Rice representa la base del sistema; los 'Bowls' son los módulos creados en hiOP y publicados en Felte vía smiledev.", "#c084fc"),
            ("ps_c2_layer", "3. .c2 Layer (Component 2)", "[app] + [sys] => Uic.transfork convierte un Bowl de Rice a un paquete firmado .c2 inyectable en PS.", "#00f5d4"),
            ("ps_nec_pair", "4. NEC Pair & ESC Keystore", "Emparejamiento criptográfico del chip NEX1 (W1 WiFi + NFC + BT) y claves biométricas Lookit en el chip ESC.", "#f59e0b"),
            ("ps_priv_data", "5. Priv Data (Felte / CSMS)", "Datos privados aislados por hardware para Felte Store y mensajería cifrada E2EE CSMS.", "#f43f5e"),
        ]
        y_cursor = 252
        for lid, ltitle, ldesc, lcol in layers:
            self._box(c, lid, 70, y_cursor, w - 70, y_cursor + 64, "#0d1322", lcol, False)
            c.create_text(90, y_cursor + 20, text=ltitle, anchor="w", fill=lcol, font=("Helvetica", 10, "bold"))
            c.create_text(90, y_cursor + 43, text=ldesc, anchor="w", fill="#cbd5e1", font=("Helvetica", 9))
            y_cursor += 74

    # ── PESTAÑA 3: CHIPS CS (ESC X1, NEX1 / NFC.E 286, XR1, XRo G1 — PÁG. 1, 2 Y 6) ──
    def _draw_chips_nec_diagram(self, c, w, h, prof):
        c.create_text(
            w // 2,
            30,
            text="🔬 ARQUITECTURA DE CHIPS COKI STUDIOS (PLANOS PÁG. 1, 2 Y 6)",
            fill="#38bdf8",
            font=("Helvetica", 12, "bold"),
        )

        mid_x = w // 2
        # Cuadrante 1: NEX1 / NFC.E 286
        self._box(c, "chip_nex1", 40, 60, mid_x - 15, 310, "#0d1322", "#38bdf8", False)
        c.create_text(60, 84, text="📡 NEX1 (NEC / NFC.E 286) Structure", anchor="w", fill="#38bdf8", font=("Helvetica", 11, "bold"))
        c.create_text(
            60,
            112,
            text="• NFC Enhanced Communication: combina W1 WiFi + NFC RW + Bluetooth\n"
                 "• Antena espiral compartida para Advice NEC y sensor Rotate 1\n"
                 "• Chip central: brightsmile chip 1 (procesador brs1 + Mem Advise NEC)\n"
                 "• Incluye Rotate 1 Mem + Battery Coil en el sustrato inferior",
            anchor="nw",
            fill="#cbd5e1",
            font=("Helvetica", 9),
        )
        # Espiral visual de la antena NEX1
        sx, sy = (40 + mid_x - 15) // 2, 238
        for r in (48, 36, 24):
            c.create_oval(sx - r, sy - r, sx + r, sy + r, outline="#38bdf8", width=1, dash=(4, 2))
        c.create_rectangle(sx - 14, sy - 14, sx + 14, sy + 14, fill="#172554", outline="#00f5d4", width=2)
        c.create_text(sx, sy, text="NE☺", fill="#00f5d4", font=("Courier", 9, "bold"))

        # Cuadrante 2: ESC X1 (Elevate Security Chip)
        self._box(c, "chip_esc_x1", mid_x + 15, 60, w - 40, 310, "#0d1322", "#00f5d4", False)
        c.create_text(
            mid_x + 35, 84, text="🔐 ESC X1 (Elevate Security Chip)", anchor="w", fill="#00f5d4", font=("Helvetica", 11, "bold")
        )
        c.create_text(
            mid_x + 35,
            112,
            text="• Keystore dedicado por hardware para todo el ecosistema CS\n"
                 "• Enlazado con Lookit (reconocimiento facial y huellas dactilares)\n"
                 "• Bloques internos del die (Pág. 6):\n"
                 "  - [minii OS] Micro-kernel aislado de seguridad\n"
                 "  - [Rotate 1] Co-procesador geométrico en diamante\n"
                 "  - [Keystores R1m] Bóveda de claves criptográficas y firmas .c2",
            anchor="nw",
            fill="#cbd5e1",
            font=("Helvetica", 9),
        )

        # Cuadrante 3: XR1 (eXcape Reality Chip 1)
        self._box(c, "chip_xr1", 40, 330, mid_x - 15, 575, "#0d1322", "#c084fc", False)
        c.create_text(
            60, 354, text="🥽 XR1 (eXcape Reality Chip 1 — 10 Cores)", anchor="w", fill="#c084fc", font=("Helvetica", 11, "bold")
        )
        c.create_text(
            60,
            380,
            text="• 8 Lightcores (2 filas superiores x 4 núcleos de alta eficiencia)\n"
                 "• 2 PowerCores inferiores de alto rendimiento gráfico",
            anchor="nw",
            fill="#cbd5e1",
            font=("Helvetica", 9),
        )
        for row in range(2):
            for col in range(4):
                lx = 75 + col * 52
                ly = 430 + row * 36
                c.create_rectangle(lx, ly, lx + 42, ly + 28, fill="#1e1136", outline="#c084fc")
                c.create_text(lx + 21, ly + 14, text="Light", fill="#c084fc", font=("Courier", 7))
        for col in range(2):
            px = 115 + col * 72
            py = 510
            c.create_rectangle(px, py, px + 58, py + 34, fill="#3b0764", outline="#f59e0b", width=2)
            c.create_text(px + 29, py + 17, text="PowerCore", fill="#f59e0b", font=("Courier", 7, "bold"))

        # Cuadrante 4: XRo G1 & XR6 (Game 1 / PortLoop)
        self._box(c, "chip_xrog1", mid_x + 15, 330, w - 40, 575, "#0d1322", "#f59e0b", False)
        c.create_text(
            mid_x + 35,
            354,
            text="⚡ XRo G1 (12 Cores) & XR6 (PortLoop Handheld)",
            anchor="w",
            fill="#f59e0b",
            font=("Helvetica", 11, "bold"),
        )
        c.create_text(
            mid_x + 35,
            380,
            text="• Fila Superior: 6 Power Cores de cómputo pesado\n"
                 "• Fila Inferior: 6 Staticker Cores de latencia ultra-baja\n"
                 "• Variante XR6 en consola portátil PortLoop (con SIM, uSD y sensor HR)",
            anchor="nw",
            fill="#cbd5e1",
            font=("Helvetica", 9),
        )
        for col in range(6):
            gx = mid_x + 38 + col * 42
            c.create_rectangle(gx, 455, gx + 36, 485, fill="#451a03", outline="#f59e0b")
            c.create_text(gx + 18, 470, text="Pwr", fill="#f59e0b", font=("Courier", 7))
            c.create_rectangle(gx, 495, gx + 36, 525, fill="#172554", outline="#38bdf8")
            c.create_text(gx + 18, 510, text="Stat", fill="#38bdf8", font=("Courier", 7))

    # ── PESTAÑA 4: LOOP OoS ARM, LOOPIZE <eNAND>, .CG & COK1 IA (PÁG. 9 Y 10) ──
    def _draw_loop_arm_diagram(self, c, w, h, prof):
        c.create_text(
            w // 2,
            32,
            text="🎮 LOOP OoS 'ARM' (ADVANCED RECOVERY MODE), LOOPIZE <eNAND> & .CG (PÁG. 9 Y 10)",
            fill="#00f5d4",
            font=("Helvetica", 12, "bold"),
        )

        steps = [
            ("arm_step1", "1. Activar ARM en la Consola Loop", "No es arm64: es Advanced Recovery Mode. Apagar Loop -> Pulsar botón especial en el mando + mantener 'L' o 'S' en la consola mientras se presiona Power.", "#38bdf8"),
            ("arm_step2", "2. Loopize Controller <eNAND> a la PC", "El control Loopize integra una 'especial NAND' (<eNAND>). Se desconecta del Loop, se conecta a la PC y se descarga el paquete desde cokistudios.com/oosrestore.", "#c084fc"),
            ("arm_step3", "3. Sideload del Loopize al Loop en ARM", "Se reconecta el mando Loopize al Loop en modo ARM. Transfiere el OS mostrando: 'Do NOT unplug your Loopize / Do NOT power off the Loop'.", "#00f5d4"),
            ("arm_step4", "4. Ecosistema Loop OS (.cg, Felte, Proton, Port Kit & COK1 IA)", "• Felte: Tienda de juegos | • .cg (Component Game): Potencia extra modular para tu Loop\n• Linux-based OS con Valve Proton + Port Kit (Win -> Loop) | • COK1 IA: Asistente in-game en pantalla dividida.", "#f59e0b"),
        ]
        y_pos = 74
        for sid, stitle, sdesc, scol in steps:
            self._box(c, sid, 60, y_pos, w - 60, y_pos + 110, "#0d1322", scol, False)
            c.create_text(82, y_pos + 26, text=stitle, anchor="w", fill=scol, font=("Helvetica", 11, "bold"))
            c.create_text(
                82, y_pos + 62, text=sdesc, anchor="w", fill="#cbd5e1", font=("Helvetica", 9), width=w - 165
            )
            y_pos += 126

    def _box(self, c, wid, x1, y1, x2, y2, fill, outline, is_wire):
        is_sel = wid == self.selected_widget_id
        c.create_rectangle(
            x1,
            y1,
            x2,
            y2,
            fill="" if is_wire else fill,
            outline="#00f5d4" if is_sel else outline,
            width=2 if is_sel else 1,
            dash=(4, 3) if is_wire else None,
        )
        self.hit_boxes.append((wid, (x1, y1, x2, y2)))


if __name__ == "__main__":
    app = UICSketchApp()
    if "--smoke-test" in sys.argv:
        app.update_idletasks()
        app.redraw_canvas()
        print("✔ [UIC SKETCH] Notebook-aligned interactive sketch verified (MRM, PS NAND, Rice/Bowls, NEX1, Loopize).")
        app.after(120, app.destroy)
    app.mainloop()
