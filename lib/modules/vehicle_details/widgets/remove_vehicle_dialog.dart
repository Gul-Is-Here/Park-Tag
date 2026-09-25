import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/utils/app_logger.dart';

const _destructive = Color(0xFFE5675E);

/// Confirms removing a vehicle, then runs [onConfirm] (the actual backend
/// delete) itself — stays open with a spinner on "Remove" while that's in
/// flight, and only pops (with `true`) once it succeeds, so the caller
/// never has to juggle a separate loading state for the dialog's own
/// button. On failure it shows the error inline and lets the resident
/// retry or cancel, rather than popping into a broken state.
class RemoveVehicleDialog extends StatefulWidget {
  const RemoveVehicleDialog({super.key, required this.nickname, required this.onConfirm});

  final String nickname;
  final Future<void> Function() onConfirm;

  @override
  State<RemoveVehicleDialog> createState() => _RemoveVehicleDialogState();
}

class _RemoveVehicleDialogState extends State<RemoveVehicleDialog> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Get.back(result: true);
    } catch (e, stack) {
      AppLogger.error('RemoveVehicle', e, stack);
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = "Couldn't remove the vehicle. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: Text('Remove vehicle?', style: AppTextStyles.headingSm.copyWith(color: AppColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will remove "${widget.nickname}" and its QR sticker. This can\'t be undone.',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.muted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.subtitle.copyWith(color: _destructive, fontSize: 12.5),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonLabel.copyWith(
                color: _isDeleting ? AppColors.faint : AppColors.muted,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _isDeleting ? null : _confirm,
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _destructive),
                  )
                : Text(
                    'Remove',
                    style: AppTextStyles.buttonLabel.copyWith(color: _destructive, fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }
}
