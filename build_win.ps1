
# Build Windows exe with PyInstaller
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install pyinstaller
pyinstaller app.py -n OverlayRouter -w ^
  --hidden-import PySide6.QtQml --hidden-import PySide6.QtGui --hidden-import PySide6.QtWidgets ^
  --collect-all PySide6 --collect-submodules PySide6 ^
  --add-data "ui;ui" --add-data "assets;assets" --add-data "config;config"
