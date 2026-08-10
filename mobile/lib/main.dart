import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // If initialisation throws before runApp, the app shows a black screen and
    // no clue why. Show the reason instead.
    runApp(_StartupError(message: '$e'));
    return;
  }
  runApp(const SmartHealthApp());
}

/// Shown only when Firebase cannot start, so a misconfiguration is visible
/// rather than silent.
class _StartupError extends StatelessWidget {
  final String message;
  const _StartupError({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 44, color: Colors.redAccent),
                const SizedBox(height: 14),
                const Text(
                  'Smart Health could not start',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Firebase failed to initialise. Check that '
                  'android/app/google-services.json is present.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SmartHealthApp extends StatefulWidget {
  const SmartHealthApp({super.key});

  @override
  State<SmartHealthApp> createState() => _SmartHealthAppState();
}

class _SmartHealthAppState extends State<SmartHealthApp> {
  final AuthService _auth = AuthService();
  late final ApiService _api;

  @override
  void initState() {
    super.initState();
    // The API client asks the auth service for a token on each request, so a
    // refreshed token is picked up without anything having to be re-wired.
    _api = ApiService(tokenProvider: () => _auth.idToken());
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Health',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthGate(api: _api, auth: _auth),
    );
  }
}
