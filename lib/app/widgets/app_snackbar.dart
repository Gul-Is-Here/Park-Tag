import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The single place every snackbar in the app is styled.
///
/// GetX has no global snackbar theme: `Get.snackbar` takes its colours as
/// per-call arguments and defaults to a transparent background, and
/// `SnackBarThemeData` does not apply to it (that only themes Flutter's
/// own `ScaffoldMessenger` snackbars, which this app never uses). So the
/// centralisation is this helper — every call site goes through it, and
/// the brand styling is defined once, here.
///
/// Call [AppSnackbar.show] instead of `Get.snackbar` for anything new.
abstract final class AppSnackbar {
  /// Brand yellow background with black text, per the app's snackbar spec.
  static void show(
    String title,
    String message, {
    Duration? duration,
    OnTap? onTap,
    Widget? icon,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    final isTop = position == SnackPosition.TOP;
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.yellow,
      colorText: Colors.black,
      // Black on yellow, so the icon matches the text rather than
      // inheriting a light tint that would wash out.
      icon: icon == null
          ? null
          : IconTheme(data: const IconThemeData(color: Colors.black), child: icon),
      titleText: Text(
        title,
        style: AppTextStyles.headingSm.copyWith(
          color: Colors.black,
          fontSize: 15,
          letterSpacing: 0,
        ),
      ),
      messageText: Text(
        message,
        style: AppTextStyles.subtitle.copyWith(
          color: Colors.black,
          fontSize: 13.5,
          height: 1.35,
        ),
      ),
      // Black-on-yellow needs no scrim, and the default shadow muddies it.
      barBlur: 0,
      overlayBlur: 0,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      // A top snackbar needs headroom below the status bar; a bottom one
      // needs it above the gesture nav / composer it might otherwise sit
      // under. GetX's own margin is a fixed EdgeInsets, so this is chosen
      // per position rather than left at one default for both.
      margin: EdgeInsets.fromLTRB(16, isTop ? 8 : 0, 16, isTop ? 0 : 16),
      borderRadius: 14,
      snackPosition: position,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
    );
  }
}
