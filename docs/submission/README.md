# Submission package

The final deliverable handed to the lecturer is a zip of this project containing
only what is needed to **read the reports and run the app** — no agent or tooling
scaffolding, and none of the private defence material.

```bash
python docs/submission/build.py
```

That writes `Smart-Health-SWE3090XA-Amy-Njau-669008-Submission.zip` to the
repository root. The zip is a build artifact and is gitignored: rebuild it, never
edit it in place.

## What the script guarantees

- **Descriptive names.** Nothing inside is named after a build slug; the folders
  are numbered in reading order (`1 - Reports` … `4 - Diagrams`).
- **One diagram set.** Every report is the `-alt-diagrams` build, so all
  documents use the same redrawn figures, and `4 - Diagrams` ships those same
  SVGs.
- **PDFs are the deliverable**; the DOCX copies sit in a clearly-labelled
  *Editable Word Versions* subfolder.
- **A runnable copy of the system**: `backend/` and `mobile/` complete, including
  the Android project and a `backend/.env` with the Firebase project id the API
  needs to verify sign-in tokens. Generated and machine-specific files
  (`node_modules`, `build/`, `.dart_tool`, `local.properties`,
  `.flutter-plugins-dependencies`) are left out.
- **Nothing private or internal**: `CLAUDE.md`, `PROJECT.md`, `LAUNCH.md`,
  `.claude/`, `.gstack/`, `.git/` and the defence notes are all excluded, and the
  build **fails** if any of them reaches the archive.

The build writes to a temporary file and only replaces the existing zip once
every check has passed, so a failed run cannot leave a broken submission behind.

## Editing what goes in

- `submission-readme.md` — becomes `README.md` at the top of the zip.
- `how-to-run-the-app.md` — becomes `3 - Source Code/How to Run the App.md`.
  This is the run guide written for the lecturer; the repo's `LAUNCH.md` is the
  author's own demo-day notes and is deliberately not shipped.
- `build.py` — the file list, the exclusions, and the checks.
