#!/usr/bin/env python3
"""Build a single, self-contained HTML file from index.html by inlining every
./assets/*.png as a base64 data URI. The output (Smart-Health-Presentation.html)
opens correctly from any viewer — email, AirDrop, Files, Drive — with no
dependence on the assets/ folder. Re-run after editing index.html:
    python build-standalone.py

Fails loudly rather than producing a file that only breaks on the presenter's
phone: any asset it cannot inline, and any surviving reference to ./assets/,
aborts the build with a non-zero exit code.
"""
import base64
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "index.html")
ASSETS = os.path.join(ROOT, "assets")
OUT = os.path.join(ROOT, "Smart-Health-Presentation.html")

MIME = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
        ".gif": "image/gif", ".svg": "image/svg+xml", ".webp": "image/webp"}


def die(message):
    sys.exit(f"build-standalone: {message}")


if not os.path.isfile(SRC):
    die(f"missing source file: {SRC}")

# newline="" on both ends: read and write the file's bytes as they are, so the
# build is reproducible on Windows and POSIX alike instead of rewriting every
# line ending and producing a 2 MB phantom diff.
with open(SRC, encoding="utf-8", newline="") as f:
    html = f.read()


def to_data_uri(filename):
    path = os.path.join(ASSETS, filename)
    if not os.path.isfile(path):
        die(f"asset referenced by index.html but not found: {path}")
    mime = MIME.get(os.path.splitext(filename)[1].lower())
    if mime is None:
        die(f"unsupported asset type: {filename}")
    with open(path, "rb") as f:
        return f"data:{mime};base64," + base64.b64encode(f.read()).decode("ascii")


# Source references assets as src="${A}app_home.png"; inline each one. The
# filename pattern is deliberately permissive (hyphens, dots, any extension) so a
# renamed asset fails the assertions below instead of slipping through unmatched.
inlined = {}


def repl(match):
    filename = match.group(1)
    inlined.setdefault(filename, to_data_uri(filename))
    return inlined[filename]


out = re.sub(r"\$\{A\}([\w.-]+)", repl, html)

# The A constant points at ./assets/ and is dead once every reference is inlined.
# Removing it is also the assertion below: no ./assets/ may survive in the output.
out = re.sub(r'^\s*const A = "\./assets/";\n', "", out, flags=re.M)

if "${A}" in out:
    die("some ${A} references were not inlined — check the asset filenames")
if "./assets/" in out:
    die("output still references ./assets/ — it would break away from this folder")
if not inlined:
    die("no assets were inlined — did the ${A} reference pattern change?")

with open(OUT, "w", encoding="utf-8", newline="") as f:
    f.write(out)

print(f"Inlined {len(inlined)} images -> {os.path.basename(OUT)} ({len(out)//1024} KB)")
