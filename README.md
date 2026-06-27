# SWE3090XA — Smart Health Symptom Checker and Doctor Recommendation System

A cross-platform mobile application that accepts user-reported symptoms, returns
a ranked list of probable medical conditions through an **explainable rule-based
engine**, recommends an appropriate medical specialist, and identifies nearby
qualified healthcare providers using the user's location.

> **Guidance tool, not a medical device.** This system provides triage guidance
> and is not a substitute for professional medical advice. The symptom–disease
> knowledge base is an educational rule set and is **not clinically validated**.

Author: **Amy Wanjugu Njau** (ID 669008) · Supervisor: Mr Fredrick Ogore
Course: SWE3090XA — Software Engineering Final Project, USIU-Africa.

## Architecture

A three-tier, layered architecture:

| Tier             | Technology                          | Folder      |
|------------------|-------------------------------------|-------------|
| Presentation     | Flutter (Dart), Android-first       | `mobile/`   |
| Application/logic | Node.js + Express REST API, rule engine | `backend/` |
| Data             | Local JSON now → Firebase Firestore (swappable) | `backend/src/data`, `backend/src/repositories` |
| Location         | Mock providers now → Google Maps Platform (swappable) | `backend/src/services/providerService.js` |

```
User → Flutter app → POST /api/diagnose → rule engine scores conditions
     → ranked conditions + recommended specialist
     → POST /api/providers (specialist + location) → nearby providers
     → results shown with a guidance disclaimer
```

Per the project decisions, the database and Google Maps are **mocked behind
clean interfaces** for now and can be swapped for real Firestore / Maps later
without changing engine, route, or UI code.

## Quick start

**1. Backend** (runs immediately; Node 18+ required):
```bash
cd backend
npm run setup     # installs deps to local disk (see note below)
npm start         # http://localhost:3000
npm test          # 15 tests: engine + API
```

**2. Mobile** (requires the Flutter SDK):
```bash
cd mobile
flutter create .  # generate native platform folders
flutter pub get
flutter run       # talks to the backend at http://10.0.2.2:3000 (Android emulator)
```

See `backend/README.md` and `mobile/README.md` for full details.

> **Google Drive note:** this repository lives on a Google Drive virtual
> filesystem, which cannot host `node_modules`. The backend therefore installs
> its dependencies to local disk via `npm run setup` (not a plain `npm install`)
> and points Node at them automatically. `node_modules` is gitignored regardless.

## Mapping to the reports

| Report concept                         | Where it lives                                   |
|----------------------------------------|--------------------------------------------------|
| Weighted symptom–disease knowledge base | `backend/src/data/knowledge_base.json`           |
| Rule-based diagnostic engine (scoring)  | `backend/src/services/diagnosisEngine.js`        |
| Diagnosis API endpoint                  | `backend/src/routes/diagnose.js`                 |
| Nearby provider lookup (geolocation)    | `backend/src/services/providerService.js`        |
| Specialist recommendation              | `backend/src/services/diagnosisService.js` + `data/specialists.json` |
| Safety / disclaimer handling           | `backend/src/config/index.js` (central disclaimer) + `DisclaimerBanner` |
| ER model (7 entities)                  | `backend/src/data/*.json` + `repositories/`      |
| Flutter symptom-input / results screens | `mobile/lib/screens/`                            |

## Status

- ✅ Backend: knowledge base, weighted engine, specialist routing, provider
  lookup (mock + Maps-ready), caching, validation, query logging, disclaimer.
- ✅ Tests: 15 backend tests passing; Flutter widget/model tests included.
- ✅ Mobile: all three screens, shared theme, graceful location fallback.
- ⏭️ Next: real Firestore + Google Maps keys, auth, clinical validation of the
  knowledge base, accessibility hardening, UAT.
