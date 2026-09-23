import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/vehicle_service.dart';
import '../../../app/utils/vehicle_color.dart';
import '../models/vehicle_model.dart';
import 'inbox_controller.dart';

class HomeTabController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _vehicleService = Get.find<VehicleService>();

  final residentFirstName = ''.obs;
  final vehicles = <VehicleModel>[].obs;

  /// True until the first vehicles snapshot arrives. Without it the view
  /// renders the "no vehicles yet" empty state for the split second before
  /// Firestore answers, which reads as "your vehicles are gone".
  final isLoading = true.obs;

  /// Set if the vehicles stream errors, so the view can offer a retry
  /// instead of looking permanently empty.
  final hasError = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _vehiclesSub;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final uid = _authService.currentUid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    hasError.value = false;
    isLoading.value = true;

    _authService.fetchResidentProfile(uid).then((profile) {
      final name = (profile?['name'] as String?)?.trim();
      residentFirstName.value = (name == null || name.isEmpty) ? 'there' : name.split(' ').first;
    });

    _vehiclesSub?.cancel();
    _vehiclesSub = _vehicleService.watchVehicles(uid).listen(
      (docs) {
        vehicles.assignAll(docs.map(_toVehicle));
        isLoading.value = false;
        hasError.value = false;
      },
      onError: (_) {
        isLoading.value = false;
        hasError.value = true;
      },
    );
  }

  /// Retry after an error, and the pull-to-refresh action. The vehicle
  /// list is a live Firestore listener, so this re-subscribes rather than
  /// pretending to re-fetch.
  Future<void> reload() async {
    _load();
  }

  /// Time-of-day greeting. This was previously the hard-coded string
  /// "Good afternoon", which was wrong for most of the day.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Unread state is owned by the Inbox tab, which already listens to the
  /// conversations collection — reading it here avoids a second listener.
  ///
  /// Resolved on demand and treated as optional: Home must still render
  /// when it is mounted without the Inbox (it is a standalone widget in
  /// tests, and binding order should not be able to break this screen).
  InboxController? get _inbox =>
      Get.isRegistered<InboxController>() ? Get.find<InboxController>() : null;

  /// Whether unread state is available at all. The view checks this before
  /// wrapping anything in `Obx`: without the Inbox there is no observable
  /// to read, and an `Obx` that reads none throws.
  bool get hasUnreadSource => _inbox != null;

  /// Total unread messages across every conversation — the number on the
  /// Messages badge in the header.
  int get unreadCount => _inbox?.unreadMessageCount ?? 0;

  /// Whether a specific vehicle has an unread conversation, for its card's
  /// dot. [VehicleModel.hasUnread] existed but was never populated, so that
  /// indicator could not previously appear at all.
  bool hasUnreadFor(String vehicleId) => _inbox?.unreadVehicleIds.contains(vehicleId) ?? false;

  VehicleModel _toVehicle(Map<String, dynamic> data) {
    final colorName = data['colorName'] as String? ?? '';
    return VehicleModel(
      id: data['id'] as String,
      nickname: data['nickname'] as String? ?? '',
      makeModel: '${data['make'] ?? ''} ${data['model'] ?? ''}'.trim(),
      plateNumber: data['plateNumber'] as String? ?? '',
      color: vehicleColorForName(colorName),
      colorName: colorName,
      dateOfRegistration: data['dateOfRegistration'] as String? ?? '',
      engineNumber: data['engineNumber'] as String? ?? '',
      chassisNumber: data['chassisNumber'] as String? ?? '',
      address: data['address'] as String? ?? '',
      photoPaths: (data['photoUrls'] as List?)?.cast<String>() ?? const [],
    );
  }

  void addVehicle() {
    Get.toNamed(AppRoutes.addVehicleScan);
  }

  @override
  void onClose() {
    _vehiclesSub?.cancel();
    super.onClose();
  }
}
