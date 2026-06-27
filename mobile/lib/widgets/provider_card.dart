import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../theme/app_theme.dart';

/// A nearby-provider list item: initials avatar, name, specialty, rating,
/// distance, and a Directions action.
class ProviderCard extends StatelessWidget {
  final Provider provider;
  final VoidCallback onDirections;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E9EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              provider.initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.specialty,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (provider.rating != null) ...[
                      const Icon(Icons.star, size: 14, color: AppColors.medium),
                      const SizedBox(width: 2),
                      Text(
                        provider.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (provider.reviews != null)
                        Text(
                          ' (${provider.reviews})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      const SizedBox(width: 8),
                      const Text('·', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(width: 8),
                    ],
                    if (provider.distanceMetres != null)
                      Text(
                        provider.distanceLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Directions'),
            style: TextButton.styleFrom(foregroundColor: AppColors.blue),
          ),
        ],
      ),
    );
  }
}
