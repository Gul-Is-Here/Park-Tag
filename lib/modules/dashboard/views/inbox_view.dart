import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/inbox_controller.dart';
import '../widgets/dashboard_placeholder_tab.dart';
import '../widgets/inbox_thread_card.dart';

class InboxView extends GetView<InboxController> {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Obx(() {
          final unreadThreads = controller.unreadThreadCount;
          final vehicleCount = controller.threads.map((t) => t.plateNumber).toSet().length;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox',
                      style: AppTextStyles.headingLg.copyWith(color: AppColors.ink, fontSize: 24),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unreadThreads == 0
                          ? "You're all caught up"
                          : '$unreadThreads unread across $vehicleCount vehicle${vehicleCount == 1 ? '' : 's'}',
                      style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (unreadThreads > 0)
                GestureDetector(
                  onTap: controller.markAllRead,
                  child: Text(
                    'Mark all read',
                    style: AppTextStyles.label.copyWith(color: AppColors.yellow, letterSpacing: 0),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 24),
        Obx(() {
          final threads = controller.threads;
          if (threads.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: DashboardPlaceholderTab(
                icon: Icons.chat_bubble_outline,
                title: 'No messages yet',
                subtitle: "You'll see messages from anyone who scans your car here.",
              ),
            );
          }
          return Column(
            children: [
              for (final thread in threads) ...[
                InboxThreadCard(thread: thread),
                if (thread != threads.last) const SizedBox(height: 10),
              ],
            ],
          );
        }),
      ],
    );
  }
}
