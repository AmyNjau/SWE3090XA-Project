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
from collections import Counter
from pathlib import Path
from urllib.parse import unquote
from xml.etree import ElementTree

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

# How many times the contents page may be re-rendered while its page numbers
# settle. Two is normally enough; more than this means something is oscillating.
MAX_NUMBERING_PASSES = 5

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
    if env:
        if not Path(env).is_file():
            die(f"MAKE_PDF_BIN is set to {env!r}, which is not a file")
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
    for c in [
        Path("C:/Program Files/Git/mingw64/bin/pdftotext.exe"),
        Path("C:/Program Files (x86)/Git/mingw64/bin/pdftotext.exe"),
    ]:
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


def fence_mask(body: str) -> list[bool]:
    """Per-line flags marking lines inside a fenced code block.

    Handles both ``` and ~~~ fences, and only closes on a fence of the same
    character that is at least as long as the one that opened it.
    """
    inside = [False] * len(body.splitlines())
    opener: tuple[str, int] | None = None
    for i, line in enumerate(body.splitlines()):
        m = re.match(r"^\s*(`{3,}|~{3,})", line)
        if m and opener is None:
            opener = (m.group(1)[0], len(m.group(1)))
            inside[i] = True
            continue
        if m and opener is not None:
            char, length = opener
            if m.group(1)[0] == char and len(m.group(1)) >= length:
                inside[i] = True
                opener = None
                continue
        inside[i] = opener is not None
    return inside


def check_images(body: str, source: Path) -> None:
    """Assert every referenced image is local and present.

    This replaces make-pdf's --strict, which cannot be used here: it rejects any
    image outside the markdown's own directory, and the figures deliberately
    live in docs/figures/ so the reports and the deck share one copy.
    """
    masked = "\n".join(
        "" if inside else line
        for line, inside in zip(body.splitlines(), fence_mask(body))
    )
    refs = re.findall(r"!\[[^\]]*\]\(\s*<?([^)>\s]+)", masked)
    missing: list[str] = []
    remote: list[str] = []
    for ref in refs:
        if re.match(r"^([a-z][a-z0-9+.-]*:|//)", ref, re.I):
            remote.append(ref)
            continue
        # Markdown percent-encodes spaces in paths.
        path = (source.parent / unquote(ref)).resolve()
        if not path.is_file():
            missing.append(ref)
    if remote:
        die(
            "remote images are not allowed in a report source (the build must be "
            "reproducible offline): " + ", ".join(remote)
        )
    if missing:
        die("referenced image(s) not found: " + ", ".join(missing))


def extract_headings(body: str) -> list[dict]:
    """Find level 1-2 ATX headings outside fenced code blocks."""
    headings: list[dict] = []
    seen: dict[str, int] = {}
    lines = body.splitlines()
    masked = fence_mask(body)
    for i, line in enumerate(lines):
        if masked[i]:
            continue
        # Setext headings would render as headings but carry no anchor, no page
        # break and no contents entry, so refuse them rather than drop them.
        if re.match(r"^(=+|-{2,})\s*$", line) and i and lines[i - 1].strip() and not masked[i - 1]:
            if not re.match(r"^\s*[-|]", lines[i - 1]):
                die(
                    f"line {i + 1}: setext heading ('{lines[i - 1].strip()}' underlined "
                    "with = or -) is not supported. Write it as '# ' or '## ' instead."
                )
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


def alternative_figure(ref: str, source: Path) -> Path | None:
    """Return the redrawn SVG for an image reference, if one exists.

    An original at `../figures/x.png` is matched by `../figures/alt/x.svg`.
    This is what lets one markdown source produce both a document carrying the
    original diagrams and one carrying the redrawn set, with no duplicated prose.
    """
    original = (source.parent / unquote(ref)).resolve()
    candidate = original.parent / "alt" / f"{original.stem}.svg"
    if not candidate.is_file():
        return None
    # The file is spliced into the document as raw markup, so a malformed one
    # would leak its source as visible text instead of drawing a figure.
    try:
        root = ElementTree.fromstring(candidate.read_text(encoding="utf-8"))
    except ElementTree.ParseError as exc:
        die(f"alternative figure {candidate} is not well-formed XML: {exc}")
    if root.tag not in ("svg", "{http://www.w3.org/2000/svg}svg"):
        die(f"alternative figure {candidate} is not an <svg> document (root: {root.tag})")
    return candidate


def fold_figures(body: str, source: Path, variant: str = "original") -> str:
    """Bind each image to the caption line beneath it.

    A bare image followed by a separate italic caption paragraph lets the
    renderer put the image on one page and its caption on the next, which left
    three orphaned captions and two near-blank pages in the first build.
    Wrapping both in one unbreakable <figure> keeps them together.

    In the "alternative" variant, an image that has a redrawn SVG beside it is
    replaced by that SVG, inlined so it stays vector-crisp in print.
    """
    lines = body.splitlines()
    masked = fence_mask(body)
    out: list[str] = []
    i = 0
    while i < len(lines):
        m = re.match(r"^!\[([^\]]*)\]\(\s*<?([^)>\s]+)>?\s*\)(\{[^}]*\})?\s*$", lines[i])
        if not m or masked[i]:
            out.append(lines[i])
            i += 1
            continue
        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        cap = re.match(r"^\*([^*].*)\*\s*$", lines[j]) if j < len(lines) else None
        if not cap:
            # Refuse rather than quietly keep the original here: an
            # -alt-diagrams document that mixed the two sets would be worse
            # than one that fails to build.
            if variant == "alternative" and alternative_figure(m.group(2), source):
                die(
                    f"{m.group(2)} has an alternative figure but no caption line, so "
                    "the alternative document would silently keep the original. Give "
                    "it an italic caption line, as every other figure has."
                )
            out.append(lines[i])
            i += 1
            continue
        alt_text, src = html.escape(m.group(1)), html.escape(m.group(2), quote=True)
        swap = alternative_figure(m.group(2), source) if variant == "alternative" else None
        inner = (
            swap.read_text(encoding="utf-8").strip()
            if swap
            else f'<img src="{src}" alt="{alt_text}">'
        )
        out.append(
            '<figure class="usiu-figure">'
            + inner
            + f"<figcaption>{html.escape(cap.group(1).strip())}</figcaption>"
            "</figure>"
        )
        i = j + 1
    return "\n".join(out)


def rewrite_headings(body: str, headings: list[dict], page_break_sections: bool = False) -> str:
    """Replace markdown headings with anchored HTML.

    Sections run on by default, as they do in a Word-produced academic report:
    a new section starts wherever the previous one ended. Set
    `page_break_sections` in the front matter to start each top-level section on
    a fresh page instead. make-pdf is run with --no-chapter-breaks either way, so
    page breaks are controlled here and nowhere else.
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
            if not first_h1 and page_break_sections:
                out.append('<div class="pagebreak"></div>')
                out.append("")
            first_h1 = False
        out.append(f'<{tag} id="{h["id"]}" class="usiu-{tag}">{esc}</{tag}>')
    return "\n".join(out)


def cover_html(meta: dict[str, str]) -> str:
    """Plain, centred title page in the style USIU coursework uses.

    Deliberately typographic rather than designed: no colour band, no rules,
    just the university, the title and the submission details, with the logo
    above them. This matches the reference report the user supplied.
    """
    logo = data_uri(BRAND / "usiu-logo.png")
    g = lambda k: html.escape(meta.get(k, ""))  # noqa: E731
    tagline = f'<div class="cover-tagline">{g("tagline")}</div>' if meta.get("tagline") else ""
    semester = f'<div class="cover-line">{g("semester")}</div>' if meta.get("semester") else ""
    return f"""<section class="usiu-cover">
  <img class="cover-logo" src="{logo}" alt="United States International University Africa logo">
  <div class="cover-university">UNITED STATES INTERNATIONAL UNIVERSITY &ndash; AFRICA</div>
  <div class="cover-school">{g("school")}</div>
  <div class="cover-school">{g("department")}</div>
  <h1 class="cover-title">{g("title")}</h1>
  <div class="cover-project">{g("project")}</div>
  {tagline}
  <div class="cover-block">
    <div class="cover-line">Submitted by</div>
    <div class="cover-line cover-strong">{g("student")} &ndash; {g("student_id")}</div>
  </div>
  <div class="cover-block">
    <div class="cover-line">Course: {g("course_code")} &ndash; {g("course_title")}</div>
    <div class="cover-line">Supervisor: {g("supervisor")}</div>
    <div class="cover-line">Date of submission: {g("date")}</div>
    {semester}
  </div>
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
    # Taken out of the flow entirely: the sentinel exists only in the measuring
    # pass, so it must not occupy a single pixel, or removing it for the real
    # render would shift the pagination the measurement just recorded.
    # Absolutely positioned inside its own row: out of the flow, so removing it
    # for the real render cannot shift the pagination the measurement recorded,
    # yet still painted (white, 1pt) on the page its row lands on, so text
    # extraction can tell contents pages from body pages.
    sentinel = (
        f'<span style="position:absolute;right:0;top:0;font-size:1pt;'
        f'color:#ffffff">{TOC_SENTINEL}</span>'
        if measuring
        else ""
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
    """Stylesheet for an academic report set the way USIU coursework is set.

    Typographic rather than designed: Times New Roman, justified body with a
    first-line indent, a running header naming the course and author, and a bare
    page number in the footer. The only brand colour is USIU blue on headings
    and table headers, kept restrained so the document still reads as a
    university report rather than a brochure.
    """
    return f"""<style>
:root {{
  --usiu-blue: {USIU_BLUE};
  --usiu-blue-dark: {USIU_BLUE_DARK};
  --usiu-gold: {USIU_GOLD};
  --usiu-ink: {INK};
  --usiu-grey: {GREY};
}}

body {{
  font-family: "Times New Roman", Times, Georgia, serif;
  font-size: 12pt;
  line-height: 1.5;
  color: #000000;
  text-align: justify;
}}
.pagebreak {{ break-after: page; }}

/* Clears the margin box on the title page. Chrome still paints the footer
   template there, so the cover carries a page number where the reference
   report carries none; its Word "different first page" setting has no
   equivalent in print-to-PDF. */
@page :first {{ margin: 0; }}

/* Cover ------------------------------------------------------------------ */
.usiu-cover {{ text-align: center; padding: 1in 1in 0; }}
.cover-logo {{ width: 190px; max-width: 46%; height: auto; margin: 0 auto 22pt; display: block; }}
.cover-university {{ font-size: 13.5pt; font-weight: bold; letter-spacing: 0.01em; }}
.cover-school {{ font-size: 12pt; margin-top: 4pt; }}
h1.cover-title {{
  font-size: 17pt; font-weight: bold; margin: 34pt auto 0; max-width: 92%;
  line-height: 1.35; color: #000000; border: none; padding: 0; text-align: center;
}}
.cover-project {{ font-size: 12.5pt; margin-top: 14pt; }}
.cover-tagline {{ font-size: 12pt; font-style: italic; margin-top: 12pt; }}
.cover-block {{ margin-top: 30pt; }}
.cover-line {{ font-size: 12pt; margin-top: 5pt; }}
.cover-strong {{ font-weight: bold; }}

/* Contents --------------------------------------------------------------- */
.usiu-toc {{ text-align: left; }}
.toc-heading {{
  font-size: 14pt; font-weight: bold; color: var(--usiu-blue);
  margin: 0 0 14pt; text-align: left;
}}
.toc-row {{
  display: flex; align-items: baseline; margin: 5pt 0; font-size: 12pt;
  position: relative; /* anchors the measuring-pass sentinel to this row */
}}
.toc-row a {{ color: #000000; text-decoration: none; }}
.toc-l1 {{ margin-top: 9pt; }}
.toc-l2 {{ padding-left: 24pt; font-size: 11.5pt; }}
.toc-dots {{
  flex: 1 1 auto; border-bottom: 1px dotted #666666;
  margin: 0 5pt; transform: translateY(-3px); min-width: 12pt;
}}
/* Fixed width and right alignment so a one-digit placeholder and a two-digit
   real page number occupy identical space; otherwise the second pass could
   reflow the very rows the first pass measured. */
.toc-page {{
  font-variant-numeric: tabular-nums;
  min-width: 26pt; text-align: right; flex: 0 0 auto;
}}

/* Body ------------------------------------------------------------------- */
h1.usiu-h1 {{
  font-size: 14pt; font-weight: bold; color: var(--usiu-blue);
  margin: 14pt 0 6pt; text-align: center; border: none; padding: 0;
  break-after: avoid;
}}
h2.usiu-h2 {{
  font-size: 12.5pt; font-weight: bold; color: var(--usiu-blue-dark);
  margin: 14pt 0 6pt; text-align: left; break-after: avoid;
}}
/* text-transform is reset explicitly: the base stylesheet upper-cases h3, which
   turned "2.1.1 WebMD Symptom Checker" into a shout. */
h3 {{
  font-size: 12pt; font-weight: bold; margin: 14pt 0 5pt; text-align: left;
  text-transform: none; letter-spacing: normal; color: #1C144C;
}}
p {{ margin: 0 0 6pt; text-indent: 0.5in; }}
/* A paragraph that only introduces a list, table or figure reads better flush. */
p:has(+ ul), p:has(+ ol), p:has(+ table), p:has(+ figure) {{ text-indent: 0; }}
li {{ margin: 0 0 5pt; text-align: justify; }}
ul, ol {{ margin: 0 0 10pt; padding-left: 0.5in; }}
a {{ color: var(--usiu-blue-dark); }}
code, pre {{ font-family: Consolas, "Courier New", monospace; font-size: 10pt; }}
pre {{ text-align: left; line-height: 1.35; }}

table {{
  border-collapse: collapse; width: 100%; font-size: 10.5pt;
  text-align: left; margin: 6pt 0 4pt;
}}
th {{
  background: var(--usiu-blue); color: #ffffff; text-align: left;
  padding: 5pt 7pt; border: 1px solid var(--usiu-blue); font-weight: bold;
}}
td {{ padding: 5pt 7pt; border: 1px solid #9aa7bf; vertical-align: top; text-align: left; }}

figure, img {{ max-width: 100%; }}
/* One unbreakable block, so a figure is never split from its caption and never
   pushed alone onto a page of its own. */
.usiu-figure {{
  break-inside: avoid; page-break-inside: avoid;
  text-align: center; margin: 12pt 0;
}}
.usiu-figure img, .usiu-figure svg {{ max-width: 100%; max-height: 6.2in; height: auto; }}
.usiu-figure figcaption {{
  font-size: 10.5pt; font-style: italic; margin-top: 6pt; text-align: center;
}}
/* Table captions: the source writes them as a lone italic line. */
p > em:only-child {{
  display: block; text-align: center; font-size: 10.5pt;
  font-style: italic; margin-top: 2pt; text-indent: 0;
}}
</style>
"""


def running_header(meta: dict[str, str]) -> str:
    """`COURSE | Author | Project`, as the reference report heads every page."""
    short = meta.get("short_title") or meta.get("project", "")
    return " | ".join(x for x in [meta.get("course_code", ""), meta.get("student", ""), short] if x)


def run_make_pdf(binary: str, src: Path, out: Path, meta: dict[str, str], fmt: str) -> None:
    cmd = [
        binary, "generate", str(src), str(out),
        "--to", fmt,
        "--page-size", "a4",
        "--margins", "1in",
        "--no-chapter-breaks",
        "--no-confidential",
        "--quiet",
        # The running header names the course, the author and the project, the
        # way the reference report does. Without an explicit title it would
        # inherit the first heading and then stay stale for the whole document.
        "--title", running_header(meta),
        # A bare centred page number, rather than make-pdf's "N of M".
        "--footer-template",
        '<div style="width:100%;text-align:center;font-family:\'Times New Roman\',Times,serif;'
        'font-size:10pt;color:#000;"><span class="pageNumber"></span></div>',
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        sys.stderr.write((proc.stdout or "") + "\n" + (proc.stderr or "") + "\n")
        die(f"make-pdf failed ({fmt}) with exit code {proc.returncode}")
    if not out.is_file() or out.stat().st_size < 1024:
        die(f"make-pdf reported success but {out} is missing or suspiciously small")


def pdf_pages_text(pdftotext: str, pdf: Path) -> list[str]:
    """Return the text of each page, in order."""
    # -enc UTF-8 matters: the pdftotext that ships with Git for Windows is Xpdf,
    # whose default output encoding is Latin-1, which mangles any non-ASCII
    # heading into replacement characters and makes it unmatchable.
    proc = subprocess.run(
        [pdftotext, "-layout", "-enc", "UTF-8", str(pdf), "-"],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    if proc.returncode != 0:
        die(f"pdftotext failed: {proc.stderr.strip()}")
    pages = proc.stdout.split("\f")
    if pages and not pages[-1].strip():
        pages.pop()  # trailing form feed, not a real page
    return pages


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

    A body heading occupies a line of its own, so it is matched as a whole line
    -- with one allowance. `pdftotext -layout` reconstructs columns by vertical
    position, so when a heading sits close above a table it merges the heading
    and the table's header row into a single extracted line
    ("7.1 Objectives Achieved      Outcome      Evidence") even though the
    rendered page is perfectly correct. A heading followed by a run of two or
    more spaces is therefore treated as that heading: prose never contains a
    column gap, so this cannot swallow an ordinary sentence that merely starts
    with the same words.

    Contents rows never match: they sit before `start`. Matching advances a
    cursor, so headings are also required to appear in source order.
    """
    # Flatten to (page index, collapsed line, raw line) so the cursor can
    # advance past a matched line rather than only to its page. Advancing by
    # page let a repeated heading title re-match its own earlier occurrence and
    # be numbered wrongly.
    flat = [
        (i, re.sub(r"\s+", " ", ln).strip(), ln.strip())
        for i, page in enumerate(pages)
        if i >= start
        for ln in page.splitlines()
    ]

    def matches(entry: tuple[int, str, str], needle: str) -> bool:
        _, collapsed, raw = entry
        if collapsed == needle:
            return True
        rest = raw[len(needle):] if raw.startswith(needle) else ""
        return bool(rest) and rest[:2] == "  "

    # Every heading title must occur in the body exactly as many times as it is
    # used as a heading. Anything else -- a repeated title, or a title that also
    # appears as an ordinary body line -- makes the mapping ambiguous, and both
    # passes would agree on the same wrong answer, so the drift check cannot
    # catch it. Refuse instead of numbering it wrongly.
    wanted = Counter(re.sub(r"\s+", " ", h["text"]).strip() for h in headings)
    body_counts = Counter(
        {title: sum(1 for e in flat if matches(e, title)) for title in wanted}
    )
    ambiguous = sorted(t for t, n in wanted.items() if body_counts.get(t, 0) != n)
    if ambiguous:
        die(
            "these heading titles do not appear in the rendered body exactly once "
            "per heading, so their page numbers cannot be trusted: "
            + "; ".join(ambiguous)
            + ". Make each heading unique, and make sure no ordinary line of text "
            "is identical to a heading."
        )

    found: dict[str, int] = {}
    unresolved: list[str] = []
    cursor = 0
    for h in headings:
        needle = re.sub(r"\s+", " ", h["text"]).strip()
        for j in range(cursor, len(flat)):
            if matches(flat[j], needle):
                found[h["id"]] = flat[j][0] + 1
                cursor = j + 1
                break
        else:
            unresolved.append(h["text"])
    if unresolved:
        die(
            "could not find these headings as standalone lines in the rendered "
            "PDF, so the contents page cannot be numbered: "
            + "; ".join(unresolved)
            + ". The usual cause is a heading long enough to wrap onto a second "
            "line in the rendered page; shorten it."
        )
    return found


def build_one(
    source: Path,
    binary: str,
    want_numbers: bool,
    keep_docx: bool,
    variant: str = "original",
) -> None:
    if not source.is_file():
        die(f"source not found: {source}")
    meta, body = split_front_matter(source.read_text(encoding="utf-8"))
    check_images(body, source)
    headings = extract_headings(body)
    body_html = fold_figures(
        rewrite_headings(body, headings, meta.get("page_break_sections") == "true"),
        source,
        variant,
    )
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    stem = source.stem if variant == "original" else f"{source.stem}-alt-diagrams"

    def assemble(pages: dict[str, int] | None, with_css: bool = True) -> str:
        # Word ignores <style>, and make-pdf's DOCX writer emits the ignored
        # block as literal body text, so the stylesheet is left out there.
        css = brand_css() + "\n" if with_css else ""
        return css + cover_html(meta) + "\n" + toc_html(headings, pages) + "\n" + body_html + "\n"

    # The staged source must sit beside the real one so that relative image
    # paths (../figures/...) resolve identically.
    stage = source.with_name(f".{stem}.staged.md")
    pdf_out = BUILD_DIR / f"{stem}.pdf"
    docx_out = BUILD_DIR / f"{stem}.docx"
    # Render to a scratch path and only move into build/ once every assertion
    # has passed, so a failed run cannot replace the committed deliverable with
    # a half-built one.
    scratch = Path(tempfile.mkdtemp(prefix="usiu-report-"))
    pdf_tmp = scratch / pdf_out.name
    docx_tmp = scratch / docx_out.name
    try:
        # Without the second pass this render *is* the deliverable, so it must
        # not carry the measurement pass's placeholders or sentinel.
        stage.write_text(
            assemble(None if want_numbers else {}), encoding="utf-8", newline="\n"
        )
        run_make_pdf(binary, stage, pdf_tmp, meta, "pdf")

        if want_numbers:
            pdftotext = find_pdftotext()
            pages_text = pdf_pages_text(pdftotext, pdf_tmp)
            body_start = first_body_page(pages_text)
            numbers = locate_headings(pages_text, headings, body_start)

            # Writing the numbers in can itself nudge a heading across a page
            # boundary, which would make the number just written wrong. So
            # re-render and re-measure until the numbers in the document are the
            # numbers the document actually has -- the same fixed-point pass
            # that typesetting systems run for cross-references.
            previous = numbers
            for _ in range(MAX_NUMBERING_PASSES):
                stage.write_text(assemble(numbers), encoding="utf-8", newline="\n")
                run_make_pdf(binary, stage, pdf_tmp, meta, "pdf")
                rendered = pdf_pages_text(pdftotext, pdf_tmp)
                measured = locate_headings(rendered, headings, body_start)
                if measured == numbers:
                    break
                # Keep the previous map separately: rebinding `numbers` to
                # `measured` would leave the give-up branch below comparing a
                # dict against itself, and it would always report nothing.
                previous, numbers = numbers, measured
            else:
                drifted = {
                    k: (previous[k], measured[k])
                    for k in previous
                    if previous[k] != measured[k]
                }
                die(
                    "contents page numbering did not settle after "
                    f"{MAX_NUMBERING_PASSES} "
                    f"{'pass' if MAX_NUMBERING_PASSES == 1 else 'passes'}; "
                    f"these headings keep moving: {drifted}"
                )

        if keep_docx:
            # Page numbers measured from the PDF do not apply once Word
            # repaginates, so the DOCX contents page carries none.
            stage.write_text(assemble({}, with_css=False), encoding="utf-8", newline="\n")
            run_make_pdf(binary, stage, docx_tmp, meta, "docx")

        shutil.move(str(pdf_tmp), str(pdf_out))
        if keep_docx:
            shutil.move(str(docx_tmp), str(docx_out))
    finally:
        if stage.exists():
            stage.unlink()
        shutil.rmtree(scratch, ignore_errors=True)

    print(f"{pdf_out.relative_to(REPO)}  ({pdf_out.stat().st_size // 1024} KB)")
    if keep_docx:
        print(f"{docx_out.relative_to(REPO)}  ({docx_out.stat().st_size // 1024} KB)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sources", nargs="*", help="markdown sources to build (default: --all)")
    ap.add_argument("--all", action="store_true", help="build every *.md in this folder")
    ap.add_argument("--no-toc-numbers", action="store_true", help="skip the second pass that numbers the contents page")
    ap.add_argument("--no-docx", action="store_true", help="build the PDF only")
    ap.add_argument(
        "--diagrams",
        choices=["both", "original", "alternative"],
        default="both",
        help=(
            "which diagram set to build. 'both' (default) emits <name>.pdf with the "
            "original figures and <name>-alt-diagrams.pdf with the redrawn ones, so "
            "the two can be compared side by side"
        ),
    )
    args = ap.parse_args()

    if args.all or not args.sources:
        # Skips README.md and any leftover ".<name>.staged.md" from a killed run.
        sources = sorted(
            p for p in HERE.glob("*.md")
            if p.name != "README.md" and not p.name.startswith(".")
        )
        if not sources:
            die("no report sources found in docs/reports/")
    else:
        # A relative path is resolved against the working directory first (what
        # a shell user expects), falling back to this folder.
        sources = []
        for s in args.sources:
            p = Path(s)
            if not p.is_absolute() and not p.is_file():
                p = HERE / s
            sources.append(p)

    binary = find_make_pdf()
    variants = ["original", "alternative"] if args.diagrams == "both" else [args.diagrams]
    for src in sources:
        for variant in variants:
            build_one(
                src,
                binary,
                want_numbers=not args.no_toc_numbers,
                keep_docx=not args.no_docx,
                variant=variant,
            )


if __name__ == "__main__":
    main()
