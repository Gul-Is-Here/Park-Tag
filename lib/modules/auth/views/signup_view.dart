import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/utils/auth_input.dart';
import '../controllers/signup_controller.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';

class SignUpView extends GetView<SignUpController> {
  const SignUpView({super.key});

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
              const AuthBrandMark(),
              const SizedBox(height: 40),
              Text(
                'Create your account',
                style: AppTextStyles.headingLg.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Just enough to tag your car and reach you. Verified with a '
                'one-time code, no password.',
                style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              AuthTextField(
                label: 'Full name',
                hint: 'e.g. Ayesha Khan',
                controller: controller.fullName,
                textCapitalization: TextCapitalization.words,
                inputFormatters: nameInputFormatters,
              ),
              const SizedBox(height: 20),
              AuthPhoneField(controller: controller.phone),
              const SizedBox(height: 20),
              AuthTextField(
                label: 'CNIC',
                helper: '(required, for verification only)',
                hint: '42101-1234567-1',
                controller: controller.cnic,
                keyboardType: TextInputType.number,
                inputFormatters: cnicInputFormatters,
              ),
              const SizedBox(height: 32),
              Obx(
                () => AuthPrimaryButton(
                  label: 'Send OTP',
                  isLoading: controller.isSubmitting.value,
                  onPressed: controller.sendOtp,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Get.offNamed(AppRoutes.login),
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.linkText.copyWith(color: AppColors.muted),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log in',
                          style: AppTextStyles.linkTextEmphasis.copyWith(
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
