import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../auth/widgets/auth_brand_mark.dart';
import '../../auth/widgets/auth_primary_button.dart';
import '../controllers/otp_controller.dart';
import '../widgets/otp_digit_box.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

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
              Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AuthBrandMark(),
              const SizedBox(height: 56),
              Text(
                'Verify your number',
                style: AppTextStyles.headingLg.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
                  children: [
                    const TextSpan(text: "Enter the 6-digit code we sent to "),
                    TextSpan(
                      text: '+92 ${controller.phone}',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  OtpController.codeLength,
                  (i) => OtpDigitBox(
                    controller: controller.digitControllers[i],
                    focusNode: controller.focusNodes[i],
                    onChanged: (value) => controller.onDigitChanged(i, value),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => AuthPrimaryButton(
                  label: 'Verify',
                  onPressed: controller.isVerifying.value ? null : controller.verify,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Obx(
                  () => controller.canResend
                      ? GestureDetector(
                          onTap: controller.resend,
                          child: Text(
                            'Resend code',
                            style: AppTextStyles.linkTextEmphasis.copyWith(
                              color: AppColors.yellow,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in 0:${controller.secondsRemaining.value.toString().padLeft(2, '0')}',
                          style: AppTextStyles.linkText.copyWith(color: AppColors.muted),
                        ),
                ),
              ),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: Get.back,
                  child: Text(
                    'Wrong number? Go back',
                    style: AppTextStyles.caption.copyWith(color: AppColors.faint),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
