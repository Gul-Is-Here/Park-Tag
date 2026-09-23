import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/bound_view.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../auth/widgets/auth_primary_button.dart';
import '../../vehicle/widgets/vehicle_form_field.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends BoundView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget buildWith(BuildContext context, ProfileController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 2.5),
        );
      }
      return _ProfileForm(
        controller: controller,
        phone: controller.phoneNumber.value,
        cnic: controller.cnic.value,
      );
    });
  }
}

/// Only shown while [ProfileController.notificationsPermitted] is false.
///
/// Why this exists: FCM reports a push as "successfully delivered" the
/// moment it reaches the device, regardless of whether the OS is actually
/// allowed to show it. With notifications denied, that push is silently
/// discarded — from the backend's side (and from a resident just staring
/// at the app) it looks identical to a broken token, when the real cause
/// is a permission this app can only ask for once.
class _NotificationsOffBanner extends StatelessWidget {
  const _NotificationsOffBanner({required this.onTapRecheck});

  final VoidCallback onTapRecheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2210),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_off_outlined, color: AppColors.yellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are turned off',
                  style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "You won't be alerted when someone messages you. Enable "
                  'notifications for ParkTag in your phone\'s Settings app, '
                  'then come back here.',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onTapRecheck,
                  child: Text(
                    "I've enabled it — check again",
                    style: AppTextStyles.linkTextEmphasis.copyWith(color: AppColors.yellow, fontSize: 12.5),
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

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({required this.controller, required this.phone, required this.cnic});

  final ProfileController controller;
  final String phone;
  final String cnic;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsOf(controller.name.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        Text(
          'Profile',
          style: AppTextStyles.headingLg.copyWith(color: AppColors.ink, fontSize: 24),
        ),
        const SizedBox(height: 16),
        Obx(
          () => controller.notificationsPermitted.value
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _NotificationsOffBanner(onTapRecheck: controller.recheckNotificationPermission),
                ),
        ),
        const SizedBox(height: 6),

        // Identity
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFF2A2210), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.headingSm.copyWith(color: AppColors.yellow, fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.name.text,
                    style: AppTextStyles.fieldValue.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 13, color: Color(0xFF7FBF7F)),
                      const SizedBox(width: 5),
                      Text(
                        'Verified Resident',
                        style: AppTextStyles.label.copyWith(color: const Color(0xFF7FBF7F), letterSpacing: 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        VehicleFormField(label: 'Full Name', controller: controller.name),
        const SizedBox(height: 18),

        // Phone — read-only, verified
        Text('PHONE NUMBER', style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0.4)),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                phone.isEmpty ? 'Not available' : phone,
                style: AppTextStyles.fieldValue.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF182018),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A3D2A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 11, color: Color(0xFF7FBF7F)),
                    const SizedBox(width: 5),
                    Text('Verified', style: AppTextStyles.overline.copyWith(color: const Color(0xFF7FBF7F), letterSpacing: 0.2, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Can't be changed without re-verification",
          style: AppTextStyles.caption.copyWith(color: AppColors.faint, fontSize: 11.5),
        ),
        const SizedBox(height: 18),

        if (cnic.isNotEmpty) ...[
          // CNIC — read-only, used for identity verification only (FR-01.1).
          Text('CNIC', style: AppTextStyles.label.copyWith(color: AppColors.muted, letterSpacing: 0.4)),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              cnic,
              style: AppTextStyles.fieldValue.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Used for identity verification only',
            style: AppTextStyles.caption.copyWith(color: AppColors.faint, fontSize: 11.5),
          ),
          const SizedBox(height: 18),
        ],

        Obx(
          () => AuthPrimaryButton(
            label: 'Save Changes',
            isLoading: controller.isSaving.value,
            onPressed: controller.save,
            height: 52,
          ),
        ),

        const SizedBox(height: 28),
        const Divider(color: Color(0xFF262622), height: 1),
        const SizedBox(height: 28),

        GestureDetector(
          onTap: controller.logout,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF33332E), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 17, color: AppColors.ink),
                const SizedBox(width: 8),
                Text('Log Out', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.ink, fontSize: 15)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: controller.deleteAccount,
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
                  'Delete Account',
                  style: AppTextStyles.buttonLabel.copyWith(color: const Color(0xFFE5675E), fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
