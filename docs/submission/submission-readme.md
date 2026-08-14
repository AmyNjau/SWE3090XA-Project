# Smart Health — Final Project Submission (SWE3090XA)

**Symptom Checker and Doctor Recommendation System**

| | |
|---|---|
| Student | Amy Wanjugu Njau |
| Student ID | 669008 |
| Course | SWE3090XA — Software Engineering Final Project |
| Supervisor | Mr Fredrick Ogore |
| School / Department | School of Science and Technology — Department of Computing |
| Institution | United States International University – Africa |
| Semester | Summer Semester 2026 |

> **Guidance tool, not a medical device.** Smart Health provides triage guidance
> only. Its symptom-to-condition knowledge base is an educational rule set that
> has **not** been clinically validated, and the application must not be used to
> make decisions about a real patient.

---

## What is in this folder

| Folder | What it holds |
|---|---|
| **1 - Reports** | The four written deliverables as PDFs, plus editable Word copies and the earlier coursework submissions. |
| **2 - Presentation** | The defence slide deck. One self-contained HTML file — double-click it, no internet needed. |
| **3 - Source Code** | The complete, runnable system: the Node.js API and rule engine (`backend/`) and the Flutter app (`mobile/`), with instructions for running both. |
| **4 - Diagrams** | The architecture, sequence and entity-relationship diagrams as standalone image files (the same drawings that appear in the reports). |
| `LICENCE.txt` | Copyright and terms of use, under the Copyright Act, 2001 (Laws of Kenya). |

### The reports, in reading order

1. **Project Concept** and **Mid-Term Report** — the proposal and the mid-semester
   progress position (in `1 - Reports`, the concept under *Earlier Coursework
   Submissions*).
2. **System Integration Report** — how the three tiers are integrated, with the
   integration architecture and data-flow diagrams.
3. **End of Semester Project Report** — the main deliverable: literature review,
   methodology, design, implementation, testing, results, limitations and
   recommendations.
4. **Student Project Log-Book** — the week-by-week record of supervision and work
   done.

---

## The system in one paragraph

The user selects symptoms in a Flutter mobile app. The app calls a Node.js /
Express REST API, which runs a **rule-based, explainable diagnostic engine**: for
each candidate condition it sums the weights of the symptoms the user reported
and divides by that condition's maximum possible weight, giving a normalised
confidence score. Conditions above a threshold are ranked and returned **together
with the exact symptoms that produced each score**, so every number can be traced
back to its evidence. The API then maps the top condition to a medical specialist
and returns nearby providers for that specialist, ranked by distance from the
user's location. A safety disclaimer is attached centrally to every diagnosis
response so it cannot be omitted.

```
Flutter app  ──POST /api/diagnose──▶  Express API  ──▶  rule engine (weighted scoring)
             ◀──ranked conditions + specialist + disclaimer──
             ──POST /api/providers─▶  provider lookup (distance-ranked)
             ◀──nearby providers──
```

The data store and the maps provider sit behind interfaces and are selected by
environment variable (`DATA_STORE`, `PROVIDER_SOURCE`), so the local JSON store
can be swapped for Firebase Firestore, and the sample provider list for the
Google Maps Platform, without changing the engine, the routes or the UI.

---

## How to run it

Full step-by-step instructions, including the emulator and Firebase sign-in, are
in **`3 - Source Code/How to Run the App.md`**. The short version:

**1. Start the API** (Node.js 18 or newer):

```bash
cd "3 - Source Code/backend"
npm install
npm start                 # http://localhost:3000
```

Check it is alive, and see the rule engine answer directly:

```bash
curl -X POST http://localhost:3000/api/diagnose \
  -H "Content-Type: application/json" \
  -d "{\"symptoms\":[\"fever\",\"chills\",\"headache\"]}"
```

Run the automated tests (25 tests — engine, API, validation and authentication):

```bash
npm test
```

**2. Run the app** (Flutter 3.10 or newer, with an Android emulator or device):

```bash
cd "3 - Source Code/mobile"
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` is how the Android emulator reaches the host machine's `localhost`.
On a physical phone, use the computer's LAN address instead.

**Suggested walkthrough:** Home → **Check** → select **Fever + Headache +
Chills** → **Analyse** → *Malaria ≈ 55%* with the "Why this match" chips →
**Find Nearby Doctors** → **Directions** → **History** → **Profile**.

---

## Where to find the marked features in the code

| Feature | File |
|---|---|
| Weighted symptom–condition knowledge base | `backend/src/data/knowledge_base.json` |
| Rule-based diagnostic engine (the scoring rule) | `backend/src/services/diagnosisEngine.js` |
| Diagnosis endpoint | `backend/src/routes/diagnose.js` |
| Specialist recommendation | `backend/src/services/diagnosisService.js`, `data/specialists.json` |
| Nearby provider lookup (geolocation, distance ranking) | `backend/src/services/providerService.js`, `utils/geo.js` |
| Firebase ID-token verification | `backend/src/middleware/auth.js`, `services/authService.js` |
| Central safety disclaimer | `backend/src/config/index.js` |
| Data-store interface and swappable stores | `backend/src/repositories/` |
| Automated tests | `backend/tests/` |
| App screens (symptom input, results, providers, history, profile) | `mobile/lib/screens/` |
| The app's single point of contact with the API | `mobile/lib/services/api_service.dart` |

---

## Known limitations (also stated in the End of Semester Report)

- The knowledge base is an educational rule set and has **not** been clinically
  validated.
- The Firestore data store is a documented stub; the working configuration is the
  local JSON store, and the query log is held in memory and cleared on restart.
- Nearby providers come from a sample data set by default; the Google Maps
  Platform path is implemented but needs an API key.
- API hardening (rate limiting, CORS allow-list, security headers) is identified
  as further work.

---

Copyright © 2026 Amy Wanjugu Njau. All rights reserved — see `LICENCE.txt`.
