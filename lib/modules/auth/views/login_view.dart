import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_primary_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandMark(),
              const SizedBox(height: 56),
              Text(
                'Welcome back',
                style: AppTextStyles.headingLg.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                "Log in with your phone number. We'll text you a one-time code.",
                style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 40),
              AuthPhoneField(controller: controller.phone, height: 56),
              const SizedBox(height: 32),
              Obx(
                () => AuthPrimaryButton(
                  label: 'Send OTP',
                  onPressed: controller.isSubmitting.value ? null : controller.sendOtp,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Get.offNamed(AppRoutes.signUp),
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.linkText.copyWith(color: AppColors.muted),
                      children: [
                        const TextSpan(text: 'New to ParkTag? '),
                        TextSpan(
                          text: 'Create an account',
                          style: AppTextStyles.linkTextEmphasis.copyWith(
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "By continuing you agree to ParkTag's Terms & Privacy Policy.\n"
                'We never show your number to anyone who scans your car.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
