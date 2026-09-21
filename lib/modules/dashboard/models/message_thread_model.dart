import 'package:flutter/material.dart';

import 'chat_message_model.dart';

/// FR-05.5/FR-06: one scanner's message thread with a resident, scoped to
/// a single vehicle.
class MessageThreadModel {
  const MessageThreadModel({
    required this.scannerName,
    required this.plateNumber,
    required this.vehicleColor,
    required this.lastMessagePreview,
    required this.timeLabel,
    this.unreadCount = 0,
    this.isResolved = false,
    this.messages = const [],
  });

  final String scannerName;
  final String plateNumber;
  final Color vehicleColor;
  final String lastMessagePreview;
  final String timeLabel;
  final int unreadCount;
  final bool isResolved;
  final List<ChatMessageModel> messages;

  bool get isAnonymous => scannerName == 'Anonymous';

  MessageThreadModel copyWith({
    int? unreadCount,
    bool? isResolved,
    List<ChatMessageModel>? messages,
    String? lastMessagePreview,
    String? timeLabel,
  }) => MessageThreadModel(
    scannerName: scannerName,
    plateNumber: plateNumber,
    vehicleColor: vehicleColor,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    timeLabel: timeLabel ?? this.timeLabel,
    unreadCount: unreadCount ?? this.unreadCount,
    isResolved: isResolved ?? this.isResolved,
    messages: messages ?? this.messages,
  );
}
