import 'package:flutter/material.dart';

import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';

/// The shared filter/segment chip, matching the Matches-screen filter pill:
/// active → primary green gradient with glow; inactive → white surface with a
/// soft shadow. Used by **new** screens (existing screens keep their inline
/// chips frozen).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 22),
        decoration: active
            ? BoxDecoration(
                gradient: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green1D8040.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ],
              )
            : BoxDecoration(
                gradient: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
        child: Text(
          label,
          style: AppText.tajawal(
            size: 14,
            weight: AppText.bold,
            color: active ? Colors.white : AppColors.chipInactiveText,
          ),
        ),
      ),
    );
  }
}
