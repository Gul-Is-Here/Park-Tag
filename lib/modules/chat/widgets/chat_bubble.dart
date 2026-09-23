import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../dashboard/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.isOutgoing = false,
    this.showTail = true,
    this.onRetry,
  });

  final ChatMessageModel message;

  /// Whether this message was sent by the person looking at the screen.
  /// Not the same as "from the owner": the scanner side of a conversation
  /// sees their own messages on the right too.
  final bool isOutgoing;

  /// False for a message in the middle of a run from the same sender —
  /// grouped messages drop the timestamp row and the bubble's tail.
  final bool showTail;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isOwner = isOutgoing;

    return Align(
      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildContent(isOwner),
            if (showTail || message.status != ChatMessageStatus.sent) ...[
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: isOwner ? 0 : 4, right: isOwner ? 4 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timeLabel,
                      style: AppTextStyles.caption.copyWith(color: AppColors.faint, fontSize: 11),
                    ),
                    // Outgoing messages show only what the backend can
                    // actually confirm: in flight, written, or failed.
                    // There is no delivery or read receipt in the schema,
                    // so no double-tick is shown.
                    if (isOwner) ...[
                      const SizedBox(width: 5),
                      switch (message.status) {
                        ChatMessageStatus.sending => const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.4, color: AppColors.faint),
                        ),
                        ChatMessageStatus.sent => const Icon(Icons.check, size: 13, color: AppColors.faint),
                        ChatMessageStatus.failed => const Icon(
                          Icons.error_outline,
                          size: 13,
                          color: Color(0xFFE0736B),
                        ),
                      },
                    ],
                  ],
                ),
              ),
            ],
            if (message.status == ChatMessageStatus.failed) ...[
              const SizedBox(height: 3),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Not sent · Tap to retry',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFE0736B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isOwner) {
    final tail = showTail ? const Radius.circular(4) : const Radius.circular(16);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isOwner ? const Radius.circular(16) : tail,
      bottomRight: isOwner ? tail : const Radius.circular(16),
    );

    switch (message.kind) {
      case ChatMessageKind.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isOwner ? AppColors.yellow : AppColors.surface,
            borderRadius: radius,
            border: isOwner ? null : Border.all(color: const Color(0xFF33332E), width: 1.5),
          ),
          child: Text(
            message.text,
            style: AppTextStyles.fieldValue.copyWith(
              color: isOwner ? AppColors.background : AppColors.ink,
              fontWeight: isOwner ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        );
      case ChatMessageKind.voice:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isOwner ? AppColors.yellow : AppColors.surface,
            borderRadius: radius,
            border: isOwner ? null : Border.all(color: const Color(0xFF33332E), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isOwner ? AppColors.background : const Color(0xFF2A2210),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, size: 15, color: isOwner ? AppColors.yellow : AppColors.yellow),
              ),
              const SizedBox(width: 10),
              Icon(Icons.graphic_eq, size: 18, color: isOwner ? AppColors.background : AppColors.muted),
              const SizedBox(width: 10),
              Text(
                message.voiceDuration,
                style: AppTextStyles.caption.copyWith(
                  color: isOwner ? AppColors.background : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case ChatMessageKind.photo:
        return ClipRRect(
          borderRadius: radius,
          child: Container(
            width: 160,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2A26), Color(0xFF1B1B18)],
              ),
              border: Border.all(color: const Color(0xFF33332E), width: 1.5),
            ),
            child: const Icon(Icons.image_outlined, size: 26, color: AppColors.faint),
          ),
        );
    }
  }
}
