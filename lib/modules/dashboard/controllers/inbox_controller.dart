import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat_message_model.dart';
import '../models/message_thread_model.dart';

class InboxController extends GetxController {
  // TODO(FR-05/FR-06): replace with real Firestore-backed threads once
  // scan-triggered messaging is implemented.
  final threads = <MessageThreadModel>[
    const MessageThreadModel(
      scannerName: 'Anonymous',
      plateNumber: 'LEA-2231',
      vehicleColor: Color(0xFFF5F1E8),
      lastMessagePreview: 'Please move your car',
      timeLabel: '2m ago',
      unreadCount: 1,
      messages: [
        ChatMessageModel(sender: ChatSender.scanner, kind: ChatMessageKind.text, timeLabel: '2:10 PM', text: 'Please move your car'),
      ],
    ),
    const MessageThreadModel(
      scannerName: 'Bilal Ahmed',
      plateNumber: 'LEB-4470',
      vehicleColor: Color(0xFF2B2B2B),
      lastMessagePreview: 'Voice note · 0:14',
      timeLabel: '41m ago',
      unreadCount: 2,
      messages: [
        ChatMessageModel(sender: ChatSender.scanner, kind: ChatMessageKind.text, timeLabel: '2:10 PM', text: 'Please move your car'),
        ChatMessageModel(sender: ChatSender.owner, kind: ChatMessageKind.text, timeLabel: '2:11 PM', text: 'On my way, 2 mins!'),
        ChatMessageModel(sender: ChatSender.scanner, kind: ChatMessageKind.voice, timeLabel: '2:12 PM', voiceDuration: '0:14'),
        ChatMessageModel(sender: ChatSender.owner, kind: ChatMessageKind.photo, timeLabel: '2:13 PM'),
      ],
    ),
    const MessageThreadModel(
      scannerName: 'Anonymous',
      plateNumber: 'LEA-2231',
      vehicleColor: Color(0xFFF5F1E8),
      lastMessagePreview: 'Urgent — please respond immediately',
      timeLabel: '1h ago',
      unreadCount: 1,
      messages: [
        ChatMessageModel(sender: ChatSender.scanner, kind: ChatMessageKind.text, timeLabel: '1:05 PM', text: 'Urgent — please respond immediately'),
      ],
    ),
    const MessageThreadModel(
      scannerName: 'Sana Malik',
      plateNumber: 'LEC-9102',
      vehicleColor: Color(0xFFC2C2BE),
      lastMessagePreview: 'Thanks, moved it now!',
      timeLabel: 'Yesterday',
      isResolved: true,
      messages: [
        ChatMessageModel(sender: ChatSender.scanner, kind: ChatMessageKind.text, timeLabel: 'Yesterday, 5:02 PM', text: 'You are blocking my exit'),
        ChatMessageModel(sender: ChatSender.owner, kind: ChatMessageKind.text, timeLabel: 'Yesterday, 5:06 PM', text: 'Thanks, moved it now!'),
      ],
    ),
  ].obs;

  int get unreadThreadCount => threads.where((t) => t.unreadCount > 0).length;

  void markAllRead() {
    threads.assignAll([for (final t in threads) t.copyWith(unreadCount: 0)]);
  }

  void updateThread(MessageThreadModel original, MessageThreadModel updated) {
    final index = threads.indexOf(original);
    if (index != -1) threads[index] = updated;
  }
}
