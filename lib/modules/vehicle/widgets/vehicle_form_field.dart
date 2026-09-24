import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class VehicleFormField extends StatelessWidget {
  const VehicleFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.emphasize = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.leading,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final String? hint;
  final String? helper;
  final TextEditingController controller;
  final bool emphasize;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final Widget? leading;

  /// Restricts what can be typed or pasted into the field.
  final List<TextInputFormatter>? inputFormatters;

  /// For fields whose value is chosen rather than typed (the date picker).
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.label.copyWith(
      color: AppColors.muted,
      letterSpacing: 0.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label.toUpperCase(),
            style: labelStyle,
            children: helper == null
                ? null
                : [
                    TextSpan(
                      text: '  $helper',
                      style: labelStyle.copyWith(
                        color: AppColors.faint,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              Padding(padding: const EdgeInsets.only(top: 14), child: leading),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                maxLines: maxLines,
                inputFormatters: inputFormatters,
                readOnly: readOnly,
                onTap: onTap,
                // A picker-backed field should not raise the keyboard.
                showCursor: !readOnly,
                mouseCursor: readOnly ? SystemMouseCursors.click : null,
                style: AppTextStyles.fieldValue.copyWith(
                  color: AppColors.ink,
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  suffixIcon: suffixIcon,
                  hintStyle: AppTextStyles.manropeBase.copyWith(
                    color: AppColors.faint,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: emphasize
                          ? AppColors.yellow
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: emphasize
                          ? AppColors.yellow
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.yellow,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
