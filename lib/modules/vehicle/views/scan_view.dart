import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/scan_controller.dart';

/// Thin launcher for ML Kit's Document Scanner — Google's flow runs
/// fullscreen on top of this screen, so this only renders what's left
/// around it: the launching state, an error/retry state, and the
/// gallery/manual fallbacks (which are all iOS ever sees, since the
/// scanner is Android-only).
class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
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
                if (controller.isLaunching.value) {
                  return const _LaunchingState();
                }
                return _FallbackState(
                  title: controller.isScannerUnavailable.value
                      ? 'Scanning isn’t available on this device'
                      : 'Scan the RC card',
                  message: controller.errorMessage.value ??
                      (controller.isScannerUnavailable.value
                          ? 'Pick a photo of the RC card from your gallery, or enter the details yourself.'
                          : 'Scan the card to fill the details automatically.'),
                  showRetry: !controller.isScannerUnavailable.value,
                  onRetry: controller.launchScanner,
                  onPickFromGallery: controller.pickFromGallery,
                  onEnterManually: controller.enterManually,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchingState extends StatelessWidget {
  const _LaunchingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.yellow),
          const SizedBox(height: 20),
          Text(
            'Opening the scanner…',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FallbackState extends StatelessWidget {
  const _FallbackState({
    required this.title,
    required this.message,
    required this.showRetry,
    required this.onRetry,
    required this.onPickFromGallery,
    required this.onEnterManually,
  });

  final String title;
  final String message;
  final bool showRetry;
  final VoidCallback onRetry;
  final VoidCallback onPickFromGallery;
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.document_scanner_outlined, size: 44, color: AppColors.faint),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSm.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          if (showRetry) ...[
            _PrimaryButton(label: 'Scan the card', onTap: onRetry),
            const SizedBox(height: 12),
          ],
          _SecondaryButton(label: 'Choose from gallery', onTap: onPickFromGallery),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onEnterManually,
            child: Text(
              'Enter details manually',
              style: AppTextStyles.linkTextEmphasis.copyWith(color: AppColors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: AppTextStyles.headingSm.copyWith(color: Colors.black, fontSize: 15)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.faint.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 15)),
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
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.ink, size: 18),
      ),
    );
  }
}
