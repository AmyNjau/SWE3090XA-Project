import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/history_store.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'sign_in_screen.dart';

/// Decides, in one place, whether the app shows the sign-in screen or the app
/// itself. Listening to the auth stream rather than navigating after a
/// successful sign-in means a token expiring or a sign-out from anywhere else
/// lands the user back on the sign-in screen without any screen having to
/// coordinate it.
class AuthGate extends StatefulWidget {
  final ApiService api;
  final AuthService auth;

  const AuthGate({super.key, required this.api, required this.auth});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Set when the user chooses to continue without an account. The backend
  /// serves anonymous requests unless AUTH_REQUIRED is on, so this keeps the
  /// app usable if sign-in is unavailable.
  bool _guest = false;

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final api = widget.api;
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final user = snapshot.data;
        // Scope history to whoever is signed in, so signing out and back in as
        // somebody else never shows the previous account's symptom checks.
        HistoryStore.instance.setUser(user?.uid);

        if (user == null && !_guest) {
          return SignInScreen(
            auth: auth,
            onContinueAsGuest: () => setState(() => _guest = true),
          );
        }
        return MainShell(api: api, auth: auth);
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
