import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../state/history_store.dart';

/// The History tab: a list of the user's past symptom checks (the "Query"
/// entity in the data model), newest first.
class HistoryScreen extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  const HistoryScreen({super.key, required this.onSelectTab});

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Your History'),
        actions: [
          AnimatedBuilder(
            animation: HistoryStore.instance,
            builder: (context, _) {
              if (HistoryStore.instance.count == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Clear history',
                onPressed: () => HistoryStore.instance.clear(),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: HistoryStore.instance,
        builder: (context, _) {
          final entries = HistoryStore.instance.entries;
          if (entries.isEmpty) return _EmptyState(onCheck: () => onSelectTab(1));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = entries[i];
              final color = AppColors.severityColor(e.severity);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.monitor_heart_rounded, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.topConditionName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _relativeTime(e.timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${e.topConfidence.round()}%',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 15, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          e.specialist ?? 'No specialist',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.checklist_rounded,
                            size: 15, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${e.symptomIds.length} symptoms',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCheck;
  const _EmptyState({required this.onCheck});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.history_rounded,
                  size: 40, color: AppColors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'No history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your past symptom checks will appear here so you can track how '
              "you've been feeling over time.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Check symptoms'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
