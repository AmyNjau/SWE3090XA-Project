#!/usr/bin/env python3
"""Build a USIU-Africa branded report (PDF + DOCX) from a markdown source.

    python build.py system-integration-report.md
    python build.py --all

Why this exists
---------------
Every report in this project shares one cover, one running header, and one
palette, all defined in ../brand/README.md. Rebuilding that by hand in Word for
each report is where inconsistency creeps in, so the branding lives here and the
markdown source stays pure prose.

How it works
------------
The heavy lifting (markdown, tables, syntax highlighting, image inlining) is done
by gstack's `make-pdf`. This script wraps it:

  1. Split the YAML-ish front matter off the source and validate it.
  2. Rewrite each markdown heading as raw HTML with a stable `id`, so the table
     of contents can link to it.
  3. Prepend the branded cover, the table of contents, and the brand stylesheet.
  4. Render once, read the real page number of every heading back out of the
     PDF, then render again with those numbers filled into the contents page.

That second pass is needed because this toolchain has no Paged.js, so CSS
`target-counter()` never resolves. Filling the numbers in does not change the
layout (the rows already occupy their lines), so pagination is stable between
the two passes; the script asserts that it is.

Failure policy: this fails loudly. A missing asset, a missing front-matter key,
a heading it cannot locate in the rendered PDF, or a pagination shift between
passes all exit non-zero rather than emit a document that is quietly wrong.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import shutil
import subprocess
import sys
import tempfile
from base64 import b64encode
from pathlib import Path

HERE = Path(__file__).resolve().parent
DOCS = HERE.parent
REPO = DOCS.parent
BRAND = DOCS / "brand"
BUILD_DIR = HERE / "build"

# Palette sampled from the official logo. Source of truth: ../brand/README.md.
USIU_BLUE = "#204098"
USIU_BLUE_DARK = "#283890"
USIU_GOLD = "#F8C808"
INK = "#201820"
GREY = "#5B6B82"

# Marks contents pages during the measurement pass only. See toc_html().
TOC_SENTINEL = "TOCPGMARK"

# Front-matter keys every report cover must carry.
REQUIRED_KEYS = [
    "title",
    "project",
    "course_code",
    "course_title",
    "school",
    "department",
    "student",
    "student_id",
    "supervisor",
    "date",
]


def die(msg: str) -> None:
    sys.stderr.write(f"build.py: error: {msg}\n")
    sys.exit(1)


def find_make_pdf() -> str:
    """Locate gstack's make-pdf binary."""
    env = os.environ.get("MAKE_PDF_BIN")
    if env and Path(env).is_file():
        return env
    candidates = [
        Path.home() / ".claude/skills/gstack/make-pdf/dist/pdf.exe",
        Path.home() / ".claude/skills/gstack/make-pdf/dist/pdf",
        Path.home() / ".codex/skills/gstack/make-pdf/dist/pdf.exe",
        Path.home() / ".codex/skills/gstack/make-pdf/dist/pdf",
    ]
    for c in candidates:
        if c.is_file():
            return str(c)
    on_path = shutil.which("pdf")
    if on_path:
        return on_path
    die(
        "make-pdf not found. It ships with gstack; run './setup' in the gstack "
        "repo, or set MAKE_PDF_BIN to the binary."
    )
    raise AssertionError  # unreachable, keeps type checkers happy


def find_pdftotext() -> str:
    """Locate pdftotext, used to read page numbers back out of the first pass."""
    found = shutil.which("pdftotext")
    if found:
        return found
    for c in [Path("C:/Program Files/Git/mingw64/bin/pdftotext.exe"), Path("/mingw64/bin/pdftotext")]:
        if c.is_file():
            return str(c)
    die(
        "pdftotext not found; it is needed to number the contents page. "
        "It ships with poppler-utils and with Git for Windows. "
        "Pass --no-toc-numbers to build without page numbers."
    )
    raise AssertionError


def data_uri(path: Path) -> str:
    if not path.is_file():
        die(f"brand asset missing: {path}")
    return "data:image/png;base64," + b64encode(path.read_bytes()).decode("ascii")


def split_front_matter(text: str) -> tuple[dict[str, str], str]:
    """Split a leading `---` delimited `key: value` block off the source."""
    if not text.startswith("---"):
        die("source is missing its front-matter block (must start with '---')")
    end = text.find("\n---", 3)
    if end == -1:
        die("front-matter block is not closed with '---'")
    raw = text[3:end].strip("\n")
    body = text[end + 4 :].lstrip("\n")
    meta: dict[str, str] = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            die(f"front-matter line is not 'key: value': {line!r}")
        k, v = line.split(":", 1)
        meta[k.strip()] = v.strip()
    missing = [k for k in REQUIRED_KEYS if not meta.get(k)]
    if missing:
        die("front matter is missing required keys: " + ", ".join(missing))
    return meta, body


def slugify(text: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", text.strip().lower()).strip("-")
    return s or "section"


def check_images(body: str, source: Path) -> list[Path]:
    """Assert every referenced image is local and present.

    This replaces make-pdf's --strict, which cannot be used here: it rejects any
    image outside the markdown's own directory, and the figures deliberately
    live in docs/figures/ so the reports and the deck share one copy.
    """
    refs = re.findall(r"!\[[^\]]*\]\(([^)\s]+)", body)
    resolved: list[Path] = []
    missing: list[str] = []
    remote: list[str] = []
    for ref in refs:
        if re.match(r"^[a-z]+://", ref, re.I):
            remote.append(ref)
            continue
        path = (source.parent / ref).resolve()
        if not path.is_file():
            missing.append(ref)
        else:
            resolved.append(path)
    if remote:
        die(
            "remote images are not allowed in a report source (the build must be "
            "reproducible offline): " + ", ".join(remote)
        )
    if missing:
        die("referenced image(s) not found: " + ", ".join(missing))
    return resolved


def extract_headings(body: str) -> list[dict]:
    """Find level 1-2 ATX headings outside fenced code blocks."""
    headings: list[dict] = []
    fenced = False
    seen: dict[str, int] = {}
    for i, line in enumerate(body.splitlines()):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        m = re.match(r"^(#{1,2})\s+(.*\S)\s*$", line)
        if not m:
            continue
        level, text = len(m.group(1)), m.group(2)
        slug = slugify(text)
        seen[slug] = seen.get(slug, 0) + 1
        if seen[slug] > 1:
            slug = f"{slug}-{seen[slug]}"
        headings.append({"line": i, "level": level, "text": text, "id": slug})
    if not headings:
        die("no headings found in the source; a report needs at least one")
    return headings


def rewrite_headings(body: str, headings: list[dict]) -> str:
    """Replace markdown headings with anchored HTML, page-breaking each H1.

    make-pdf is run with --no-chapter-breaks so that page breaks are controlled
    here and nowhere else; two break sources produced a blank page.
    """
    lines = body.splitlines()
    by_line = {h["line"]: h for h in headings}
    out: list[str] = []
    first_h1 = True
    for i, line in enumerate(lines):
        h = by_line.get(i)
        if not h:
            out.append(line)
            continue
        tag = f"h{h['level']}"
        esc = html.escape(h["text"])
        if h["level"] == 1:
            if not first_h1:
                out.append('<div class="pagebreak"></div>')
                out.append("")
            first_h1 = False
        out.append(f'<{tag} id="{h["id"]}" class="usiu-{tag}">{esc}</{tag}>')
    return "\n".join(out)


def cover_html(meta: dict[str, str]) -> str:
    logo = data_uri(BRAND / "usiu-logo.png")
    logo_white = data_uri(BRAND / "usiu-logo-white.png")
    g = lambda k: html.escape(meta.get(k, ""))  # noqa: E731
    semester = f'<div class="cover-semester">{g("semester")}</div>' if meta.get("semester") else ""
    return f"""<section class="usiu-cover">
  <img class="cover-logo" src="{logo}" alt="United States International University Africa logo">
  <div class="cover-university">United States International University &ndash; Africa</div>
  <div class="cover-school">{g("school")}</div>
  <div class="cover-school">{g("department")}</div>
  <div class="cover-band">
    <img class="cover-band-logo" src="{logo_white}" alt="">
    <div class="cover-band-title">{g("title")}</div>
  </div>
  <div class="cover-project-label">Project</div>
  <div class="cover-project">{g("project")}</div>
  <table class="cover-meta">
    <tr><th>Course</th><td>{g("course_code")} &ndash; {g("course_title")}</td></tr>
    <tr><th>Submitted by</th><td>{g("student")}</td></tr>
    <tr><th>Registration number</th><td>{g("student_id")}</td></tr>
    <tr><th>Supervisor</th><td>{g("supervisor")}</td></tr>
    <tr><th>Submission date</th><td>{g("date")}</td></tr>
  </table>
  {semester}
</section>
<div class="pagebreak"></div>
"""


def toc_html(headings: list[dict], pages: dict[str, int] | None) -> str:
    """Render the contents page.

    `pages is None` marks the measurement pass: every row carries an invisible
    sentinel so that the contents pages can be identified exactly and excluded
    when hunting for body headings. Text extraction splits each row into
    separate runs, so a contents row is otherwise indistinguishable from the
    heading it points at. The sentinel is absent from the delivered document.
    """
    measuring = pages is None
    sentinel = (
        f'<span style="font-size:1pt;color:#ffffff">{TOC_SENTINEL}</span>' if measuring else ""
    )
    rows = []
    for h in headings:
        num = "0" if measuring else str(pages.get(h["id"], ""))
        rows.append(
            f'<div class="toc-row toc-l{h["level"]}">'
            f'<a href="#{h["id"]}">{html.escape(h["text"])}</a>'
            f'<span class="toc-dots"></span>'
            f'<span class="toc-page">{num}</span>{sentinel}'
            f"</div>"
        )
    return (
        '<section class="usiu-toc">\n<h2 class="toc-heading">Table of Contents</h2>\n'
        + "\n".join(rows)
        + "\n</section>\n<div class=\"pagebreak\"></div>\n"
    )


def brand_css() -> str:
    return f"""<style>
:root {{
  --usiu-blue: {USIU_BLUE};
  --usiu-blue-dark: {USIU_BLUE_DARK};
  --usiu-gold: {USIU_GOLD};
  --usiu-ink: {INK};
  --usiu-grey: {GREY};
}}
body {{ color: var(--usiu-ink); }}
.pagebreak {{ break-after: page; }}

/* The cover carries no running header, no page number and no margin box, so
   the title page reads as a title page and the blue band can run full bleed.
   Everything on the cover supplies its own horizontal padding instead. */
@page :first {{ margin: 0; }}

/* Cover ------------------------------------------------------------------ */
.usiu-cover {{ text-align: center; padding: 0.85in 0 0; }}
.usiu-cover .cover-university,
.usiu-cover .cover-school,
.usiu-cover .cover-project-label,
.usiu-cover .cover-project,
.usiu-cover .cover-semester {{ padding-left: 0.9in; padding-right: 0.9in; }}
.cover-logo {{ width: 250px; max-width: 60%; height: auto; margin: 0 auto 18pt; display: block; }}
.cover-university {{
  font-size: 15pt; font-weight: 700; color: var(--usiu-blue);
  letter-spacing: 0.02em; text-transform: uppercase; line-height: 1.3;
}}
.cover-school {{ font-size: 11.5pt; color: var(--usiu-grey); margin-top: 4pt; }}
.cover-band {{
  background: var(--usiu-blue); color: #fff; margin: 26pt 0 0;
  padding: 16pt 0.9in; border-bottom: 5px solid var(--usiu-gold);
}}
.cover-band-logo {{ width: 150px; height: auto; display: block; margin: 0 auto 10pt; }}
.cover-band-title {{
  font-size: 21pt; font-weight: 700; letter-spacing: 0.03em;
  text-transform: uppercase; color: #fff; line-height: 1.25;
}}
.cover-project-label {{
  margin-top: 24pt; font-size: 9.5pt; letter-spacing: 0.14em;
  text-transform: uppercase; color: var(--usiu-grey);
}}
.cover-project {{
  font-size: 14pt; font-weight: 600; color: var(--usiu-blue-dark);
  margin: 5pt auto 0; max-width: 86%; line-height: 1.4;
}}
table.cover-meta {{
  margin: 30pt auto 0; border-collapse: collapse; text-align: left;
  font-size: 11pt; max-width: 84%;
}}
/* Beats the body zebra-striping rule below, which is more specific. */
table.cover-meta tbody tr th, table.cover-meta tbody tr td {{
  border: none; padding: 5pt 10pt; vertical-align: top; background: none;
}}
table.cover-meta th {{
  color: var(--usiu-grey); font-weight: 600; white-space: nowrap;
  text-align: left; width: 1%;
}}
table.cover-meta td {{ color: var(--usiu-ink); }}
.cover-semester {{ margin-top: 26pt; font-size: 10.5pt; color: var(--usiu-grey); }}

/* Contents --------------------------------------------------------------- */
.usiu-toc {{ padding-top: 4pt; }}
.toc-heading {{
  color: var(--usiu-blue); font-size: 17pt; margin: 0 0 4pt;
  padding-bottom: 6pt; border-bottom: 3px solid var(--usiu-gold);
}}
.toc-row {{ display: flex; align-items: baseline; margin: 7pt 0; font-size: 11pt; }}
.toc-row a {{ color: var(--usiu-ink); text-decoration: none; }}
.toc-l1 {{ font-weight: 600; margin-top: 11pt; }}
.toc-l1 a {{ color: var(--usiu-blue-dark); }}
.toc-l2 {{ padding-left: 20pt; font-size: 10.5pt; }}
.toc-dots {{
  flex: 1 1 auto; border-bottom: 1px dotted var(--usiu-grey);
  margin: 0 6pt; transform: translateY(-3px); min-width: 12pt;
}}
.toc-page {{ color: var(--usiu-grey); font-variant-numeric: tabular-nums; }}

/* Body ------------------------------------------------------------------- */
h1.usiu-h1 {{
  color: var(--usiu-blue); font-size: 17pt; margin: 0 0 12pt;
  padding-bottom: 6pt; border-bottom: 3px solid var(--usiu-gold);
}}
h2.usiu-h2 {{ color: var(--usiu-blue-dark); font-size: 13pt; margin: 18pt 0 6pt; }}
p, li {{ line-height: 1.5; }}
a {{ color: var(--usiu-blue-dark); }}
table {{ border-collapse: collapse; width: 100%; font-size: 10pt; }}
th {{
  background: var(--usiu-blue); color: #fff; text-align: left;
  padding: 6pt 8pt; border: 1px solid var(--usiu-blue);
}}
td {{ padding: 6pt 8pt; border: 1px solid #c9d2e4; vertical-align: top; }}
tbody tr:nth-child(even) td {{ background: #f4f6fb; }}
figure, img {{ max-width: 100%; }}
/* Figure and table captions: the source writes them as a lone italic line. */
p > em:only-child {{
  display: block; text-align: center; color: var(--usiu-grey);
  font-size: 9.5pt; font-style: italic; margin-top: 4pt;
}}
</style>
"""


def run_make_pdf(binary: str, src: Path, out: Path, meta: dict[str, str], fmt: str) -> None:
    cmd = [
        binary, "generate", str(src), str(out),
        "--to", fmt,
        "--page-size", "a4",
        "--margins", "0.9in",
        "--no-chapter-breaks",
        "--no-confidential",
        "--quiet",
        # Sets the running header on every page after the cover. Without it the
        # header inherits the first heading ("1. Introduction") and then stays
        # stale for the rest of the document.
        "--title", meta["title"],
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout + "\n" + proc.stderr + "\n")
        die(f"make-pdf failed ({fmt}) with exit code {proc.returncode}")
    if not out.is_file() or out.stat().st_size < 1024:
        die(f"make-pdf reported success but {out} is missing or suspiciously small")


def pdf_pages_text(pdftotext: str, pdf: Path) -> list[str]:
    """Return the text of each page, in order."""
    proc = subprocess.run(
        [pdftotext, "-layout", str(pdf), "-"], capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    if proc.returncode != 0:
        die(f"pdftotext failed: {proc.stderr.strip()}")
    return proc.stdout.split("\f")


def first_body_page(pages: list[str]) -> int:
    """Return the 0-based index of the first page after cover and contents."""
    last_toc = -1
    for i, text in enumerate(pages):
        if TOC_SENTINEL in text:
            last_toc = i
    if last_toc == -1:
        die("could not locate the contents pages in the rendered PDF")
    return last_toc + 1


def locate_headings(pages: list[str], headings: list[dict], start: int) -> dict[str, int]:
    """Map heading id -> 1-based page number of its occurrence in the body.

    A body heading occupies a line of its own, so it is matched as a whole line.
    Contents rows never match: they always carry a page number on the same line
    (a placeholder on the first pass), and the running header is a different
    string again. Matching advances a cursor, so headings are also required to
    appear in source order.
    """
    per_page = [[re.sub(r"\s+", " ", ln).strip() for ln in p.splitlines()] for p in pages]
    found: dict[str, int] = {}
    unresolved: list[str] = []
    cursor = start
    for h in headings:
        needle = re.sub(r"\s+", " ", h["text"]).strip()
        for idx in range(cursor, len(per_page)):
            if any(line == needle for line in per_page[idx]):
                found[h["id"]] = idx + 1
                cursor = idx
                break
        else:
            unresolved.append(h["text"])
    if unresolved:
        die(
            "could not find these headings as standalone lines in the rendered "
            "PDF, so the contents page cannot be numbered: " + "; ".join(unresolved)
        )
    return found


def build_one(source: Path, binary: str, want_numbers: bool, keep_docx: bool) -> None:
    if not source.is_file():
        die(f"source not found: {source}")
    meta, body = split_front_matter(source.read_text(encoding="utf-8"))
    check_images(body, source)
    headings = extract_headings(body)
    body_html = rewrite_headings(body, headings)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    def assemble(pages: dict[str, int] | None, with_css: bool = True) -> str:
        # Word ignores <style>, and make-pdf's DOCX writer emits the ignored
        # block as literal body text, so the stylesheet is left out there.
        css = brand_css() + "\n" if with_css else ""
        return css + cover_html(meta) + "\n" + toc_html(headings, pages) + "\n" + body_html + "\n"

    # The staged source must sit beside the real one so that relative image
    # paths (../figures/...) resolve identically.
    stage = source.with_name(f".{source.stem}.staged.md")
    pdf_out = BUILD_DIR / f"{source.stem}.pdf"
    try:
        stage.write_text(assemble(None), encoding="utf-8", newline="\n")
        run_make_pdf(binary, stage, pdf_out, meta, "pdf")

        if want_numbers:
            pdftotext = find_pdftotext()
            pages_text = pdf_pages_text(pdftotext, pdf_out)
            first_pass_pages = len(pages_text)
            body_start = first_body_page(pages_text)
            numbers = locate_headings(pages_text, headings, body_start)
            stage.write_text(assemble(numbers), encoding="utf-8", newline="\n")
            run_make_pdf(binary, stage, pdf_out, meta, "pdf")

            # Filling in the numbers must not have moved anything.
            second = pdf_pages_text(pdftotext, pdf_out)
            if len(second) != first_pass_pages:
                die(
                    "pagination changed between passes "
                    f"({first_pass_pages} -> {len(second)} pages); the contents "
                    "page numbers would be wrong. Shorten the contents page."
                )
            # The sentinel is gone from the delivered render, so reuse the body
            # offset measured in the first pass; the page-count check above has
            # already established that pagination did not move.
            recheck = locate_headings(second, headings, body_start)
            drifted = {k: (numbers[k], recheck[k]) for k in numbers if numbers[k] != recheck[k]}
            if drifted:
                die(f"heading pages moved between passes: {drifted}")

        if keep_docx:
            # Page numbers measured from the PDF do not apply once Word
            # repaginates, so the DOCX contents page carries none.
            stage.write_text(assemble({}, with_css=False), encoding="utf-8", newline="\n")
            run_make_pdf(binary, stage, BUILD_DIR / f"{source.stem}.docx", meta, "docx")
    finally:
        if stage.exists():
            stage.unlink()

    size_kb = pdf_out.stat().st_size // 1024
    print(f"{pdf_out.relative_to(REPO)}  ({size_kb} KB)")
    if keep_docx:
        docx = BUILD_DIR / f"{source.stem}.docx"
        print(f"{docx.relative_to(REPO)}  ({docx.stat().st_size // 1024} KB)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sources", nargs="*", help="markdown sources to build (default: --all)")
    ap.add_argument("--all", action="store_true", help="build every *.md in this folder")
    ap.add_argument("--no-toc-numbers", action="store_true", help="skip the second pass that numbers the contents page")
    ap.add_argument("--no-docx", action="store_true", help="build the PDF only")
    args = ap.parse_args()

    if args.all or not args.sources:
        sources = sorted(p for p in HERE.glob("*.md") if p.name != "README.md")
        if not sources:
            die("no report sources found in docs/reports/")
    else:
        sources = [Path(s) if Path(s).is_absolute() else (HERE / s) for s in args.sources]

    binary = find_make_pdf()
    for src in sources:
        build_one(src, binary, want_numbers=not args.no_toc_numbers, keep_docx=not args.no_docx)


if __name__ == "__main__":
    main()
