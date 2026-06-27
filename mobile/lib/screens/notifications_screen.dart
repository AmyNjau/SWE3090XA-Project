import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Notifications / health reminders feed, opened from the home bell. Static
/// content for now; a real build would source reminders from the backend.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Note>[
      _Note(Icons.tips_and_updates_rounded, AppColors.blue, 'Health tip',
          'Persistent fever for more than 3 days? Seek professional care.',
          'Just now'),
      _Note(Icons.water_drop_rounded, AppColors.green, 'Hydration reminder',
          "You've logged symptoms recently — remember to stay hydrated.", '2h ago'),
      _Note(Icons.calendar_month_rounded, AppColors.violet, 'Wellness check',
          'It has been a while since your last check-in. How are you feeling?',
          'Yesterday'),
      _Note(Icons.verified_rounded, AppColors.amber, 'Did you know?',
          'Smart Health explains which symptoms drove each result for transparency.',
          '2 days ago'),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final n = items[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n.icon, color: n.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            n.time,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Note {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  _Note(this.icon, this.color, this.title, this.body, this.time);
}
