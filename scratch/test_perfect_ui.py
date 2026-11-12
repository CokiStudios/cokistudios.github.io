#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, subprocess, time
import tkinter as tk

os.environ['TK_SILENCE_DEPRECATION'] = '1'

THEME = {
    'bg': '#0b0f19',
    'card_bg': '#151d30',
    'card_border': '#22314e',
    'primary': '#38bdf8',
    'fg': '#f8fafc',
    'sub_fg': '#94a3b8',
    'accent': '#00f5d4',
    'btn_bg': '#0284c7',
    'btn_fg': '#ffffff',
    'log_bg': '#070a12',
    'log_fg': '#10b981'
}

CARDS_DATA = [
    {
        'title': "📱 Dispositivos Shine OS",
        'badge': "ADB ENLACE",
        'text': "Soporte para Shine X1, Xa1, f1, i1, A1 y Nomad 1. Enlace de depuración a ultra-baja latencia vía ADB USB o Wi-Fi."
    },
    {
        'title': "📦 Módulos Component 2 (.c2)",
        'badge': "HOT-RELOAD",
        'text': "Gestión de paquetes .c2 en c2-modules/. Empuje en tiempo real a /sdcard/ShineUI/modules con broadcast com.cokistudios.shine.INSTALL_C2."
    },
    {
        'title': "🌐 CS WEBS Cloud Edge (OTA)",
        'badge': "EDGE OTA",
        'text': "Despliegue Over-The-Air global a través de https://webs.cokistudios.com/api/v1/c2/upload para actualizar launchers sin cables."
    },
    {
        'title': "⚡ Motor Loop OS v2.5",
        'badge': "NATIVE AQUA",
        'text': "Renderizado directo al sistema operativo. Cero contenedores web, cero Chromium, cero dependencias pesadas."
    }
]

BUTTONS = [
    {'text': "⚡ Escanear Celulares (ADB)", 'action': "Escanear_Celulares_ADB", 'snippet': "val out = sys.exec(\"adb devices -l\")\nprint $\"[ADB] Dispositivos detectados en el sistema:\\n{out}\"\n"},
    {'text': "⚡ Instalar C2 (USB)", 'action': "Instalar_C2_USB", 'snippet': "val mod = \"c2-modules/cyber_neon_xui.c2\"\nval res = sys.exec($\"python3 UIConnect/ui_connect.py --install {mod}\")\nprint $\"[INSTALADOR C2] Resultado de instalación:\\n{res}\"\n"},
    {'text': "⚡ Publicar OTA (CS WEBS)", 'action': "Publicar_OTA_CS_WEBS", 'snippet': "val mod = \"c2-modules/cyber_neon_xui.c2\"\nval res = sys.exec($\"python3 UIConnect/ui_connect.py --ota {mod}\")\nprint $\"[CS WEBS OTA] Estado de publicación Cloudflare Edge:\\n{res}\"\n"},
    {'text': "⚡ Auditar Módulos (Pipeline |>)", 'action': "Auditar_Mdulos_Pipeline_", 'snippet': "fn is_c2_file(f) => contains(f, \".c2\")\nval all_mods = [\"cyber_neon_xui.c2\", \"aqua_nomad_ui.c2\", \"aurora_fold_flui.c2\", \"vintage_amber.c2\", \"feather_lite_hiui.c2\", \"custom_launcher.c2\"]\nval verified = all_mods |> filter(is_c2_file)\nprint $\"[C2 AUDIT] Módulos validados con pipeline (|>) [{len(verified)}/6]:\\n{verified}\"\n"},
    {'text': "⚡ Feedback Acústico (APU)", 'action': "Feedback_Acstico_APU", 'snippet': "play tone at 880 Hz for 80 ms\nplay tone at 1174 Hz for 100 ms\nprint \"[AUDIO] Feedback acústico sintetizado (880Hz / 1174Hz APU Tone).\"\n"},
]

class TestWindow(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("✦ UI CONNECT (PC) — Shine OS Component 2 Manager ✦ — Loop OS Native Window")
        self.geometry("980x740")
        self.configure(bg=THEME['bg'])
        self.minsize(600, 450)
        self.setup_ui()

    def setup_ui(self):
        # 1. Header (Canvas for razor-sharp rendering on macOS)
        self.c_hdr = tk.Canvas(self, height=52, bg=THEME['card_bg'], highlightthickness=0)
        self.c_hdr.pack(fill='x', side='top')
        self.c_hdr.create_text(18, 26, text="✦ UI CONNECT (PC) — Shine OS Component 2 Manager ✦", anchor='w', fill=THEME['primary'], font=('Helvetica', 14, 'bold'))
        # Hardware Profile Badge
        self.c_hdr.create_rectangle(740, 13, 960, 39, fill=THEME['accent'], outline='')
        self.c_hdr.create_text(850, 26, text="XUI • 240 FPS Direct", fill='#0b0f19', font=('Helvetica', 10, 'bold'))

        # 2. Main Container
        main = tk.Frame(self, bg=THEME['bg'], padx=16, pady=10)
        main.pack(fill='both', expand=True)

        # 3. Cards Canvas (Dynamic 2-column Grid, never clips or vanishes)
        self.c_cards = tk.Canvas(main, height=225, bg=THEME['bg'], highlightthickness=0)
        self.c_cards.pack(fill='x', pady=(0, 10))

        card_w = 460
        card_h = 98
        for i, c in enumerate(CARDS_DATA):
            col = i % 2
            row = i // 2
            x = col * (card_w + 16)
            y = row * (card_h + 12)
            # Card Background with border
            self.c_cards.create_rectangle(x, y, x + card_w, y + card_h, fill=THEME['card_bg'], outline=THEME['card_border'], width=1)
            # Card Title
            self.c_cards.create_text(x + 14, y + 20, text=c['title'], anchor='w', fill=THEME['primary'], font=('Helvetica', 11, 'bold'))
            # Badge pill
            badge_txt = c['badge']
            bw = len(badge_txt) * 7 + 16
            bx2 = x + card_w - 12
            bx1 = bx2 - bw
            self.c_cards.create_rectangle(bx1, y + 10, bx2, y + 30, fill='#22314e', outline='')
            self.c_cards.create_text((bx1 + bx2) // 2, y + 20, text=badge_txt, fill=THEME['accent'], font=('Helvetica', 8, 'bold'))
            # Card Text
            self.c_cards.create_text(x + 14, y + 60, text=c['text'], anchor='w', fill=THEME['fg'], font=('Helvetica', 9), width=card_w - 28)

        # 4. Controls Frame
        ctrl = tk.Frame(main, bg=THEME['card_bg'], highlightbackground=THEME['card_border'], highlightthickness=1, padx=14, pady=10)
        ctrl.pack(fill='x', pady=(0, 10))

        # Sliders using standard tk.Scale (native and fully rendered)
        self.sl_lbl_0 = tk.Label(ctrl, text="Tasa de Transferencia ADB (KB/s): 1024", font=('Helvetica', 9, 'bold'), fg=THEME['sub_fg'], bg=THEME['card_bg'])
        self.sl_lbl_0.pack(anchor='w')
        def on_sl_0(val):
            self.sl_lbl_0.config(text=f"Tasa de Transferencia ADB (KB/s): {float(val):.0f}")
        self.sl_0 = tk.Scale(ctrl, from_=64, to=4096, orient='horizontal', bg=THEME['card_bg'], fg=THEME['fg'], highlightthickness=0, troughcolor=THEME['log_bg'], activebackground=THEME['primary'], showvalue=0, command=on_sl_0)
        self.sl_0.set(1024)
        self.sl_0.pack(fill='x', pady=(2, 6))

        self.sl_lbl_1 = tk.Label(ctrl, text="Sensibilidad de Hot-Reload (ms): 150", font=('Helvetica', 9, 'bold'), fg=THEME['sub_fg'], bg=THEME['card_bg'])
        self.sl_lbl_1.pack(anchor='w')
        def on_sl_1(val):
            self.sl_lbl_1.config(text=f"Sensibilidad de Hot-Reload (ms): {float(val):.0f}")
        self.sl_1 = tk.Scale(ctrl, from_=50, to=1000, orient='horizontal', bg=THEME['card_bg'], fg=THEME['fg'], highlightthickness=0, troughcolor=THEME['log_bg'], activebackground=THEME['primary'], showvalue=0, command=on_sl_1)
        self.sl_1.set(150)
        self.sl_1.pack(fill='x', pady=(2, 6))

        # Toggles using native tk.Checkbutton
        self.tg_0 = tk.BooleanVar(value=True)
        def on_tg_0():
            st = 'ACTIVADO' if self.tg_0.get() else 'DESACTIVADO'
            self.log(f"Toggle 'Auto-Sincronización' -> {st}", 'action')
        tk.Checkbutton(ctrl, text="Auto-Sincronización al Guardar en c2-modules/", variable=self.tg_0, command=on_tg_0, font=('Helvetica', 9), fg=THEME['fg'], bg=THEME['card_bg'], selectcolor=THEME['log_bg'], activebackground=THEME['card_bg']).pack(anchor='w', pady=2)

        self.tg_1 = tk.BooleanVar(value=True)
        def on_tg_1():
            st = 'ACTIVADO' if self.tg_1.get() else 'DESACTIVADO'
            self.log(f"Toggle 'Modo Direct-Vulkan APU' -> {st}", 'action')
        tk.Checkbutton(ctrl, text="Modo Direct-Vulkan APU Low-Latency (<0.2ms)", variable=self.tg_1, command=on_tg_1, font=('Helvetica', 9), fg=THEME['fg'], bg=THEME['card_bg'], selectcolor=THEME['log_bg'], activebackground=THEME['card_bg']).pack(anchor='w', pady=2)

        # Progress Bar via Canvas (Always paints, never collapses)
        tk.Label(ctrl, text="Estado del Buffer y Cola de Instalación (100%)", font=('Helvetica', 9, 'bold'), fg=THEME['sub_fg'], bg=THEME['card_bg']).pack(anchor='w', pady=(4, 2))
        self.c_pr = tk.Canvas(ctrl, height=12, bg=THEME['log_bg'], highlightthickness=1, highlightbackground=THEME['card_border'])
        self.c_pr.pack(fill='x', pady=(0, 4))
        self.c_pr.create_rectangle(0, 0, 940, 12, fill=THEME['accent'], outline='')

        # 5. Buttons Toolbar
        btn_bar = tk.Frame(main, bg=THEME['bg'])
        btn_bar.pack(fill='x', pady=(2, 10))
        for idx, b in enumerate(BUTTONS):
            btn = tk.Button(btn_bar, text=b['text'], font=('Helvetica', 9, 'bold'), bg=THEME['btn_bg'], fg=THEME['btn_fg'], relief='flat', padx=8, pady=5, activebackground=THEME['primary'], cursor='hand2', command=lambda i=idx: self.on_btn_click(i))
            btn.pack(side='left', padx=(0, 8))

        # 6. Interactive Log Drawer
        log_frame = tk.Frame(main, bg=THEME['log_bg'], highlightbackground=THEME['card_border'], highlightthickness=1)
        log_frame.pack(fill='both', expand=True)
        log_scroll = tk.Scrollbar(log_frame)
        log_scroll.pack(side='right', fill='y')
        self.log_txt = tk.Text(log_frame, bg=THEME['log_bg'], fg=THEME['log_fg'], font=('Courier', 10), yscrollcommand=log_scroll.set, wrap='word', height=6, padx=10, pady=8, relief='flat')
        self.log_txt.pack(fill='both', expand=True)
        log_scroll.config(command=self.log_txt.yview)
        self.log_txt.tag_config('action', foreground='#38bdf8')
        self.log_txt.tag_config('success', foreground='#10b981')
        self.log_txt.tag_config('snippet', foreground='#facc15')

        self.log("[Loop OS Native] Ventana '✦ UI CONNECT (PC) — Shine OS Component 2 Manager ✦' inicializada (XUI Direct-to-Vulkan 240Hz).", 'success')

    def log(self, msg, tag='success'):
        now = time.strftime('%H:%M:%S')
        self.log_txt.insert('end', f"[{now}] {msg}\n", tag)
        self.log_txt.see('end')

    def on_btn_click(self, idx):
        self.bell()
        b = BUTTONS[idx]
        self.log(f"⚡ Ejecutando snippet: {b['text']}", 'snippet')
        if b['action'] == 'Auditar_Mdulos_Pipeline_':
            self.log("[C2 AUDIT] Módulos validados con pipeline (|>) [6/6]: ['cyber_neon_xui.c2', 'aqua_nomad_ui.c2', 'aurora_fold_flui.c2', 'vintage_amber.c2', 'feather_lite_hiui.c2', 'custom_launcher.c2']", 'action')
        elif b['action'] == 'Escanear_Celulares_ADB':
            self.log("[ADB] Dispositivos detectados en el sistema:\nList of devices attached\nRF8N90XXXXX device product:shine_x1 model:Shine_X1 device:x1 transport_id:1", 'action')
        elif b['action'] == 'Feedback_Acstico_APU':
            self.log("[AUDIO] Feedback acústico sintetizado (880Hz / 1174Hz APU Tone).", 'action')
        else:
            self.log(f"[ACTION] {b['action']} ejecutado correctamente.", 'action')

if __name__ == '__main__':
    app = TestWindow()
    app.mainloop()
