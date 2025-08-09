#!/usr/bin/env python
import argparse
import json
import os
import sys
import urllib.request
import urllib.parse

try:
    import pyperclip
except Exception:  # optional
    pyperclip = None


def parse_kv(items):
    out = {}
    for it in items:
        if "=" in it:
            k, v = it.split("=", 1)
        else:
            k, v = it, ""
        out[k] = v
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--url", required=True)
    p.add_argument("--method", default="POST")
    p.add_argument("--header", action="append", default=[])
    p.add_argument("--data", action="append", default=[])
    p.add_argument("--file", action="append", default=[])
    p.add_argument("--clipboard", action="store_true")
    args = p.parse_args()

    headers = parse_kv(args.header)
    data = parse_kv(args.data)

    if args.clipboard and pyperclip:
        try:
            data.setdefault("clipboard", pyperclip.paste())
        except Exception:
            pass

    method = args.method.upper()
    files = {}
    for f in args.file:
        if "=" in f:
            name, path = f.split("=", 1)
        else:
            name, path = "file", f
        files[name] = path

    if files:
        boundary = "----n8n-trigger"
        body = b""
        for k, v in data.items():
            body += (f"--{boundary}\r\n" +
                     f"Content-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n").encode()
        for name, path in files.items():
            with open(path, "rb") as fh:
                content = fh.read()
            body += (f"--{boundary}\r\n" +
                     f"Content-Disposition: form-data; name=\"{name}\"; filename=\"{os.path.basename(path)}\"\r\n" +
                     "Content-Type: application/octet-stream\r\n\r\n").encode() + content + b"\r\n"
        body += f"--{boundary}--\r\n".encode()
        headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"
    else:
        if method == "GET":
            args.url += ("?" + urllib.parse.urlencode(data)) if data else ""
            body = None
        else:
            body = json.dumps(data).encode()
            headers["Content-Type"] = "application/json"

    req = urllib.request.Request(args.url, data=body, method=method, headers=headers)
    with urllib.request.urlopen(req) as resp:
        sys.stdout.write(str(resp.status) + "\n")
        try:
            txt = resp.read().decode()
            sys.stdout.write(txt[:200] + "\n")
        except Exception:
            pass


if __name__ == "__main__":
    main()
