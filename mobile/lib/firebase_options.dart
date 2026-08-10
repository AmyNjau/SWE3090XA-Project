import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for the Smart Health project.
///
/// These values identify the Firebase project; they are not secrets. An Android
/// API key is restricted by package name and signing certificate, which is why
/// Google ships the same values in `google-services.json` and why this file is
/// committed. The Maps Platform key, which *is* billable and sensitive, stays
/// server-side and never appears in the client (see backend/src/config).
///
/// Only Android is configured, because that is the platform the project
/// targets. Adding iOS later means registering an iOS app in the Firebase
/// console and filling in the corresponding block.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Smart Health is not configured for web. Register a web app in the '
        'Firebase console and add its options here.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Smart Health is configured for Android only. Register an app for '
          '${defaultTargetPlatform.name} in the Firebase console and add its '
          'options here.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB79kZJr8DhjNzPCMzN0urOmEF3cSZIovo',
    appId: '1:171400267730:android:c4492f5d05fbf9b783aa0b',
    messagingSenderId: '171400267730',
    projectId: 'smart-health-swe3090xa',
    storageBucket: 'smart-health-swe3090xa.firebasestorage.app',
  );
}
