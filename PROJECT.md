# PROJECT.md — Smart Health (SWE3090XA)

Working memory for this repository. **Any agent picking up this project should read
this file first**, then `CLAUDE.md` (rules), `README.md` (architecture) and
`LAUNCH.md` (how to run the demo).

- **Repo:** `github.com/AmyNjau/SWE3090XA-Project` (`origin`, `gh` authed as AmyNjau)
- **Default branch:** `main`
- **Local path:** `G:\My Drive\Claude\SWE3090XA` (Google Drive — see the constraint below)
- **Author:** Amy Wanjugu Njau (ID 669008) · Supervisor: Mr Fredrick Ogore · USIU-Africa
- **Last updated:** 2026-08-09

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
    errorHandler.js             404 + central error handler (never leaks internals on 5xx)
  services/
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
tests/                          15 tests (node:test) — api.test.js + diagnosisEngine.test.js
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
  screens/                      main_shell (tabbed) + home, symptom_input, results,
                                providers, history, profile, notifications
  services/api_service.dart     the ONLY point of contact with the API
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
`CLAUDE.md` (rules for agents), plus the submitted `.docx`/`.pdf` reports.

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
- ✅ **15/15 backend tests passing** (`cd backend && npm test`, verified 2026-08-09).
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
- No authentication; the knowledge base is not clinically validated.
- No CI pipeline.

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

Ordered. The stated goal is **a fully secure, production-ready product**, so security
comes before features.

### Milestone A — Security hardening of the API (do this first)

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
npm test          # 15 tests

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
