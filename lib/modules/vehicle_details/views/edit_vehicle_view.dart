import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../auth/widgets/auth_primary_button.dart';
import '../../vehicle/widgets/vehicle_form_field.dart';
import '../../vehicle/widgets/vehicle_photo_tile.dart';
import '../controllers/edit_vehicle_controller.dart';

class EditVehicleView extends GetView<EditVehicleController> {
  const EditVehicleView({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Vehicle',
                          style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Update your vehicle's saved details",
                          style: AppTextStyles.label.copyWith(color: AppColors.yellow, letterSpacing: 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: VehicleFormField(label: 'Make', controller: controller.make, hint: 'Toyota'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: VehicleFormField(
                      label: 'Model',
                      controller: controller.model,
                      hint: 'Corolla Altis',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Registration number (plate)',
                controller: controller.plateNumber,
                hint: 'LEA-2231',
                emphasize: true,
                textCapitalization: TextCapitalization.characters,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Engine number',
                controller: controller.engineNumber,
                hint: '2ZR-4498231',
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Chassis number',
                controller: controller.chassisNumber,
                hint: 'MR053CE3204119876',
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Registered address',
                helper: '(optional)',
                controller: controller.address,
                hint: '123-B, Model Town, Lahore',
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              VehicleFormField(
                label: 'Vehicle nickname',
                helper: '(optional)',
                controller: controller.nickname,
                hint: 'e.g. White Corolla',
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
                          style: AppTextStyles.label.copyWith(color: AppColors.muted),
                        ),
                        Text(
                          '${photos.length} of ${EditVehicleController.requiredVehiclePhotos} added',
                          style: AppTextStyles.label.copyWith(color: AppColors.yellow, letterSpacing: 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: VehiclePhotoTile(
                            label: 'Front view',
                            imagePath: photos.isNotEmpty ? photos[0] : null,
                            onTap: () => _pickPhoto(context),
                            onRemove: photos.isNotEmpty ? () => controller.removeVehiclePhoto(0) : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VehiclePhotoTile(
                            label: 'Back view',
                            imagePath: photos.length > 1 ? photos[1] : null,
                            onTap: () => _pickPhoto(context),
                            onRemove: photos.length > 1 ? () => controller.removeVehiclePhoto(1) : null,
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
                    controller.vehiclePhotos.length >= EditVehicleController.requiredVehiclePhotos;
                final busy = controller.isSaving.value;
                return Column(
                  children: [
                    AuthPrimaryButton(
                      label: 'Save Changes',
                      onPressed: busy || !enoughPhotos ? null : controller.save,
                    ),
                    if (!enoughPhotos)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Add 2 vehicle photos to continue',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(color: AppColors.faint),
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
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.yellow),
              title: Text('Take a photo', style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink)),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.yellow),
              title: Text('Choose from gallery', style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink)),
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
