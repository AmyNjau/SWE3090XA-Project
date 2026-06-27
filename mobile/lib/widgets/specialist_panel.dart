import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Highlighted panel recommending the appropriate specialist for the top
/// condition, with a call-to-action to find nearby doctors.
class SpecialistPanel extends StatelessWidget {
  final String specialist;
  final String? description;
  final VoidCallback onFindDoctors;

  const SpecialistPanel({
    super.key,
    required this.specialist,
    required this.description,
    required this.onFindDoctors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.navy,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOMMENDED SPECIALIST',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialist,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onFindDoctors,
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Find Nearby Doctors'),
          ),
        ],
      ),
    );
  }
}
