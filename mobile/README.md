# Smart Health — Flutter Mobile Client

Cross-platform (Android-first) client for the Smart Health Symptom Checker and
Doctor Recommendation System. It implements the three screens described in the
project reports:

1. **Symptom input** — search + quick-pick chips, with a live "N selected" count.
2. **Possible conditions** — ranked conditions with confidence bars and the
   recommended specialist.
3. **Nearby providers** — map view + distance-sorted provider list.

The client holds **no diagnostic logic**. It collects input, calls the REST API,
and renders typed responses — so the UI and the engine evolve independently.

## Prerequisites

- Flutter SDK 3.10+ ( https://docs.flutter.dev/get-started/install )
- An Android emulator or device (or Chrome for `flutter run -d chrome`)
- The backend running (see `../backend/README.md`)

## First-time setup

This folder contains the app source (`lib/`, `test/`, `pubspec.yaml`) but not the
generated native platform folders. Generate them once, then fetch packages:

```bash
cd mobile
flutter create .          # generates android/, ios/, web/ without touching lib/
flutter pub get
```

## Running

The default API base URL is `http://10.0.2.2:3000`, which is how the **Android
emulator** reaches the backend on your host machine. Override it for a real
device or a different host:

```bash
# Android emulator (default) — backend on the host machine:
flutter run

# Real device on the same Wi-Fi (replace with your machine's LAN IP):
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000

# Web (Chrome) — backend on localhost:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## Required platform configuration

After `flutter create .`, add the following so the app can reach the local HTTP
backend and request location.

**`android/app/src/main/AndroidManifest.xml`** — inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

…and on the `<application>` tag, allow cleartext HTTP for local development:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

> `usesCleartextTraffic` is only needed because the dev backend is plain HTTP.
> A production build should use HTTPS and remove this.

## Testing

```bash
flutter test
```

The tests use a mock HTTP client, so they run without a live backend.

## Swapping mocks for real services later

- **Real map:** add `google_maps_flutter`, supply a Maps API key in the native
  manifests, and replace `widgets/map_placeholder.dart` with a `GoogleMap`
  rendering the providers as markers. No screen changes required.
- **Backend data/source:** nothing changes in the client — switch the backend's
  `DATA_STORE`/`PROVIDER_SOURCE` env vars instead.
