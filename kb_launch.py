
import os, sys, runpy
# Set ffmpeg path from imageio-ffmpeg if available
try:
    import imageio_ffmpeg as i
    os.environ["IMAGEIO_FFMPEG_EXE"] = i.get_ffmpeg_exe()
except Exception:
    pass

# Point to your images directory
IMAGES_DIR = r"C:\Users\admin\Downloads\video"

# Launch the package's __main__
sys.argv = ["ken_burns_reel", IMAGES_DIR]
runpy.run_module("ken_burns_reel", run_name="__main__", alter_sys=True)
