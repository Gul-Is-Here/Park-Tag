import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/services/conversation_service.dart';
import 'package:parktag_app/modules/chat/controllers/chat_thread_controller.dart';
import 'package:parktag_app/modules/chat/views/chat_thread_view.dart';
import 'package:parktag_app/modules/dashboard/models/message_thread_model.dart';

import 'support/fake_conversation_service.dart';

const _thread = MessageThreadModel(
  conversationId: 'v2_scanner-1',
  scannerName: 'Bilal Ahmed',
  plateNumber: 'LEB-4470',
  vehicleColor: Color(0xFF2B2B2B),
  lastMessagePreview: 'Please move your car',
  timeLabel: '41m ago',
  unreadCount: 2,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  late FakeConversationService fakeConversations;

  setUp(() {
    Get.reset();
    fakeConversations = FakeConversationService();
    Get.put<ConversationService>(fakeConversations);
    fakeConversations.seed(
      const ConversationSummary(
        conversationId: 'v2_scanner-1',
        vehicleId: 'v2',
        ownerUid: 'resident-1',
        scannerName: 'Bilal Ahmed',
        plateNumber: 'LEB-4470',
        colorName: 'Black',
        resolved: false,
        unreadForOwner: true,
        lastMessagePreview: 'Please move your car',
        lastMessageAt: null,
      ),
      const [ConversationMessage(sender: MessageSender.scanner, text: 'Please move your car', createdAt: null)],
    );
  });

  testWidgets('Chat thread renders header, messages and the resolved banner', (tester) async {
    Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    expect(find.text('Bilal Ahmed'), findsOneWidget);
    expect(find.text('Please move your car'), findsOneWidget);
    expect(find.text('Has this issue been resolved?'), findsOneWidget);
  });

  testWidgets('Sending a text message appends it to the thread', (tester) async {
    final controller = Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'On my way!');
    controller.sendText();
    await tester.pump();

    expect(find.text('On my way!'), findsOneWidget);
  });

  testWidgets('Marking resolved updates the banner', (tester) async {
    final controller = Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    controller.markResolved();
    await tester.pump();

    expect(find.text('Marked as resolved'), findsOneWidget);
    expect(controller.isResolved.value, isTrue);
  });

  group('viewing as the scanner (authenticated in-app QR scan/deep link)', () {
    const scannerSideThread = MessageThreadModel(
      conversationId: 'v2_resident-2',
      scannerName: '',
      ownerName: 'Ayesha Khan',
      plateNumber: 'LEB-4470',
      vehicleColor: Color(0xFF2B2B2B),
      lastMessagePreview: '',
      timeLabel: 'Just now',
      viewerRole: ThreadViewerRole.scanner,
    );

    setUp(() {
      fakeConversations.seed(
        const ConversationSummary(
          conversationId: 'v2_resident-2',
          vehicleId: 'v2',
          ownerUid: 'resident-1',
          ownerName: 'Ayesha Khan',
          scannerUid: 'resident-2',
          scannerName: 'resident-2',
          plateNumber: 'LEB-4470',
          colorName: 'Black',
          resolved: false,
          unreadForOwner: false,
          lastMessagePreview: '',
          lastMessageAt: null,
        ),
      );
    });

    testWidgets('shows the vehicle owner as the header, not the scanner', (tester) async {
      Get.put(ChatThreadController(thread: scannerSideThread));

      await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
      await tester.pump();

      expect(find.text('Ayesha Khan'), findsOneWidget);
    });

    testWidgets('sending a message calls sendAuthenticatedScannerReply, not sendOwnerReply', (tester) async {
      final controller = Get.put(ChatThreadController(thread: scannerSideThread));

      await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), "I'll move it now");
      controller.sendText();
      await tester.pump();

      final messages = await fakeConversations.watchMessages('v2_resident-2').first;
      expect(messages.single.sender, MessageSender.scanner);
      expect(messages.single.text, "I'll move it now");
    });
  });
}
