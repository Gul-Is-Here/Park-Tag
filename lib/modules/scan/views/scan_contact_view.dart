import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/services/conversation_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../chat/widgets/resolved_banner.dart';
import '../controllers/scan_contact_controller.dart';

/// FR-04: the public page a vehicle's QR sticker opens. No sign-in — anyone
/// who scans the sticker lands here, sees the vehicle + owner, can message
/// the owner, and can mark the issue resolved or not.
class ScanContactView extends GetView<ScanContactController> {
  const ScanContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
          }
          if (controller.notFound.value) {
            return const _NotFound();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _VehicleCard(),
                  SizedBox(height: 18),
                  _ResolvedRow(),
                  SizedBox(height: 18),
                  _MessageThread(),
                  SizedBox(height: 18),
                  _MessageComposer(),
                  SizedBox(height: 24),
                  _DownloadAppBanner(),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 40, color: AppColors.faint),
            const SizedBox(height: 16),
            Text(
              "This QR code doesn't match a ParkTag vehicle",
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'The sticker may be damaged, or the vehicle was removed from ParkTag.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends GetView<ScanContactController> {
  const _VehicleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.yellow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: controller.photoUrl.value.isEmpty
                      ? Container(
                          color: AppColors.background,
                          child: const Icon(Icons.directions_car, color: AppColors.faint),
                        )
                      : Image.network(
                          controller.photoUrl.value,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.background,
                            child: const Icon(Icons.directions_car, color: AppColors.faint),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.nickname.value.isEmpty ? controller.plateNumber.value : controller.nickname.value,
                      style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 18),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: controller.vehicleColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF33332E)),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${controller.makeModel.value}${controller.colorName.value.isNotEmpty ? ' · ${controller.colorName.value}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.yellow),
                const SizedBox(width: 8),
                Text(controller.plateNumber.value, style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, letterSpacing: 0.5)),
                const Spacer(),
                const Icon(Icons.person_outline, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    controller.ownerName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 12.5),
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

class _ResolvedRow extends GetView<ScanContactController> {
  const _ResolvedRow();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasConversation.value) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ResolvedBanner(
          isResolved: controller.resolved.value,
          onResolved: controller.toggleResolved,
          onNotResolved: controller.toggleResolved,
        ),
      );
    });
  }
}

class _MessageThread extends GetView<ScanContactController> {
  const _MessageThread();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.messages.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF33332E), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final message in controller.messages) ...[
              Align(
                alignment: message.sender == MessageSender.owner ? Alignment.centerLeft : Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: message.sender == MessageSender.owner ? AppColors.background : AppColors.yellow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sender == MessageSender.owner ? controller.ownerName.value : 'You',
                          style: AppTextStyles.overline.copyWith(
                            color: message.sender == MessageSender.owner ? AppColors.muted : AppColors.background,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.text,
                          style: AppTextStyles.fieldValue.copyWith(
                            color: message.sender == MessageSender.owner ? AppColors.ink : AppColors.background,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _MessageComposer extends GetView<ScanContactController> {
  const _MessageComposer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF33332E), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Message the owner', style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          TextField(
            controller: controller.scannerNameController,
            style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontSize: 13.5),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Your name (optional)',
              hintStyle: AppTextStyles.manropeBase.copyWith(color: AppColors.faint, fontSize: 13.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.messageController,
            minLines: 2,
            maxLines: 4,
            style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontSize: 13.5),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.background,
              hintText: 'e.g. "Please move your car, you are blocking the exit"',
              hintStyle: AppTextStyles.manropeBase.copyWith(color: AppColors.faint, fontSize: 13.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: controller.isSending.value ? null : controller.sendMessage,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isSending.value)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      else
                        const Icon(Icons.send_outlined, size: 16, color: AppColors.background),
                      const SizedBox(width: 8),
                      Text('Send message', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.background, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadAppBanner extends GetView<ScanContactController> {
  const _DownloadAppBanner();

  // TODO: replace with the real published store listings once ParkTag ships.
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.parktag.app';
  static const _appStoreUrl = 'https://apps.apple.com/app/parktag/id0000000000';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2210),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_none, size: 18, color: AppColors.yellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Want to send a voice note or call instead?',
                  style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Get the ParkTag app to talk directly with the owner.',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Obx(() {
            // FR-09: once a Branch handoff link is ready, both store buttons
            // route through it instead of straight to the store, so this
            // browser's scannerId rides along and gets linked automatically
            // once the resident signs in — same conversation continues in
            // the app rather than starting fresh.
            final handoffUrl = controller.appLinkUrl.value;
            return Row(
              children: [
                Expanded(child: _StoreButton(label: 'App Store', url: handoffUrl ?? _appStoreUrl)),
                const SizedBox(width: 10),
                Expanded(child: _StoreButton(label: 'Google Play', url: handoffUrl ?? _playStoreUrl)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.yellow, width: 1.5),
        ),
        child: Text(label, style: AppTextStyles.buttonLabel.copyWith(color: AppColors.yellow, fontSize: 13)),
      ),
    );
  }
}
