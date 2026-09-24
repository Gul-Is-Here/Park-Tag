import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/comm_preference_controller.dart';

class CommPreferenceView extends GetView<CommPreferenceController> {
  const CommPreferenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How should we\nreach you?', style: AppTextStyles.headingLg.copyWith(color: AppColors.ink)),
              const SizedBox(height: 12),
              Text(
                "When someone scans your car's QR and messages you, where do you want to see it?",
                style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 36),
              Obx(
                () => Column(
                  children: [
                    _PreferenceCard(
                      title: 'In this app',
                      subtitle: 'Push notifications the moment someone messages you. Recommended.',
                      icon: Icons.notifications_active_outlined,
                      enabled: !controller.isSaving.value,
                      isLoading: controller.selectedPreference.value == 'app',
                      onTap: () => controller.choose('app'),
                    ),
                    const SizedBox(height: 16),
                    _PreferenceCard(
                      title: 'On the web link',
                      subtitle: "I'll check replies through the chat link shared when someone scans.",
                      icon: Icons.language_outlined,
                      enabled: !controller.isSaving.value,
                      isLoading: controller.selectedPreference.value == 'web',
                      onTap: () => controller.choose('web'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Text('You can change this anytime in Profile.', style: AppTextStyles.caption.copyWith(color: AppColors.faint)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  /// True while THIS card's choice is the one being saved — puts the
  /// spinner on the tapped card, not both, since only one save is
  /// actually in flight.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.background),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.yellow),
                    )
                  : Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
