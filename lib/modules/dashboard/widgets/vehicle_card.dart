import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/vehicle_model.dart';
import 'vehicle_image_thumb.dart';
import 'vehicle_qr_thumb.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.vehicleDetails, arguments: vehicle),
      child: Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF33332E), width: 1.5),
          ),
          child: Row(
            children: [
              VehicleImageThumb(photoPaths: vehicle.photoPaths),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSm.copyWith(
                        color: AppColors.ink,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle.makeModel,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: vehicle.color,
                            border: Border.all(color: const Color(0xFF33332E)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.plateNumber,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.muted,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const VehicleQrThumb(),
            ],
          ),
        ),
        if (vehicle.hasUnread)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow,
                border: Border.all(color: AppColors.surface, width: 3),
              ),
            ),
          ),
      ],
      ),
    );
  }
}
