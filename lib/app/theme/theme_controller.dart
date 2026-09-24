import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  system;

  String get _prefsValue => name;

  static AppThemeMode fromPrefs(String? value) =>
      AppThemeMode.values.firstWhereOrNull((m) => m.name == value) ?? AppThemeMode.dark;
}

/// Drives light/dark mode for [AppColors]. Dark is the app's original,
/// default look; [AppThemeMode.system] follows the OS setting and updates
/// live if the resident changes it while the app is open.
///
/// [AppColors]'s fields aren't `const` colors any more (they read
/// [isLight]), so setting [mode] and calling [Get.forceAppUpdate] is
/// enough to repaint every screen with the right palette — no per-widget
/// Obx wiring needed.
class ThemeController extends GetxController with WidgetsBindingObserver {
  /// Registered permanently from `main()`. Falls back to a fresh, dark
  /// instance where that never ran — e.g. widget tests that pump a view
  /// directly without the app's full startup.
  static ThemeController get to =>
      Get.isRegistered<ThemeController>() ? Get.find<ThemeController>() : ThemeController();

  static const _prefsKey = 'themeMode';

  final mode = AppThemeMode.dark.obs;

  /// The effective light/dark flag [AppColors] reads — resolves
  /// [AppThemeMode.system] against the current platform brightness.
  bool get isLight {
    if (mode.value == AppThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
    }
    return mode.value == AppThemeMode.light;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// The OS theme changed while on [AppThemeMode.system] — repaint to
  /// match, same as an explicit [setMode] call.
  @override
  void didChangePlatformBrightness() {
    if (mode.value == AppThemeMode.system) Get.forceAppUpdate();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = AppThemeMode.fromPrefs(prefs.getString(_prefsKey));
  }

  Future<void> setMode(AppThemeMode next) async {
    mode.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next._prefsValue);
    Get.forceAppUpdate();
  }
}
