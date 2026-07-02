import 'package:flutter/material.dart';

import '../theme/clay.dart';
import 'pressable.dart';

/// A raised claymorphism card. Reuses the shared [Clay] shadow recipe so every
/// card in the app gets the same stacked-shadow look. When [onTap] is provided
/// it presses (sinks + shrinks) on tap-down like the mockups.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 22,
    this.onTap,
    this.strong = false,
    this.gradient,
    this.pressScale = 0.985,
    this.pressDy = 0.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool strong;
  final Gradient? gradient;
  final double pressScale;
  final double pressDy;

  BoxDecoration _decoration(bool pressed) {
    if (strong) return Clay.cardStrong(radius: radius, pressed: pressed);
    return Clay.card(radius: radius, pressed: pressed, gradient: gradient);
  }

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: _decoration(false),
        child: child,
      );
    }
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translateByDouble(0.0, pressed ? pressDy : 0.0, 0.0, 1.0)
            ..scaleByDouble(
              pressed ? pressScale : 1.0,
              pressed ? pressScale : 1.0,
              1.0,
              1.0,
            ),
          transformAlignment: Alignment.center,
          padding: padding,
          decoration: _decoration(pressed),
          child: child,
        );
      },
    );
  }
}
