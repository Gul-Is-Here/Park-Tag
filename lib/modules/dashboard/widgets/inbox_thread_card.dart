import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/message_thread_model.dart';

class InboxThreadCard extends StatelessWidget {
  const InboxThreadCard({super.key, required this.thread});

  final MessageThreadModel thread;

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadCount > 0;
    final accent = unread ? AppColors.yellow : const Color(0xFF33332E);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.chatThread, arguments: thread),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: unread ? const Color(0xFF2A2210) : const Color(0xFF242420),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, size: 18, color: unread ? AppColors.yellow : AppColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.scannerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.fieldValue.copyWith(
                            color: unread ? AppColors.ink : AppColors.muted,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(thread.timeLabel, style: AppTextStyles.caption.copyWith(color: AppColors.faint)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: unread ? const Color(0xFF33332E) : const Color(0xFF262622)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: thread.vehicleColor,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: const Color(0xFF33332E)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              thread.plateNumber,
                              style: AppTextStyles.overline.copyWith(
                                color: unread ? AppColors.muted : AppColors.faint,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (thread.isResolved) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF182018),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2A3D2A)),
                          ),
                          child: Text(
                            'RESOLVED',
                            style: AppTextStyles.overline.copyWith(
                              color: const Color(0xFF7FBF7F),
                              letterSpacing: 0.4,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    thread.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      color: unread ? AppColors.ink : AppColors.muted,
                      fontSize: 13.5,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.yellow),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
