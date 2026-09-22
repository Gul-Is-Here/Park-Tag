import 'dart:async';

import 'package:get/get.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/conversation_service.dart';
import '../../../app/utils/vehicle_color.dart';
import '../models/message_thread_model.dart';

class InboxController extends GetxController {
  final _conversationService = Get.find<ConversationService>();
  final _authService = Get.find<AuthService>();

  final threads = <MessageThreadModel>[].obs;

  /// FR-09: conversations this resident started as an anonymous scanner
  /// (messaging someone else's car) before/without owning the vehicle,
  /// once linked via [ConversationService.linkScannerIdentity].
  final sentThreads = <MessageThreadModel>[].obs;

  StreamSubscription<List<ConversationSummary>>? _sub;
  StreamSubscription<List<ConversationSummary>>? _sentSub;

  @override
  void onInit() {
    super.onInit();
    final uid = _authService.currentUid;
    if (uid == null) return;
    _sub = _conversationService.watchOwnerConversations(uid).listen((summaries) {
      threads.assignAll(summaries.map(_toOwnerThread));
    });
    _sentSub = _conversationService.watchScannerConversations(uid).listen((summaries) {
      sentThreads.assignAll(summaries.map(_toScannerThread));
    });
  }

  int get unreadThreadCount => threads.where((t) => t.unreadCount > 0).length;

  void markAllRead() {
    for (final thread in threads.where((t) => t.unreadCount > 0)) {
      _conversationService.markReadByOwner(thread.conversationId);
    }
  }

  MessageThreadModel _toOwnerThread(ConversationSummary summary) => MessageThreadModel(
    conversationId: summary.conversationId,
    scannerName: summary.scannerName,
    plateNumber: summary.plateNumber,
    vehicleColor: vehicleColorForName(summary.colorName),
    lastMessagePreview: summary.lastMessagePreview,
    timeLabel: _formatTime(summary.lastMessageAt),
    unreadCount: summary.unreadForOwner ? 1 : 0,
    isResolved: summary.resolved,
    viewerRole: ThreadViewerRole.owner,
  );

  /// The "Sent" section — this resident is the *scanner* here, so the
  /// unread badge is meaningless (that's the owner's flag) and the
  /// counterpart shown is the vehicle's owner, not [summary.scannerName]
  /// (which would just be this resident's own name).
  MessageThreadModel _toScannerThread(ConversationSummary summary) => MessageThreadModel(
    conversationId: summary.conversationId,
    scannerName: summary.scannerName,
    ownerName: summary.ownerName,
    plateNumber: summary.plateNumber,
    vehicleColor: vehicleColorForName(summary.colorName),
    lastMessagePreview: summary.lastMessagePreview,
    timeLabel: _formatTime(summary.lastMessageAt),
    isResolved: summary.resolved,
    viewerRole: ThreadViewerRole.scanner,
  );

  static String _formatTime(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void onClose() {
    _sub?.cancel();
    _sentSub?.cancel();
    super.onClose();
  }
}
