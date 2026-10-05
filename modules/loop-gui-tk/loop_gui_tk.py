# loop-gui-tk: Tkinter Native Interop for Looping
import os, sys, tkinter as tk
from tkinter import ttk, messagebox

class TkLoopWindow:
    def __init__(self, title="Looping App", width=600, height=400):
        self.root = tk.Tk()
        self.root.title(title)
        self.root.geometry(f"{width}x{height}")
        self.root.configure(bg="#06090f")
        self.style = ttk.Style()
        try: self.style.theme_use("clam")
        except: pass

    def add_label(self, text, color="#00f5d4", size=14):
        lbl = tk.Label(self.root, text=text, fg=color, bg="#06090f", font=("Helvetica", size, "bold"))
        lbl.pack(pady=10)
        return lbl

    def add_button(self, text, command=None):
        btn = tk.Button(self.root, text=text, command=command, bg="#6366f1", fg="#ffffff", font=("Helvetica", 11, "bold"), padx=12, pady=6)
        btn.pack(pady=8)
        return btn

    def show_alert(self, title, msg):
        messagebox.showinfo(title, msg)

    def run(self):
        self.root.mainloop()
