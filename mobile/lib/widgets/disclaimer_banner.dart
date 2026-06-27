import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Persistent guidance disclaimer shown at the foot of every screen. Centralised
/// so it is impossible to ship a screen without it (a safety requirement).
class DisclaimerBanner extends StatelessWidget {
  final String text;
  const DisclaimerBanner({
    super.key,
    this.text = 'Guidance only — not a substitute for professional medical advice.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }
}
