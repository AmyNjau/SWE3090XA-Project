# System Integration Report — Figures

Editable mermaid sources for the three figures embedded in
*Amy Njau SWE3090XA System Integration Report.docx*. Paste any block into a
mermaid renderer (e.g. https://mermaid.live) to tweak and re-export.

The PNGs in this folder were rendered from these sources (navy/blue theme to
match the app and prior reports).

## Figure 3.1 — Integration architecture

```mermaid
flowchart TB
  subgraph P[Presentation Tier]
    A["Flutter Mobile Client<br/>(symptom input, results, providers)"]
  end
  subgraph L[Application Tier]
    B["Node.js / Express REST API<br/>(integration mediator)"]
    C["Rule-Based Diagnostic Engine<br/>(weighted scoring)"]
  end
  subgraph D[Data & External Services]
    E[("Firebase Firestore<br/>rules · providers · logs")]
    F["Google Maps Platform<br/>nearby providers"]
  end
  A -- "REST / JSON over HTTPS" --> B
  B -- "ranked results + disclaimer" --> A
  B -- "score(symptoms)" --> C
  C -- "reads weighted rules" --> E
  B -- "query logs" --> E
  B -- "nearby search (HTTPS, server-side)" --> F
```

## Figure 3.2 — End-to-end data flow (sequence)

```mermaid
sequenceDiagram
  autonumber
  participant U as Flutter Client
  participant A as Express API
  participant E as Diagnostic Engine
  participant F as Firestore
  participant M as Google Maps
  U->>A: POST /api/diagnose {symptoms}
  A->>E: score(symptoms)
  E->>F: read weighted symptom-disease rules
  F-->>E: rules
  E-->>A: ranked conditions + specialist
  A->>F: log query (anonymised)
  A-->>U: conditions + specialist + disclaimer
  U->>A: POST /api/providers {specialist, lat, lng}
  A->>M: nearby search (specialist, location)
  M-->>A: nearby places
  A-->>U: ranked nearby providers
```

## Figure A.1 — Entity Relationship Diagram

```mermaid
erDiagram
  USER ||--o{ QUERY : initiates
  SYMPTOM ||--o{ CONDITION_SYMPTOM : appears_in
  CONDITION ||--o{ CONDITION_SYMPTOM : has
  CONDITION }o--|| SPECIALIST : maps_to
  SPECIALIST }o--o{ PROVIDER : offered_by
  USER { string user_id PK
    string name
    string location
    datetime created_at }
  SYMPTOM { string symptom_id PK
    string name
    string category }
  CONDITION { string condition_id PK
    string name
    string description
    string severity }
  CONDITION_SYMPTOM { string condition_id FK
    string symptom_id FK
    float weight }
  SPECIALIST { string specialist_id PK
    string type
    string description }
  PROVIDER { string provider_id PK
    string name
    string specialty
    float latitude
    float longitude
    float rating }
  QUERY { string query_id PK
    string user_id FK
    string symptoms
    string result
    datetime timestamp }
```
