# loop-gui-qt: PyQt6 / PySide6 Native Interop for Looping
import sys

try:
    from PyQt6.QtWidgets import QApplication, QMainWindow, QLabel, QPushButton, QVBoxLayout, QWidget, QMessageBox
    from PyQt6.QtCore import Qt
    QT_BACKEND = "PyQt6"
except ImportError:
    try:
        from PySide6.QtWidgets import QApplication, QMainWindow, QLabel, QPushButton, QVBoxLayout, QWidget, QMessageBox
        from PySide6.QtCore import Qt
        QT_BACKEND = "PySide6"
    except ImportError:
        QT_BACKEND = None

class QtLoopWindow:
    def __init__(self, title="Looping Qt App", width=640, height=480):
        self.app = QApplication.instance() or QApplication(sys.argv)
        self.window = QMainWindow()
        self.window.setWindowTitle(title)
        self.window.resize(width, height)
        self.central = QWidget()
        self.window.setCentralWidget(self.central)
        self.layout = QVBoxLayout(self.central)
        self.window.setStyleSheet("QMainWindow { background-color: #06090f; } QLabel { color: #00f5d4; font-family: Outfit, sans-serif; font-size: 16px; font-weight: bold; } QPushButton { background-color: #6366f1; color: white; border-radius: 8px; padding: 10px 18px; font-weight: bold; font-size: 13px; } QPushButton:hover { background-color: #4f46e5; }")

    def add_label(self, text):
        lbl = QLabel(text)
        lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.layout.addWidget(lbl)
        return lbl

    def add_button(self, text, callback=None):
        btn = QPushButton(text)
        if callback: btn.clicked.connect(callback)
        self.layout.addWidget(btn)
        return btn

    def show_alert(self, title, msg):
        QMessageBox.information(self.window, title, msg)

    def run(self):
        self.window.show()
        return self.app.exec()
