from __future__ import annotations
import sys
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, QProcess
from core.process import ProcessRunner

class KenBurnsBridge(QObject):
    """Minimal bridge to run ken_burns_reel in a separate process."""

    output = Signal(str)
    finished = Signal(int)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._runner = ProcessRunner()
        self._runner.output.connect(self.output)
        self._runner.finished.connect(self.finished)

    @Slot(str)
    def run(self, args: str) -> None:
        cmd = f'"{sys.executable}" -m ken_burns_reel {args}'.strip()
        self._runner.run(cmd)

    @Slot()
    def stop(self) -> None:
        proc = self._runner.proc
        if proc and proc.state() != QProcess.NotRunning:
            proc.kill()
            proc.waitForFinished(1000)

    @Slot(str, str, result=bool)
    def savePreset(self, filename: str, args: str) -> bool:
        """Save given args string to a JSON file near executable.

        Returns True on success.
        """
        try:
            import json
            base = Path(sys.argv[0]).resolve().parent
            path = base / filename
            tmp = path.with_suffix('.tmp')
            tmp.write_text(json.dumps({"args": args}))
            tmp.replace(path)
            return True
        except Exception:
            return False
