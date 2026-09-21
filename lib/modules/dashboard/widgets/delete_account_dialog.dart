import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete account?', style: AppTextStyles.headingSm.copyWith(color: AppColors.ink)),
      content: Text(
        'This will permanently delete your account, vehicles, QR stickers, and messages. This can\'t be undone.',
        style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('Cancel', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.muted, fontSize: 14)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(
            'Delete',
            style: AppTextStyles.buttonLabel.copyWith(color: const Color(0xFFE5675E), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
