import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/services/conversation_service.dart';
import '../../dashboard/models/chat_message_model.dart';
import '../../dashboard/models/message_thread_model.dart';

class ChatThreadController extends GetxController {
  ChatThreadController({required this.thread});

  final MessageThreadModel thread;
  final _conversationService = Get.find<ConversationService>();

  final textController = TextEditingController();
  final messages = <ChatMessageModel>[].obs;
  late final isResolved = thread.isResolved.obs;

  StreamSubscription<List<ConversationMessage>>? _messagesSub;
  StreamSubscription<ConversationSummary?>? _metaSub;

  String get scannerName => thread.scannerName;
  String get plateNumber => thread.plateNumber;
  Color get vehicleColor => thread.vehicleColor;

  /// Who this screen's header should show as "who you're talking to" —
  /// the scanner, from the owner's side; the owner, from the scanner's
  /// side (never the viewer's own name).
  String get counterpartName {
    if (thread.viewerRole == ThreadViewerRole.owner) return thread.scannerName;
    return thread.ownerName.isEmpty ? 'Car owner' : thread.ownerName;
  }

  @override
  void onInit() {
    super.onInit();
    _messagesSub = _conversationService.watchMessages(thread.conversationId).listen((msgs) {
      messages.assignAll(
        msgs.map(
          (m) => ChatMessageModel(
            sender: m.sender == MessageSender.owner ? ChatSender.owner : ChatSender.scanner,
            kind: ChatMessageKind.text,
            timeLabel: _formatTime(m.createdAt),
            text: m.text,
          ),
        ),
      );
    });
    _metaSub = _conversationService.watchConversation(thread.conversationId).listen((summary) {
      if (summary != null) isResolved.value = summary.resolved;
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Opening a thread reads it — clear its unread badge in the Inbox.
    // `unreadForOwner` is specifically the owner's flag, so only clear it
    // when this viewer actually is the owner.
    if (thread.viewerRole == ThreadViewerRole.owner && thread.unreadCount > 0) {
      _conversationService.markReadByOwner(thread.conversationId);
    }
  }

  void sendText() {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    textController.clear();
    if (thread.viewerRole == ThreadViewerRole.owner) {
      _conversationService.sendOwnerReply(conversationId: thread.conversationId, text: text);
    } else {
      _conversationService.sendAuthenticatedScannerReply(conversationId: thread.conversationId, text: text);
    }
  }

  // TODO(FR-05.2): wire to the `record`/`just_audio` packages for real
  // voice-note capture and playback.
  void recordVoiceNote() {
    Get.snackbar('Coming soon', 'Voice notes are not available yet.');
  }

  // TODO(FR-05.3): wire to image_picker + Firebase Storage upload.
  void attachMedia() {
    Get.snackbar('Coming soon', 'Sending photos and videos is not available yet.');
  }

  // TODO(FR-05.4): wire to agora_rtc_engine for in-app audio/video calls.
  void startCall({required bool video}) {
    Get.snackbar('Coming soon', '${video ? 'Video' : 'Audio'} calls are not available yet.');
  }

  void markResolved() {
    isResolved.value = true;
    _conversationService.setResolved(conversationId: thread.conversationId, resolved: true);
  }

  void markNotResolved() {
    isResolved.value = false;
    _conversationService.setResolved(conversationId: thread.conversationId, resolved: false);
  }

  static String _formatTime(DateTime? at) {
    if (at == null) return 'Now';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final period = at.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    _metaSub?.cancel();
    textController.dispose();
    super.onClose();
  }
}
