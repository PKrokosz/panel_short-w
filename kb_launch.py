
import os, sys, runpy
try:
    import imageio_ffmpeg as i
    os.environ["IMAGEIO_FFMPEG_EXE"] = i.get_ffmpeg_exe()
except Exception:
    pass
TESS_EXE = r"C:\Progra~1\Tesseract-OCR\tesseract.exe"
os.environ["TESSERACT_PATH"] = TESS_EXE
tess_dir = r"C:\Program Files\Tesseract-OCR"
if os.path.isdir(tess_dir):
    os.environ["PATH"] = tess_dir + os.pathsep + os.environ.get("PATH","")
try:
    import pytesseract; pytesseract.pytesseract.tesseract_cmd = TESS_EXE
except Exception:
    pass
IMAGES_DIR = r"C:\Users\admin\Downloads\video"
sys.argv = ["ken_burns_reel", IMAGES_DIR]
runpy.run_module("ken_burns_reel", run_name="__main__", alter_sys=True)
