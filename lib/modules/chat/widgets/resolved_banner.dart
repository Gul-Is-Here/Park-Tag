import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// FR-07.2: "Has this issue been resolved?" banner shown inside a chat.
class ResolvedBanner extends StatelessWidget {
  const ResolvedBanner({
    super.key,
    required this.isResolved,
    required this.onResolved,
    required this.onNotResolved,
  });

  final bool isResolved;
  final VoidCallback onResolved;
  final VoidCallback onNotResolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isResolved ? 'Marked as resolved' : 'Has this issue been resolved?',
              style: AppTextStyles.subtitle.copyWith(
                color: isResolved ? AppColors.success : AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isResolved)
            GestureDetector(
              onTap: onNotResolved,
              child: Text(
                'Reopen',
                style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0),
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: onResolved,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 13, color: AppColors.success),
                        const SizedBox(width: 5),
                        Text('Resolved', style: AppTextStyles.label.copyWith(color: AppColors.success, letterSpacing: 0)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onNotResolved,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 13, color: AppColors.muted),
                        const SizedBox(width: 5),
                        Text('Not yet', style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
