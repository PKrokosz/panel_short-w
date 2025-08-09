
import os, shutil, subprocess, shlex

def _version_ok(cmd: list[str]) -> tuple[bool, str]:
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        ok = out.returncode == 0; text = (out.stdout or "") + (out.stderr or "")
        return ok, text.strip()[:400]
    except Exception as e:
        return False, f"ERR: {e}"

def preflight(actions: list[dict]) -> list[str]:
    msgs = []
    for a in actions:
        cmd = a.get("command","")
        try: tokens = shlex.split(cmd, posix=False)
        except Exception: tokens = cmd.split()
        exe = tokens[0] if tokens else ""; exe_l = exe.lower()

        if exe_l.endswith("tesseract.exe"):
            if os.path.exists(exe):
                ok, text = _version_ok([exe, "--version"])
                msgs.append(f"[OK] tesseract (explicit): {text.splitlines()[0] if text else 'version ok'}" if ok else f"[WARN] tesseract (explicit): {text}")
            else:
                msgs.append(f"[FAIL] tesseract path missing: {exe}")
            continue

        if exe_l in ("tesseract","tesseract.exe"):
            if shutil.which("tesseract"):
                ok, text = _version_ok(["tesseract","--version"])
                msgs.append(f"[OK] tesseract: {text.splitlines()[0] if text else 'version ok'}" if ok else f"[WARN] tesseract: {text}")
            else:
                msgs.append("[FAIL] 'tesseract' not found in PATH")
            continue

        if exe_l in ("magick","magick.exe"):
            if shutil.which("magick"):
                ok, text = _version_ok(["magick","-version"])
                msgs.append(f"[OK] magick: {text.splitlines()[0] if text else 'version ok'}" if ok else f"[WARN] magick: {text}")
            else:
                msgs.append("[FAIL] 'magick' not found in PATH")

    seen=set(); uniq=[]; 
    for m in msgs:
        if m not in seen: uniq.append(m); seen.add(m)
    return uniq
