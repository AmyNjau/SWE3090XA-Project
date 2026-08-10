# Reports

USIU-Africa branded reports, written as markdown and built to PDF + DOCX by
`build.py`. The branding (logos, palette, cover and header conventions) comes
from `../brand/README.md`; the figures come from `../figures/`.

## Build

```bash
cd docs/reports
python build.py system-integration-report.md   # one report
python build.py --all                          # every *.md here
```

Outputs land in `build/`, and both are committed so the finished documents can
be downloaded from GitHub without anyone having to run the build.

**The PDF is the submission artifact.** The DOCX is an editable convenience
copy: it carries the full text, tables and figures, but Word ignores the
stylesheet, so it has no branding, no title-page break and no working contents
links. Submit the PDF; use the DOCX only if you need to edit in Word.

Nothing is written into `build/` until every check has passed, so a failed run
leaves the previous good documents untouched.

Useful flags:

| Flag | Effect |
|---|---|
| `--no-docx` | PDF only (faster while iterating on wording) |
| `--no-toc-numbers` | Build without the measuring pass; the contents page then lists sections with no page numbers |
| `--diagrams original\|alternative\|both` | Which diagram set to use. Default `both` |

## Two diagram sets

Every report is built twice, so you can pick whichever version you prefer to
submit:

| Output | Diagrams |
|---|---|
| `<name>.pdf` | The original figures from `../figures/` |
| `<name>-alt-diagrams.pdf` | The redrawn set from `../figures/alt/` |

The prose is identical; only the figures differ. There is no duplicated source.

To provide an alternative for a figure, drop an SVG next to the original with
the same stem, under an `alt/` subfolder: `../figures/x.png` is matched by
`../figures/alt/x.svg`. The build inlines that SVG, so it stays vector-crisp in
print. Any figure without an alternative simply keeps its original in both
documents.

The redrawn diagrams are hand-authored SVG in the USIU palette rather than
generated, because the generated route rendered as solid black boxes with
clipped labels in this toolchain.

## Writing a report

Each source is plain markdown with a front-matter block that feeds the cover:

```markdown
---
title: System Integration Report
project: Smart Health Symptom Checker and Doctor Recommendation System
course_code: SWE3090XA
course_title: Software Engineering Final Project
school: School of Science and Technology
department: Department of Computing
student: Amy Wanjugu Njau
student_id: 669008
supervisor: Mr Fredrick Ogore
date: June 2026
semester: Summer Semester 2026      # optional
---
```

Every key except `semester` is required; the build fails if one is missing.

Conventions the stylesheet expects:

- `#` is a top-level section and starts a new page; `##` is a subsection. Both
  are picked up into the contents page automatically, so do **not** write a
  contents page by hand. Section numbers are written by hand in the heading
  text (`# 3. Integration Architecture`); nothing is auto-numbered.
- Captions are a lone italic line under the figure or table:
  `*Figure 3.1: Integration architecture.*`
- Figures are normal markdown images pointing at `../figures/`:
  `![Architecture](../figures/fig3_1_architecture.png)`. An image immediately
  followed by an italic caption line is folded into a single unbreakable
  `<figure>`, so a figure is never split from its caption or stranded on a page
  of its own.
- Images must be local files that exist. Remote images are rejected so the build
  stays reproducible offline.

Rules headings must follow, all of them enforced with a loud failure rather
than a silently wrong contents page:

- A heading must not **wrap onto a second line** when rendered. Keep it short.
- Each heading's exact text must appear in the rendered body once per heading.
  Two sections may share a title, but no ordinary line of body text may be
  identical to a heading.
- Setext headings (`Heading` underlined with `===` or `---`) are rejected; use
  `#` and `##`.
- Headings are emitted as raw HTML, so markdown emphasis inside them
  (`**bold**`) renders as literal asterisks. Keep headings plain text.

## How the build works

`build.py` wraps gstack's `make-pdf` (markdown, tables, syntax highlighting,
image inlining) and adds the branding on top:

1. The front matter is split off and validated.
2. Headings are rewritten to anchored HTML so the contents page can link to them,
   and each top-level section gets an explicit page break.
3. The branded cover, the contents page and the stylesheet are prepended.
4. The document is rendered repeatedly until the contents page settles. The
   first render measures which page each heading landed on; each subsequent one
   writes those numbers in and re-measures.

That loop exists because this toolchain has no Paged.js, so the CSS
`target-counter()` that would normally number a contents page never resolves.
Writing the numbers in can itself nudge a heading across a page boundary, so the
build iterates to a fixed point the way a typesetting system resolves
cross-references, and gives up loudly if the numbers have not settled after five
passes rather than ship a contents page that lies.

During the measuring pass only, each contents row carries an invisible sentinel
so those pages can be excluded when locating body headings. Text extraction
splits a contents row into separate runs, which otherwise makes it
indistinguishable from the heading it points at. The sentinel never appears in
the delivered document.

## Requirements

- `make-pdf` from gstack (`pdf.exe`). Set `MAKE_PDF_BIN` if it is somewhere
  unusual; if that variable points at a non-file the build stops rather than
  quietly falling back.
- `pdftotext` to number the contents page. Git for Windows ships one (Xpdf, at
  `C:\Program Files\Git\mingw64\bin`), and poppler provides it elsewhere. It is
  always invoked with `-enc UTF-8`, because Xpdf otherwise emits Latin-1 and
  mangles any non-ASCII heading. Without `pdftotext`, build with
  `--no-toc-numbers`.

The build exits non-zero on a missing tool, a missing brand asset, a missing or
remote image, a missing front-matter key, a rejected heading style, a heading it
cannot locate, an ambiguous heading title, or any change in pagination between
the two passes. Output is moved into `build/` only after all of that passes.
