#!/usr/bin/env python3
"""Build a single, self-contained HTML file from index.html by inlining every
./assets/*.png as a base64 data URI. The output (Smart-Health-Presentation.html)
opens correctly from any viewer — email, AirDrop, Files, Drive — with no
dependence on the assets/ folder. Re-run after editing index.html:
    python build-standalone.py
"""
import re, base64, os

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "index.html")
ASSETS = os.path.join(ROOT, "assets")
OUT = os.path.join(ROOT, "Smart-Health-Presentation.html")

html = open(SRC, encoding="utf-8").read()

def to_data_uri(filename):
    with open(os.path.join(ASSETS, filename), "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    return "data:image/png;base64," + b64

# Source references images as src="${A}app_home.png"; inline each one.
inlined = {}
def repl(m):
    fn = m.group(1)
    inlined.setdefault(fn, to_data_uri(fn))
    return inlined[fn]

out = re.sub(r"\$\{A\}([A-Za-z0-9_]+\.png)", repl, html)

with open(OUT, "w", encoding="utf-8") as f:
    f.write(out)

print(f"Inlined {len(inlined)} images -> {os.path.basename(OUT)} ({len(out)//1024} KB)")
