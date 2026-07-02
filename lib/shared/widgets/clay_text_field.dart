import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';

/// A claymorphism-styled text input: an optional label, a soft white clay card
/// holding a borderless field, and an optional error line. Built from the same
/// tokens as the rest of the kit so forms look native.
class ClayTextField extends StatelessWidget {
  const ClayTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.textDirection,
    this.textAlign,
    this.maxLength,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.textStyle,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: Text(label!, style: AppText.groupLabel),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: Clay.card(radius: 18, gradient: AppColors.surface).copyWith(
            border: Border.all(
              color: hasError ? AppColors.logoutText.withValues(alpha: 0.6) : AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  autofocus: autofocus,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textDirection: textDirection,
                  textAlign: textAlign ?? TextAlign.start,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  inputFormatters: inputFormatters,
                  style: textStyle ??
                      AppText.tajawal(
                        size: 16,
                        weight: AppText.bold,
                        color: AppColors.textPrimary,
                      ),
                  cursorColor: AppColors.primaryGreen,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '',
                    hintText: hint,
                    hintStyle: AppText.tajawal(
                      size: 15,
                      weight: AppText.medium,
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffix != null) ...[const SizedBox(width: 10), suffix!],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              errorText!,
              style: AppText.tajawal(
                size: 12,
                weight: AppText.medium,
                color: AppColors.logoutText,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
