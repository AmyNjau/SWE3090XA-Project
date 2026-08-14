# How to Run the App

Smart Health has two parts that run together: the **backend** (the REST API and
the rule engine) and the **mobile app** (Flutter, Android). Start the backend
first — the app talks to it for everything.

Everything below has been run on Windows; the commands are the same on macOS and
Linux apart from the quoting.

---

## What you need

| | Version | Check with |
|---|---|---|
| Node.js | 18 or newer | `node --version` |
| Flutter SDK | 3.10 or newer (Dart 3) | `flutter --version` |
| Android Studio | any recent version, with an emulator or a USB-debugging phone | `flutter doctor` |

Only Node.js is needed to run the API and its tests. The Flutter tool-chain is
needed only for the mobile app.

---

## 1. The backend

```bash
cd "2 - Source Code/backend"
npm install
npm start
```

The API is then on **http://localhost:3000**. Leave this window open.

Confirm it is up:

```bash
curl http://localhost:3000/api/health
```

Ask the rule engine for a diagnosis directly — no app needed:

```bash
curl -X POST http://localhost:3000/api/diagnose -H "Content-Type: application/json" -d "{\"symptoms\":[\"fever\",\"chills\",\"headache\"]}"
```

That is one line on purpose, so it works in PowerShell, `cmd` and a POSIX shell
alike.

The response carries the ranked conditions, the `matchedSymptoms` behind each
score, the recommended specialist and the safety disclaimer.

### The automated tests

```bash
npm test
```

25 tests: the scoring engine, the API endpoints, request validation, the error
handler and ID-token verification. They need no credentials and no network.

### Configuration

`backend/.env` is already filled in for this submission. All of its settings are
optional except the Firebase project id, which the API needs in order to verify
the sign-in tokens the app sends.

| Setting | Default | Purpose |
|---|---|---|
| `PORT` | `3000` | HTTP port |
| `DATA_STORE` | `local` | `local` (JSON files) or `firestore` |
| `PROVIDER_SOURCE` | `mock` | `mock` (sample provider data) or `google` (Google Maps Platform) |
| `MAPS_API_KEY` | — | Required only when `PROVIDER_SOURCE=google` |
| `FIREBASE_PROJECT_ID` | set | The project whose sign-in tokens are accepted |
| `AUTH_REQUIRED` | `false` | When `true`, `/api/diagnose` and `/api/providers` reject anonymous requests. A token that *is* supplied is verified either way, so a forged token is never accepted. |

---

## 2. The mobile app

```bash
cd "2 - Source Code/mobile"
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`API_BASE_URL` tells the app where the backend is:

- **Android emulator:** `http://10.0.2.2:3000` — `10.0.2.2` is the emulator's
  alias for the host machine's `localhost`.
- **Physical phone:** the computer's address on the same Wi-Fi network, for
  example `http://192.168.1.10:3000`.

If the argument is left out the app falls back to `http://10.0.2.2:3000`.

### From Android Studio instead

1. Run `flutter pub get` once in `2 - Source Code/mobile` **before opening the
   project**. It writes `android/local.properties` with the path to your Flutter
   SDK, which Gradle reads during sync; without it the sync stops with a
   `FileNotFoundException`.
2. **Open** the `2 - Source Code/mobile` folder and let Gradle finish syncing.
3. Choose the emulator or device in the toolbar.
4. Pick the **main.dart** run configuration — it is included with the API
   address already set — and press **Run**.

If that configuration is missing, add the address by hand under **Run → Edit
Configurations → main.dart → Additional run args**:
`--dart-define=API_BASE_URL=http://10.0.2.2:3000`.

The Android project is included, already wired to Firebase. If it is ever
regenerated with `flutter create .`, the Google-services plugin has to be
re-added to `android/settings.gradle.kts` and `android/app/build.gradle.kts`, and
`android/app/google-services.json` restored.

### Signing in

The app opens on a sign-in screen: **Create account** with any email and a
password of at least six characters, or sign in with an existing one. Accounts
are held in Firebase Authentication, so this step needs an internet connection.
Sign-in identifies the user and keeps their query history separate; the diagnosis
itself is computed by the local backend.

### The walkthrough

**Home → Check → Fever + Headache + Chills → Analyse → Malaria ≈ 55% →**
**Find Nearby Doctors → Directions → History → Profile**

On the results screen each condition shows a **"Why this match"** row listing the
exact symptoms that produced its score — the explainability that the rule-based
design exists to provide.

Watch the backend window while you tap **Analyse**: the request arriving there is
the request the app just sent.

---

## Troubleshooting

**The app shows a connection error.** The backend is not running, or
`API_BASE_URL` points to the wrong host. Emulators cannot reach `localhost` —
that is the emulator itself; use `10.0.2.2`.

**"Nearby providers" spins, then shows a "using a default location" banner.**
Location permission was refused or the emulator has no position fixed. The app
falls back to central Nairobi after about eight seconds, by design. To set a
position on an emulator before opening the screen:

```
adb emu geo fix 36.8028 -1.2641
```

**Sign-in fails with a network error.** Firebase Authentication needs internet
access; the rest of the app does not.

**A Gradle build fails after switching settings.** Run `flutter clean`, then
build again.

**`npm start` says dependencies are not installed.** Run `npm install` in the
`backend` folder first.
