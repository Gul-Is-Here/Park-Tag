import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../firebase_options.dart';
import '../../modules/dashboard/models/message_thread_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/vehicle_color.dart';
import 'auth_service.dart';

/// Runs in a separate isolate for background/terminated-app messages, so it
/// must be a top-level (or static) function, and re-initializes Firebase
/// itself since nothing else in this isolate has done so.
///
/// FCM already renders the notification tray entry from the payload's
/// `notification` block without any help from here — this handler exists so
/// a background data-only message wouldn't be silently dropped if one is
/// ever sent, and so the framework doesn't warn about a missing handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Wraps Firebase Cloud Messaging: registers this device for chat push
/// notifications (FR-05/FR-06 — a resident gets notified when someone
/// messages them about a scanned vehicle) and routes a notification tap to
/// the right Chat thread.
abstract class PushNotificationService {
  Future<void> init();

  /// Fetches this device's current FCM token and saves it to the signed-in
  /// resident's profile. Call after sign-in/sign-up, and again on app start
  /// for an already-signed-in resident — a token can be issued before the
  /// resident is signed in, or can rotate between sessions.
  Future<void> syncToken();

  /// Call before signing out so this device stops receiving another
  /// resident's notifications if someone else signs in on it.
  Future<void> unregisterToken();

  /// A chat thread to open because the resident tapped a notification while
  /// the app was fully closed — captured before `GetMaterialApp` existed to
  /// navigate anywhere, so `SplashController` picks it up once routing is
  /// ready and consumes it (returns null every time after the first read).
  MessageThreadModel? consumePendingChatThread();
}

class FirebasePushNotificationService implements PushNotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _authService = Get.find<AuthService>();

  String? _currentToken;
  MessageThreadModel? _pendingThread;

  @override
  Future<void> init() async {
    // Web push needs its own VAPID key + service worker setup that hasn't
    // been done for this project, and the public Scan Contact Page is
    // anonymous anyway (nothing to notify) — mobile only, for now.
    if (kIsWeb) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      final uid = _authService.currentUid;
      if (uid != null) _authService.saveFcmToken(uid: uid, token: token);
    });

    // App open (foreground): surface it ourselves since the OS won't.
    FirebaseMessaging.onMessage.listen(_showForegroundBanner);

    // App backgrounded, resident tapped the tray notification: GetMaterialApp
    // is already alive, so navigate right away.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    // App was fully closed and opened via the tray notification: routing
    // isn't ready yet, so stash it for SplashController to pick up.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingThread = _threadFromMessage(initialMessage);
    }
  }

  @override
  Future<void> syncToken() async {
    if (kIsWeb) return;
    final uid = _authService.currentUid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    _currentToken = token;
    await _authService.saveFcmToken(uid: uid, token: token);
  }

  @override
  Future<void> unregisterToken() async {
    if (kIsWeb) return;
    final uid = _authService.currentUid;
    final token = _currentToken ?? await _messaging.getToken();
    if (uid == null || token == null) return;
    await _authService.removeFcmToken(uid: uid, token: token);
  }

  @override
  MessageThreadModel? consumePendingChatThread() {
    final thread = _pendingThread;
    _pendingThread = null;
    return thread;
  }

  void _showForegroundBanner(RemoteMessage message) {
    final thread = _threadFromMessage(message);
    if (thread == null) return;
    Get.snackbar(
      message.notification?.title ?? 'New message',
      message.notification?.body ?? thread.lastMessagePreview,
      backgroundColor: AppColors.surface,
      colorText: AppColors.ink,
      onTap: (_) => Get.toNamed(AppRoutes.chatThread, arguments: thread),
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final thread = _threadFromMessage(message);
    if (thread == null) return;
    Get.toNamed(AppRoutes.chatThread, arguments: thread);
  }

  /// The Cloud Function that sends these (`functions/index.js`) always
  /// includes `conversationId` in the data payload — anything else missing
  /// just means a slightly less complete header on the Chat screen, since
  /// its real data streams in live from Firestore once opened.
  MessageThreadModel? _threadFromMessage(RemoteMessage message) {
    final conversationId = message.data['conversationId'] as String?;
    if (conversationId == null || conversationId.isEmpty) return null;

    final colorName = message.data['colorName'] as String? ?? '';
    return MessageThreadModel(
      conversationId: conversationId,
      scannerName: message.data['scannerName'] as String? ?? 'Anonymous',
      plateNumber: message.data['plateNumber'] as String? ?? '',
      vehicleColor: vehicleColorForName(colorName),
      lastMessagePreview: message.notification?.body ?? '',
      timeLabel: 'Just now',
      unreadCount: 1,
    );
  }
}
