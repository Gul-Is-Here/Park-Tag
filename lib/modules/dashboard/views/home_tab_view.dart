import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/home_tab_controller.dart';
import '../widgets/dashboard_placeholder_tab.dart';
import '../widgets/vehicle_card.dart';

class HomeTabView extends GetView<HomeTabController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good afternoon',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.residentFirstName,
                    style: AppTextStyles.headingLg.copyWith(
                      color: AppColors.ink,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF33332E), width: 1.5),
              ),
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.muted,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your vehicles',
              style: AppTextStyles.headingSm.copyWith(color: AppColors.ink),
            ),
            GestureDetector(
              onTap: controller.addVehicle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF33332E), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.yellow),
                    const SizedBox(width: 6),
                    Text(
                      'Add Vehicle',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.yellow,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final vehicles = controller.vehicles;
          if (vehicles.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: DashboardPlaceholderTab(
                icon: Icons.directions_car_filled_outlined,
                title: 'No vehicles yet',
                subtitle: 'Add a vehicle to generate its QR sticker.',
              ),
            );
          }
          return Column(
            children: [
              for (final vehicle in vehicles) ...[
                VehicleCard(vehicle: vehicle),
                if (vehicle != vehicles.last) const SizedBox(height: 14),
              ],
            ],
          );
        }),
      ],
    );
  }
}
