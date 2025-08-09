
import glob
import os, shutil, subprocess, shlex

def _version_ok(cmd: list[str]) -> tuple[bool, str]:
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        ok = out.returncode == 0
        text = (out.stdout or "") + (out.stderr or "")
        return ok, text.strip()[:400]
    except Exception as e:
        return False, f"ERR: {e}"

def preflight(actions: list[dict]) -> list[str]:
    msgs = []
    # Check explicit executables present in commands
    for a in actions:
        cmd = a.get("command","")
        try:
            tokens = shlex.split(cmd, posix=False)
        except Exception:
            tokens = cmd.split()
        exe = tokens[0] if tokens else ""
        exe_l = exe.lower()

        # Tesseract: absolute exe path
        if exe_l.endswith("tesseract.exe"):
            if os.path.exists(exe):
                ok, text = _version_ok([exe, "--version"])
                msgs.append(f"[OK] tesseract (explicit): {text.splitlines()[0] if text else 'version ok'}" if ok else f"[WARN] tesseract (explicit): {text}")
            else:
                msgs.append(f"[FAIL] tesseract path missing: {exe}")
            continue

        # Tesseract via PATH
        if exe_l == "tesseract":
            if shutil.which("tesseract"):
                ok, text = _version_ok(["tesseract", "--version"])
                msgs.append(f"[OK] tesseract: {text.splitlines()[0] if text else 'version ok'}" if ok else f"[WARN] tesseract: {text}")
            else:
                msgs.append("[FAIL] 'tesseract' not found in PATH")
            continue

        # ImageMagick via PATH
        if exe_l in ("magick", "magick.exe"):
            if shutil.which("magick"):
                ok, text = _version_ok(["magick", "-version"])
                msgs.append(f"[OK] magick: {text.splitlines()[0] if text else 'version ok'}" if ok else f"[WARN] magick: {text}")
            else:
                msgs.append("[FAIL] 'magick' not found in PATH")

    # Deduplicate messages
    seen = set()
    uniq = []
    for m in msgs:
        if m not in seen:
            uniq.append(m); seen.add(m)
    return uniq

def probe_status(actions: list[dict], env: dict | None = None) -> dict:
    env = env or os.environ
    status = {
        "magick": {"state": "unknown", "version": ""},
        "tesseract": {"state": "unknown", "version": ""},
        "ffmpeg": {"state": "unknown", "version": ""},
        "n8n": {"state": "unknown", "version": "not set"},
    }

    # --- ImageMagick ---
    magick_cmd = shutil.which("magick")
    if not magick_cmd:
        pf = "C:/Program Files"
        candidates = glob.glob(os.path.join(pf, "ImageMagick*", "magick.exe"))
        magick_cmd = candidates[0] if candidates else None
    if magick_cmd:
        ok, text = _version_ok([magick_cmd, "-version"])
        status["magick"] = {
            "state": "ok" if ok else "warn",
            "version": text.splitlines()[0] if text else "",
        }
    else:
        status["magick"] = {"state": "fail", "version": ""}

    # --- Tesseract ---
    tess_cmd = shutil.which("tesseract")
    if not tess_cmd:
        tess_cmd = env.get("TESSERACT_PATH")
    if not tess_cmd:
        candidates = [
            "C:/Progra~1/Tesseract-OCR/tesseract.exe",
            "C:/Program Files/Tesseract-OCR/tesseract.exe",
        ]
        for c in candidates:
            if os.path.exists(c):
                tess_cmd = c
                break
    if tess_cmd:
        ok, text = _version_ok([tess_cmd, "--version"])
        status["tesseract"] = {
            "state": "ok" if ok else "warn",
            "version": text.splitlines()[0] if text else "",
        }
    else:
        status["tesseract"] = {"state": "fail", "version": ""}

    # --- ffmpeg ---
    if shutil.which("ffmpeg"):
        ok, text = _version_ok(["ffmpeg", "-version"])
        status["ffmpeg"] = {
            "state": "ok" if ok else "warn",
            "version": text.splitlines()[0] if text else "",
        }
    else:
        status["ffmpeg"] = {"state": "fail", "version": ""}

    # --- n8n ---
    if env.get("N8N_WEBHOOK_PING"):
        status["n8n"] = {"state": "ok", "version": "configured"}
    else:
        status["n8n"] = {"state": "unknown", "version": "not set"}

    return status
