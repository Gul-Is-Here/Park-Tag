import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/widgets/bound_view.dart';
import '../../../app/widgets/shimmer.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/home_tab_controller.dart';
import '../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

/// Home: who you are, the two things you can do from here (scan a sticker,
/// open your messages), and the vehicles you own.
///
/// Every value shown comes from the existing controller — the resident's
/// first name, their vehicle documents, and the unread state the Inbox tab
/// is already listening to. Nothing on this screen is generated.
class HomeTabView extends BoundView<HomeTabController> {
  const HomeTabView({super.key});

  @override
  Widget buildWith(BuildContext context, HomeTabController controller) {
    return RefreshIndicator(
      onRefresh: controller.reload,
      color: AppColors.yellow,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        // Always scrollable so pull-to-refresh still works on the empty
        // and error states, which are shorter than the viewport.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            sliver: SliverToBoxAdapter(child: _Header(controller: controller)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(controller: controller),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            sliver: Obx(() {
              if (controller.hasError.value) {
                return SliverToBoxAdapter(
                  child: _ErrorState(controller: controller),
                );
              }
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(child: _VehiclesSkeleton());
              }

              final vehicles = controller.vehicles;
              if (vehicles.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyState(controller: controller),
                );
              }

              return SliverList.separated(
                itemCount: vehicles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _AppearInOrder(
                  index: index,
                  child: _ReactiveVehicleCard(
                    controller: controller,
                    vehicle: vehicles[index],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Only the unread dot reacts here, so a new message repaints one card
/// rather than the whole list.
class _ReactiveVehicleCard extends StatelessWidget {
  const _ReactiveVehicleCard({required this.controller, required this.vehicle});

  final HomeTabController controller;
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasUnreadSource) return VehicleCard(vehicle: vehicle);
    return Obx(
      () => VehicleCard(
        vehicle: vehicle,
        hasUnread: controller.hasUnreadFor(vehicle.id),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.greeting,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.muted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Obx(
                () => Text(
                  controller.residentFirstName.value.isEmpty
                      ? 'there'
                      : controller.residentFirstName.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingLg.copyWith(
                    color: AppColors.ink,
                    fontSize: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderAction(
          icon: Icons.qr_code_scanner_rounded,
          tint: AppColors.yellow,
          semanticLabel: 'Scan a vehicle QR code',
          onTap: () => Get.toNamed(AppRoutes.qrScanner),
        ),
        const SizedBox(width: 10),
        // Previously a decorative bell with no onTap at all. Wired to the
        // Inbox tab, carrying the unread count that tab already computes.
        // Builder(
        //   builder: (context) {
        //     Widget action(int count) => _HeaderAction(
        //       icon: Icons.forum_outlined,
        //       tint: AppColors.muted,
        //       semanticLabel: 'Messages',
        //       badgeCount: count,
        //       onTap: () => Get.find<DashboardController>().changeTab(1),
        //     );
        //     if (!controller.hasUnreadSource) return action(0);
        //     return Obx(() => action(controller.unreadCount));
        //   },
        // ),
        _HeaderAction(
          icon: Icons.notifications,
          tint: AppColors.yellow,
          semanticLabel: 'Notification icon',
          onTap: () {},
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tint,
    required this.semanticLabel,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final Color tint;
  final String semanticLabel;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: badgeCount > 0
          ? '$semanticLabel, $badgeCount unread'
          : semanticLabel,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.yellow.withValues(alpha: 0.1),
          child: Container(
            // 44x44 keeps the touch target at the platform minimum.
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: tint, size: 20),
                if (badgeCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.overline.copyWith(
                          color: Colors.black,
                          fontSize: 9,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your vehicles',
                style: AppTextStyles.headingSm.copyWith(
                  color: AppColors.ink,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() {
                if (controller.isLoading.value || controller.hasError.value) {
                  return const SizedBox(height: 16);
                }
                final count = controller.vehicles.length;
                return SizedBox(
                  height: 16,
                  child: Text(
                    count == 0
                        ? 'Each vehicle gets its own QR sticker'
                        : '$count vehicle${count == 1 ? '' : 's'} · tap one for its QR code',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AddVehicleButton(onTap: controller.addVehicle),
      ],
    );
  }
}

class _AddVehicleButton extends StatelessWidget {
  const _AddVehicleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add a vehicle',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: AppColors.yellow.withValues(alpha: 0.1),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppColors.yellow,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.yellow,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors [VehicleCard]'s geometry exactly — same 20px radius, same 14px
/// padding, same 56px thumb — so the real cards drop in without the list
/// shifting.
class _VehiclesSkeleton extends StatelessWidget {
  const _VehiclesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const ShimmerBox(width: 56, height: 56, radius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(width: 130, height: 15),
                        const SizedBox(height: 7),
                        const ShimmerBox(width: 92, height: 12),
                        const SizedBox(height: 11),
                        const ShimmerBox(width: 104, height: 22, radius: 9),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ShimmerBox(width: 52, height: 52, radius: 12),
                ],
              ),
            ),
            if (i != 2) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return HomeStateBlock(
      icon: Icons.directions_car_filled_outlined,
      title: 'No vehicles yet',
      subtitle:
          'Add your first vehicle and ParkTag generates a QR sticker for it. '
          'Anyone who scans it can message you without seeing your number.',
      action: _AddVehicleButton(onTap: controller.addVehicle),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.controller});

  final HomeTabController controller;

  @override
  Widget build(BuildContext context) {
    return HomeStateBlock(
      icon: Icons.wifi_off_rounded,
      title: 'Something went wrong',
      subtitle:
          "We couldn't load your vehicles. Check your connection and try again.",
      action: Semantics(
        button: true,
        child: Material(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: controller.reload,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Try again',
                style: AppTextStyles.buttonLabel.copyWith(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A brief staggered fade/rise, capped so a long list never makes the last
/// card wait.
class _AppearInOrder extends StatelessWidget {
  const _AppearInOrder({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (index.clamp(0, 5) * 45)),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
