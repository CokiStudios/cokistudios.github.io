# loop-gui-tk: Modern Dark GUI Toolkit & Tkinter Interop for Looping (.loop)
# Developed by Coki Studios - APU Engine Division
# Supports complex components: Tabbed Notebooks, Splitters, Sortable Tables, 
# Hierarchical Trees, Monospaced Code Editors, KPI Metric Cards, Vector Canvas, 
# Form Controls, In-Window Toasts, and Declarative UI JSON/Spec building.

import os
import sys
import json
import time

# Suppress macOS Tk 8.5 deprecation notice if running on Darwin
os.environ["TK_SILENCE_DEPRECATION"] = "1"

try:
    import tkinter as tk
    from tkinter import ttk, messagebox
except ImportError as err:
    sys.stderr.write(f"[loop-gui-tk] Error: Tkinter is required but not installed: {err}\n")
    raise

# Coki Studios Dark Palette
THEME = {
    "bg": "#06090f",
    "surface": "#0f172a",
    "card": "#131b2e",
    "border": "#1e293b",
    "border_light": "#334155",
    "text": "#f8fafc",
    "text_muted": "#94a3b8",
    "accent": "#38bdf8",          # Cyan
    "accent_purple": "#818cf8",   # Indigo / Purple
    "accent_success": "#10b981",  # Emerald
    "accent_warning": "#f59e0b",  # Amber
    "accent_danger": "#ef4444",   # Rose
    "input_bg": "#1e293b",
    "input_fg": "#f8fafc",
    "button_primary": "#2563eb",
    "button_primary_hover": "#1d4ed8",
    "font_family": "Helvetica",
    "font_mono": "Courier"
}

class InteractiveCanvas:
    """Helper wrapper around tk.Canvas providing high-level 2D graphics and charts."""
    def __init__(self, canvas: tk.Canvas):
        self.canvas = canvas

    def clear(self):
        self.canvas.delete("all")

    def draw_rect(self, x1, y1, x2, y2, fill=THEME["card"], outline=THEME["border"], width=1):
        return self.canvas.create_rectangle(x1, y1, x2, y2, fill=fill, outline=outline, width=width)

    def draw_circle(self, cx, cy, radius, fill=THEME["accent"], outline=""):
        return self.canvas.create_oval(cx - radius, cy - radius, cx + radius, cy + radius, fill=fill, outline=outline)

    def draw_line(self, x1, y1, x2, y2, color=THEME["accent"], width=2):
        return self.canvas.create_line(x1, y1, x2, y2, fill=color, width=width, smooth=True)

    def draw_text(self, x, y, text, color=THEME["text"], font=(THEME["font_family"], 11, "bold"), anchor="nw"):
        return self.canvas.create_text(x, y, text=text, fill=color, font=font, anchor=anchor)

    def draw_bar_chart(self, data, labels=None, title="", fill=THEME["accent"]):
        """Renders an interactive animated-looking bar chart on the canvas."""
        self.clear()
        self.canvas.update_idletasks()
        w = self.canvas.winfo_width() or int(self.canvas.cget("width"))
        h = self.canvas.winfo_height() or int(self.canvas.cget("height"))

        padding_x = 40
        padding_y = 40
        chart_w = w - (padding_x * 2)
        chart_h = h - (padding_y * 2)

        if title:
            self.draw_text(padding_x, 10, title, color=THEME["text"], font=(THEME["font_family"], 12, "bold"))

        if not data:
            self.draw_text(w / 2, h / 2, "No Data", color=THEME["text_muted"], anchor="center")
            return

        max_val = max(data) if max(data) > 0 else 1
        n = len(data)
        bar_w = max(10, (chart_w / n) - 10)

        # Draw axis
        self.canvas.create_line(padding_x, h - padding_y, w - padding_x, h - padding_y, fill=THEME["border"], width=1)

        for i, val in enumerate(data):
            bx = padding_x + (i * (chart_w / n)) + 5
            norm_h = (val / max_val) * (chart_h - 20)
            by = (h - padding_y) - norm_h

            # Bar with subtle gradient look
            self.canvas.create_rectangle(bx, by, bx + bar_w, h - padding_y, fill=fill, outline=THEME["border"], width=1)
            # Label
            lbl = labels[i] if labels and i < len(labels) else str(val)
            self.draw_text(bx + (bar_w / 2), h - padding_y + 8, str(lbl), color=THEME["text_muted"], font=(THEME["font_family"], 8), anchor="n")
            # Value on top
            self.draw_text(bx + (bar_w / 2), by - 14, str(val), color=THEME["accent"], font=(THEME["font_family"], 8, "bold"), anchor="n")

    def draw_sparkline(self, values, color=THEME["accent_success"], stroke_width=2):
        """Draws a mini sparkline graph."""
        self.clear()
        w = self.canvas.winfo_width() or int(self.canvas.cget("width"))
        h = self.canvas.winfo_height() or int(self.canvas.cget("height"))
        if not values or len(values) < 2:
            return

        min_v = min(values)
        max_v = max(values)
        spread = (max_v - min_v) if max_v != min_v else 1

        points = []
        step_x = (w - 10) / (len(values) - 1)
        for i, v in enumerate(values):
            x = 5 + (i * step_x)
            y = (h - 5) - ((v - min_v) / spread) * (h - 10)
            points.extend([x, y])

        self.canvas.create_line(*points, fill=color, width=stroke_width, smooth=True)


class LoopTkApp:
    """
    Main Tkinter application runtime for Looping (.loop).
    Provides modern UI creation with a rich suite of responsive components.
    """
    def __init__(self, title="Looping App", width=860, height=620, resizable=True):
        self.root = tk.Tk()
        self.root.title(title)
        self.root.geometry(f"{width}x{height}")
        self.root.configure(bg=THEME["bg"])
        self.root.resizable(resizable, resizable)

        # Named state registry for inputs/controls
        self.state = {}
        self.status_bar_lbl = None
        self.status_dot = None

        # Setup modern TTK theme styling
        self._init_ttk_styles()

        # Main scrollable or root container
        self.main_container = tk.Frame(self.root, bg=THEME["bg"])
        self.main_container.pack(fill="both", expand=True)

    def _init_ttk_styles(self):
        self.style = ttk.Style(self.root)
        try:
            self.style.theme_use("clam")
        except Exception:
            pass

        # Notebook tabs
        self.style.configure("TNotebook", background=THEME["bg"], borderwidth=0)
        self.style.configure("TNotebook.Tab", 
            background=THEME["surface"], 
            foreground=THEME["text_muted"], 
            padding=[16, 8], 
            font=(THEME["font_family"], 10, "bold"),
            borderwidth=0
        )
        self.style.map("TNotebook.Tab",
            background=[("selected", THEME["card"])],
            foreground=[("selected", THEME["accent"])]
        )

        # Treeview (Data Tables)
        self.style.configure("Treeview",
            background=THEME["card"],
            foreground=THEME["text"],
            fieldbackground=THEME["card"],
            rowheight=30,
            borderwidth=0,
            font=(THEME["font_family"], 10)
        )
        self.style.configure("Treeview.Heading",
            background=THEME["surface"],
            foreground=THEME["accent"],
            font=(THEME["font_family"], 10, "bold"),
            borderwidth=1,
            relief="flat"
        )
        self.style.map("Treeview",
            background=[("selected", THEME["button_primary"])],
            foreground=[("selected", "#ffffff")]
        )

        # Progressbar
        self.style.configure("TProgressbar",
            troughcolor=THEME["surface"],
            background=THEME["accent"],
            thickness=8,
            borderwidth=0
        )

        # Combobox
        self.style.configure("TCombobox",
            background=THEME["input_bg"],
            foreground=THEME["input_fg"],
            fieldbackground=THEME["input_bg"],
            arrowcolor=THEME["accent"],
            borderwidth=0
        )

    # ==========================================
    # Header & Banner Components
    # ==========================================
    def add_header(self, title, subtitle="", badge="", parent=None):
        target = parent or self.main_container
        hdr_frame = tk.Frame(target, bg=THEME["bg"], pady=12, padx=16)
        hdr_frame.pack(fill="x")

        top_row = tk.Frame(hdr_frame, bg=THEME["bg"])
        top_row.pack(fill="x")

        title_lbl = tk.Label(top_row, text=title, font=(THEME["font_family"], 18, "bold"), fg=THEME["text"], bg=THEME["bg"])
        title_lbl.pack(side="left")

        if badge:
            badge_lbl = tk.Label(
                top_row, text=f" {badge} ", 
                font=(THEME["font_family"], 9, "bold"), 
                fg=THEME["bg"], bg=THEME["accent"], 
                padx=6, pady=2
            )
            badge_lbl.pack(side="left", padx=10)

        if subtitle:
            sub_lbl = tk.Label(hdr_frame, text=subtitle, font=(THEME["font_family"], 10), fg=THEME["text_muted"], bg=THEME["bg"])
            sub_lbl.pack(anchor="w", pady=(4, 0))

        # Thin accent divider
        sep = tk.Frame(target, bg=THEME["border"], height=1)
        sep.pack(fill="x", padx=16, pady=(0, 10))
        return hdr_frame

    # ==========================================
    # Containers: Cards, Splitters, Notebooks, Scroll
    # ==========================================
    def add_card(self, title=None, subtitle=None, parent=None, padx=16, pady=8):
        """Creates an elevated dark card container with border."""
        target = parent or self.main_container
        outer = tk.Frame(target, bg=THEME["border"], padx=1, pady=1)
        outer.pack(fill="x", padx=padx, pady=pady)

        card = tk.Frame(outer, bg=THEME["card"], padx=14, pady=12)
        card.pack(fill="both", expand=True)

        if title:
            t_lbl = tk.Label(card, text=title, font=(THEME["font_family"], 12, "bold"), fg=THEME["text"], bg=THEME["card"])
            t_lbl.pack(anchor="w")
        if subtitle:
            s_lbl = tk.Label(card, text=subtitle, font=(THEME["font_family"], 9), fg=THEME["text_muted"], bg=THEME["card"])
            s_lbl.pack(anchor="w", pady=(2, 8))

        return card

    def add_scrollable_container(self, parent=None, height=None, width=None):
        """Creates a smooth scrollable container for long forms or dashboards."""
        target = parent or self.main_container
        container = tk.Frame(target, bg=THEME["bg"])
        container.pack(fill="both", expand=True)

        canvas = tk.Canvas(container, bg=THEME["bg"], highlightthickness=0, height=height, width=width)
        scrollbar = ttk.Scrollbar(container, orient="vertical", command=canvas.yview)
        scrollable_frame = tk.Frame(canvas, bg=THEME["bg"])

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        canvas_window = canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")

        def _on_canvas_configure(e):
            canvas.itemconfig(canvas_window, width=e.width)
        canvas.bind("<Configure>", _on_canvas_configure)

        def _on_mousewheel(event):
            delta = -1 if event.num == 5 or event.delta < 0 else 1
            canvas.yview_scroll(delta * -1, "units")

        canvas.bind_all("<MouseWheel>", _on_mousewheel)
        canvas.bind_all("<Button-4>", _on_mousewheel)
        canvas.bind_all("<Button-5>", _on_mousewheel)

        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        return scrollable_frame

    def add_notebook(self, parent=None):
        """Creates a tabbed notebook container."""
        target = parent or self.main_container
        nb = ttk.Notebook(target)
        nb.pack(fill="both", expand=True, padx=16, pady=8)
        return nb

    def add_tab(self, notebook, title):
        """Adds a tab to a notebook and returns its frame."""
        frame = tk.Frame(notebook, bg=THEME["bg"], padx=12, pady=12)
        notebook.add(frame, text=title)
        return frame

    def add_paned_window(self, orient="horizontal", parent=None):
        """Creates a split paned window (horizontal or vertical)."""
        target = parent or self.main_container
        tk_orient = tk.HORIZONTAL if orient == "horizontal" else tk.VERTICAL
        pw = tk.PanedWindow(target, orient=tk_orient, bg=THEME["border"], sashrelief="flat", sashwidth=4)
        pw.pack(fill="both", expand=True, padx=16, pady=8)
        return pw

    # ==========================================
    # Complex UI: Metrics Strip, Data Tables, Tree, Code Editor
    # ==========================================
    def add_metrics_row(self, metrics: list, parent=None):
        """
        Renders a row of modern KPI cards side-by-side.
        metrics format: [{"title": "TPS", "value": "12.4k", "badge": "+4.2%", "accent": "#38bdf8"}]
        """
        target = parent or self.main_container
        row = tk.Frame(target, bg=THEME["bg"])
        row.pack(fill="x", padx=16, pady=8)

        for m in metrics:
            col = tk.Frame(row, bg=THEME["border"], padx=1, pady=1)
            col.pack(side="left", fill="both", expand=True, padx=4)

            box = tk.Frame(col, bg=THEME["card"], padx=12, pady=10)
            box.pack(fill="both", expand=True)

            # Title & badge row
            top = tk.Frame(box, bg=THEME["card"])
            top.pack(fill="x")

            tk.Label(top, text=m.get("title", ""), font=(THEME["font_family"], 9, "bold"), fg=THEME["text_muted"], bg=THEME["card"]).pack(side="left")
            if "badge" in m:
                tk.Label(
                    top, text=m["badge"], 
                    font=(THEME["font_family"], 8, "bold"), 
                    fg=m.get("accent", THEME["accent_success"]), 
                    bg=THEME["surface"], padx=4, pady=1
                ).pack(side="right")

            # Value
            val_lbl = tk.Label(
                box, text=m.get("value", "0"), 
                font=(THEME["font_family"], 16, "bold"), 
                fg=m.get("accent", THEME["accent"]), 
                bg=THEME["card"]
            )
            val_lbl.pack(anchor="w", pady=(6, 0))

        return row

    def add_table(self, headers: list, rows: list = None, parent=None, on_select=None, height=8):
        """
        Creates a sortable, scrollable, dark styled data table.
        """
        target = parent or self.main_container
        container = tk.Frame(target, bg=THEME["card"], padx=1, pady=1)
        container.pack(fill="both", expand=True, padx=16, pady=8)

        # Scrollbar
        scroll_y = ttk.Scrollbar(container, orient="vertical")
        scroll_x = ttk.Scrollbar(container, orient="horizontal")

        tree = ttk.Treeview(
            container, 
            columns=headers, 
            show="headings", 
            height=height,
            yscrollcommand=scroll_y.set,
            xscrollcommand=scroll_x.set
        )
        scroll_y.config(command=tree.yview)
        scroll_x.config(command=tree.xview)

        # Header sorting
        def sort_column(col, reverse):
            l = [(tree.set(k, col), k) for k in tree.get_children('')]
            try:
                l.sort(key=lambda t: float(t[0]), reverse=reverse)
            except ValueError:
                l.sort(reverse=reverse)
            for index, (val, k) in enumerate(l):
                tree.move(k, '', index)
            tree.heading(col, command=lambda: sort_column(col, not reverse))

        for h in headers:
            tree.heading(h, text=h, command=lambda _c=h: sort_column(_c, False))
            tree.column(h, anchor="w", width=120)

        if rows:
            for r in rows:
                tree.insert("", "end", values=r)

        if on_select:
            def _handle_select(e):
                selected = tree.selection()
                if selected:
                    vals = tree.item(selected[0])["values"]
                    on_select(vals)
            tree.bind("<<TreeviewSelect>>", _handle_select)

        scroll_y.pack(side="right", fill="y")
        scroll_x.pack(side="bottom", fill="x")
        tree.pack(side="left", fill="both", expand=True)

        # Expose helpers on tree instance
        tree.add_row = lambda r: tree.insert("", "end", values=r)
        tree.clear_all = lambda: [tree.delete(i) for i in tree.get_children()]
        return tree

    def add_tree(self, hierarchy_dict: dict, parent=None, on_select=None, height=10):
        """
        Creates a hierarchical collapsible tree widget (ideal for ASTs, file systems, etc.)
        """
        target = parent or self.main_container
        tree = ttk.Treeview(target, height=height)
        tree.pack(fill="both", expand=True, padx=16, pady=8)

        def _populate(node, parent_id=""):
            for k, v in node.items():
                if isinstance(v, dict):
                    node_id = tree.insert(parent_id, "end", text=k, open=True)
                    _populate(v, node_id)
                elif isinstance(v, list):
                    node_id = tree.insert(parent_id, "end", text=k, open=True)
                    for item in v:
                        tree.insert(node_id, "end", text=str(item))
                else:
                    tree.insert(parent_id, "end", text=f"{k}: {v}")

        _populate(hierarchy_dict)

        if on_select:
            def _on_node(e):
                sel = tree.selection()
                if sel:
                    on_select(tree.item(sel[0])["text"])
            tree.bind("<<TreeviewSelect>>", _on_node)

        return tree

    def add_code_editor(self, initial_text="", language="loop", parent=None, height=12):
        """
        Creates a monospaced code editor with line counter and Looping syntax keywords.
        """
        target = parent or self.main_container
        outer = tk.Frame(target, bg=THEME["border"], padx=1, pady=1)
        outer.pack(fill="both", expand=True, padx=16, pady=8)

        editor_box = tk.Frame(outer, bg=THEME["card"])
        editor_box.pack(fill="both", expand=True)

        # Top bar with language tag & copy button
        top = tk.Frame(editor_box, bg=THEME["surface"], padx=8, pady=4)
        top.pack(fill="x")
        tk.Label(top, text=f"EDITOR ({language.upper()})", font=(THEME["font_mono"], 9, "bold"), fg=THEME["accent"], bg=THEME["surface"]).pack(side="left")

        text_area = tk.Text(
            editor_box,
            bg=THEME["card"],
            fg=THEME["text"],
            insertbackground=THEME["accent"],
            selectbackground=THEME["button_primary"],
            font=(THEME["font_mono"], 10),
            height=height,
            relief="flat",
            padx=8,
            pady=8
        )

        copy_btn = tk.Button(
            top, text="Copy", font=(THEME["font_family"], 8),
            bg=THEME["border"], fg=THEME["text"], relief="flat", padx=6, pady=2,
            command=lambda: (self.root.clipboard_clear(), self.root.clipboard_append(text_area.get("1.0", tk.END)), self.show_toast("Code copied to clipboard!"))
        )
        copy_btn.pack(side="right")

        text_area.insert("1.0", initial_text)
        text_area.pack(fill="both", expand=True)

        # Simple keyword syntax highlight
        text_area.tag_config("kw", foreground=THEME["accent"])
        text_area.tag_config("fn", foreground=THEME["accent_purple"])
        text_area.tag_config("num", foreground=THEME["accent_success"])
        text_area.tag_config("str", foreground=THEME["accent_warning"])

        def _highlight_syntax(e=None):
            keywords = ["val", "var", "fn", "loop", "if", "else", "use", "import", "return", "pub", "py!"]
            for kw in keywords:
                idx = "1.0"
                while True:
                    idx = text_area.search(r'\m' + kw + r'\M', idx, nocase=False, stopindex=tk.END, regexp=True)
                    if not idx:
                        break
                    lastidx = f"{idx}+{len(kw)}c"
                    text_area.tag_add("kw", idx, lastidx)
                    idx = lastidx

        text_area.bind("<KeyRelease>", _highlight_syntax)
        _highlight_syntax()

        # Expose get/set
        text_area.get_text = lambda: text_area.get("1.0", tk.END).strip()
        text_area.set_text = lambda t: (text_area.delete("1.0", tk.END), text_area.insert("1.0", t), _highlight_syntax())
        return text_area

    def add_canvas(self, width=400, height=280, parent=None):
        """
        Creates an InteractiveCanvas supporting 2D drawing, circles, lines and charts.
        """
        target = parent or self.main_container
        outer = tk.Frame(target, bg=THEME["border"], padx=1, pady=1)
        outer.pack(fill="both", expand=True, padx=16, pady=8)

        cv = tk.Canvas(outer, width=width, height=height, bg=THEME["card"], highlightthickness=0)
        cv.pack(fill="both", expand=True)
        return InteractiveCanvas(cv)

    # ==========================================
    # Form Controls: Inputs, Sliders, Progress, Toggles, Buttons
    # ==========================================
    def add_input(self, label="", placeholder="", default="", name=None, parent=None, on_change=None):
        target = parent or self.main_container
        box = tk.Frame(target, bg=THEME["bg"], pady=4)
        box.pack(fill="x", padx=16)

        if label:
            tk.Label(box, text=label, font=(THEME["font_family"], 9, "bold"), fg=THEME["text_muted"], bg=THEME["bg"]).pack(anchor="w", pady=(0, 2))

        var = tk.StringVar(value=default)
        entry = tk.Entry(
            box,
            textvariable=var,
            font=(THEME["font_family"], 10),
            bg=THEME["input_bg"],
            fg=THEME["input_fg"],
            insertbackground=THEME["accent"],
            relief="flat",
            bd=6
        )
        entry.pack(fill="x")

        if on_change:
            var.trace_add("write", lambda *args: on_change(var.get()))

        if name:
            self.state[name] = var

        entry.get_value = lambda: var.get()
        entry.set_value = lambda v: var.set(v)
        return entry

    def add_combobox(self, label="", options=None, default=None, name=None, parent=None, on_change=None):
        target = parent or self.main_container
        box = tk.Frame(target, bg=THEME["bg"], pady=4)
        box.pack(fill="x", padx=16)

        if label:
            tk.Label(box, text=label, font=(THEME["font_family"], 9, "bold"), fg=THEME["text_muted"], bg=THEME["bg"]).pack(anchor="w", pady=(0, 2))

        opts = options or []
        var = tk.StringVar(value=default or (opts[0] if opts else ""))
        combo = ttk.Combobox(box, textvariable=var, values=opts, state="readonly")
        combo.pack(fill="x")

        if on_change:
            combo.bind("<<ComboboxSelected>>", lambda e: on_change(var.get()))

        if name:
            self.state[name] = var

        combo.get_value = lambda: var.get()
        combo.set_value = lambda v: var.set(v)
        return combo

    def add_slider(self, label="", min_val=0, max_val=100, default=50, name=None, parent=None, on_change=None):
        """Slider with dynamic value badge."""
        target = parent or self.main_container
        box = tk.Frame(target, bg=THEME["bg"], pady=4)
        box.pack(fill="x", padx=16)

        hdr = tk.Frame(box, bg=THEME["bg"])
        hdr.pack(fill="x")

        if label:
            tk.Label(hdr, text=label, font=(THEME["font_family"], 9, "bold"), fg=THEME["text_muted"], bg=THEME["bg"]).pack(side="left")

        val_lbl = tk.Label(hdr, text=str(default), font=(THEME["font_family"], 9, "bold"), fg=THEME["accent"], bg=THEME["bg"])
        val_lbl.pack(side="right")

        var = tk.DoubleVar(value=default)

        def _update(v):
            ival = int(float(v))
            val_lbl.config(text=str(ival))
            if on_change:
                on_change(ival)

        scale = tk.Scale(
            box,
            from_=min_val,
            to=max_val,
            orient="horizontal",
            showvalue=False,
            variable=var,
            command=_update,
            bg=THEME["surface"],
            fg=THEME["text"],
            troughcolor=THEME["card"],
            activebackground=THEME["accent"],
            highlightthickness=0,
            bd=0
        )
        scale.pack(fill="x", pady=2)

        if name:
            self.state[name] = var

        scale.get_value = lambda: int(var.get())
        scale.set_value = lambda v: (var.set(v), _update(v))
        return scale

    def add_progress_bar(self, label="", max_val=100, parent=None):
        """Modern styled determinate progress bar."""
        target = parent or self.main_container
        box = tk.Frame(target, bg=THEME["bg"], pady=4)
        box.pack(fill="x", padx=16)

        if label:
            tk.Label(box, text=label, font=(THEME["font_family"], 9, "bold"), fg=THEME["text_muted"], bg=THEME["bg"]).pack(anchor="w", pady=(0, 2))

        bar = ttk.Progressbar(box, maximum=max_val, mode="determinate")
        bar.pack(fill="x")

        bar.set_progress = lambda v: bar.configure(value=v)
        return bar

    def add_toggle(self, label="", default=False, name=None, parent=None, on_change=None):
        """Modern toggle switch."""
        target = parent or self.main_container
        box = tk.Frame(target, bg=THEME["bg"], pady=4)
        box.pack(fill="x", padx=16)

        var = tk.BooleanVar(value=default)
        chk = tk.Checkbutton(
            box,
            text=label,
            variable=var,
            font=(THEME["font_family"], 10),
            fg=THEME["text"],
            bg=THEME["bg"],
            selectcolor=THEME["card"],
            activebackground=THEME["bg"],
            activeforeground=THEME["accent"],
            command=lambda: on_change(var.get()) if on_change else None
        )
        chk.pack(anchor="w")

        if name:
            self.state[name] = var

        chk.get_value = lambda: var.get()
        chk.set_value = lambda v: var.set(v)
        return chk

    def add_button(self, text, callback=None, variant="primary", parent=None):
        target = parent or self.main_container
        colors = {
            "primary": (THEME["button_primary"], "#ffffff"),
            "accent": (THEME["accent"], THEME["bg"]),
            "secondary": (THEME["surface"], THEME["text"]),
            "danger": (THEME["accent_danger"], "#ffffff"),
            "success": (THEME["accent_success"], "#ffffff")
        }
        bg, fg = colors.get(variant, colors["primary"])

        btn = tk.Button(
            target,
            text=text,
            font=(THEME["font_family"], 9, "bold"),
            bg=bg,
            fg=fg,
            activebackground=THEME["border_light"],
            activeforeground=fg,
            relief="flat",
            padx=14,
            pady=8,
            cursor="hand2",
            command=callback
        )
        btn.pack(pady=4)
        return btn

    def add_button_group(self, buttons: list, parent=None):
        """Renders a row of buttons: [{'text': 'Deploy', 'variant': 'accent', 'action': fn}]"""
        target = parent or self.main_container
        row = tk.Frame(target, bg=THEME["bg"])
        row.pack(fill="x", padx=16, pady=6)

        created = []
        for b in buttons:
            btn = self.add_button(b.get("text", "Button"), callback=b.get("action"), variant=b.get("variant", "primary"), parent=row)
            btn.pack_configure(side="left", padx=4)
            created.append(btn)
        return created

    # ==========================================
    # Status Bar & Floating Toasts
    # ==========================================
    def add_status_bar(self, text="Ready", status_type="ready"):
        bar = tk.Frame(self.root, bg=THEME["surface"], padx=10, pady=4)
        bar.pack(side="bottom", fill="x")

        colors = {
            "ready": THEME["accent_success"],
            "working": THEME["accent_warning"],
            "error": THEME["accent_danger"],
            "info": THEME["accent"]
        }
        dot_color = colors.get(status_type, THEME["accent_success"])

        self.status_dot = tk.Label(bar, text="●", fg=dot_color, bg=THEME["surface"], font=(THEME["font_family"], 9))
        self.status_dot.pack(side="left", padx=(0, 6))

        self.status_bar_lbl = tk.Label(bar, text=text, fg=THEME["text_muted"], bg=THEME["surface"], font=(THEME["font_family"], 9))
        self.status_bar_lbl.pack(side="left")

        # Engine signature
        tk.Label(bar, text="Coki Studios APU • Looping v2.8.0", fg=THEME["border_light"], bg=THEME["surface"], font=(THEME["font_family"], 8)).pack(side="right")
        return bar

    def set_status(self, text, status_type="ready"):
        if self.status_bar_lbl:
            self.status_bar_lbl.config(text=text)
        if self.status_dot:
            colors = {
                "ready": THEME["accent_success"],
                "working": THEME["accent_warning"],
                "error": THEME["accent_danger"],
                "info": THEME["accent"]
            }
            self.status_dot.config(fg=colors.get(status_type, THEME["accent_success"]))

    def show_toast(self, message, duration=2500, level="info"):
        """Displays a floating non-blocking dark toast banner inside the window."""
        accent_colors = {
            "info": THEME["accent"],
            "success": THEME["accent_success"],
            "warning": THEME["accent_warning"],
            "error": THEME["accent_danger"]
        }
        accent = accent_colors.get(level, THEME["accent"])

        toast = tk.Frame(self.root, bg=THEME["card"], padx=14, pady=8, highlightbackground=accent, highlightthickness=1)
        lbl = tk.Label(toast, text=message, font=(THEME["font_family"], 9, "bold"), fg=THEME["text"], bg=THEME["card"])
        lbl.pack()

        toast.place(relx=0.5, rely=0.08, anchor="n")
        self.root.after(duration, lambda: toast.destroy())

    def show_modal(self, title, message, dialog_type="info"):
        if dialog_type == "error":
            messagebox.showerror(title, message, parent=self.root)
        elif dialog_type == "warning":
            messagebox.showwarning(title, message, parent=self.root)
        elif dialog_type == "confirm":
            return messagebox.askyesno(title, message, parent=self.root)
        else:
            messagebox.showinfo(title, message, parent=self.root)

    # ==========================================
    # State Management & Declarative Spec Engine
    # ==========================================
    def get_state(self, name=None):
        if name:
            v = self.state.get(name)
            return v.get() if v else None
        return {k: v.get() for k, v in self.state.items()}

    def build_from_spec(self, spec):
        """
        Builds a full complex UI from a dict or JSON specification.
        Example spec:
        {
            "header": {"title": "Dashboard", "subtitle": "Looping Tkinter", "badge": "PRO"},
            "metrics": [{"title": "Memory", "value": "24MB"}],
            "tabs": [
                {"title": "Overview", "components": [...]},
                {"title": "Logs", "components": [...]}
            ]
        }
        """
        if isinstance(spec, str):
            spec = json.loads(spec)

        if "header" in spec:
            h = spec["header"]
            self.add_header(h.get("title", ""), h.get("subtitle", ""), h.get("badge", ""))

        if "metrics" in spec:
            self.add_metrics_row(spec["metrics"])

        if "tabs" in spec:
            nb = self.add_notebook()
            for t in spec["tabs"]:
                tab_frame = self.add_tab(nb, t.get("title", "Tab"))
                for comp in t.get("components", []):
                    self._build_component(comp, tab_frame)

        if "components" in spec:
            for comp in spec["components"]:
                self._build_component(comp, self.main_container)

        if "status_bar" in spec:
            self.add_status_bar(spec["status_bar"].get("text", "Ready"), spec["status_bar"].get("status", "ready"))

    def _build_component(self, comp, parent):
        ctype = comp.get("type")
        if ctype == "card":
            card = self.add_card(comp.get("title"), comp.get("subtitle"), parent=parent)
            for sub in comp.get("children", []):
                self._build_component(sub, card)
        elif ctype == "table":
            self.add_table(comp.get("headers", []), comp.get("rows", []), parent=parent)
        elif ctype == "editor":
            self.add_code_editor(comp.get("text", ""), comp.get("language", "loop"), parent=parent)
        elif ctype == "input":
            self.add_input(comp.get("label", ""), default=comp.get("default", ""), name=comp.get("name"), parent=parent)
        elif ctype == "slider":
            self.add_slider(comp.get("label", ""), min_val=comp.get("min", 0), max_val=comp.get("max", 100), default=comp.get("default", 50), name=comp.get("name"), parent=parent)
        elif ctype == "button":
            self.add_button(comp.get("text", "Action"), variant=comp.get("variant", "primary"), parent=parent)

    def run(self):
        """Starts the event loop."""
        self.root.mainloop()


# Backward compatibility alias
TkLoopWindow = LoopTkApp

def init_module(vars_dict=None):
    """Looping module initializer factory."""
    app = LoopTkApp()
    if vars_dict and isinstance(vars_dict, dict):
        if "title" in vars_dict:
            app.root.title(vars_dict["title"])
        if "width" in vars_dict and "height" in vars_dict:
            app.root.geometry(f"{vars_dict['width']}x{vars_dict['height']}")
    return app


if __name__ == "__main__":
    # Self-test demo when executed directly
    app = LoopTkApp(title="Looping Tkinter Complex UI Showcase", width=880, height=680)
    app.add_header("Coki Studios Looping Toolkit", subtitle="Advanced Tkinter native component demonstration", badge="APU v2.8")

    app.add_metrics_row([
        {"title": "ACTIVE THREADS", "value": "16", "badge": "OPTIMAL", "accent": THEME["accent_success"]},
        {"title": "CYCLE LATENCY", "value": "0.14 ms", "badge": "-12%", "accent": THEME["accent"]},
        {"title": "VIRTUAL MEMORY", "value": "34.2 MB", "badge": "LEAN", "accent": THEME["accent_purple"]}
    ])

    tabs = app.add_notebook()

    # Tab 1: Data Table & Form Controls
    t1 = app.add_tab(tabs, "Data Grid & Inputs")
    card1 = app.add_card("System Tasks", "Sortable multi-column telemetry table", parent=t1)
    tbl = app.add_table(["PID", "Process", "Status", "Load"], [
        ["1001", "LoopingAPU", "Running", "1.2%"],
        ["1002", "CSMS Bridge", "Active", "0.4%"],
        ["1003", "Shine Vector", "Idle", "0.0%"],
        ["1004", "SmileDev Daemon", "Listening", "0.8%"]
    ], parent=card1, height=4)

    app.add_slider("Throttle Rate (%)", min_val=0, max_val=100, default=75, name="throttle", parent=t1)
    app.add_input("Search Filter", placeholder="Filter jobs...", name="filter", parent=t1)
    app.add_button_group([
        {"text": "Refresh Grid", "variant": "primary", "action": lambda: app.show_toast("Refreshed telemetry grid!")},
        {"text": "Clear Logs", "variant": "secondary", "action": lambda: tbl.clear_all()}
    ], parent=t1)

    # Tab 2: Code Editor
    t2 = app.add_tab(tabs, "Code Editor")
    app.add_code_editor("""// Looping v2.8 Native Script
use "loop-gui-tk" as gui

fn start_service() {
    val status = "INITIALIZED"
    print("APU Service Started with status: " + status)
}

start_service()
""", language="loop", parent=t2, height=10)

    # Tab 3: Interactive Canvas & Charts
    t3 = app.add_tab(tabs, "Vector Canvas")
    cv = app.add_canvas(width=800, height=240, parent=t3)
    cv.draw_bar_chart([35, 78, 45, 92, 60, 85, 99], labels=["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], title="Throughput (ops/sec)")

    app.add_status_bar("Tkinter UI Engine Ready", "ready")
    print("[loop-gui-tk] Self-test started.")
    # Exit cleanly without blocking during automated headless checks
    app.root.after(500, app.root.destroy)
    app.run()
    print("[loop-gui-tk] Self-test passed.")
