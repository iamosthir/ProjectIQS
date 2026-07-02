import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/clay.dart';
import 'pressable.dart';

/// A square raised clay tile with a centered green icon and a label below.
/// Used by the Home "أقسام التطبيق" 4-up grid. Designed to live inside an
/// [Expanded] so the four tiles share the row equally (aspect-ratio 1:1).
class ClaySectionTile extends StatelessWidget {
  const ClaySectionTile({super.key, required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Pressable(
            onTap: onTap,
            builder: (context, pressed) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                transform: Matrix4.identity()
                  ..translateByDouble(0.0, pressed ? 4.0 : 0.0, 0.0, 1.0)
                  ..scaleByDouble(
                    pressed ? 0.97 : 1.0,
                    pressed ? 0.97 : 1.0,
                    1.0,
                    1.0,
                  ),
                transformAlignment: Alignment.center,
                alignment: Alignment.center,
                decoration: Clay.card(radius: 22, gradient: AppColors.sectionTile, pressed: pressed),
                child: Icon(icon, size: 30, color: AppColors.primaryGreen),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Text(label, style: AppText.tajawal(size: 13, weight: AppText.bold, color: AppColors.textSubtleGreen)),
      ],
    );
  }
}
