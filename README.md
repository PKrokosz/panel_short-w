
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

## Ken Burns (opcjonalny moduł)

Funkcjonalność Ken Burns jest w pełni opcjonalna. Aby ją włączyć:

1. Zainstaluj moduł `ken_burns_reel` oraz upewnij się, że `ffmpeg` jest dostępny w `PATH`.
2. Ustaw zmienną środowiskową `KENBURNS_ENABLED=1` przed uruchomieniem aplikacji.

Po spełnieniu warunków w UI pojawi się przycisk **Ken Burns...** otwierający dialog z prostym formularzem uruchamiającym CLI.

Aby wyłączyć moduł, usuń zmienną `KENBURNS_ENABLED` i zrestartuj aplikację.

## Build EXE (Windows)
```powershell
.\build_win.ps1
```
Artefakt pojawi się w `dist/OverlayRouter/OverlayRouter.exe`.

## GitHub Actions
Push do main tworzy artefakt z binarką (Windows). Zobacz `.github/workflows/windows-build.yml`.
