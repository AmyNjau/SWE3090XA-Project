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

## Demo-day performance checklist

The single biggest cause of a laggy demo was the **emulator running without GPU
acceleration**. Verify it before you present:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell dumpsys SurfaceFlinger | Select-String "GLES:"
```

It must name your real GPU (e.g. `Intel(R) Iris(R) Xe Graphics`). If it says
`SwiftShader` or `Android Emulator OpenGL ES Translator (Google (Google))`,
Android is rendering in **software** and Flutter will crawl. Fix it in
`C:\Users\amnja\.android\avd\swe_pixel.avd\config.ini`:

```ini
hw.gpu.enabled=yes
hw.gpu.mode=host
hw.ramSize=3072      ; 2G is too tight for an Android 36 image
vm.heapSize=512
hw.lcd.depth=32
```

The emulator must be **cold-restarted** for these to apply.

**Pre-grant location**, or the first tap on "Find Nearby Doctors" shows a long
spinner *and then* a permission dialog — which looks broken in front of an
audience:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm grant com.example.smart_health android.permission.ACCESS_FINE_LOCATION
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell pm grant com.example.smart_health android.permission.ACCESS_COARSE_LOCATION
```

**Run the emulator as its own window, not inside Android Studio, if you want to
scroll with the mouse wheel.**

- **Standalone emulator app** — the mouse wheel scrolls correctly (verified both
  directions). Click-and-drag also works.
- **Android Studio's embedded tool window** — the wheel does nothing. The IDE
  swallows it. Only click-and-drag works there.

Launch it standalone with:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd swe_pixel -gpu host
```

To stop Studio grabbing it back, turn off **Settings → Tools → Emulator →
Launch in a tool window**.

The guest has no wheel device at all (only `virtio_input_multi_touch_*`, no
`REL_WHEEL`) — the standalone emulator translates host wheel into a touch scroll
itself, which is why it works without any configuration.

> **Do not try to "fix" the wheel with `VirtioTablet = off` in
> `~/.android/advancedFeatures.ini`.** It does create a real `QEMU Virtio Mouse`
> with `REL_WHEEL`, and adb-injected taps and drags keep working — but it stops
> **real mouse clicks registering at all** in the embedded emulator. This was
> tried and reverted. If that file exists, delete it and cold-boot.

**Check the window fits the screen.** The emulator opened 881 px tall on an
816 px work area, leaving most of it off-screen above the top edge. Drag it back
or resize before presenting.

Note the **home screen's content fits the viewport, so scrolling on Home does
nothing** — that is correct behaviour, not a bug. Use Profile or the providers
list to demonstrate scrolling.

**Set the emulator location *before* opening Nearby Providers.** If the geo fix
lands after the screen is already waiting, the 8-second timeout fires and the
list renders under a *"Using a default location — enable location access"*
banner, even when permission is granted. Setting it first (and allowing a few
seconds to settle) makes that banner disappear.

**Build before you present, not during.** Gradle on the `G:` Drive mount is
roughly **14× slower** than local disk (measured: 1259 s vs 89 s for the same
profile APK), because `G:` is a Drive File Stream virtual filesystem and every
one of Gradle's thousands of small file operations pays driver overhead. Press
**Run** once well before the presentation so the build is warm; during the demo
you are then launching an already-built app.

> **If a Gradle task fails with `AccessDeniedException` on a folder under
> `mobile/build`**, Drive is holding a lock that even `Remove-Item` cannot
> break. Deleting fails, but **renaming the folder works** — rename it and
> Gradle recreates it cleanly. This happens especially after switching
> `--target-platform`, which leaves stale per-ABI folders behind.

Measured on the fixed setup (profile build, GPU on): warm launch ~5.6 s, and
**zero** `Choreographer: Skipped frames` warnings across 20 sustained scroll
gestures. Note that once the GPU is enabled, debug and profile measured
essentially the same on these metrics (5.8 s vs 5.6 s warm launch) — the GPU
setting was the real fix, not the build mode.

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

---

## Firebase sign-in

### Backend — required, or every sign-in fails

`backend/.env` **must** set the Firebase project, or the Admin SDK has no
project to validate a token's audience against and rejects every ID token with
"invalid or expired":

```
FIREBASE_PROJECT_ID=smart-health-swe3090xa
```

`.env` is gitignored, so this has to be recreated on any fresh clone. Copy
`.env.example`. If it is missing the API now fails with a 500 naming the
variable, rather than a 401 that looks like a bad password.

To additionally require a signed-in user on `/api/diagnose` and
`/api/providers`:

```
AUTH_REQUIRED=true
```

A token that *is* supplied is verified either way, so a forged token is never
accepted regardless of this setting. Leave it unset for the demo and tests.

### Firebase console — one manual step

Enable **Authentication → Sign-in method → Email/Password** once in the
[Firebase console](https://console.firebase.google.com/project/smart-health-swe3090xa/authentication/providers).
There is no CLI command for it. Until it is enabled, sign-in fails with
"Email sign-in is not enabled for this project yet."

### Running it from Android Studio (the demo path)

1. Start the backend first, in a terminal you can leave visible:

   ```powershell
   cd "G:\My Drive\Claude\SWE3090XA\backend"
   npm start
   ```

2. In Android Studio, **open the folder** `G:\My Drive\Claude\SWE3090XA\mobile`.
   Let Gradle finish syncing.

   > **Why the Drive folder builds at all.** Gradle on a Google Drive path fails
   > by default with *"Could not close incremental caches"*, because Drive's sync
   > layer cannot host the memory-mapped files the Kotlin incremental compiler
   > uses, and Kotlin cannot compute relative paths between the pub cache on `C:`
   > and a project on `G:` (*"different roots"*). The fix is
   > `kotlin.incremental=false` in `mobile/android/gradle.properties`. Do not
   > remove it, or the build breaks again. Rebuilds are a little slower as a
   > result.
   >
   > **`mobile/android/` is tracked** (since the submission milestone), because
   > it carries hand-made changes the app depends on: that flag, the location
   > permissions and cleartext-HTTP setting in the manifest, the `url_launcher`
   > `<queries>` entry, and the Firebase Gradle wiring. Ignored inside it:
   > `local.properties`, `.gradle/`, `.kotlin/`, build output, `/captures/`,
   > `.cxx/`, keystores, and `GeneratedPluginRegistrant.java` (regenerated by
   > `flutter pub get`). The Gradle wrapper **is** tracked, against the Flutter
   > template's default, so a fresh clone builds. If the folder is ever
   > regenerated with `flutter create .`, all the hand-made changes have to be
   > re-applied — see `mobile/README.md`.
   >
   > If a build ever fails oddly after switching branches or settings, run
   > `flutter clean` first — stale Gradle state on Drive does not recover on its
   > own.
   >
   > `C:\Users\amnja\swe3090xa-mobile` remains as a faster local-disk copy and
   > still works; it is a copy, not the source of truth.

3. Pick the device in the toolbar dropdown: either the `swe_pixel` emulator or
   a physical phone with USB debugging on.

4. The app needs the API address passed at build time. In Android Studio:
   **Run → Edit Configurations → main.dart → Additional run args**, and add:

   ```
   --dart-define=API_BASE_URL=http://10.0.2.2:3000
   ```

   `10.0.2.2` is how the emulator reaches the host machine's localhost. On a
   **physical phone** use the computer's LAN address instead, for example
   `--dart-define=API_BASE_URL=http://192.168.1.10:3000`, and make sure the
   phone is on the same network.

5. Press **Run**. On an emulator, set a location so nearby providers resolve
   immediately:

   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" emu geo fix 36.8028 -1.2641
   ```

If Gradle re-downloads the Android SDK platform on the first Firebase build,
that is expected once and then cached.

### Android — one-time wiring

`mobile/android/` is generated by `flutter create`. It is now tracked, wiring
included, so this is only needed if the folder is regenerated (or if the local
build copy at `C:\Users\amnja\swe3090xa-mobile` is recreated):

1. Write the Android config to `android/app/google-services.json`:

   ```bash
   firebase apps:sdkconfig ANDROID 1:171400267730:android:c4492f5d05fbf9b783aa0b \
     --project smart-health-swe3090xa > android/app/google-services.json
   ```

2. In `android/settings.gradle.kts`, inside the `plugins` block:

   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   ```

3. In `android/app/build.gradle.kts`, inside the `plugins` block:

   ```kotlin
   id("com.google.gms.google-services")
   ```

The app package (`com.example.smart_health`) must match the one registered in
Firebase, or `Firebase.initializeApp` fails at startup.
