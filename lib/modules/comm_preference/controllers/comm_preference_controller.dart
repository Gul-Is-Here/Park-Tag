import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/push_notification_service.dart';

/// FR-09: shown once, right after registration, so a resident picks how
/// they want to hear about messages on their car — in-app push, or the web
/// chat link (e.g. if they don't want to keep the app installed).
class CommPreferenceController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _pushService = Get.find<PushNotificationService>();

  final isSaving = false.obs;

  Future<void> choose(String preference) async {
    final uid = _authService.currentUid;
    if (uid == null) {
      Get.offAllNamed(AppRoutes.dashboard);
      return;
    }
    isSaving.value = true;
    await _authService.saveCommunicationPreference(uid: uid, preference: preference);
    if (preference == 'app') {
      await _pushService.syncToken();
    }
    isSaving.value = false;
    Get.offAllNamed(AppRoutes.dashboard);
  }
}
