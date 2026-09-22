import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/chat_thread_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/resolved_banner.dart';

class ChatThreadView extends GetView<ChatThreadController> {
  const ChatThreadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(controller: controller),
            Obx(
              () => ResolvedBanner(
                isResolved: controller.isResolved.value,
                onResolved: controller.markResolved,
                onNotResolved: controller.markNotResolved,
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: controller.messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => ChatBubble(message: controller.messages[index]),
                ),
              ),
            ),
            _InputBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final ChatThreadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF262622))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF33332E), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: Color(0xFF2A2210), shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, size: 17, color: AppColors.yellow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.counterpartName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.vehicleColor,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: const Color(0xFF33332E)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(controller.plateNumber, style: AppTextStyles.overline.copyWith(color: AppColors.muted, letterSpacing: 0)),
                  ],
                ),
              ],
            ),
          ),
          _IconButton(icon: Icons.call_outlined, onTap: () => controller.startCall(video: false)),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.videocam_outlined, onTap: () => controller.startCall(video: true)),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF33332E), width: 1.5),
        ),
        child: Icon(icon, size: 16, color: AppColors.ink),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller});

  final ChatThreadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF262622))),
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.attach_file, onTap: controller.attachMedia),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF33332E), width: 1.5),
              ),
              child: TextField(
                controller: controller.textController,
                style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontSize: 13.5),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Message ${controller.counterpartName}...',
                  hintStyle: AppTextStyles.manropeBase.copyWith(color: AppColors.faint, fontSize: 13.5),
                ),
                onSubmitted: (_) => controller.sendText(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: controller.sendText,
            onLongPress: controller.recordVoiceNote,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
              child: const Icon(Icons.mic_none, size: 17, color: AppColors.background),
            ),
          ),
        ],
      ),
    );
  }
}
