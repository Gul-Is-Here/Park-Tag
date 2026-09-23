import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// The app's one primary "submit/save" button — Login, Sign Up, OTP verify,
/// Add Vehicle save, Edit Vehicle save and Profile save all render through
/// this single widget, so its loading treatment applies everywhere at once
/// rather than needing to be re-implemented per screen.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;

  /// While true, the label is replaced with a spinner and the button stays
  /// disabled — regardless of [onPressed] — so a second tap during a save
  /// can't fire a second request.
  final bool isLoading;

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          disabledBackgroundColor: AppColors.yellow.withValues(alpha: isLoading ? 0.85 : 0.4),
          foregroundColor: AppColors.background,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  // Dark on the yellow fill, matching the label's own colour.
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                ),
              )
            : Text(label, style: AppTextStyles.buttonLabel),
      ),
    );
  }
}
