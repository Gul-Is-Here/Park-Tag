import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../auth/widgets/auth_primary_button.dart';
import '../controllers/review_vehicle_controller.dart';
import '../utils/card_validator.dart';
import '../widgets/vehicle_form_field.dart';
import '../widgets/vehicle_photo_tile.dart';
import '../../../app/utils/vehicle_input.dart';

class _RcCardImage extends StatelessWidget {
  const _RcCardImage({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF33332E), width: 1.5),
              image: DecorationImage(
                image: FileImage(File(path)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class ReviewVehicleView extends GetView<ReviewVehicleController> {
  const ReviewVehicleView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF33332E),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.ink,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review vehicle details',
                          style: AppTextStyles.headingSm.copyWith(
                            color: AppColors.ink,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.hasScannedCard
                              ? "Read from your RC card — check before saving"
                              : 'Enter your vehicle details',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.yellow,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (controller.hasScannedCard) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (controller.frontImagePath != null)
                      Expanded(
                        child: _RcCardImage(
                          path: controller.frontImagePath!,
                          label: 'Front',
                        ),
                      ),
                    if (controller.frontImagePath != null &&
                        controller.backImagePath != null)
                      const SizedBox(width: 12),
                    if (controller.backImagePath != null)
                      Expanded(
                        child: _RcCardImage(
                          path: controller.backImagePath!,
                          label: 'Back',
                        ),
                      ),
                  ],
                ),
                Obx(() {
                  if (!controller.isScanningRcCard.value)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.yellow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Reading card…',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Obx(() {
                  if (!controller.ocrFailed.value ||
                      controller.isScanningRcCard.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
                      onTap: controller.retryOcrScan,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 16,
                            color: AppColors.yellow,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Retry scan',
                            style: AppTextStyles.linkTextEmphasis.copyWith(
                              color: AppColors.yellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => VehicleFormField(
                        label: 'Make',
                        controller: controller.make,
                        hint: 'US 70',
                        helper: controller.isLowConfidence(CardField.make)
                            ? '⚠ check'
                            : null,
                        inputFormatters: [vehicleNameFormatter],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Obx(
                      () => VehicleFormField(
                        label: 'Maker Name',
                        controller: controller.model,
                        hint: 'UNITED',
                        helper: controller.isLowConfidence(CardField.makerName)
                            ? '⚠ check'
                            : null,
                        inputFormatters: [vehicleNameFormatter],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Obx(
                () => VehicleFormField(
                  label: 'Registration number (plate)',
                  controller: controller.plateNumber,
                  hint: 'LEA-2231',
                  helper: controller.isLowConfidence(CardField.plateNumber)
                      ? '⚠ check'
                      : null,
                  emphasize: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [vehicleIdentifierFormatter],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: VehicleFormField(
                      label: 'Color',
                      controller: controller.color,
                      hint: 'White',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: VehicleFormField(
                      label: 'Date of registration',
                      controller: controller.dateOfRegistration,
                      hint: '14 Mar 2022',
                      readOnly: true,
                      onTap: () => controller.pickRegistrationDate(context),
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Engine number',
                controller: controller.engineNumber,
                hint: '2ZR-4498231',
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [vehicleIdentifierFormatter],
              ),
              const SizedBox(height: 18),
              Obx(
                () => VehicleFormField(
                  label: 'Chassis number',
                  controller: controller.chassisNumber,
                  hint: 'MR053CE3204119876',
                  helper: controller.isLowConfidence(CardField.chassisNumber)
                      ? '⚠ check'
                      : null,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [vehicleIdentifierFormatter],
                ),
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Registered address',
                helper: '(optional)',
                controller: controller.address,
                hint: '123 B Model Town Lahore',
                maxLines: 2,
                inputFormatters: [vehicleNameFormatter],
              ),
              const SizedBox(height: 28),
              Obx(() {
                final photos = controller.vehiclePhotos;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VEHICLE PHOTOS',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          '${photos.length} of ${ReviewVehicleController.requiredVehiclePhotos} added',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.yellow,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add at least 2 photos of your vehicle so scanners can confirm it's the right car.",
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: VehiclePhotoTile(
                            label: 'Front view',
                            imagePath: photos.isNotEmpty
                                ? photos[0].path
                                : null,
                            onTap: () => _pickPhoto(context),
                            onRemove: photos.isNotEmpty
                                ? () => controller.removeVehiclePhoto(0)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VehiclePhotoTile(
                            label: 'Back view',
                            imagePath: photos.length > 1
                                ? photos[1].path
                                : null,
                            onTap: () => _pickPhoto(context),
                            onRemove: photos.length > 1
                                ? () => controller.removeVehiclePhoto(1)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 28),
              Obx(() {
                final enoughPhotos =
                    controller.vehiclePhotos.length >=
                    ReviewVehicleController.requiredVehiclePhotos;
                final busy = controller.isSaving.value;
                return Column(
                  children: [
                    AuthPrimaryButton(
                      label: 'Save Vehicle',
                      isLoading: busy,
                      onPressed: !enoughPhotos ? null : controller.save,
                    ),
                    if (!enoughPhotos)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Add 2 vehicle photos to continue',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.faint,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.yellow,
              ),
              title: Text(
                'Take a photo',
                style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.yellow,
              ),
              title: Text(
                'Choose from gallery',
                style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink),
              ),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) {
      await controller.addVehiclePhoto(source);
    }
  }
}
