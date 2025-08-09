
from __future__ import annotations
import os
from PySide6.QtCore import QObject, Signal, QProcess

class ProcessRunner(QObject):
    output = Signal(str); finished = Signal(int)
    def __init__(self, parent=None): super().__init__(parent); self.proc=None
    def run(self, command: str, cwd: str | None = None):
        if self.proc and self.proc.state()!=QProcess.NotRunning: self.output.emit("[WARN] Previous process still running"); return
        self.proc = QProcess()
        if cwd: self.proc.setWorkingDirectory(cwd)
        if os.name=="nt":
            comspec = os.environ.get("ComSpec", r"C:\Windows\System32\cmd.exe"); self.proc.setProgram(comspec); self.proc.setArguments(["/C", command])
        else:
            self.proc.setProgram("/bin/sh"); self.proc.setArguments(["-lc", command])
        self.proc.readyReadStandardOutput.connect(lambda: self.output.emit(bytes(self.proc.readAllStandardOutput()).decode(errors="ignore")))
        self.proc.readyReadStandardError.connect(lambda: self.output.emit(bytes(self.proc.readAllStandardError()).decode(errors="ignore")))
        self.proc.finished.connect(lambda code,_=None: self.finished.emit(code)); self.proc.start()
