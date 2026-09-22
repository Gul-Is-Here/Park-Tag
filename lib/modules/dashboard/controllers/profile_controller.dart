import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/push_notification_service.dart';
import '../widgets/delete_account_dialog.dart';

class ProfileController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _pushService = Get.find<PushNotificationService>();

  late final name = TextEditingController();

  final phoneNumber = ''.obs;
  final cnic = ''.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;

  @override
  void onReady() {
    super.onReady();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    phoneNumber.value = _authService.currentPhone ?? '';

    final uid = _authService.currentUid;
    if (uid != null) {
      final data = await _authService.fetchResidentProfile(uid);
      if (data != null) {
        name.text = (data['name'] as String?) ?? '';
        cnic.value = (data['cnic'] as String?) ?? '';
      }
    }

    isLoading.value = false;
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      Get.snackbar('Name required', 'Please enter your full name.');
      return;
    }
    final uid = _authService.currentUid;
    if (uid == null) return;

    isSaving.value = true;
    await _authService.updateResidentProfile(uid: uid, name: name.text.trim());
    isSaving.value = false;
    Get.snackbar('Profile updated', 'Your details have been saved.');
  }

  Future<void> logout() async {
    await _pushService.unregisterToken();
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
    Get.snackbar('Logged out', "You've been signed out of ParkTag.");
  }

  Future<void> deleteAccount() async {
    final confirmed = await Get.dialog<bool>(const DeleteAccountDialog());
    if (confirmed != true) return;

    await _pushService.unregisterToken();
    final uid = _authService.currentUid;
    if (uid != null) {
      await _authService.deleteResidentAccount(uid);
    }
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
    Get.snackbar('Account deleted', 'All your data has been removed.');
  }

  @override
  void onClose() {
    name.dispose();
    super.onClose();
  }
}
