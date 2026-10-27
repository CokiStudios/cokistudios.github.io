# loop-gui-qt: Advanced PyQt6 / PySide6 Native Interop & Complex UI Toolkit for Looping (.loop)
# Developed by Coki Studios - APU Engine Division
# Features: Dual backend (PyQt6 / PySide6), Modern QSS Dark Obsidian & Glass Theme,
# Tabbed Workspaces, Splitters, Sortable Tables, Trees, Monospace Code Editors,
# KPI Metrics Strip, Live Sliders, Form Controls, Toasts, Declarative UI Spec Parser,
# and Graceful Tkinter Fallback Bridge when Qt is not installed.

import sys
import os
import json

QT_BACKEND = None
try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QLineEdit, QComboBox, QSlider, QProgressBar,
        QTabWidget, QSplitter, QTableWidget, QTableWidgetItem, QHeaderView,
        QTreeWidget, QTreeWidgetItem, QPlainTextEdit, QCheckBox, QFrame,
        QScrollArea, QMessageBox, QStatusBar
    )
    from PyQt6.QtCore import Qt, QTimer
    from PyQt6.QtGui import QFont, QColor, QPalette, QCursor
    QT_BACKEND = "PyQt6"
except ImportError:
    try:
        from PySide6.QtWidgets import (
            QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
            QLabel, QPushButton, QLineEdit, QComboBox, QSlider, QProgressBar,
            QTabWidget, QSplitter, QTableWidget, QTableWidgetItem, QHeaderView,
            QTreeWidget, QTreeWidgetItem, QPlainTextEdit, QCheckBox, QFrame,
            QScrollArea, QMessageBox, QStatusBar
        )
        from PySide6.QtCore import Qt, QTimer
        from PySide6.QtGui import QFont, QColor, QPalette, QCursor
        QT_BACKEND = "PySide6"
    except ImportError:
        QT_BACKEND = None

# Coki Studios Dark Obsidian & Cyan QSS Stylesheet
COKI_QSS_STYLESHEET = """
QMainWindow, QWidget {
    background-color: #06090f;
    color: #f8fafc;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    font-size: 13px;
}

/* Tab Widget */
QTabWidget::pane {
    border: 1px solid #1e293b;
    background-color: #0b0f19;
    border-radius: 8px;
    padding: 6px;
}
QTabBar::tab {
    background: #0f172a;
    color: #94a3b8;
    padding: 8px 18px;
    margin-right: 4px;
    border-top-left-radius: 6px;
    border-top-right-radius: 6px;
    font-weight: 600;
}
QTabBar::tab:selected {
    background: #131b2e;
    color: #38bdf8;
    border-bottom: 2px solid #38bdf8;
}
QTabBar::tab:hover {
    color: #f8fafc;
}

/* Buttons */
QPushButton {
    background-color: #2563eb;
    color: #ffffff;
    border: none;
    border-radius: 6px;
    padding: 8px 16px;
    font-weight: 600;
}
QPushButton:hover {
    background-color: #1d4ed8;
}
QPushButton:pressed {
    background-color: #1e40af;
}

/* Inputs & Form Elements */
QLineEdit {
    background-color: #1e293b;
    color: #f8fafc;
    border: 1px solid #334155;
    border-radius: 6px;
    padding: 6px 10px;
    selection-background-color: #38bdf8;
}
QLineEdit:focus {
    border: 1px solid #38bdf8;
}

QComboBox {
    background-color: #1e293b;
    color: #f8fafc;
    border: 1px solid #334155;
    border-radius: 6px;
    padding: 6px 10px;
}
QComboBox::drop-down {
    border: none;
    width: 20px;
}
QComboBox QAbstractItemView {
    background-color: #0f172a;
    color: #f8fafc;
    selection-background-color: #2563eb;
    border: 1px solid #1e293b;
}

/* Data Table */
QTableWidget {
    background-color: #0f172a;
    color: #f8fafc;
    gridline-color: #1e293b;
    border: 1px solid #1e293b;
    border-radius: 6px;
    selection-background-color: #2563eb;
    selection-color: #ffffff;
}
QHeaderView::section {
    background-color: #131b2e;
    color: #38bdf8;
    padding: 6px;
    font-weight: 600;
    border: 1px solid #1e293b;
}

/* Tree Widget */
QTreeWidget {
    background-color: #0f172a;
    color: #f8fafc;
    border: 1px solid #1e293b;
    border-radius: 6px;
    padding: 4px;
}
QTreeWidget::item:selected {
    background-color: #2563eb;
    color: #ffffff;
}

/* Code Editor */
QPlainTextEdit {
    background-color: #090d16;
    color: #38bdf8;
    font-family: Menlo, Monaco, Consolas, "Courier New", monospace;
    font-size: 12px;
    border: 1px solid #1e293b;
    border-radius: 6px;
    padding: 8px;
}

/* Sliders */
QSlider::groove:horizontal {
    border: none;
    height: 6px;
    background: #1e293b;
    border-radius: 3px;
}
QSlider::sub-page:horizontal {
    background: #38bdf8;
    border-radius: 3px;
}
QSlider::handle:horizontal {
    background: #ffffff;
    border: 2px solid #38bdf8;
    width: 14px;
    margin-top: -4px;
    margin-bottom: -4px;
    border-radius: 7px;
}

/* Progress Bar */
QProgressBar {
    border: 1px solid #1e293b;
    border-radius: 6px;
    text-align: center;
    background-color: #1e293b;
    color: #f8fafc;
    font-weight: 600;
}
QProgressBar::chunk {
    background-color: #38bdf8;
    border-radius: 5px;
}

/* Status Bar */
QStatusBar {
    background-color: #0b0f19;
    color: #94a3b8;
    border-top: 1px solid #1e293b;
}

/* ScrollBars */
QScrollBar:vertical {
    background: #06090f;
    width: 8px;
    margin: 0;
}
QScrollBar::handle:vertical {
    background: #334155;
    min-height: 20px;
    border-radius: 4px;
}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
    height: 0px;
}
"""

if QT_BACKEND is not None:
    class QtLoopWindow:
        """
        Native PyQt6 / PySide6 Window Implementation supporting complex UI layouts,
        data grids, code editors, KPI stat strips, and declarative building.
        """
        def __init__(self, title="Looping Qt App", width=860, height=620):
            self.app = QApplication.instance() or QApplication(sys.argv)
            self.window = QMainWindow()
            self.window.setWindowTitle(title)
            self.window.resize(width, height)

            # Central Widget & Main Layout
            self.central = QWidget()
            self.window.setCentralWidget(self.central)
            self.layout = QVBoxLayout(self.central)
            self.layout.setContentsMargins(16, 16, 16, 16)
            self.layout.setSpacing(10)

            # Apply QSS
            self.window.setStyleSheet(COKI_QSS_STYLESHEET)

            # State Registry
            self.state = {}
            self.status_bar = None

        # ==========================================
        # Header & Cards
        # ==========================================
        def add_header(self, title, subtitle="", badge=""):
            hdr_widget = QWidget()
            hdr_layout = QVBoxLayout(hdr_widget)
            hdr_layout.setContentsMargins(0, 0, 0, 8)
            hdr_layout.setSpacing(2)

            top_row = QWidget()
            top_layout = QHBoxLayout(top_row)
            top_layout.setContentsMargins(0, 0, 0, 0)

            title_lbl = QLabel(title)
            title_lbl.setStyleSheet("font-size: 18px; font-weight: bold; color: #f8fafc;")
            top_layout.addWidget(title_lbl)

            if badge:
                badge_lbl = QLabel(f" {badge} ")
                badge_lbl.setStyleSheet("background-color: #38bdf8; color: #06090f; font-weight: bold; font-size: 10px; border-radius: 4px; padding: 2px 6px;")
                top_layout.addWidget(badge_lbl)

            top_layout.addStretch()
            hdr_layout.addWidget(top_row)

            if subtitle:
                sub_lbl = QLabel(subtitle)
                sub_lbl.setStyleSheet("font-size: 11px; color: #94a3b8;")
                hdr_layout.addWidget(sub_lbl)

            self.layout.addWidget(hdr_widget)
            return hdr_widget

        def add_card(self, title=None, subtitle=None, parent_layout=None):
            card = QFrame()
            card.setStyleSheet("QFrame { background-color: #131b2e; border: 1px solid #1e293b; border-radius: 8px; }")
            card_layout = QVBoxLayout(card)
            card_layout.setContentsMargins(12, 12, 12, 12)
            card_layout.setSpacing(8)

            if title:
                t_lbl = QLabel(title)
                t_lbl.setStyleSheet("font-size: 13px; font-weight: bold; color: #f8fafc; border: none; background: transparent;")
                card_layout.addWidget(t_lbl)
            if subtitle:
                s_lbl = QLabel(subtitle)
                s_lbl.setStyleSheet("font-size: 10px; color: #94a3b8; border: none; background: transparent;")
                card_layout.addWidget(s_lbl)

            target = parent_layout or self.layout
            target.addWidget(card)
            card.content_layout = card_layout
            return card

        # ==========================================
        # Tabs, Splitters & Scroll Areas
        # ==========================================
        def add_tabs(self, parent_layout=None):
            tabs = QTabWidget()
            target = parent_layout or self.layout
            target.addWidget(tabs)
            return tabs

        def add_tab(self, tab_widget, title):
            tab_page = QWidget()
            tab_layout = QVBoxLayout(tab_page)
            tab_layout.setContentsMargins(12, 12, 12, 12)
            tab_widget.addTab(tab_page, title)
            tab_page.content_layout = tab_layout
            return tab_page

        def add_splitter(self, orientation="horizontal", parent_layout=None):
            qt_orient = Qt.Orientation.Horizontal if orientation == "horizontal" else Qt.Orientation.Vertical
            splitter = QSplitter(qt_orient)
            splitter.setStyleSheet("QSplitter::handle { background-color: #1e293b; }")
            target = parent_layout or self.layout
            target.addWidget(splitter)
            return splitter

        def add_scroll_area(self, parent_layout=None):
            scroll = QScrollArea()
            scroll.setWidgetResizable(True)
            scroll.setStyleSheet("QScrollArea { border: none; background: transparent; }")
            content = QWidget()
            content_layout = QVBoxLayout(content)
            scroll.setWidget(content)
            target = parent_layout or self.layout
            target.addWidget(scroll)
            scroll.content_layout = content_layout
            return scroll

        # ==========================================
        # Complex Components: Metrics Strip, Table, Tree, Code Editor
        # ==========================================
        def add_metrics_strip(self, metrics: list, parent_layout=None):
            """metrics: [{'title': 'CPU', 'value': '4.2%', 'badge': 'LOW', 'accent': '#38bdf8'}]"""
            row = QWidget()
            row_layout = QHBoxLayout(row)
            row_layout.setContentsMargins(0, 0, 0, 0)
            row_layout.setSpacing(8)

            for m in metrics:
                card = QFrame()
                card.setStyleSheet("QFrame { background-color: #131b2e; border: 1px solid #1e293b; border-radius: 8px; }")
                c_lay = QVBoxLayout(card)
                c_lay.setContentsMargins(10, 8, 10, 8)

                top_w = QWidget()
                top_lay = QHBoxLayout(top_w)
                top_lay.setContentsMargins(0, 0, 0, 0)

                t_lbl = QLabel(m.get("title", ""))
                t_lbl.setStyleSheet("font-size: 10px; font-weight: bold; color: #94a3b8; border: none; background: transparent;")
                top_lay.addWidget(t_lbl)

                if "badge" in m:
                    b_lbl = QLabel(m["badge"])
                    accent = m.get("accent", "#10b981")
                    b_lbl.setStyleSheet(f"font-size: 8px; font-weight: bold; color: {accent}; background: #0f172a; border-radius: 3px; padding: 1px 4px; border: 1px solid #1e293b;")
                    top_lay.addWidget(b_lbl)

                c_lay.addWidget(top_w)

                accent_color = m.get("accent", "#38bdf8")
                v_lbl = QLabel(m.get("value", "0"))
                v_lbl.setStyleSheet(f"font-size: 16px; font-weight: bold; color: {accent_color}; border: none; background: transparent;")
                c_lay.addWidget(v_lbl)

                row_layout.addWidget(card)

            target = parent_layout or self.layout
            target.addWidget(row)
            return row

        def add_table(self, headers: list, rows: list = None, parent_layout=None, on_select=None):
            table = QTableWidget()
            table.setColumnCount(len(headers))
            table.setHorizontalHeaderLabels(headers)
            table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
            table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
            table.setSortingEnabled(True)

            if rows:
                table.setRowCount(len(rows))
                for r_idx, row in enumerate(rows):
                    for c_idx, val in enumerate(row):
                        table.setItem(r_idx, c_idx, QTableWidgetItem(str(val)))

            if on_select:
                def _handle():
                    sel = table.selectedItems()
                    if sel:
                        row_vals = [table.item(sel[0].row(), c).text() for c in range(table.columnCount())]
                        on_select(row_vals)
                table.itemSelectionChanged.connect(_handle)

            target = parent_layout or self.layout
            target.addWidget(table)
            return table

        def add_tree(self, hierarchy_dict: dict, parent_layout=None, on_select=None):
            tree = QTreeWidget()
            tree.setHeaderHidden(True)

            def _populate(node, parent_item=None):
                for k, v in node.items():
                    item = QTreeWidgetItem([str(k)])
                    if parent_item:
                        parent_item.addChild(item)
                    else:
                        tree.addTopLevelItem(item)

                    if isinstance(v, dict):
                        _populate(v, item)
                    elif isinstance(v, list):
                        for el in v:
                            item.addChild(QTreeWidgetItem([str(el)]))
                    else:
                        item.addChild(QTreeWidgetItem([f"{k}: {v}"]))

            _populate(hierarchy_dict)
            tree.expandAll()

            if on_select:
                tree.itemClicked.connect(lambda item, col: on_select(item.text(0)))

            target = parent_layout or self.layout
            target.addWidget(tree)
            return tree

        def add_code_editor(self, initial_text="", language="loop", height=180, parent_layout=None):
            box = QFrame()
            box.setStyleSheet("QFrame { background-color: #0b0f19; border: 1px solid #1e293b; border-radius: 8px; }")
            lay = QVBoxLayout(box)
            lay.setContentsMargins(6, 6, 6, 6)

            top = QWidget()
            top_lay = QHBoxLayout(top)
            top_lay.setContentsMargins(4, 2, 4, 2)
            lbl = QLabel(f"EDITOR ({language.upper()})")
            lbl.setStyleSheet("font-size: 10px; font-weight: bold; color: #38bdf8; border: none; background: transparent;")
            top_lay.addWidget(lbl)
            top_lay.addStretch()

            editor = QPlainTextEdit()
            editor.setPlainText(initial_text)
            editor.setMinimumHeight(height)

            copy_btn = QPushButton("Copy")
            copy_btn.setStyleSheet("padding: 3px 8px; font-size: 10px; background-color: #1e293b; color: #f8fafc;")
            copy_btn.clicked.connect(lambda: (QApplication.clipboard().setText(editor.toPlainText()), self.show_toast("Copied code to clipboard!")))
            top_lay.addWidget(copy_btn)

            lay.addWidget(top)
            lay.addWidget(editor)

            target = parent_layout or self.layout
            target.addWidget(box)

            editor.get_text = lambda: editor.toPlainText().strip()
            editor.set_text = lambda t: editor.setPlainText(t)
            return editor

        # ==========================================
        # Form Controls
        # ==========================================
        def add_input(self, label="", placeholder="", default="", name=None, parent_layout=None, on_change=None):
            target = parent_layout or self.layout
            if label:
                lbl = QLabel(label)
                lbl.setStyleSheet("font-size: 11px; font-weight: bold; color: #94a3b8;")
                target.addWidget(lbl)

            inp = QLineEdit(default)
            if placeholder:
                inp.setPlaceholderText(placeholder)
            if on_change:
                inp.textChanged.connect(on_change)
            if name:
                self.state[name] = inp

            inp.get_value = lambda: inp.text()
            inp.set_value = lambda v: inp.setText(str(v))
            target.addWidget(inp)
            return inp

        def add_combobox(self, label="", options=None, default=None, name=None, parent_layout=None, on_change=None):
            target = parent_layout or self.layout
            if label:
                lbl = QLabel(label)
                lbl.setStyleSheet("font-size: 11px; font-weight: bold; color: #94a3b8;")
                target.addWidget(lbl)

            combo = QComboBox()
            opts = options or []
            combo.addItems(opts)
            if default and default in opts:
                combo.setCurrentText(default)
            if on_change:
                combo.currentTextChanged.connect(on_change)
            if name:
                self.state[name] = combo

            combo.get_value = lambda: combo.currentText()
            combo.set_value = lambda v: combo.setCurrentText(str(v))
            target.addWidget(combo)
            return combo

        def add_slider(self, label="", min_val=0, max_val=100, default=50, name=None, parent_layout=None, on_change=None):
            target = parent_layout or self.layout
            top = QWidget()
            top_lay = QHBoxLayout(top)
            top_lay.setContentsMargins(0, 0, 0, 0)

            if label:
                lbl = QLabel(label)
                lbl.setStyleSheet("font-size: 11px; font-weight: bold; color: #94a3b8;")
                top_lay.addWidget(lbl)

            val_lbl = QLabel(str(default))
            val_lbl.setStyleSheet("font-size: 11px; font-weight: bold; color: #38bdf8;")
            top_lay.addWidget(val_lbl)
            target.addWidget(top)

            slider = QSlider(Qt.Orientation.Horizontal)
            slider.setRange(min_val, max_val)
            slider.setValue(default)

            def _handle(v):
                val_lbl.setText(str(v))
                if on_change:
                    on_change(v)

            slider.valueChanged.connect(_handle)
            if name:
                self.state[name] = slider

            slider.get_value = lambda: slider.value()
            slider.set_value = lambda v: slider.setValue(int(v))
            target.addWidget(slider)
            return slider

        def add_progress_bar(self, label="", max_val=100, parent_layout=None):
            target = parent_layout or self.layout
            if label:
                lbl = QLabel(label)
                lbl.setStyleSheet("font-size: 11px; font-weight: bold; color: #94a3b8;")
                target.addWidget(lbl)

            prog = QProgressBar()
            prog.setMaximum(max_val)
            prog.setValue(0)
            target.addWidget(prog)

            prog.set_progress = lambda v: prog.setValue(int(v))
            return prog

        def add_toggle(self, label="", default=False, name=None, parent_layout=None, on_change=None):
            target = parent_layout or self.layout
            chk = QCheckBox(label)
            chk.setChecked(default)
            chk.setStyleSheet("QCheckBox { color: #f8fafc; font-size: 12px; } QCheckBox::indicator { width: 16px; height: 16px; border: 1px solid #334155; border-radius: 4px; background: #1e293b; } QCheckBox::indicator:checked { background: #38bdf8; border-color: #38bdf8; }")
            if on_change:
                chk.stateChanged.connect(lambda s: on_change(s == Qt.CheckState.Checked.value))
            if name:
                self.state[name] = chk

            chk.get_value = lambda: chk.isChecked()
            chk.set_value = lambda v: chk.setChecked(bool(v))
            target.addWidget(chk)
            return chk

        def add_button(self, text, callback=None, variant="primary", parent_layout=None):
            btn = QPushButton(text)
            styles = {
                "primary": "background-color: #2563eb; color: #ffffff;",
                "accent": "background-color: #38bdf8; color: #06090f; font-weight: bold;",
                "secondary": "background-color: #1e293b; color: #f8fafc;",
                "danger": "background-color: #ef4444; color: #ffffff;"
            }
            btn.setStyleSheet(styles.get(variant, styles["primary"]))
            if callback:
                btn.clicked.connect(callback)
            target = parent_layout or self.layout
            target.addWidget(btn)
            return btn

        # ==========================================
        # Status Bar, Toasts & Alerts
        # ==========================================
        def add_status_bar(self, text="Ready", status_type="ready"):
            bar = QStatusBar()
            self.window.setStatusBar(bar)
            colors = {"ready": "#10b981", "working": "#f59e0b", "error": "#ef4444"}
            c = colors.get(status_type, "#10b981")
            dot = QLabel("● ")
            dot.setStyleSheet(f"color: {c}; font-size: 11px;")
            lbl = QLabel(text)
            lbl.setStyleSheet("color: #94a3b8; font-size: 11px;")
            bar.addWidget(dot)
            bar.addWidget(lbl)
            self.status_bar = bar
            return bar

        def show_toast(self, message, duration=2500):
            lbl = QLabel(f"  {message}  ", self.window)
            lbl.setStyleSheet("background-color: #131b2e; color: #38bdf8; border: 1px solid #38bdf8; border-radius: 6px; padding: 6px 12px; font-weight: bold;")
            lbl.adjustSize()
            lbl.move((self.window.width() - lbl.width()) // 2, 40)
            lbl.show()
            QTimer.singleShot(duration, lbl.deleteLater)

        def show_alert(self, title, msg, level="info"):
            if level == "error":
                QMessageBox.critical(self.window, title, msg)
            elif level == "warning":
                QMessageBox.warning(self.window, title, msg)
            else:
                QMessageBox.information(self.window, title, msg)

        # ==========================================
        # State & Declarative Spec
        # ==========================================
        def get_state(self, name=None):
            if name:
                w = self.state.get(name)
                return w.get_value() if hasattr(w, "get_value") else None
            return {k: w.get_value() for k, w in self.state.items() if hasattr(w, "get_value")}

        def build_from_spec(self, spec):
            if isinstance(spec, str):
                spec = json.loads(spec)
            if "header" in spec:
                h = spec["header"]
                self.add_header(h.get("title", ""), h.get("subtitle", ""), h.get("badge", ""))
            if "metrics" in spec:
                self.add_metrics_strip(spec["metrics"])
            if "tabs" in spec:
                tabs = self.add_tabs()
                for t in spec["tabs"]:
                    tab = self.add_tab(tabs, t.get("title", "Tab"))
                    for c in t.get("components", []):
                        self._build_comp(c, tab.content_layout)
            if "components" in spec:
                for c in spec["components"]:
                    self._build_comp(c, self.layout)
            if "status_bar" in spec:
                self.add_status_bar(spec["status_bar"].get("text", "Ready"), spec["status_bar"].get("status", "ready"))

        def _build_comp(self, comp, target_layout):
            ctype = comp.get("type")
            if ctype == "table":
                self.add_table(comp.get("headers", []), comp.get("rows", []), parent_layout=target_layout)
            elif ctype == "editor":
                self.add_code_editor(comp.get("text", ""), parent_layout=target_layout)
            elif ctype == "input":
                self.add_input(comp.get("label", ""), default=comp.get("default", ""), name=comp.get("name"), parent_layout=target_layout)
            elif ctype == "slider":
                self.add_slider(comp.get("label", ""), min_val=comp.get("min", 0), max_val=comp.get("max", 100), default=comp.get("default", 50), name=comp.get("name"), parent_layout=target_layout)
            elif ctype == "button":
                self.add_button(comp.get("text", "Button"), variant=comp.get("variant", "primary"), parent_layout=target_layout)

        def run(self):
            self.window.show()
            return self.app.exec() if hasattr(self.app, "exec") else self.app.exec_()

else:
    # Graceful fallback: Delegate to loop_gui_tk when PyQt6 / PySide6 is not present on host
    # Auto-resolve sibling or installed loop-gui-tk paths
    _curr_dir = os.path.dirname(os.path.abspath(__file__))
    _cand_dirs = [
        os.path.join(_curr_dir, "../loop-gui-tk"),
        os.path.expanduser("~/.smiledev/modules/loop-gui-tk"),
        os.path.abspath("./modules/loop-gui-tk")
    ]
    for _cd in _cand_dirs:
        if os.path.isdir(_cd) and _cd not in sys.path:
            sys.path.insert(0, _cd)

    try:
        from loop_gui_tk import LoopTkApp as _FallbackTkApp
    except ImportError:
        try:
            # Relative import fallback
            from .loop_gui_tk import LoopTkApp as _FallbackTkApp
        except Exception:
            _FallbackTkApp = None

    class QtLoopWindow:
        """
        Graceful Fallback Window: Automatically invoked when PyQt6/PySide6 is not installed.
        Provides diagnostic logging and delegates seamlessly to Tkinter with the same rich API.
        """
        def __init__(self, title="Looping Qt App (Tkinter Bridge)", width=860, height=620):
            sys.stderr.write(
                "[loop-gui-qt] Notice: Neither PyQt6 nor PySide6 was detected.\n"
                "               Install with: 'pip install PyQt6' or 'pip install PySide6'.\n"
                "               Gracefully activating Coki Studios Tkinter Bridge...\n"
            )
            if _FallbackTkApp:
                self._tk = _FallbackTkApp(title=title, width=width, height=height)
            else:
                self._tk = None
                sys.stderr.write("[loop-gui-qt] Error: Neither Qt nor Tkinter fallback available.\n")

        def add_header(self, *args, **kwargs):
            return self._tk.add_header(*args, **kwargs) if self._tk else None

        def add_card(self, *args, **kwargs):
            return self._tk.add_card(*args, **kwargs) if self._tk else None

        def add_tabs(self, *args, **kwargs):
            return self._tk.add_notebook(*args, **kwargs) if self._tk else None

        def add_tab(self, tabs, title):
            return self._tk.add_tab(tabs, title) if self._tk else None

        def add_metrics_strip(self, metrics, *args, **kwargs):
            return self._tk.add_metrics_row(metrics, *args, **kwargs) if self._tk else None

        def add_table(self, headers, rows=None, on_select=None, *args, **kwargs):
            return self._tk.add_table(headers, rows=rows, on_select=on_select) if self._tk else None

        def add_tree(self, hierarchy, *args, **kwargs):
            return self._tk.add_tree(hierarchy, *args, **kwargs) if self._tk else None

        def add_code_editor(self, text="", language="loop", *args, **kwargs):
            return self._tk.add_code_editor(text, language=language) if self._tk else None

        def add_input(self, *args, **kwargs):
            return self._tk.add_input(*args, **kwargs) if self._tk else None

        def add_combobox(self, *args, **kwargs):
            return self._tk.add_combobox(*args, **kwargs) if self._tk else None

        def add_slider(self, *args, **kwargs):
            return self._tk.add_slider(*args, **kwargs) if self._tk else None

        def add_progress_bar(self, *args, **kwargs):
            return self._tk.add_progress_bar(*args, **kwargs) if self._tk else None

        def add_toggle(self, *args, **kwargs):
            return self._tk.add_toggle(*args, **kwargs) if self._tk else None

        def add_button(self, *args, **kwargs):
            return self._tk.add_button(*args, **kwargs) if self._tk else None

        def add_status_bar(self, *args, **kwargs):
            return self._tk.add_status_bar(*args, **kwargs) if self._tk else None

        def show_toast(self, msg, *args, **kwargs):
            if self._tk: self._tk.show_toast(msg)

        def show_alert(self, title, msg, *args, **kwargs):
            if self._tk: self._tk.show_modal(title, msg)

        def build_from_spec(self, spec):
            if self._tk: self._tk.build_from_spec(spec)

        def get_state(self, name=None):
            return self._tk.get_state(name) if self._tk else {}

        def run(self):
            if self._tk:
                return self._tk.run()


# Universal Aliases & Init
LoopQtApp = QtLoopWindow

def init_module(vars_dict=None):
    title = (vars_dict or {}).get("title", "Looping Qt App")
    w = (vars_dict or {}).get("width", 860)
    h = (vars_dict or {}).get("height", 620)
    return QtLoopWindow(title=title, width=w, height=h)


if __name__ == "__main__":
    print(f"[loop-gui-qt] Initializing module (Detected Backend: {QT_BACKEND or 'Tkinter Bridge'})...")
    app = QtLoopWindow("Looping Qt Complex UI Demo", 860, 620)
    app.add_header("Looping Qt UI Engine", subtitle="PyQt6 / PySide6 with Tkinter Fallback Bridge", badge="Qt6 / APU")
    app.add_metrics_strip([
        {"title": "BACKEND", "value": QT_BACKEND or "TkBridge", "badge": "ACTIVE", "accent": "#38bdf8"},
        {"title": "FRAME RATE", "value": "120 FPS", "badge": "VSYNC", "accent": "#10b981"},
        {"title": "HEAP USAGE", "value": "18.4 MB", "badge": "LEAN", "accent": "#818cf8"}
    ])
    tabs = app.add_tabs()
    tab1 = app.add_tab(tabs, "Telemetry")
    app.add_table(["ID", "Target", "Status"], [["01", "Worker-US-East", "Online"], ["02", "D1-Replica", "Active"]], parent_layout=tab1)

    tab2 = app.add_tab(tabs, "Editor")
    app.add_code_editor("// Looping Qt Editor\nval x = 100\nprint(x)", parent_layout=tab2)

    app.add_status_bar("Qt Engine Initialized", "ready")
    print("[loop-gui-qt] Self-test successfully loaded.")
    if hasattr(app, "_tk") and app._tk:
        app._tk.root.after(500, app._tk.root.destroy)
        app.run()
    print("[loop-gui-qt] Self-test complete.")
