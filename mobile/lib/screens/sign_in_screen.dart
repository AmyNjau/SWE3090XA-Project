import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Sign in or create an account. One screen for both, because the fields are
/// nearly identical and a toggle keeps the user out of a navigation dead end.
class SignInScreen extends StatefulWidget {
  final AuthService auth;

  /// Lets the user proceed without an account. Present so that a sign-in
  /// outage never leaves the app with nowhere to go.
  final VoidCallback? onContinueAsGuest;

  const SignInScreen({super.key, required this.auth, this.onContinueAsGuest});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _registering = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_registering) {
        await widget.auth.register(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
      } else {
        await widget.auth.signIn(email: _email.text, password: _password.text);
      }
      // No navigation here: AuthGate listens to authStateChanges and swaps the
      // screen itself, so there is exactly one place that decides what is shown.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then tap reset.');
      return;
    }
    try {
      await widget.auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If that account exists, a reset link is on its way.')),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Enter your password';
    if (_registering && value.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Brand(),
                    const SizedBox(height: 28),
                    Text(
                      _registering ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _registering
                          ? 'Your symptom checks stay tied to your account.'
                          : 'Sign in to see your history and continue.',
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 22),
                    if (_registering) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                        ),
                      ),
                    ),
                    if (!_registering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      _ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_registering ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _registering = !_registering;
                                _error = null;
                              }),
                      child: Text(
                        _registering
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                    if (widget.onContinueAsGuest != null)
                      TextButton(
                        onPressed: _busy ? null : widget.onContinueAsGuest,
                        child: const Text('Continue without an account'),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'Smart Health offers guidance only and is not a substitute '
                      'for professional medical advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 12),
        const Text(
          'Smart Health',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3B7B7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 19, color: Color(0xFFB3261E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFB3261E), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
