import 'package:flutter/material.dart';

/// Which side of the conversation the signed-in resident viewing this
/// thread is on — determines what the Chat screen shows in its header and
/// which [ConversationService] method sending a message calls.
enum ThreadViewerRole { owner, scanner }

/// FR-05.5/FR-06: one scanner's message thread with a resident, scoped to
/// a single vehicle *and* a single scanner — see ConversationService's
/// `conversationIdFor`. Backed 1:1 by a `conversations/{conversationId}`
/// Firestore doc.
class MessageThreadModel {
  const MessageThreadModel({
    required this.conversationId,
    required this.scannerName,
    required this.plateNumber,
    required this.vehicleColor,
    required this.lastMessagePreview,
    required this.timeLabel,
    this.unreadCount = 0,
    this.isResolved = false,
    this.ownerName = '',
    this.viewerRole = ThreadViewerRole.owner,
  });

  final String conversationId;
  final String scannerName;
  final String plateNumber;
  final Color vehicleColor;
  final String lastMessagePreview;
  final String timeLabel;
  final int unreadCount;
  final bool isResolved;

  /// Only meaningful when [viewerRole] is [ThreadViewerRole.scanner] — the
  /// vehicle owner's name, shown as the chat counterpart instead of
  /// [scannerName] (which would just be the viewer's own name in that case).
  final String ownerName;

  final ThreadViewerRole viewerRole;

  bool get isAnonymous => scannerName == 'Anonymous';
}
