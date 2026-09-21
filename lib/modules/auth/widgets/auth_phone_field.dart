import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Pakistan-only phone entry: a fixed "+92" prefix plus the subscriber
/// number. FR-01 has no other country in scope, so the prefix is static
/// rather than a country picker.
class AuthPhoneField extends StatelessWidget {
  const AuthPhoneField({super.key, required this.controller, this.height = 52});

  final TextEditingController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.label.copyWith(color: AppColors.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PHONE NUMBER', style: labelStyle),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF33332E), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '+92',
                style: AppTextStyles.phoneValue.copyWith(color: AppColors.ink),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: const Color(0xFF33332E)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: AppTextStyles.phoneValue.copyWith(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: '300 1234567',
                    hintStyle: AppTextStyles.manropeBase.copyWith(color: AppColors.faint),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
