# LAUNCH — Running the Demo

How to run the Smart Health app on the Android emulator for a presentation.

## Easiest way — one-command launcher

Open **PowerShell** and run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\amnja\swe3090xa-mobile\run-demo.ps1"
```

This script does everything automatically:
1. Starts the **backend** (opens a window at `http://localhost:3000` — leave it visible).
2. Boots the **`swe_pixel` emulator** and waits for it to finish booting (~1–2 min).
3. Builds + launches the **app** on the emulator.

First launch takes a minute or two; after that the app opens and you can tap through
Home → Check → results → providers.

## Manual way (separate terminals)

```powershell
# Terminal 1 — backend (keep running)
cd "G:\My Drive\Claude\SWE3090XA\backend"
npm start

# Terminal 2 — emulator, then the app
$env:Path = "C:\Users\amnja\flutter\bin;$env:Path"
& "C:\Users\amnja\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd swe_pixel
# once it has booted, in the same terminal:
cd "C:\Users\amnja\swe3090xa-mobile"
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

> The app is built from the local-disk copy at `C:\Users\amnja\swe3090xa-mobile`
> (Google Drive cannot host the Android build). The canonical source lives in
> `mobile/` in this repo; if you edit it, copy the changed files into the local
> copy before running.

## Demo tips

- **Start the backend first and keep its window visible.** When you tap
  "Analyse Symptoms," you'll see the request hit the rule engine live — this makes
  the architecture tangible for the lecturer.
- **Suggested demo path:** Home dashboard → Check → pick **Fever + Headache + Chills**
  → Analyse → **Malaria 55%** with the "Why this match" chips → **Find Nearby Doctors**
  → **Directions** (opens Google Maps) → **History** tab → **Profile** tab.
- If "Nearby Providers" spins, it falls back to a default Nairobi location after ~8s
  by design. To set a location instantly:
  ```powershell
  & "C:\Users\amnja\AppData\Local\Android\Sdk\platform-tools\adb.exe" emu geo fix 36.8028 -1.2641
  ```

## Backend only (no app)

To exercise the API directly (e.g. with Postman or curl):

```powershell
cd "G:\My Drive\Claude\SWE3090XA\backend"
npm run setup   # first time only — installs deps to local disk
npm start
# POST http://localhost:3000/api/diagnose  body: {"symptoms":["fever","chills","headache"]}
```
