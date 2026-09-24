import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/scan_controller.dart';
import '../widgets/vehicle_photo_tile.dart';

/// 3.18mm (the standard ID-card corner radius) converted to logical
/// pixels at 96dpi (1mm ≈ 3.7795px) — ≈12.02.
const _cardCornerRadius = 3.18 * 3.7795275591;

/// Launcher for ML Kit's Document Scanner — Google's flow runs fullscreen
/// on top of this screen. Flow: choose to scan or enter manually -> if
/// scanning, capture the RC card's front then back (CNIC-style two-box
/// layout) -> Next hands both images to Review, which OCRs and merges
/// them to fill the form.
class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  _RoundIconButton(icon: Icons.close, onTap: Get.back),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isChoosing.value) {
                  return _ChoiceState(
                    isScannerUnavailable: controller.isScannerUnavailable.value,
                    onScan: controller.startScanning,
                    onEnterManually: controller.enterManually,
                  );
                }
                return _CaptureState(
                  frontImagePath: controller.frontImagePath.value,
                  backImagePath: controller.backImagePath.value,
                  isLaunching: controller.isLaunching.value,
                  errorMessage: controller.errorMessage.value,
                  isScannerUnavailable: controller.isScannerUnavailable.value,
                  onCaptureFront: () => _capture(RcCardSide.front),
                  onCaptureBack: () => _capture(RcCardSide.back),
                  onRemoveFront: () => controller.removeSide(RcCardSide.front),
                  onRemoveBack: () => controller.removeSide(RcCardSide.back),
                  onNext: controller.next,
                  onEnterManually: controller.enterManually,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _capture(RcCardSide side) {
    if (controller.isScannerUnavailable.value) {
      controller.pickSideFromGallery(side);
    } else {
      controller.scanSide(side);
    }
  }
}

class _ChoiceState extends StatelessWidget {
  const _ChoiceState({
    required this.isScannerUnavailable,
    required this.onScan,
    required this.onEnterManually,
  });

  final bool isScannerUnavailable;
  final VoidCallback onScan;
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add your vehicle',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSm.copyWith(
              color: AppColors.ink,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan the RC card to fill the details automatically, or enter them yourself.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),
          _ChoiceCard(
            icon: Icons.document_scanner_outlined,
            title: 'Scan the document',
            subtitle: 'Scan the front and back of the RC card',
            onTap: onScan,
          ),
          const SizedBox(height: 16),
          _ChoiceCard(
            icon: Icons.edit_note_outlined,
            title: 'Enter manual details',
            subtitle: 'Fill in the vehicle details yourself',
            onTap: onEnterManually,
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingSm.copyWith(
                        color: AppColors.ink,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureState extends StatelessWidget {
  const _CaptureState({
    required this.frontImagePath,
    required this.backImagePath,
    required this.isLaunching,
    required this.errorMessage,
    required this.isScannerUnavailable,
    required this.onCaptureFront,
    required this.onCaptureBack,
    required this.onRemoveFront,
    required this.onRemoveBack,
    required this.onNext,
    required this.onEnterManually,
  });

  final String? frontImagePath;
  final String? backImagePath;
  final bool isLaunching;
  final String? errorMessage;
  final bool isScannerUnavailable;
  final VoidCallback onCaptureFront;
  final VoidCallback onCaptureBack;
  final VoidCallback onRemoveFront;
  final VoidCallback onRemoveBack;
  final VoidCallback onNext;
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    final hasBoth = frontImagePath != null && backImagePath != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scan the RC card',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSm.copyWith(
              color: AppColors.ink,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isScannerUnavailable
                ? 'Add a photo of the front, then the back.'
                : 'Scan the front, then the back — just like scanning a CNIC.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ),
          VehiclePhotoTile(
            label: 'Front side',
            imagePath: frontImagePath,
            onTap: onCaptureFront,
            onRemove: frontImagePath != null ? onRemoveFront : null,
            // CR80 ID-card proportions (85.6mm x 53.98mm) and radius — the
            // RC card is scanned in the same shape it actually is.
            aspectRatio: 1.586,
            borderRadius: _cardCornerRadius,
          ),
          const SizedBox(height: 14),
          VehiclePhotoTile(
            label: 'Back side',
            imagePath: backImagePath,
            onTap: onCaptureBack,
            onRemove: backImagePath != null ? onRemoveBack : null,
            aspectRatio: 1.586,
            borderRadius: _cardCornerRadius,
          ),
          if (isLaunching)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.yellow),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasBoth ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                disabledBackgroundColor: AppColors.yellow.withValues(
                  alpha: 0.4,
                ),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Next',
                style: AppTextStyles.headingSm.copyWith(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onEnterManually,
            child: Text(
              'Enter details manually',
              textAlign: TextAlign.center,
              style: AppTextStyles.linkTextEmphasis.copyWith(
                color: AppColors.yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.ink, size: 18),
      ),
    );
  }
}
