import 'dart:async';

import 'package:parktag_app/app/services/conversation_service.dart';

class FakeConversationService implements ConversationService {
  final Map<String, ConversationSummary> _summaries = {};
  final Map<String, List<ConversationMessage>> _messages = {};

  final _summariesController = StreamController<Map<String, ConversationSummary>>.broadcast();
  final _messagesController = StreamController<Map<String, List<ConversationMessage>>>.broadcast();

  void _emit() {
    _summariesController.add(Map.of(_summaries));
    _messagesController.add(Map.of(_messages));
  }

  /// Test helper — seeds a conversation directly, bypassing sendScannerMessage.
  void seed(ConversationSummary summary, [List<ConversationMessage> messages = const []]) {
    _summaries[summary.conversationId] = summary;
    _messages[summary.conversationId] = List.of(messages);
    _emit();
  }

  /// Test seed for [resolveVehicleAndOpenChat] — mirrors what the real
  /// Cloud Function reads server-side from `vehicles/{vehicleId}`.
  final Map<String, ({String ownerUid, String ownerName, String plateNumber, String colorName})> vehicles = {};

  /// Test seed — mirrors `request.auth.uid` inside the real Cloud
  /// Function; the "signed-in caller" [resolveVehicleAndOpenChat] acts as.
  String callerUid = 'test-caller';

  /// Every vehicleId [resolveVehicleAndOpenChat] successfully created a
  /// *new* conversation for (not just returned an existing one) — lets
  /// tests assert duplicate scans don't create duplicate rooms.
  final resolvedNewChats = <String>[];

  @override
  Stream<List<ConversationSummary>> watchOwnerConversations(String ownerUid) async* {
    yield _summaries.values.where((s) => s.ownerUid == ownerUid).toList();
    yield* _summariesController.stream.map((all) => all.values.where((s) => s.ownerUid == ownerUid).toList());
  }

  @override
  Stream<List<ConversationSummary>> watchScannerConversations(String scannerUid) async* {
    yield _summaries.values.where((s) => s.scannerUid == scannerUid).toList();
    yield* _summariesController.stream.map((all) => all.values.where((s) => s.scannerUid == scannerUid).toList());
  }

  @override
  Future<void> linkScannerIdentity({required String scannerId, required String uid}) async {
    for (final entry in _summaries.entries.toList()) {
      final existing = entry.value;
      if (existing.scannerId != scannerId || existing.scannerUid != null) continue;
      _summaries[entry.key] = ConversationSummary(
        conversationId: existing.conversationId,
        vehicleId: existing.vehicleId,
        ownerUid: existing.ownerUid,
        ownerName: existing.ownerName,
        scannerId: existing.scannerId,
        scannerName: existing.scannerName,
        plateNumber: existing.plateNumber,
        colorName: existing.colorName,
        resolved: existing.resolved,
        unreadForOwner: existing.unreadForOwner,
        lastMessagePreview: existing.lastMessagePreview,
        lastMessageAt: existing.lastMessageAt,
        scannerUid: uid,
      );
    }
    _emit();
  }

  @override
  Future<ResolvedChat> resolveVehicleAndOpenChat({required String vehicleId}) async {
    final vehicle = vehicles[vehicleId];
    if (vehicle == null) {
      throw const ResolveVehicleException("This QR code doesn't match a ParkTag vehicle.");
    }
    if (vehicle.ownerUid == callerUid) {
      throw const ResolveVehicleException("This is your own vehicle — nothing to message.");
    }

    final conversationId = conversationIdFor(vehicleId, callerUid);
    final existing = _summaries[conversationId];
    if (existing != null) {
      return ResolvedChat(
        conversationId: conversationId,
        ownerName: existing.ownerName,
        plateNumber: existing.plateNumber,
        colorName: existing.colorName,
        resolved: existing.resolved,
      );
    }

    resolvedNewChats.add(vehicleId);
    _summaries[conversationId] = ConversationSummary(
      conversationId: conversationId,
      vehicleId: vehicleId,
      ownerUid: vehicle.ownerUid,
      ownerName: vehicle.ownerName,
      scannerId: callerUid,
      scannerUid: callerUid,
      scannerName: 'Test Scanner',
      plateNumber: vehicle.plateNumber,
      colorName: vehicle.colorName,
      resolved: false,
      unreadForOwner: false,
      lastMessagePreview: '',
      lastMessageAt: DateTime.now(),
    );
    _emit();

    return ResolvedChat(
      conversationId: conversationId,
      ownerName: vehicle.ownerName,
      plateNumber: vehicle.plateNumber,
      colorName: vehicle.colorName,
      resolved: false,
    );
  }

  @override
  Future<void> sendAuthenticatedScannerReply({required String conversationId, required String text}) async {
    final existing = _summaries[conversationId];
    if (existing != null) {
      _summaries[conversationId] = ConversationSummary(
        conversationId: existing.conversationId,
        vehicleId: existing.vehicleId,
        ownerUid: existing.ownerUid,
        ownerName: existing.ownerName,
        scannerId: existing.scannerId,
        scannerUid: existing.scannerUid,
        scannerName: existing.scannerName,
        plateNumber: existing.plateNumber,
        colorName: existing.colorName,
        resolved: existing.resolved,
        unreadForOwner: true,
        lastMessagePreview: text,
        lastMessageAt: DateTime.now(),
      );
    }
    _messages.putIfAbsent(conversationId, () => []).add(
      ConversationMessage(sender: MessageSender.scanner, text: text, createdAt: DateTime.now()),
    );
    _emit();
  }

  @override
  Stream<ConversationSummary?> watchConversation(String conversationId) async* {
    yield _summaries[conversationId];
    yield* _summariesController.stream.map((all) => all[conversationId]);
  }

  @override
  Stream<List<ConversationMessage>> watchMessages(String conversationId) async* {
    yield _messages[conversationId] ?? const [];
    yield* _messagesController.stream.map((all) => all[conversationId] ?? const []);
  }

  @override
  Future<void> sendScannerMessage({
    required String vehicleId,
    required String scannerId,
    required String ownerUid,
    required String plateNumber,
    required String colorName,
    required String scannerName,
    required String text,
  }) async {
    final conversationId = conversationIdFor(vehicleId, scannerId);
    _summaries[conversationId] = ConversationSummary(
      conversationId: conversationId,
      vehicleId: vehicleId,
      ownerUid: ownerUid,
      scannerId: scannerId,
      scannerName: scannerName.isEmpty ? 'Anonymous' : scannerName,
      plateNumber: plateNumber,
      colorName: colorName,
      resolved: false,
      unreadForOwner: true,
      lastMessagePreview: text,
      lastMessageAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(
      ConversationMessage(sender: MessageSender.scanner, text: text, createdAt: DateTime.now()),
    );
    _emit();
  }

  @override
  Future<void> sendOwnerReply({required String conversationId, required String text}) async {
    final existing = _summaries[conversationId];
    if (existing != null) {
      _summaries[conversationId] = ConversationSummary(
        conversationId: existing.conversationId,
        vehicleId: existing.vehicleId,
        ownerUid: existing.ownerUid,
        ownerName: existing.ownerName,
        scannerId: existing.scannerId,
        scannerUid: existing.scannerUid,
        scannerName: existing.scannerName,
        plateNumber: existing.plateNumber,
        colorName: existing.colorName,
        resolved: existing.resolved,
        unreadForOwner: false,
        lastMessagePreview: text,
        lastMessageAt: DateTime.now(),
      );
    }
    _messages.putIfAbsent(conversationId, () => []).add(
      ConversationMessage(sender: MessageSender.owner, text: text, createdAt: DateTime.now()),
    );
    _emit();
  }

  @override
  Future<void> setResolved({required String conversationId, required bool resolved}) async {
    final existing = _summaries[conversationId];
    if (existing == null) return;
    _summaries[conversationId] = ConversationSummary(
      conversationId: existing.conversationId,
      vehicleId: existing.vehicleId,
      ownerUid: existing.ownerUid,
      ownerName: existing.ownerName,
      scannerId: existing.scannerId,
      scannerUid: existing.scannerUid,
      scannerName: existing.scannerName,
      plateNumber: existing.plateNumber,
      colorName: existing.colorName,
      resolved: resolved,
      unreadForOwner: existing.unreadForOwner,
      lastMessagePreview: existing.lastMessagePreview,
      lastMessageAt: existing.lastMessageAt,
    );
    _emit();
  }

  @override
  Future<void> markReadByOwner(String conversationId) async {
    final existing = _summaries[conversationId];
    if (existing == null) return;
    _summaries[conversationId] = ConversationSummary(
      conversationId: existing.conversationId,
      vehicleId: existing.vehicleId,
      ownerUid: existing.ownerUid,
      ownerName: existing.ownerName,
      scannerId: existing.scannerId,
      scannerUid: existing.scannerUid,
      scannerName: existing.scannerName,
      plateNumber: existing.plateNumber,
      colorName: existing.colorName,
      resolved: existing.resolved,
      unreadForOwner: false,
      lastMessagePreview: existing.lastMessagePreview,
      lastMessageAt: existing.lastMessageAt,
    );
    _emit();
  }
}
