import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/bound_view.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/inbox_controller.dart';
import '../models/message_thread_model.dart';
import '../widgets/inbox_thread_card.dart';

/// The resident's conversation list.
///
/// Ordering is not done here — `watchOwnerConversations` already returns
/// conversations by `lastMessageAt` descending, and it is a live Firestore
/// listener, so a new message re-sorts the list to the top on its own.
/// Search and filtering run over the summaries already in memory, so they
/// cost nothing per keystroke.
class InboxView extends BoundView<InboxController> {
  const InboxView({super.key});

  @override
  Widget buildWith(BuildContext context, InboxController controller) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          sliver: SliverToBoxAdapter(child: _Header(controller: controller)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          sliver: Obx(() {
            if (controller.hasError.value) {
              return SliverToBoxAdapter(child: _ErrorState(controller: controller));
            }
            if (controller.isLoading.value) {
              return const SliverToBoxAdapter(child: _LoadingState());
            }

            final threads = controller.visibleThreads;
            final sent = controller.visibleSentThreads;

            if (threads.isEmpty && sent.isEmpty) {
              return SliverToBoxAdapter(
                child: controller.query.value.isNotEmpty || controller.filter.value != InboxFilter.all
                    ? const _NoMatchesState()
                    : const _EmptyState(),
              );
            }

            return SliverList(
              delegate: SliverChildListDelegate([
                for (var i = 0; i < threads.length; i++) ...[
                  _AnimatedRow(index: i, child: InboxThreadCard(thread: threads[i])),
                  if (i != threads.length - 1) const SizedBox(height: 10),
                ],
                if (sent.isNotEmpty) _SentSection(threads: sent, hasInbox: threads.isNotEmpty),
              ]),
            );
          }),
        ),
      ],
    );
  }
}

/// Title, live unread summary, search toggle, and the filter row. The
/// filters map onto real conversation fields — there is no mute/archive/
/// pin flag in Firestore to filter on, so none is offered.
class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final InboxController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final unreadThreads = controller.unreadThreadCount;
          final unreadMessages = controller.unreadMessageCount;
          // Vehicles that actually have something unread — previously this
          // counted every vehicle, so "2 unread across 3 vehicles" could
          // name a vehicle with nothing waiting on it.
          final vehicleCount = controller.threads
              .where((t) => t.unreadCount > 0)
              .map((t) => t.plateNumber)
              .toSet()
              .length;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox',
                      style: AppTextStyles.headingLg.copyWith(color: AppColors.ink, fontSize: 26),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unreadThreads == 0
                          ? "You're all caught up"
                          : '$unreadMessages unread message${unreadMessages == 1 ? '' : 's'}'
                                '${vehicleCount == 0 ? '' : ' across $vehicleCount vehicle${vehicleCount == 1 ? '' : 's'}'}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: unreadThreads == 0 ? AppColors.muted : AppColors.yellow,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleAction(
                icon: controller.isSearching.value ? Icons.close : Icons.search,
                active: controller.isSearching.value,
                onTap: controller.toggleSearch,
              ),
              if (unreadThreads > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: controller.markAllRead,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2210),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.yellow.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.label.copyWith(color: AppColors.yellow, letterSpacing: 0),
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        Obx(
          () => AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: controller.isSearching.value
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _SearchField(controller: controller),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
        const SizedBox(height: 14),
        _FilterRow(controller: controller),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final InboxController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E29)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.faint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: controller.setQuery,
              cursorColor: AppColors.yellow,
              style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search name, plate or message',
                hintStyle: AppTextStyles.subtitle.copyWith(color: AppColors.faint, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.controller});

  final InboxController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.filter.value;
      return Row(
        children: [
          for (final f in InboxFilter.values) ...[
            _FilterChip(
              label: switch (f) {
                InboxFilter.all => 'All',
                InboxFilter.unread => 'Unread',
                InboxFilter.resolved => 'Resolved',
              },
              selected: f == active,
              onTap: () => controller.setFilter(f),
            ),
            if (f != InboxFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellow : AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? AppColors.yellow : const Color(0xFF2E2E29)),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.black : AppColors.muted,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.active, required this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A2210) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.yellow.withValues(alpha: 0.35) : const Color(0xFF2E2E29)),
        ),
        child: Icon(icon, size: 18, color: active ? AppColors.yellow : AppColors.muted),
      ),
    );
  }
}

class _SentSection extends StatelessWidget {
  const _SentSection({required this.threads, required this.hasInbox});

  final List<MessageThreadModel> threads;
  final bool hasInbox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: hasInbox ? 30 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sent', style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            'Conversations you started by messaging other cars.',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < threads.length; i++) ...[
            _AnimatedRow(index: i, child: InboxThreadCard(thread: threads[i])),
            if (i != threads.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// A short staggered fade/slide as rows appear. Capped so a long list
/// doesn't make the last card wait — this should read as responsive, not
/// as an animation being performed at the user.
class _AnimatedRow extends StatelessWidget {
  const _AnimatedRow({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayed = (index.clamp(0, 6)) * 40;
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + delayed),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
      ),
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++) ...[
          const _SkeletonCard(),
          if (i != 3) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final v = 0.35 + (_pulse.value * 0.35);
        Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF33332E).withValues(alpha: v),
            borderRadius: BorderRadius.circular(6),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2A2A26)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF33332E).withValues(alpha: v),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(120, 12),
                    const SizedBox(height: 10),
                    bar(80, 10),
                    const SizedBox(height: 10),
                    bar(double.infinity, 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _StateBlock(
      icon: Icons.forum_outlined,
      title: 'No messages yet',
      subtitle:
          "When someone scans your car's QR sticker, their message lands here — "
          'and anyone you message shows up under Sent.',
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState();

  @override
  Widget build(BuildContext context) {
    return const _StateBlock(
      icon: Icons.search_off,
      title: 'No conversations match',
      subtitle: 'Try a different name, plate number or word from the message.',
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.controller});

  final InboxController controller;

  @override
  Widget build(BuildContext context) {
    return _StateBlock(
      icon: Icons.wifi_off,
      title: 'Unable to load messages',
      subtitle: 'Check your connection and try again.',
      action: GestureDetector(
        onTap: controller.retry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Retry',
            style: AppTextStyles.buttonLabel.copyWith(color: Colors.black, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _StateBlock extends StatelessWidget {
  const _StateBlock({required this.icon, required this.title, required this.subtitle, this.action});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: const Color(0xFF2E2E29)),
            ),
            child: Icon(icon, size: 30, color: AppColors.faint),
          ),
          const SizedBox(height: 18),
          Text(title, style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 17)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13, height: 1.45),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}
