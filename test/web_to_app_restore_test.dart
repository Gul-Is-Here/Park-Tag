import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:parktag_app/app/services/conversation_service.dart';

import 'support/fake_conversation_service.dart';

/// FR-09: someone scans a sticker with an external QR scanner, chats with
/// the owner anonymously on the public web page, then installs the app and
/// signs in. That web conversation must come back to them — same thread,
/// same history — not a fresh empty one.
void main() {
  late FakeConversationService conversations;

  setUp(() {
    Get.reset();
    conversations = FakeConversationService();
    conversations.vehicles['v1'] = (
      ownerUid: 'owner-1',
      ownerName: 'Ayesha Khan',
      plateNumber: 'LEA-2231',
      colorName: 'White',
    );
  });

  /// What the public web page leaves behind: a conversation keyed by the
  /// browser's random scannerId, with no account attached to it yet.
  void seedAnonymousWebChat({String scannerId = 'browser-abc'}) {
    conversations.seed(
      ConversationSummary(
        conversationId: conversationIdFor('v1', scannerId),
        vehicleId: 'v1',
        ownerUid: 'owner-1',
        ownerName: 'Ayesha Khan',
        scannerId: scannerId,
        scannerName: 'Anonymous',
        plateNumber: 'LEA-2231',
        colorName: 'White',
        resolved: false,
        unreadForOwner: true,
        lastMessagePreview: 'Please move your car',
        lastMessageAt: DateTime(2026, 9, 23, 11),
      ),
      const [
        ConversationMessage(
          sender: MessageSender.scanner,
          text: 'Please move your car',
          createdAt: null,
        ),
      ],
    );
  }

  test('Signing in reopens the web conversation instead of a new empty one', () async {
    seedAnonymousWebChat();
    conversations.callerUid = 'new-resident';

    final result = await conversations.resolveVehicleAndOpenChat(
      vehicleId: 'v1',
      anonymousScannerId: 'browser-abc',
    );

    // The adopted thread, not v1_new-resident.
    expect(result.conversationId, conversationIdFor('v1', 'browser-abc'));
    expect(conversations.resolvedNewChats, isEmpty, reason: 'no parallel chat created');

    // Its history is intact.
    final messages = await conversations.watchMessages(result.conversationId).first;
    expect(messages.single.text, 'Please move your car');

    // And it is now claimed by the account, so it appears under "Sent".
    final sent = await conversations.watchScannerConversations('new-resident').first;
    expect(sent.single.conversationId, conversationIdFor('v1', 'browser-abc'));
  });

  test('Without the scannerId it cannot be restored — a new chat is opened', () async {
    seedAnonymousWebChat();
    conversations.callerUid = 'new-resident';

    // This is the plain "installed the app and scanned the sticker again"
    // path: the sticker URL carries no scannerId, so there is nothing to
    // tie the browser's conversation to this account.
    final result = await conversations.resolveVehicleAndOpenChat(vehicleId: 'v1');

    expect(result.conversationId, conversationIdFor('v1', 'new-resident'));
    expect(conversations.resolvedNewChats, ['v1']);
  });

  test("Another person's linked conversation is never adopted", () async {
    seedAnonymousWebChat();
    // Someone else already claimed that browser's conversation.
    await conversations.linkScannerIdentity(scannerId: 'browser-abc', uid: 'other-resident');

    conversations.callerUid = 'attacker';
    final result = await conversations.resolveVehicleAndOpenChat(
      vehicleId: 'v1',
      anonymousScannerId: 'browser-abc',
    );

    // Falls back to their own fresh thread rather than taking it over.
    expect(result.conversationId, conversationIdFor('v1', 'attacker'));
    final stolen = conversations.summaryFor(conversationIdFor('v1', 'browser-abc'))!;
    expect(stolen.scannerUid, 'other-resident');
  });

  test('Re-scanning after restore keeps returning the same thread', () async {
    seedAnonymousWebChat();
    conversations.callerUid = 'new-resident';

    final first = await conversations.resolveVehicleAndOpenChat(
      vehicleId: 'v1',
      anonymousScannerId: 'browser-abc',
    );
    final second = await conversations.resolveVehicleAndOpenChat(
      vehicleId: 'v1',
      anonymousScannerId: 'browser-abc',
    );

    expect(second.conversationId, first.conversationId);
    expect(conversations.resolvedNewChats, isEmpty);
  });
}
