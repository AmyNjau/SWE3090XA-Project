import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A persistent three-step progress indicator (symptoms -> conditions ->
/// providers) so users always know where they are in the flow. This implements
/// a recommendation from the design report.
class StepIndicator extends StatelessWidget {
  final int activeStep; // 0, 1, or 2
  static const _labels = ['Symptoms', 'Conditions', 'Providers'];

  const StepIndicator({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line between dots.
            final done = (i ~/ 2) < activeStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? AppColors.blue : AppColors.chipIdle,
              ),
            );
          }
          final index = i ~/ 2;
          final active = index <= activeStep;
          return Semantics(
            label: 'Step ${index + 1}: ${_labels[index]}'
                '${index == activeStep ? ', current' : ''}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: active ? AppColors.blue : AppColors.chipIdle,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: active ? AppColors.navy : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
