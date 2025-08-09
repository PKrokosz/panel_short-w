# Overlay Router — PySide6 + QML

Półprzezroczysta nakładka na pulpit do odpalania lokalnych skryptów.
Frameless, always-on-top, przyciski z YAML-a, logi procesów, click‑through.

## Instalacja
```bash
python -m venv .venv
# Windows:
. .venv/Scripts/activate
# Linux/macOS:
# source .venv/bin/activate
pip install -r requirements.txt
```

## Uruchomienie
```bash
python app.py
```

## Konfiguracja akcji
Edytuj `config/actions.yaml` — każda akcja ma `label` i `command`.
Po zmianach kliknij **Reload** w UI lub z menu w trayu.

## Wymagania dodatkowe
Jeśli używasz Tesseract / ImageMagick, upewnij się, że masz je w PATH
albo podaj pełne ścieżki w `config/actions.yaml`.
