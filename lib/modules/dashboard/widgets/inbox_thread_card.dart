import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/message_thread_model.dart';

/// One conversation row in the Inbox.
///
/// Deliberately shows only what a `conversations/{id}` document actually
/// carries: counterpart name, plate + colour, last message text, the time
/// of that message, resolved state, and whether it is unread. There is no
/// avatar image, presence, delivery receipt or message-type field in the
/// data model, so none of those are rendered — an initials avatar stands
/// in for the picture rather than a fake photo.
class InboxThreadCard extends StatelessWidget {
  const InboxThreadCard({super.key, required this.thread});

  final MessageThreadModel thread;

  /// The person on the other side: from the owner's Inbox that's whoever
  /// scanned the sticker; from the "Sent" list it's the car's owner.
  String get _counterpartName {
    if (thread.viewerRole == ThreadViewerRole.owner) return thread.scannerName;
    return thread.ownerName.isEmpty ? 'Car owner' : thread.ownerName;
  }

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.chatThread, arguments: thread),
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.yellow.withValues(alpha: 0.06),
        highlightColor: AppColors.yellow.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: unread ? const Color(0xFF211E16) : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread ? AppColors.yellow.withValues(alpha: 0.55) : const Color(0xFF2A2A26),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: unread ? 0.28 : 0.18),
                blurRadius: unread ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: _counterpartName, unread: unread, anonymous: thread.isAnonymous),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            _counterpartName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.fieldValue.copyWith(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          thread.timeLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: unread ? AppColors.yellow : AppColors.faint,
                            fontSize: 11.5,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(child: _PlateChip(thread: thread)),
                        if (thread.isResolved) ...[
                          const SizedBox(width: 6),
                          const _ResolvedChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessagePreview.isEmpty
                                ? 'No messages yet'
                                : thread.lastMessagePreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              color: unread ? AppColors.ink : AppColors.muted,
                              fontSize: 13.5,
                              height: 1.35,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 10),
                          _UnreadBadge(count: thread.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.unread, required this.anonymous});

  final String name;
  final bool unread;
  final bool anonymous;

  /// Up to two initials from the counterpart's name. Anonymous scanners
  /// (the default for someone who messaged from the public web page
  /// without giving a name) get an icon instead of the letter "A", which
  /// would read as a real initial.
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unread ? const Color(0xFF3A2F12) : const Color(0xFF262622),
        border: Border.all(
          color: unread ? AppColors.yellow.withValues(alpha: 0.7) : const Color(0xFF33332E),
          width: 1.5,
        ),
      ),
      child: anonymous
          ? Icon(Icons.person_outline, size: 20, color: unread ? AppColors.yellow : AppColors.muted)
          : Text(
              _initials,
              style: AppTextStyles.fieldValue.copyWith(
                color: unread ? AppColors.yellow : AppColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.thread});

  final MessageThreadModel thread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E2E29)),
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
              border: Border.all(color: const Color(0xFF3A3A34)),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              thread.plateNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.overline.copyWith(color: AppColors.muted, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedChip extends StatelessWidget {
  const _ResolvedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF16231A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF2E4A33)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 11, color: Color(0xFF7FBF7F)),
          const SizedBox(width: 4),
          Text(
            'RESOLVED',
            style: AppTextStyles.overline.copyWith(
              color: const Color(0xFF7FBF7F),
              letterSpacing: 0.4,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The number of unread messages in this conversation.
///
/// Conversations written before the per-message counters existed have only
/// the old boolean, which reads back as 1 — so those threads still show a
/// badge rather than silently losing it.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count unread message${count == 1 ? '' : 's'}',
      child: Container(
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(color: AppColors.yellow.withValues(alpha: 0.35), blurRadius: 7),
          ],
        ),
        child: Text(
          // Past 99 the exact number stops being useful and starts
          // stretching the row.
          count > 99 ? '99+' : '$count',
          textAlign: TextAlign.center,
          style: AppTextStyles.overline.copyWith(
            color: Colors.black,
            fontSize: 10.5,
            letterSpacing: 0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
