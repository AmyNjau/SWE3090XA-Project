# SWE3090XA — Smart Health

Symptom checker + doctor recommendation system. Three tiers: Flutter client
(`mobile/`), Node.js/Express API + rule engine (`backend/`), swappable data +
Maps layer. See `README.md` for architecture and `LAUNCH.md` to run the demo.
The defence deck lives in `presentation/`.

## Milestone workflow (do this autonomously for every milestone)

The user reviews after the fact on `main`. For each milestone:
1. New branch off `main` — never commit directly to `main`.
2. Commit + push the branch, open a PR (`gh pr create`).
3. Spawn my own sub-agent (Agent tool) to review the diff and give critical feedback.
4. Address the feedback.
5. Merge the PR to `main` and push.

Remote: `origin` = github.com/AmyNjau/SWE3090XA-Project (`gh` authed as AmyNjau).

## Coding preferences

- **TypeScript:** never use `any` unless 100% necessary or explicitly instructed.
- **Commands:** don't run dev-server commands (assume it's running); don't run build
  commands unless told; DO run checks like typecheck/lint.
- **Package managers:** `pnpm` if the project already uses it, else `bun`. Never `npm`/`yarn`.
- **Tech stack (when uncertain, prefer):** Tailwind, TypeScript, Bun, React, Convex, Clerk, Cloudflare.
- **Code style:** concise, simple solutions; propose a simpler approach when one exists.
- **Scope:** if asked to do too much at once, stop and say so.
- **Verification:** use a sub-agent when computer use helps complete/verify work.

## Project-specific notes

- Repo lives on Google Drive, which can't host `node_modules`. In `backend/`, use
  `npm run setup` (installs deps to local disk via `NODE_PATH`) — not plain `npm install`.
- The Android build runs from a local-disk copy, not from Drive. See `LAUNCH.md`.
- `presentation/index.html` is the editable deck; `presentation/Smart-Health-Presentation.html`
  is the phone-ready single-file build (regenerate via `python build-standalone.py`).
