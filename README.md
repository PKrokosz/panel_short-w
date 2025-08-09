
# Overlay Router (PySide6 + Acrylic)

Szklany panel nad pulpitem do odpalania lokalnych skryptów (akcje z YAML), blur Acrylic, tray, panic-hotkey.

## Szybki start
```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

## Hotkey
Globalny: **Alt+Shift+P** (wymaga `keyboard` — już w `requirements.txt`).

## Konfiguracja akcji
Edytuj `config/actions.yaml`. Obsługiwane pola:

- `label` – tekst na przycisku
- `command` – polecenie shell
- `cwd` *(opcjonalnie)* – katalog roboczy dla akcji

Po zmianie w YAML kliknij **Reload** w panelu.

## Build EXE (Windows)
```powershell
.\build_win.ps1
```
Artefakt pojawi się w `dist/OverlayRouter/OverlayRouter.exe`.

## GitHub Actions
Push do main tworzy artefakt z binarką (Windows). Zobacz `.github/workflows/windows-build.yml`.
