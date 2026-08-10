import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartHealthApp());
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
