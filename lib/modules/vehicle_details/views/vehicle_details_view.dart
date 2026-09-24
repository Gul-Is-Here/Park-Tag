import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../dashboard/models/vehicle_model.dart';
import '../controllers/vehicle_details_controller.dart';

class VehicleDetailsView extends GetView<VehicleDetailsController> {
  const VehicleDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Reactive: editing this vehicle pops back into this same screen with
    // the updated data (see VehicleDetailsController.editVehicle) instead
    // of pushing a fresh copy of it, so this needs to rebuild in place.
    return Obx(() => _buildContent(context, controller.vehicle));
  }

  Widget _buildContent(BuildContext context, VehicleModel vehicle) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RoundIconButton(icon: Icons.arrow_back, onTap: Get.back),
                  const Spacer(),
                  Text(
                    'Vehicle Details',
                    style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 17),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.yellow,
                    onTap: controller.editVehicle,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                vehicle.nickname,
                style: AppTextStyles.headingLg.copyWith(color: AppColors.ink, fontSize: 24),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: vehicle.color,
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${vehicle.makeModel}${vehicle.colorName.isNotEmpty ? ' · ${vehicle.colorName}' : ''}',
                    style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // QR card
              RepaintBoundary(
                key: controller.qrBoundaryKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.yellow, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: vehicle.qrScanUrl,
                          size: 156,
                          backgroundColor: AppColors.ink,
                          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.background),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SCAN TO VERIFY VEHICLE',
                        style: AppTextStyles.label.copyWith(color: AppColors.yellow, letterSpacing: 0.4),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show this to the parking attendant',
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Obx(
                () => GestureDetector(
                  onTap: controller.isSharing.value ? null : controller.shareQrCode,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isSharing.value)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
                          )
                        else
                          Icon(Icons.ios_share, size: 16, color: AppColors.yellow),
                        const SizedBox(width: 8),
                        Text('Share QR Code', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.ink, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Plate
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.yellow, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REGISTRATION NUMBER',
                          style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0.4),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicle.plateNumber,
                          style: AppTextStyles.headingSm.copyWith(
                            color: AppColors.ink,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.confirmation_number_outlined, color: AppColors.yellow, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              if (vehicle.photoPaths.isNotEmpty) ...[
                Text(
                  'VEHICLE PHOTOS',
                  style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final path in vehicle.photoPaths.take(2)) ...[
                      Expanded(child: _VehiclePhoto(path: path)),
                      if (path != vehicle.photoPaths.take(2).last) const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
              ],

              // Info card
              Text(
                'VEHICLE INFORMATION',
                style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0.4),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Make & Model', value: vehicle.makeModel),
                    if (vehicle.colorName.isNotEmpty)
                      _InfoRow(label: 'Color', value: vehicle.colorName, swatch: vehicle.color),
                    if (vehicle.dateOfRegistration.isNotEmpty)
                      _InfoRow(label: 'Date of registration', value: vehicle.dateOfRegistration),
                    if (vehicle.engineNumber.isNotEmpty)
                      _InfoRow(label: 'Engine number', value: vehicle.engineNumber),
                    if (vehicle.chassisNumber.isNotEmpty)
                      _InfoRow(label: 'Chassis number', value: vehicle.chassisNumber),
                    if (vehicle.address.isNotEmpty)
                      _InfoRow(label: 'Registered address', value: vehicle.address, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: controller.editVehicle,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 17, color: AppColors.background),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Vehicle',
                        style: AppTextStyles.buttonLabel.copyWith(color: AppColors.background, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: controller.removeVehicle,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3A2323), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline, size: 17, color: Color(0xFFE5675E)),
                      const SizedBox(width: 8),
                      Text(
                        'Remove Vehicle',
                        style: AppTextStyles.buttonLabel.copyWith(color: const Color(0xFFE5675E), fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  _RoundIconButton({required this.icon, required this.onTap, Color? iconColor}) : iconColor = iconColor ?? AppColors.ink;

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _VehiclePhoto extends StatelessWidget {
  const _VehiclePhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
          image: DecorationImage(
            image: path.startsWith('http') ? NetworkImage(path) : FileImage(File(path)) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.swatch, this.isLast = false});

  final String label;
  final String value;
  final Color? swatch;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13.5, height: 1.3)),
          const SizedBox(width: 16),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (swatch != null) ...[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
