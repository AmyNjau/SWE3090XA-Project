# SWE3090XA — Smart Health

Symptom checker + doctor recommendation system. Three tiers: Flutter client
(`mobile/`), Node.js/Express API + rule engine (`backend/`), swappable data +
Maps layer. See `README.md` for architecture and `LAUNCH.md` to run the demo.
The defence deck lives in `presentation/`.

**Read `PROJECT.md` first.** It holds the full rundown, the codebase map, the
user's preferences verbatim, the changelog, and the roadmap.

## The standing bar: attention to detail

Be obsessed with attention to detail. Do everything to perfection, and make the
review **thorough on every PR** — small ones included. The goal is a **fully
secure, production-ready product**, so security work outranks new features.

Verify claims against the running system, never against intent: UI change → look
at it in a browser; API change → run the tests; a doc that describes behaviour →
re-read it after the change and confirm every sentence is still true. Regenerate
generated artifacts when their source changes.

## Milestone workflow (do this autonomously for every milestone)

The user reviews after the fact on `main`. For each milestone:
1. New branch off `main` — never commit directly to `main`.
2. Commit + push the branch, open a PR (`gh pr create`).
3. Spawn my own sub-agent (Agent tool) to review the diff and give critical feedback.
4. Address the feedback.
5. Merge the PR to `main` and push.
6. Update the changelog and roadmap in `PROJECT.md`.

Remote: `origin` = github.com/AmyNjau/SWE3090XA-Project (`gh` authed as AmyNjau).

## Coding preferences

- **TypeScript:** never use `any` unless 100% necessary or explicitly instructed.
- **Commands:** don't run dev-server commands (assume it's running); don't run build
  commands unless told; DO run checks like typecheck/lint.
- **Package managers:** `pnpm` if the project already uses it, else `bun`. Never `npm`/`yarn`
  — **except `backend/`**, which is locked to `npm run setup` by the Google Drive
  workaround below. That exception is deliberate; don't "fix" it.
- **Tech stack (when uncertain, prefer):** Tailwind, TypeScript, Bun, React, Convex, Clerk, Cloudflare.
  This is the user's general preference for *new* projects. **This repo is Flutter +
  Express + plain JS and has no TypeScript** — don't import that stack here.
- **Code style:** concise, simple solutions; propose a simpler approach when one exists.
- **Scope:** if asked to do too much at once, stop and say so.
- **Verification:** use a sub-agent when computer use helps complete/verify work.

## Project-specific notes

- Repo lives on Google Drive, which can't host `node_modules`. In `backend/`, use
  `npm run setup` (installs deps to local disk via `NODE_PATH`) — not plain `npm install`.
- The Android build runs from a local-disk copy, not from Drive. See `LAUNCH.md`.
- `presentation/index.html` is the editable deck; `presentation/Smart-Health-Presentation.html`
  is the phone-ready single-file build (regenerate via `python build-standalone.py`).
