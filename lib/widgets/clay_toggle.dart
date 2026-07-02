import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A claymorphism switch. Track turns from a grey gradient (off) to the primary
/// green gradient (on); the knob slides via [AnimatedPositioned].
///
/// Matches the mockup geometry exactly: 50×30 track, 24px knob, 3px inset. In
/// the RTL mockup the knob rests on the right when off and slides left when on
/// (`right: 3px` → `right: 23px`), so the toggle "fills" from the right.
class ClayToggle extends StatelessWidget {
  const ClayToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Directionality(
        // Position the knob with explicit left/right regardless of app RTL.
        textDirection: TextDirection.ltr,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 50,
          height: 30,
          decoration: BoxDecoration(
            gradient: value ? AppColors.toggleOn : AppColors.toggleOff,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: 3,
                right: value ? 23 : 3,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.knob,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
