import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Side drawer opened from the menu icon. Explains what the app does and how it
/// works, and restates the guidance-only disclaimer — reinforcing that this is
/// a triage/guidance tool, not a diagnostic device.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.navy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.health_and_safety, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Smart Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Symptom checker & doctor finder',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const _SectionTitle('How it works'),
            const _Step(
              number: '1',
              title: 'Enter your symptoms',
              body: 'Pick from common symptoms or search for your own.',
            ),
            const _Step(
              number: '2',
              title: 'See possible conditions',
              body: 'A rule-based engine ranks likely conditions and explains '
                  'which symptoms drove each match.',
            ),
            const _Step(
              number: '3',
              title: 'Find nearby care',
              body: 'Get the right kind of specialist and nearby providers.',
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.navy),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Smart Health',
                  applicationVersion: '0.1.0',
                  applicationLegalese:
                      'Smart Health Symptom Checker and Doctor Recommendation '
                      'System.\nAmy Wanjugu Njau — SWE3090XA, USIU-Africa.',
                );
              },
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.navy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a guidance tool, not a substitute for '
                      'professional medical advice.',
                      style: TextStyle(fontSize: 12, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _Step({required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.lightBlue,
        child: Text(
          number,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(body, style: const TextStyle(fontSize: 12)),
    );
  }
}
