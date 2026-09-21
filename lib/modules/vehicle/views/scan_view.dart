import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/scan_controller.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(icon: Icons.close, onTap: Get.back),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Scan the RC card',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingSm.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Position the RC card inside the frame',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            AspectRatio(
              aspectRatio: 326 / 206,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _RcFrameGuide(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hold steady · good lighting helps',
              style: AppTextStyles.label.copyWith(color: AppColors.faint, letterSpacing: 0),
            ),
            const Spacer(),
            Obx(
              () => _ShutterButton(
                isBusy: controller.isCapturing.value,
                onTap: controller.captureRcCard,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: controller.enterManually,
              child: Text(
                'Enter details manually',
                style: AppTextStyles.linkTextEmphasis.copyWith(color: AppColors.yellow),
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
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

class _RcFrameGuide extends StatelessWidget {
  const _RcFrameGuide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.35)),
            ),
          ),
        ),
        const _CornerBracket(alignment: Alignment.topLeft),
        const _CornerBracket(alignment: Alignment.topRight),
        const _CornerBracket(alignment: Alignment.bottomLeft),
        const _CornerBracket(alignment: Alignment.bottomRight),
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.yellow, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.yellow, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.yellow, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.yellow, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.yellow, width: 4),
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellow,
                  ),
                ),
        ),
      ),
    );
  }
}
