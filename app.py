
import os, sys, threading
from pathlib import Path

# HiDPI + Basic style (customizable controls)
os.environ.setdefault("QT_ENABLE_HIGHDPI_SCALING", "1")
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

from PySide6.QtCore import QObject, Signal, Slot, QUrl, Qt, QTimer
from PySide6.QtGui import QIcon, QAction
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu

# Optional global hotkey via 'keyboard' (pure Python, Windows-friendly)
try:
    import keyboard
except Exception:
    keyboard = None

from core.config import load_actions
from core.process import ProcessRunner
from core.bincheck import preflight

APP_DIR = Path(__file__).resolve().parent

# ---- Windows Acrylic/Mica (system blur) ----
from ctypes import Structure, c_int, c_void_p, sizeof, byref, windll
from ctypes.wintypes import HWND, DWORD

ACCENT_DISABLED = 0
ACCENT_ENABLE_BLURBEHIND = 3
ACCENT_ENABLE_ACRYLICBLURBEHIND = 4
WCA_ACCENT_POLICY = 19

class ACCENT_POLICY(Structure):
    _fields_ = [
        ("AccentState", c_int),
        ("AccentFlags", c_int),
        ("GradientColor", DWORD),  # ARGB
        ("AnimationId", c_int),
    ]

class WINDOWCOMPOSITIONATTRIBDATA(Structure):
    _fields_ = [
        ("Attribute", c_int),
        ("Data", c_void_p),
        ("SizeOfData", c_int),
    ]

def _make_argb(a, r, g, b):
    return (a << 24) | (b << 16) | (g << 8) | r

def set_accent(hwnd: int, state: int, opacity=0xEE, tint=(26,26,26)):
    accent = ACCENT_POLICY()
    accent.AccentState = state
    accent.AccentFlags = 0
    r, g, b = tint
    accent.GradientColor = _make_argb(opacity, r, g, b)

    data = WINDOWCOMPOSITIONATTRIBDATA()
    data.Attribute = WCA_ACCENT_POLICY
    data.SizeOfData = sizeof(accent)
    data.Data = c_void_p(c_void_p.from_buffer(accent).value)

    SWCA = windll.user32.SetWindowCompositionAttribute
    SWCA.argtypes = [HWND, c_void_p]
    SWCA.restype = c_int
    SWCA(HWND(hwnd), byref(data))

def enable_blur(window, acrylic=True):
    try:
        hwnd = int(window.winId())
        try:
            set_accent(hwnd, ACCENT_ENABLE_ACRYLICBLURBEHIND if acrylic else ACCENT_ENABLE_BLURBEHIND)
        except Exception:
            set_accent(hwnd, ACCENT_ENABLE_BLURBEHIND)
    except Exception as e:
        print(f"[WARN] Blur enable failed: {e}")

# ---- App Bridge & UI ----
class Bridge(QObject):
    log = Signal(str)
    notify = Signal(str)
    actionsChanged = Signal()

    def __init__(self, runner: ProcessRunner, engine: QQmlApplicationEngine, parent=None):
        super().__init__(parent)
        self.runner = runner
        self._click_through = False
        self._actions = []
        self._engine = engine

    @Slot(str, result=bool)
    def runAction(self, action_id: str) -> bool:
        action = next((a for a in self._actions if a["id"] == action_id), None)
        if not action:
            self.log.emit(f"[ERR] Action '{action_id}' not found")
            return False
        cmd = action["command"]
        self.log.emit(f"[RUN] {cmd}")
        self.runner.run(cmd)
        return True

    @Slot()
    def toggleClickThrough(self):
        self._click_through = not self._click_through
        win = self._get_window()
        if win:
            win.setFlag(Qt.WindowTransparentForInput, self._click_through)
            win.show()
            state = "ON" if self._click_through else "OFF"
            self.notify.emit(f"Click-through: {state}")

    @Slot()
    def reloadActions(self):
        try:
            self._actions = load_actions(APP_DIR / "config" / "actions.yaml")
            self.actionsChanged.emit()
            self.notify.emit("Actions reloaded")
        except Exception as e:
            self.log.emit(f"[ERR] reload: {e}")

    @Slot(result='QVariant')
    def getActions(self):
        return self._actions

    def _get_window(self):
        if self._engine.rootObjects():
            return self._engine.rootObjects()[0]
        return None


def create_tray(app: QApplication, bridge: Bridge, win):
    tray = QSystemTrayIcon(QIcon(str(APP_DIR / "assets" / "icon.png")))
    menu = QMenu()

    act_reload = QAction("Reload actions.yaml", tray)
    act_reload.triggered.connect(bridge.reloadActions)
    menu.addAction(act_reload)

    act_panic = QAction("PANIC: regain input", tray)
    def _panic():
        if win:
            win.setFlag(Qt.WindowTransparentForInput, False)
            win.show()
            win.raise_()
            win.requestActivate()
        bridge.notify.emit("Click-through: OFF (panic)")
    act_panic.triggered.connect(_panic)
    menu.addAction(act_panic)

    act_blur = QAction("Toggle Acrylic/Blur", tray)
    act_blur.setCheckable(True)
    act_blur.setChecked(True)
    def _toggle_blur(checked):
        enable_blur(win, acrylic=checked)
        bridge.notify.emit(f"Blur mode: {'Acrylic' if checked else 'Classic'}")
    act_blur.triggered.connect(_toggle_blur)
    menu.addAction(act_blur)

    menu.addSeparator()

    act_preflight = QAction("Run pre-flight", tray)
    def _run_preflight():
        msgs = preflight(bridge.getActions())
        for m in msgs:
            bridge.notify.emit(m)
    act_preflight.triggered.connect(_run_preflight)
    menu.addAction(act_preflight)

    menu.addSeparator()

    act_quit = QAction("Quit", tray)
    act_quit.triggered.connect(app.quit)
    menu.addAction(act_quit)

    tray.setContextMenu(menu)
    tray.setToolTip("Overlay Router")
    tray.show()
    return tray

def setup_keyboard_hotkey(win, bridge):
    if keyboard is None:
        bridge.log.emit("[INFO] 'keyboard' not installed; panic hotkey disabled")
        return None

    # Register Alt+Shift+P in a background thread to not block Qt loop
    def _worker():
        try:
            keyboard.add_hotkey("alt+shift+p", lambda: _panic_action())
            keyboard.wait()  # block thread until program exit
        except Exception as e:
            bridge.log.emit(f"[WARN] keyboard hotkey error: {e}")

    def _panic_action():
        if win:
            win.setFlag(Qt.WindowTransparentForInput, False)
            win.show()
            win.raise_()
            win.requestActivate()
        bridge.notify.emit("Click-through: OFF (panic hotkey)")

    t = threading.Thread(target=_worker, daemon=True)
    t.start()
    bridge.notify.emit("Panic hotkey active (Alt+Shift+P)")
    return t

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationDisplayName("Overlay Router")
    app.setWindowIcon(QIcon(str(APP_DIR / "assets" / "icon.png")))

    engine = QQmlApplicationEngine()

    runner = ProcessRunner()
    bridge = Bridge(runner, engine)

    runner.output.connect(bridge.log)
    runner.finished.connect(lambda code: bridge.notify.emit(f"Process finished ({code})"))

    engine.rootContext().setContextProperty("Bridge", bridge)

    bridge._actions = load_actions(APP_DIR / "config" / "actions.yaml")

    engine.load(QUrl.fromLocalFile(str(APP_DIR / "ui" / "Main.qml")))
    if not engine.rootObjects():
        sys.exit("Failed to load QML")

    win = engine.rootObjects()[0]
    enable_blur(win, acrylic=True)

    tray = create_tray(app, bridge, win)
    hk_thread = setup_keyboard_hotkey(win, bridge)

    QTimer.singleShot(300, lambda: [bridge.notify.emit(m) for m in preflight(bridge.getActions())])

    sys.exit(app.exec())
