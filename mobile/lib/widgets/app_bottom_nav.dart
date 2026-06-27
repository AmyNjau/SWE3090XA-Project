import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single destination in the bottom navigation bar.
class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavDestination(this.icon, this.activeIcon, this.label);
}

/// Premium bottom navigation bar: a floating white pill with a soft shadow.
/// The active item expands into a tinted pill that reveals its label, while
/// inactive items show only their icon — a clean, modern pattern.
class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  static const destinations = <NavDestination>[
    NavDestination(Icons.home_outlined, Icons.home_rounded, 'Home'),
    NavDestination(Icons.search_outlined, Icons.search_rounded, 'Check'),
    NavDestination(Icons.history_outlined, Icons.history_rounded, 'History'),
    NavDestination(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  const AppBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(destinations.length, (i) {
            final d = destinations[i];
            final active = i == index;
            return _NavItem(
              destination: d,
              active: active,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? AppColors.lightBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? destination.activeIcon : destination.icon,
                color: active ? AppColors.blue : AppColors.textMuted,
                size: 24,
              ),
              if (active) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
