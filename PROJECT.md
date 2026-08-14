# PROJECT.md — Smart Health (SWE3090XA)

Working memory for this repository. **Any agent picking up this project should read
this file first**, then `CLAUDE.md` (rules), `README.md` (architecture) and
`LAUNCH.md` (how to run the demo).

- **Repo:** `github.com/AmyNjau/SWE3090XA-Project` (`origin`, `gh` authed as AmyNjau)
- **Default branch:** `main`
- **Local path:** `G:\My Drive\Claude\SWE3090XA` (Google Drive — see the constraint below)
- **Author:** Amy Wanjugu Njau (ID 669008) · Supervisor: Mr Fredrick Ogore · USIU-Africa
- **Last updated:** 2026-08-14

---

## 1. The user's personal preferences — saved word for word

> These are reproduced verbatim at the user's explicit request so that any future
> agent, in any chat, knows exactly what to do. Follow them literally.

```
## Code Style
- Always strive for concise, simple solutions.
- If a problem can be solved in a simpler way, propose it.

## General preferences
- If asked to do too much work at once, stop and state that clearly.
- If computer use is helpful for completing or verifying work, use a sub-agent for it.
- I give you full permission to use all your skills and access everything.
- For every milestone achieved, I want you to commit and push into a new PR for
  review, then use your own sub-agent to review and give yourself feedback before
  you merge it to the main branch. So yes all of these steps you'll do, I'll just
  manually review when you've already pushed and committed after review on the main
  branch. The main branch should be the default branch that you will initialize with.
- Create a "PROJECT.md" file where you'll be writing down what you've done and what
  you're planning to do. This will help when I use another agent in future on a
  separate chat for them to reference. (Meaning you also save this personal
  preferences word for word so that they exactly know what to do)
- From now hence forth, I really want you to be obsessed with the attention to
  detail. I want you when you do everything, do it to perfection and also as you
  review, the review is always thorough per PR. Save this to your memory and the
  project.md file so that you'll never forget.
- The goal is to have a fully secure, production-ready product.
```

### Standing instructions added 2026-08-10

These came directly from the user and override earlier sequencing.

**The goal is a strong A.** Every graded artifact is optimised for marks, not
merely for being finished. When the choice is between "good enough" and "what a
marker would reward", pick the latter.

**Delivery order — do not reorder without being asked:**

1. The **end-semester report** (done — `docs/reports/end-semester-report.md`).
2. **Firebase login** — email/password, full stack.
3. The **internal notes presentation** (see below).
4. Everything else.

**The presentation is the most important artifact overall**, even though it is
sequenced after the two items above. Two decks are required and must stay
separate:

- `presentation/index.html` — what the lecturer sees.
- A **private internal-notes deck** that only the user reads while presenting.
  It must carry the full presenting script plus **every question the lecturer
  might plausibly ask**. The lecturer is known to probe **the code and the
  backend**, so it has to go deep on `backend/` and be answerable without
  opening an editor. Never show or publish this one.

**Repo and folder are one thing.** `G:\My Drive\Claude\SWE3090XA` and
`github.com/AmyNjau/SWE3090XA-Project` must stay in sync. Never leave work
committed locally but unpushed, or pushed but unmerged.

**Licensing** must suit Kenyan law (Copyright Act 2001, academic work by a
USIU-Africa student).

**The final milestone of the whole project** is a **submission zip** of this
folder containing only what the lecturer needs to run the app and read the
reports. Exclude agent and tooling scaffolding: `CLAUDE.md`, `PROJECT.md`,
`.gstack/`, `.claude/`, `.git/`, caches, and both private defence-notes files.
Everything inside must be **named so the lecturer can navigate it unaided** —
descriptive names, not build slugs — with a short README at the top.
**Use the `-alt-diagrams` build of every report** (the redrawn SVG diagram set)
so all documents are visually consistent. Ship the PDFs; the DOCX files are
editable copies only.

### What that means in practice

**The milestone loop — run it autonomously, every time:**

1. Branch off `main`. Never commit to `main` directly.
2. Commit + push, open a PR (`gh pr create`).
3. Spawn your **own sub-agent** (Agent tool) to review the diff and give critical feedback.
4. Address that feedback — actually fix it, don't just acknowledge it.
5. Merge to `main` and push.
6. Update this file's changelog (§6) before you finish.

The user reviews **after** the fact, on `main`. Do not stop to ask for permission
mid-loop.

**Attention to detail is the standing bar.** Do not ship "probably fine". Verify
claims against the running system, not against intent. If a change touches the UI,
look at it in a browser. If it touches the API, run the tests. If a doc describes
behaviour, re-read the doc after the change and confirm every sentence is still
true — stale docs have already caused two defects here (see §6).

**Reviews are thorough, per PR, no exceptions** — including small PRs.

---

## 2. What this project is

A symptom checker and doctor-recommendation system. The user enters symptoms; a
**rule-based, explainable engine** returns ranked probable conditions with the exact
symptoms that produced each score, recommends a specialist, and finds nearby
providers by location.

> **Guidance tool, not a medical device.** The knowledge base is an educational rule
> set and is **not clinically validated**. A disclaimer is attached centrally to every
> diagnosis response (`backend/src/config/index.js`) so it cannot be forgotten.

**Why rule-based and not ML:** every score traces back to specific weighted symptoms,
so the reasoning is auditable. That explainability is the project's core contribution
and the thing to defend in the viva.

### Three tiers

| Tier | Technology | Folder |
|------|-----------|--------|
| Presentation | Flutter (Dart), Android-first | `mobile/` |
| Application / logic | Node.js + Express REST API, rule engine | `backend/` |
| Data | Local JSON now → Firebase Firestore (swappable) | `backend/src/data`, `backend/src/repositories` |
| Location | Mock providers now → Google Maps Platform (swappable) | `backend/src/services/providerService.js` |

```
User → Flutter app → POST /api/diagnose → rule engine scores conditions
     → ranked conditions + recommended specialist
     → POST /api/providers (specialist + location) → nearby providers
     → results shown with a guidance disclaimer
```

The database and Maps are **mocked behind clean interfaces**. `DATA_STORE` and
`PROVIDER_SOURCE` env vars swap the implementation without touching engine, route or
UI code. That is a deliberate design decision, not a shortcut — say so in the defence.

---

## 3. Codebase map

### `backend/` — Node 18+, Express 4, CommonJS, zero build step

```
src/
  app.js                        createApp() — no port binding, so tests import it directly
  server.js                     binds the port
  config/index.js               all env reads in one place + the central disclaimer
  routes/
    diagnose.js                 POST /api/diagnose
    providers.js                POST /api/providers
    catalog.js                  GET /api/symptoms, GET /api/specialists
  middleware/
    validate.js                 request-body validation → 400s
    auth.js                     Firebase ID token → req.user (verified whenever supplied)
    errorHandler.js             404 + central error handler (never leaks internals on 5xx)
  services/
    authService.js              ID-token verification via firebase-admin (lazy-loaded)
    diagnosisEngine.js          PURE scoring — no I/O, trivially unit-testable
    diagnosisService.js         orchestration: engine + specialist + query log + disclaimer
    providerService.js          mock (haversine ranking) | google (Nearby Search) + TTL cache
  repositories/
    index.js                    factory → returns the configured store singleton
    localDataStore.js           file-backed, in-memory query log
    firestoreDataStore.js       documented STUB — throws until implemented
  data/
    knowledge_base.json         15 conditions, weighted symptom→condition map
    symptoms.json               35 symptoms
    specialists.json            9 specialists (+ Maps search keywords)
    providers.json              12 sample providers
  utils/geo.js                  haversine distance
tests/                          25 tests (node:test) — api / auth / diagnosisEngine
scripts/                        setup.js / run.js / deps.js — the Google Drive workaround
```

**The scoring rule** (`diagnosisEngine.js`): for each condition, sum the weights of
the symptoms the user reported, divide by that condition's maximum possible weight →
a normalised 0..1 confidence. Filter below `threshold` (0.2), sort descending, cap at
`maxResults` (5). Results carry `matchedSymptoms` for explainability.

### `mobile/` — Flutter 3.10+ / Dart 3

```
lib/
  config.dart                   API_BASE_URL via --dart-define; Nairobi fallback coords
  main.dart, theme/app_theme.dart
  screens/                      auth_gate + sign_in, main_shell (tabbed) + home,
                                symptom_input, results, providers, history,
                                profile, notifications
  services/api_service.dart     the ONLY point of contact with the API
  services/auth_service.dart    Firebase email/password sign-in + ID tokens
  services/location_service.dart
  state/history_store.dart      in-app Query history
  models/                       symptom, condition, diagnosis_result, provider
  widgets/                      condition_card, provider_card, symptom_chip,
                                specialist_panel, disclaimer_banner, step_indicator,
                                map_placeholder, app_bottom_nav
```

The client holds **no diagnostic logic**. It collects input, calls the API, and maps
JSON into typed models. That separation is deliberate and defensible.

### `presentation/` — the defence deck

- `index.html` — the **editable source**, 24 slides, references `./assets/`.
- `Smart-Health-Presentation.html` — **generated** single-file build (~2 MB) with all
  9 images inlined as base64. This is the phone-ready file. It is committed
  deliberately, despite being a build artifact, so the file can be downloaded from
  GitHub and AirDropped without anyone running a build; the cost is ~2 MB of history
  per deck revision. `.gitattributes` marks it (and `index.html`) binary-ish `-text`
  so line endings survive and the diff is never a whole-file rewrite.
- `build-standalone.py` — regenerates the above. **Run it after every edit to
  `index.html`**, or the phone build goes stale. It fails loudly (non-zero exit) if
  an asset is missing or any `./assets/` reference survives, rather than emitting a
  file that only breaks on the presenter's phone.
- `assets/` — 6 app screenshots + 3 report figures.

Notes panel is **hidden by default** on every device. With notes closed the deck fits
without scrolling at 1280×720 → 1920×1080.

### Docs at the repo root

`README.md` (architecture + report mapping), `LAUNCH.md` (demo run instructions),
`CLAUDE.md` (rules for agents), `LICENSE` (Kenyan copyright terms), plus the
submitted `.docx`/`.pdf` reports.

### `docs/submission/` — the deliverable zip

`build.py` assembles the lecturer-facing submission from the rest of the repo:
renamed reports, the single-file deck, a runnable copy of the code, and
`submission-readme.md` / `how-to-run-the-app.md` written for a marker rather than
for the author. It refuses to produce an archive containing anything internal.
Run `python docs/submission/build.py` after any change that belongs in the
submission.

---

## 4. Hard constraints — read before you run anything

1. **Google Drive cannot host `node_modules`.** In `backend/`, run `npm run setup`
   (installs deps to local disk and points Node at them via `NODE_PATH`) — **never a
   plain `npm install`**. `npm start` / `npm test` go through `scripts/run.js`, which
   sets `NODE_PATH` for the child process.
2. **The Android build runs from a local-disk copy**, not from Drive:
   `C:\Users\amnja\swe3090xa-mobile`. `mobile/` here is the canonical source; copy
   changed files into the local copy before running. See `LAUNCH.md`.
3. **Don't run dev-server or build commands** unless told. Do run checks
   (tests / lint / typecheck).
4. **Package managers:** `pnpm` if the project already uses it, else `bun`. Never
   `npm`/`yarn` — *except* `backend/`, which is locked to the `npm run setup`
   workaround above.
5. **TypeScript: never use `any`** unless 100% necessary or explicitly instructed.

---

## 5. Current status

**Working and verified:**

- ✅ Backend: knowledge base, weighted explainable engine, specialist routing,
  provider lookup (mock + Maps-ready), TTL cache, validation, anonymised query
  logging, central disclaimer.
- ✅ **25/25 backend tests passing** (`cd backend && npm test`, verified 2026-08-14) —
  engine, API, validation, error handling and Firebase ID-token verification.
- ✅ Firebase email/password sign-in end to end: auth gate in the app, ID token on
  every API call, token verification in `backend/src/middleware/auth.js`.
- ✅ Mobile: tabbed shell (Home, Check, History, Profile), full
  symptom → conditions → providers flow, "why this match" explainability chips,
  in-app history, profile, graceful location-permission fallback, live Directions.
- ✅ Presentation: 24 slides, speaker script + scoring cue on every slide, responsive,
  phone-ready single-file build. Layout measured in a headless browser across
  1024×768, 1280×720, 1366×768, 1440×900, 1536×864, 1920×1080, 844×390, 390×844 and
  360×640 — notes open and closed, all 24 slides, source **and** standalone build:
  **zero occlusion and zero unreachable content** in every combination. Fullscreen
  with notes closed fits without scrolling from 1366×768 up; smaller or notes-open
  combinations scroll inside the slide card rather than cutting content off.

**Known gaps (deliberate, prototype-stage):**

- `FirestoreDataStore` is a stub that throws — `DATA_STORE=local` is the only working store.
- Query log is in-memory and lost on restart.
- The knowledge base is not clinically validated.
- `AUTH_REQUIRED` is off by default, so the API still answers anonymous callers
  in the demo configuration (a supplied token is always verified).
- No CI pipeline; API hardening (Milestone A) is still outstanding.

---

## 6. Changelog — what has been done

| Date | Milestone | Detail |
|------|-----------|--------|
| 2026-06 | Backend core | Knowledge base, engine, routes, repositories, 15 tests |
| 2026-06 | Mobile app | Full flow + premium tabbed shell, explainability surfacing |
| 2026-06 | Report figures | `docs/figures/` — architecture, sequence, ERD |
| 2026-06 | `LAUNCH.md` | One-command demo launcher + manual path |
| 2026-07 | Defence deck | 24-slide HTML deck with speaker notes and scoring cues |
| 2026-07 | Deck responsive | Phone breakpoints, code-block rendering fix |
| 2026-07–08 | **PR #1** | Notes-overlap fix, phone-ready standalone build, `CLAUDE.md`, this file |
| 2026-08-10 | **PR #2** | USIU brand assets + `docs/reports/build.py` branded report pipeline; System Integration Report rebuilt from markdown |
| 2026-08-10 | **PR #3** | End-of-semester report; two diagram sets per report (original vs redrawn) |
| 2026-08-10 | **PR #4** | Firebase sign-in (app + API token verification), private defence notes, logbook, reference-matched report formatting |
| 2026-08-14 | **PR #5** | **Submission package** — `docs/submission/build.py` builds the lecturer-facing zip; Kenyan-law licence; `mobile/android/` tracked; Android manifest defect fixed |

**Defects found and fixed while building the submission (PR #5):**

1. **The Android app could never get a location.** When `mobile/android/` was
   regenerated so the app would build from the Drive folder (commit `e084fae`),
   the hand-made manifest changes were lost: `ACCESS_FINE_LOCATION` and
   `ACCESS_COARSE_LOCATION` were gone, so the runtime permission could not be
   granted and every nearby-provider lookup silently fell back to the default
   Nairobi coordinates. The `<queries>` entry for `url_launcher` (the Directions
   button, needed on Android 11+) and `usesCleartextTraffic` had gone with them.
   Found by diffing the Drive copy against `C:\Users\amnja\swe3090xa-mobile`,
   which still had all three. Fixed, and `mobile/android/` is now **tracked** so
   it cannot happen again.
2. **`npm install` did not work off Google Drive.** `scripts/run.js` refused to
   start unless the local-disk workaround had been run, so the submitted copy
   would have failed on the marker's machine with a message about Google Drive —
   and `backend/README.md` already claimed a normal install worked. It now uses
   a project-local `node_modules` when one exists. Verified by installing and
   running the tests from the extracted zip: 25/25 pass.
3. **Signed-in requests would have 500'd.** `.env` is gitignored, and without
   `FIREBASE_PROJECT_ID` the API rejects every ID token. The zip now ships a
   `backend/.env`.

**Defects found and fixed while verifying PR #2** (the sub-agent review caught
all four blockers; every one was reproduced before being fixed):

1. **Every figure caption was orphaned** onto the page after its figure, leaving
   two near-blank pages. An image plus its italic caption is now folded into one
   unbreakable `<figure>`; the report went from 18 pages to 15.
2. **Contents numbers could be silently wrong.** The page cursor advanced to the
   matched *page* rather than past the matched *line*, so a repeated heading
   title re-matched its own earlier occurrence; and a heading whose text also
   appeared as an ordinary body line took that line's page. Both passes made the
   identical mistake, so the drift check could never catch either.
3. **`--no-toc-numbers` shipped the measurement pass**, emitting a contents page
   of `0`s plus 31 copies of the invisible sentinel — and it was the documented
   fallback for machines without `pdftotext`.
4. **A failed build overwrote the committed deliverable**, because output was
   written straight into `build/` before any assertion ran.

**The lesson from PR #2, worth remembering:** the first build "worked" — exit 0,
correct page count, plausible contents page — and was still wrong in four ways
that only a page-by-page look at the rendered output revealed. Exit codes are
not verification.

**Defects found and fixed while verifying PR #1** (recorded because they show the
failure mode to watch for — *claims not checked against the running page*):

1. **Notes panel overlaid slide content.** Notes were fixed to the bottom, open by
   default, reserving no layout space. Fixed: notes default closed; when open, a
   `--notes-h` variable drives space reservation for `#stage`, `.slide` and `#hud`.
2. **Tall content painted over the slide header.** `.cols` had `height:100%` with
   `align-items:center`, so a column taller than the row (the phone mockups, ~562 px)
   overflowed *upward* and drew on top of the kicker and heading. Visible at 1366×768,
   the most common projector resolution. Fixed with `min-height:100%` plus
   height-aware `.device` sizing, so the mockups shrink to the space available instead
   of overflowing. Verified: zero scrolling and zero overlap with notes closed at every
   laptop resolution tested.
3. **`presentation/README.md` had gone stale.** It claimed "21 slides" (there are 24)
   and "speaker notes shown by default" (they are hidden by default, changed in the
   same PR). Corrected.
4. **The same centring flaw again, one level up.** The sub-agent review caught that
   `.body` had `justify-content:center` with the identical failure mode, still
   occluding headings at 1280×720 and 1366×768 with notes open — and that fix (2)
   had *introduced* a regression at 360×640. Root cause for both: plain centring
   overflows in **both** directions. Fixed properly with `justify-content:safe center`
   / `align-items:safe center`, which start-aligns the moment content would overflow.
5. **Content was squeezed and unreachable.** `.slide` had `overflow-y:auto`, but
   `.body` is the flex child that actually gets compressed, so the slide's scrollbar
   never engaged and content was silently cut. Moved the scroll to `.body`.
6. **The HUD sat on top of slide text** when notes were open — `#stage` reserved
   `--notes-h + 26px` but the HUD occupies `--notes-h + 12px` plus its own 34px.
   Now reserves `--notes-h + 70px`, matching the notes-closed clearance.
7. **Mockups sized off the viewport, not the slide.** `.slide` is capped at
   `min(680px, 82vh)`, so on a big screen a 262px mockup overflowed regardless of
   viewport height. Now sized from a `--slide-h` variable that mirrors the cap, with
   a `clamp()` floor so a mockup never shrinks below legibility.
8. **Stale slide-index comments.** `/* 4 */` appeared twice and everything after was
   off by two, so `go(n)` and the comments disagreed. Renumbered 0–23.
9. **`build-standalone.py` was not reproducible off Windows** (`open(..., "w")`
   rewrote every line ending) and failed silently on unmatched assets. Now uses
   `newline=""`, asserts no `${A}` or `./assets/` survives, and exits non-zero.

**The lesson, recorded because it is the failure mode to watch for:** the first pass
declared victory on a measurement that was too narrow — it checked whether the
*slide box* overlapped the notes, not whether *content inside the slide* was painting
over its own heading. The measurement has to target the thing that actually breaks.

---

## 7. Roadmap — what is planned next

**The user's delivery order takes precedence over the milestone letters below.**
Firebase login, the internal notes deck and the submission package are done.
The security work in
Milestone A remains the top *engineering* priority and is already written up as
a limitation in the end-of-semester report.

### Milestone R — Reports (done 2026-08-10)

- [x] `docs/reports/build.py` — markdown to USIU-branded PDF + DOCX.
- [x] System Integration Report rebuilt from markdown.
- [x] End-of-semester report written and built.
- [x] Two diagram sets per report: originals in `docs/figures/`, redrawn SVGs in
      `docs/figures/alt/`. Every report builds both ways so the user can choose.
- [ ] Rebuild the logbook through the same pipeline.

### Milestone F — Firebase login (do this next)

- [ ] Enable email/password on the existing project `smart-health-swe3090xa`
      (an Android app is already registered for `com.example.smart_health`).
- [ ] `firebase-admin` token-verification middleware on the backend; protect the
      routes; attach the uid to the query log.
- [ ] Flutter sign-in/sign-up, auth gate, ID token on API calls, per-user History.
- [ ] Note that `mobile/android/` lives only in the local-disk copy, so
      `google-services.json` and the Gradle plugin edits must be documented in
      `LAUNCH.md` rather than committed here.

### Milestone P — Presentation

- [ ] Private internal-notes deck: full script plus anticipated lecturer
      questions, weighted to code and backend. Never shown to the lecturer.
- [ ] Refresh the lecturer-facing deck to match the delivered system.

### Milestone Z — Submission (done 2026-08-14)

- [x] `docs/submission/build.py` builds
      `Smart-Health-SWE3090XA-Amy-Njau-669008-Submission.zip` (~8 MB, 110 files):
      numbered folders in reading order, `-alt-diagrams` PDFs, editable DOCX in a
      labelled subfolder, the single-file deck, a runnable `backend/` + `mobile/`
      (Android project and `.env` included), and a README at the top. The build
      fails if any excluded file — `CLAUDE.md`, `PROJECT.md`, `LAUNCH.md`,
      `.claude/`, `.gstack/`, `.git/`, caches, the private defence notes — reaches
      the archive. Rebuild it rather than editing it; it is gitignored.
- [x] `LICENSE` — Copyright Act, 2001 (Laws of Kenya), academic-use terms,
      medical disclaimer, third-party components noted.
- [ ] Re-run `python docs/submission/build.py` after any later change, so the zip
      never lags behind the repo.

### Milestone A — Security hardening of the API

Concrete gaps found by reading `backend/src` on 2026-08-09:

- [ ] **CORS is wide open** — `app.use(cors())` allows every origin. Restrict to an
      allowlist from config.
- [ ] **No security headers** — add `helmet`.
- [ ] **No rate limiting** — `/api/diagnose` and `/api/providers` are unauthenticated
      and uncapped. In `PROVIDER_SOURCE=google` mode this is direct billing exposure.
- [ ] **`radius` and `limit` are unvalidated** (`middleware/validate.js` checks only
      `specialist`, `latitude`, `longitude`). A client can pass an arbitrary radius or
      limit straight into the Maps query. Clamp both server-side.
- [ ] **No cap on the `symptoms` array** — cap its length and each string's length.
- [ ] **Unbounded in-memory growth** — the provider cache `Map`
      (`providerService.js`) and the local query log (`localDataStore.js`) never evict.
      Both grow without limit. Add a size cap / LRU eviction.
- [ ] **No request ID or structured logging**; no `/api/health` readiness split.
- [ ] **Flutter talks cleartext HTTP** — production needs HTTPS and certificate
      validation, and `API_BASE_URL` must not default to a plaintext host in release
      builds.
- [ ] Add `npm audit` to the workflow.

### Milestone B — Real data + location tier

- [ ] Implement `FirestoreDataStore` against the documented interface (the method
      signatures already match `LocalDataStore` exactly — no service or route changes).
- [ ] Persist the query log to Firestore, keeping it anonymised.
- [ ] Wire real Google Maps Platform keys; verify the `google` provider path
      end-to-end; keep the key server-side only (it already is — do not regress that).

### Milestone C — Quality gates

- [ ] GitHub Actions CI: backend tests + `flutter analyze` + `flutter test` on every PR.
- [ ] Lint config for the backend (there is none today).
- [ ] Widen backend test coverage: error handler, cache expiry, `google` provider path
      (mocked `fetch`), validation edge cases.

### Milestone D — Product

- [ ] Authentication (Clerk or Firebase Auth) so History and Profile are per-user.
- [ ] Clinical review of `knowledge_base.json` by a qualified person; record who
      reviewed it and when.
- [ ] Accessibility pass on the Flutter UI (contrast, semantics, text scaling).
- [ ] UAT with real users; record results for the final report.

---

## 8. Quick command reference

```bash
# Backend
cd backend
npm run setup     # FIRST TIME ONLY — installs deps to local disk (Drive workaround)
npm start         # http://localhost:3000
npm test          # 25 tests

# Mobile (from the local-disk copy, not Drive)
cd C:\Users\amnja\swe3090xa-mobile
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Presentation — view it locally
cd presentation && python -m http.server 8899
# → http://127.0.0.1:8899/index.html
python build-standalone.py   # regenerate the phone file AFTER editing index.html

# Milestone loop
git checkout -b <branch> main
gh pr create
gh pr merge --squash
```

## 9. Demo path for the defence

Home dashboard → **Check** → pick **Fever + Headache + Chills** → **Analyse** →
**Malaria 55%** with the "Why this match" chips → **Find Nearby Doctors** →
**Directions** (opens Google Maps) → **History** tab → **Profile** tab.

Keep the backend terminal visible so the panel sees the request hit the rule engine
live. If Nearby Providers spins, it falls back to Nairobi after ~8 s by design; to set
a location instantly:

```powershell
& "C:\Users\amnja\AppData\Local\Android\Sdk\platform-tools\adb.exe" emu geo fix 36.8028 -1.2641
```
