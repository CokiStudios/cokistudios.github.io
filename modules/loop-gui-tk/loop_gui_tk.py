# loop-gui-tk: Tkinter Native Interop for Looping
import tkinter as tk
from tkinter import ttk, messagebox

class LoopTkApp:
    def __init__(self, title="Looping App", width=600, height=400):
        self.root = tk.Tk()
        self.root.title(title)
        self.root.geometry(f"{width}x{height}")
        self.root.configure(bg="#0f172a")

    def run(self):
        self.root.mainloop()

def init_module(vars_dict=None):
    return LoopTkApp()
