import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../modules/dashboard/models/message_thread_model.dart';
import '../../modules/dashboard/models/vehicle_model.dart';
import '../routes/app_routes.dart';
import '../utils/vehicle_color.dart';
import 'auth_service.dart';
import 'conversation_service.dart';
import '../widgets/app_snackbar.dart';

/// A vehicle's QR sticker/scan link carries a `vehicleId` that arrived via
/// a deep link before the app could resolve it — either because the app
/// was cold-starting (routing not up yet) or the resident wasn't signed
/// in. Splash/Otp resume it once auth is settled (see the flow docs on
/// [DeepLinkService]).
class PendingVehicleScan {
  const PendingVehicleScan({required this.vehicleId, this.anonymousScannerId});

  final String vehicleId;

  /// Present only if this link also carried an anonymous web `scannerId`
  /// (i.e. it's the same link the public Scan Contact Page shares) — used
  /// to backfill that browser's past conversations via
  /// [ConversationService.linkScannerIdentity] once this resident signs in.
  /// Unrelated to, and never required for, resolving the actual chat.
  final String? anonymousScannerId;
}

/// The public Scan Contact Page's URL is a plain `https://{host}/scan/{id}`
/// link (see [VehicleModel.qrScanUrl]). It is registered as an Android App
/// Link / iOS Universal Link, so the *same* QR code/link works everywhere
/// with no separate app-vs-web codes:
///
///   - **App installed, signed in, link opened while running (warm)**: the
///     OS hands it straight to this service, which resolves it against the
///     backend ([ConversationService.resolveVehicleAndOpenChat] — never a
///     client-trusted owner identity) and opens the chat immediately.
///   - **App installed, not signed in (or cold start)**: the `vehicleId` is
///     stashed as a [PendingVehicleScan] for Splash/Otp to resume once
///     authentication finishes — never dropped, never "just send them to
///     the home screen".
///   - **App not installed**: the OS just opens it as a normal web page —
///     nothing extra needed, that IS the Scan Contact Page, with its own
///     "Get the app" CTA.
///   - **App installed *after* the fact**: re-opening/re-scanning the same
///     link now routes into the app instead of the browser.
abstract class DeepLinkService {
  /// Starts listening for both a cold-start link (app opened directly from
  /// it) and any link opened while the app is already running.
  Future<void> init();

  /// The most recent unconsumed pending scan, or null. Call once
  /// authentication has just succeeded (or was already true at boot) —
  /// same pattern as [PushNotificationService.consumePendingChatThread].
  PendingVehicleScan? consumePendingVehicleScan();

  /// Resolves [scan] against the backend and navigates to the resulting
  /// chat, or shows an error and does nothing if the vehicle/QR is
  /// invalid. Called both from here (warm, already-signed-in case) and
  /// from Splash/Otp after they consume a pending scan post-authentication.
  Future<void> resolveAndOpenChat(PendingVehicleScan scan);

  /// The public Scan Contact Page URL for [vehicleId] — an anonymous
  /// scanner's [scannerId] rides along only so that, if the app gets
  /// installed and opened later, [PendingVehicleScan.anonymousScannerId]
  /// can backfill that browser's history; it plays no part in the
  /// authenticated in-app resolution path.
  String scanLinkFor({required String vehicleId, required String scannerId});

  Future<void> dispose();
}

class AppLinksDeepLinkService implements DeepLinkService {
  final _appLinks = AppLinks();
  PendingVehicleScan? _pending;
  StreamSubscription<Uri>? _sub;

  /// Guards against the OS redelivering the same intent/link more than
  /// once (observed on some Android versions on activity re-creation).
  ///
  /// Deliberately time-boxed rather than permanent: the *same* sticker is
  /// legitimately scanned again later in a session (walk back to the same
  /// blocked car, reopen the same link from a chat), and that must still
  /// open the chat. Only a redelivery of the identical link within a
  /// couple of seconds is treated as a duplicate.
  String? _lastHandledUri;
  DateTime? _lastHandledAt;
  static const _redeliveryWindow = Duration(seconds: 2);

  @override
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri, isColdStart: true);

      _sub = _appLinks.uriLinkStream.listen((uri) => _handleUri(uri, isColdStart: false));
    } catch (e) {
      debugPrint('DeepLinkService init failed: $e');
    }
  }

  void _handleUri(Uri uri, {required bool isColdStart}) {
    final uriString = uri.toString();
    final lastAt = _lastHandledAt;
    if (_lastHandledUri == uriString &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < _redeliveryWindow) {
      return;
    }
    _lastHandledUri = uriString;
    _lastHandledAt = DateTime.now();

    final segments = uri.pathSegments;
    final scanIndex = segments.indexOf('scan');
    if (scanIndex == -1 || scanIndex + 1 >= segments.length) return;

    final vehicleId = segments[scanIndex + 1];
    if (vehicleId.isEmpty) return;
    final scannerId = uri.queryParameters['scannerId'];

    // Cold start: routing isn't up yet, can't navigate at all — Splash
    // reads the pending scan once it decides where to send the resident.
    if (isColdStart) {
      _pending = PendingVehicleScan(vehicleId: vehicleId, anonymousScannerId: scannerId);
      return;
    }

    // Warm/foreground: resolve immediately if already signed in; otherwise
    // stash the same way, and Login/Otp will resume it after auth instead
    // of just landing on the home screen.
    final authService = Get.find<AuthService>();
    if (authService.isSignedIn) {
      unawaited(
        resolveAndOpenChat(PendingVehicleScan(vehicleId: vehicleId, anonymousScannerId: scannerId)),
      );
    } else {
      _pending = PendingVehicleScan(vehicleId: vehicleId, anonymousScannerId: scannerId);
    }
  }

  @override
  Future<void> resolveAndOpenChat(PendingVehicleScan scan) async {
    final conversationService = Get.find<ConversationService>();
    final authService = Get.find<AuthService>();

    final uid = authService.currentUid;
    final anonymousScannerId = scan.anonymousScannerId;
    if (anonymousScannerId != null && anonymousScannerId.isNotEmpty && uid != null) {
      // Awaited, not fire-and-forget: this claims every conversation this
      // browser started anonymously — including ones for OTHER vehicles —
      // so they are already in the resident's "Sent" list by the time the
      // Inbox renders. Failing to link must not block opening the chat,
      // which the backend adopts on its own below.
      try {
        await conversationService.linkScannerIdentity(scannerId: anonymousScannerId, uid: uid);
      } catch (_) {
        // Non-fatal — the conversation for THIS vehicle is still adopted
        // by resolveVehicleAndOpenChat.
      }
    }

    try {
      final result = await conversationService.resolveVehicleAndOpenChat(
        vehicleId: scan.vehicleId,
        // Lets the backend reopen the web conversation rather than
        // starting an empty parallel one.
        anonymousScannerId: anonymousScannerId,
      );
      Get.toNamed(
        AppRoutes.chatThread,
        arguments: MessageThreadModel(
          conversationId: result.conversationId,
          scannerName: '',
          ownerName: result.ownerName,
          plateNumber: result.plateNumber,
          vehicleColor: vehicleColorForName(result.colorName),
          lastMessagePreview: '',
          timeLabel: 'Just now',
          isResolved: result.resolved,
          viewerRole: ThreadViewerRole.scanner,
        ),
      );
    } on ResolveVehicleException catch (e) {
      AppSnackbar.show('Could not open chat', e.message);
    } catch (_) {
      AppSnackbar.show('Could not open chat', 'Please try scanning again.');
    }
  }

  @override
  PendingVehicleScan? consumePendingVehicleScan() {
    final payload = _pending;
    _pending = null;
    return payload;
  }

  @override
  String scanLinkFor({required String vehicleId, required String scannerId}) {
    return '$scanBaseUrl/scan/$vehicleId?scannerId=$scannerId';
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
