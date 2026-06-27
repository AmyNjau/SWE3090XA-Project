# Smart Health — Backend (REST API + Rule Engine)

Node.js / Express REST API that hosts the rule-based diagnostic engine,
specialist mapping, and nearby-provider lookup for the Smart Health Symptom
Checker and Doctor Recommendation System.

## Architecture (application tier)

```
src/
  config/            Central config (env vars with safe defaults)
  data/              Curated JSON: knowledge base, symptoms, specialists, providers
  repositories/      Data-store abstraction: local (JSON) now, Firestore stub for later
  services/
    diagnosisEngine.js   Pure weighted-scoring engine (fully unit-tested)
    diagnosisService.js  Orchestrates engine + specialist + query log + disclaimer
    providerService.js   Nearby providers (mock or Google Maps), with caching
  middleware/        Request validation + central error handling
  routes/            /api/diagnose, /api/providers, /api/symptoms, /api/specialists
  app.js / server.js Express wiring
tests/               Engine unit tests + API integration tests (node:test)
```

The data tier is swappable behind a single interface (`repositories/`), so moving
from local JSON to Firebase Firestore never touches engine or route code.

## The diagnostic algorithm

For each candidate condition, the engine sums the weights of the symptoms the
user reported and divides by the maximum possible weight for that condition,
giving a normalised confidence in `0..1`. Every score traces back to specific
weighted symptoms (`matchedSymptoms`), so the reasoning is **fully explainable**
— a deliberate choice for a safety-sensitive domain.

> ⚠️ The knowledge base in `src/data/knowledge_base.json` is an **educational**
> rule set and is **not clinically validated**. Validate it against recognised
> medical references before any real-world use.

## Setup & run

> **Note on Google Drive:** this project lives on a Google Drive virtual drive,
> which cannot host `node_modules`. The scripts below install dependencies on
> local disk and point Node at them automatically. Use `npm run setup` instead
> of a plain `npm install`.

```bash
cd backend
npm run setup      # installs deps to local disk (one time, and after dep changes)
npm start          # http://localhost:3000
npm run dev        # same, with --watch auto-reload
npm test           # engine unit tests + API integration tests
```

If you are **not** on Google Drive, a normal `npm install` also works.

## Configuration

Copy `.env.example` to `.env` to override defaults (all optional):

| Var               | Default | Purpose                                        |
|-------------------|---------|------------------------------------------------|
| `PORT`            | `3000`  | HTTP port                                      |
| `DATA_STORE`      | `local` | `local` (JSON files) or `firestore`            |
| `PROVIDER_SOURCE` | `mock`  | `mock` (sample data) or `google` (Maps API)    |
| `MAPS_API_KEY`    | —       | Required when `PROVIDER_SOURCE=google`         |

## API

### `GET /api/health`
Liveness probe.

### `GET /api/symptoms`
Returns the symptom catalogue used to populate the input screen.

### `GET /api/specialists`
Returns the specialist directory.

### `POST /api/diagnose`
```json
{ "symptoms": ["fever", "chills", "headache", "sweating"] }
```
Returns ranked conditions, the recommended specialist, and a disclaimer:
```json
{
  "results": [
    { "id": "malaria", "name": "Malaria", "specialist": "General Physician",
      "severity": "high", "confidence": 70, "matchedSymptoms": ["fever","chills","headache","sweating"] }
  ],
  "recommendedSpecialist": "General Physician",
  "specialistInfo": { "type": "General Physician", "description": "..." },
  "disclaimer": "This is a guidance tool, not a substitute for professional medical advice. ..."
}
```

### `POST /api/providers`
```json
{ "specialist": "General Physician", "latitude": -1.2641, "longitude": 36.8028, "radius": 5000 }
```
Returns nearby providers ranked by distance (mock) or rating (google).
