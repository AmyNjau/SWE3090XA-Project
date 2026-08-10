import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../state/history_store.dart';

/// The Profile tab: a premium profile header, quick stats, and settings.
/// Conceptually backed by the "User" entity in the data model.
class ProfileScreen extends StatelessWidget {
  final AuthService auth;
  const ProfileScreen({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
      color: AppColors.bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _ProfileHeader(),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              children: [
                const _StatsRow(),
                const SizedBox(height: 20),
                _SettingsGroup(
                  title: 'Preferences',
                  tiles: [
                    _SettingTile(
                      icon: Icons.notifications_none_rounded,
                      color: AppColors.blue,
                      label: 'Notifications',
                      trailing: _SoftSwitch(),
                    ),
                    _SettingTile(
                      icon: Icons.language_rounded,
                      color: AppColors.green,
                      label: 'Language',
                      value: 'English',
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.location_on_outlined,
                      color: AppColors.violet,
                      label: 'Location access',
                      value: 'While using',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsGroup(
                  title: 'About',
                  tiles: [
                    _SettingTile(
                      icon: Icons.help_outline_rounded,
                      color: AppColors.blue,
                      label: 'How it works',
                      onTap: () => _showHowItWorks(context),
                    ),
                    _SettingTile(
                      icon: Icons.shield_outlined,
                      color: AppColors.amber,
                      label: 'Privacy & disclaimer',
                      onTap: () => _showDisclaimer(context),
                    ),
                    _SettingTile(
                      icon: Icons.info_outline_rounded,
                      color: AppColors.textMuted,
                      label: 'About Smart Health',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Smart Health',
                        applicationVersion: '0.1.0',
                        applicationLegalese:
                            'Smart Health Symptom Checker and Doctor '
                            'Recommendation System.\nAmy Wanjugu Njau — '
                            'SWE3090XA, USIU-Africa.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsGroup(
                  title: 'Account',
                  tiles: [
                    _SettingTile(
                      icon: Icons.alternate_email_rounded,
                      color: AppColors.blue,
                      label: auth.currentUser?.email ?? 'Signed in',
                    ),
                    _SettingTile(
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFB3261E),
                      label: 'Sign out',
                      onTap: () => _confirmSignOut(context, auth),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 16),
            _HowStep('1', 'Enter your symptoms',
                'Pick from common symptoms or search for your own.'),
            _HowStep('2', 'See possible conditions',
                'A rule-based engine ranks likely conditions and shows which '
                    'symptoms drove each match.'),
            _HowStep('3', 'Find nearby care',
                'Get the right kind of specialist and nearby providers.'),
          ],
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy & disclaimer'),
        content: const Text(
          'Smart Health provides guidance only and is not a substitute for '
          'professional medical advice, diagnosis, or treatment.\n\n'
          'Your symptom and location data are used only to produce a '
          'recommendation and are not shared. In an emergency, contact your '
          'local emergency services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}


/// Signing out is destructive enough to confirm: in-memory history for the
/// session is not visible to a signed-out user.
Future<void> _confirmSignOut(BuildContext context, AuthService auth) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'You will need to sign in again to run a symptom check or see your history.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
      ],
    ),
  );
  if (confirmed == true) {
    // AuthGate is listening; it swaps back to the sign-in screen itself.
    await auth.signOut();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 12),
            const Text(
              'Guest User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Tap to set up your profile',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HistoryStore.instance,
      builder: (context, _) {
        final count = HistoryStore.instance.count;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                _Stat(value: '$count', label: 'Checks'),
                _divider(),
                const _Stat(value: '14', label: 'Conditions'),
                _divider(),
                const _Stat(value: '9', label: 'Specialists'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  const _SettingsGroup({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.softShadow,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(children: tiles),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.color,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(value!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
    );
  }
}

class _SoftSwitch extends StatefulWidget {
  @override
  State<_SoftSwitch> createState() => _SoftSwitchState();
}

class _SoftSwitchState extends State<_SoftSwitch> {
  bool _on = true;
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _on,
      activeThumbColor: AppColors.blue,
      onChanged: (v) => setState(() => _on = v),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _HowStep(this.number, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.lightBlue,
            child: Text(number,
                style: const TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
