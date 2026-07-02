import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/clay.dart';
import 'pressable.dart';

/// One bottom-nav destination.
class NavDestination {
  const NavDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// The 5-tab bottom navigation bar. The active tab shows a raised green clay
/// tile behind its icon with a green label; inactive tabs are a grey icon +
/// grey label. Matches the mockups' white bar with a soft top shadow.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C5030).withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, -10),
            spreadRadius: -12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < destinations.length; i++)
                _NavItem(
                  destination: destinations[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.active, required this.onTap});

  final NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedSlide(
          offset: Offset(0, pressed && !active ? 0.04 : 0),
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active)
                Container(
                  width: 54,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: Clay.activePill(),
                  child: Icon(destination.icon, size: 24, color: Colors.white),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(destination.icon, size: 24, color: AppColors.textMuted),
                ),
              SizedBox(height: active ? 7 : 9),
              Text(
                destination.label,
                style: active ? AppText.navActive : AppText.navInactive,
              ),
            ],
          ),
        );
      },
    );
  }
}
