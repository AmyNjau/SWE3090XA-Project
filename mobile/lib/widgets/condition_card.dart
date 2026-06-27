import 'package:flutter/material.dart';
import '../models/condition.dart';
import '../theme/app_theme.dart';

/// A result card pairing a condition name with a confidence bar and percentage.
/// The top result is emphasised and shows a severity hint line.
class ConditionCard extends StatelessWidget {
  final Condition condition;
  final bool emphasised;

  const ConditionCard({
    super.key,
    required this.condition,
    this.emphasised = false,
  });

  String get _severityHint {
    switch (condition.severity) {
      case 'high':
        return 'High match — seek care promptly.';
      case 'medium':
        return 'Moderate match — consider seeing a doctor.';
      default:
        return 'Lower match — monitor your symptoms.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.severityColor(condition.severity);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E9EE)),
        boxShadow: emphasised
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        condition.name,
                        style: TextStyle(
                          fontSize: emphasised ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${condition.confidence.round()}%',
                style: TextStyle(
                  fontSize: emphasised ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (condition.confidence / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.chipIdle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (emphasised) ...[
            const SizedBox(height: 8),
            Text(
              _severityHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          // Explainability: show which reported symptoms drove this match, so
          // the rule-based reasoning is transparent to the user.
          if (condition.matchedSymptomNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text(
                  'Why this match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: condition.matchedSymptomNames
                  .map(
                    (name) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
