import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dashboard/controllers/inbox_controller.dart';
import '../../dashboard/models/chat_message_model.dart';
import '../../dashboard/models/message_thread_model.dart';

class ChatThreadController extends GetxController {
  ChatThreadController({required MessageThreadModel thread}) : _originalThread = thread;

  /// The thread instance as looked up in [InboxController.threads] — kept
  /// so edits can be written back by reference/index.
  MessageThreadModel _originalThread;

  final textController = TextEditingController();
  late final messages = <ChatMessageModel>[..._originalThread.messages].obs;
  late final isResolved = _originalThread.isResolved.obs;

  String get scannerName => _originalThread.scannerName;
  String get plateNumber => _originalThread.plateNumber;
  Color get vehicleColor => _originalThread.vehicleColor;

  @override
  void onReady() {
    super.onReady();
    // Opening a thread reads it — clear its unread badge in the Inbox.
    // Deferred to onReady (post first frame) so this doesn't mutate
    // InboxController's RxList while GetX is still mid-build for the
    // push transition.
    if (_originalThread.unreadCount > 0) _writeBack(unreadCount: 0);
  }

  void sendText() {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    messages.add(ChatMessageModel(sender: ChatSender.owner, kind: ChatMessageKind.text, timeLabel: 'Now', text: text));
    textController.clear();
    _writeBack(lastMessagePreview: text, timeLabel: 'Now');
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
    _writeBack(isResolved: true);
  }

  void markNotResolved() {
    isResolved.value = false;
    _writeBack(isResolved: false);
  }

  void _writeBack({int? unreadCount, bool? isResolved, String? lastMessagePreview, String? timeLabel}) {
    if (!Get.isRegistered<InboxController>()) return;
    final inbox = Get.find<InboxController>();
    final updated = _originalThread.copyWith(
      unreadCount: unreadCount,
      isResolved: isResolved,
      messages: List.of(messages),
      lastMessagePreview: lastMessagePreview,
      timeLabel: timeLabel,
    );
    inbox.updateThread(_originalThread, updated);
    _originalThread = updated;
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
