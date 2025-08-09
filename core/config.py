
from __future__ import annotations
from pathlib import Path
import yaml

def load_actions(path: Path):
    data = yaml.safe_load(Path(path).read_text(encoding="utf-8")) or {}
    items = []
    for key, spec in (data.get("actions") or {}).items():
        label = spec.get("label", key); cmd = spec.get("command"); cwd = spec.get("cwd")
        if not cmd: raise ValueError(f"Action '{key}' missing 'command'")
        items.append({"id": key, "label": label, "command": cmd, "cwd": cwd})
    return items
