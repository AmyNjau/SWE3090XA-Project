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

Outputs land in `build/`. Both the PDF and the DOCX are committed so the
finished documents can be downloaded from GitHub and submitted without anyone
having to run the build.

Useful flags:

| Flag | Effect |
|---|---|
| `--no-docx` | PDF only (faster while iterating on wording) |
| `--no-toc-numbers` | Skip the second pass that numbers the contents page |

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

- `#` is a numbered top-level section and starts a new page. `##` is a
  subsection. Both are picked up into the contents page automatically, so do
  **not** write a contents page by hand.
- Captions are a lone italic line under the figure or table:
  `*Figure 3.1: Integration architecture.*`
- Figures are normal markdown images pointing at `../figures/`, optionally sized:
  `![Architecture](../figures/fig3_1_architecture.png){width=full}`
- Images must be local files that exist. Remote images are rejected so the build
  stays reproducible offline.

## How the build works

`build.py` wraps gstack's `make-pdf` (markdown, tables, syntax highlighting,
image inlining) and adds the branding on top:

1. The front matter is split off and validated.
2. Headings are rewritten to anchored HTML so the contents page can link to them,
   and each top-level section gets an explicit page break.
3. The branded cover, the contents page and the stylesheet are prepended.
4. The document is rendered **twice**. The first pass measures which page each
   heading landed on; the second fills those numbers into the contents page.

The second pass exists because this toolchain has no Paged.js, so the CSS
`target-counter()` that would normally number a contents page never resolves.
Filling numbers in does not reflow anything, and the build asserts that: if the
page count or any heading's page moves between the two passes, it fails rather
than ship a contents page that lies.

During the measuring pass only, each contents row carries an invisible sentinel
so those pages can be excluded when locating body headings. Text extraction
splits a contents row into separate runs, which otherwise makes it
indistinguishable from the heading it points at. The sentinel never appears in
the delivered document.

## Requirements

- `make-pdf` from gstack (`pdf.exe`). Set `MAKE_PDF_BIN` if it is somewhere
  unusual.
- `pdftotext` (poppler; ships with Git for Windows) to number the contents page.
  Without it, build with `--no-toc-numbers`.

The build fails loudly and exits non-zero on a missing tool, a missing brand
asset, a missing image, a missing front-matter key, or a heading it cannot
locate. It never emits a document that is quietly wrong.
