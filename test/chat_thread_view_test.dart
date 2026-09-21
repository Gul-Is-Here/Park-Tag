import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/modules/chat/controllers/chat_thread_controller.dart';
import 'package:parktag_app/modules/chat/views/chat_thread_view.dart';
import 'package:parktag_app/modules/dashboard/controllers/inbox_controller.dart';
import 'package:parktag_app/modules/dashboard/models/chat_message_model.dart';
import 'package:parktag_app/modules/dashboard/models/message_thread_model.dart';

const _thread = MessageThreadModel(
  scannerName: 'Bilal Ahmed',
  plateNumber: 'LEB-4470',
  vehicleColor: Color(0xFF2B2B2B),
  lastMessagePreview: 'Please move your car',
  timeLabel: '41m ago',
  unreadCount: 2,
  messages: [
    ChatMessageModel(sender: ChatSender.scanner, kind: ChatMessageKind.text, timeLabel: '2:10 PM', text: 'Please move your car'),
  ],
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  setUp(Get.reset);

  testWidgets('Chat thread renders header, messages and the resolved banner', (tester) async {
    Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    expect(find.text('Bilal Ahmed'), findsOneWidget);
    expect(find.text('Please move your car'), findsOneWidget);
    expect(find.text('Has this issue been resolved?'), findsOneWidget);
  });

  testWidgets('Opening a thread with unread messages clears its Inbox badge', (tester) async {
    Get.put(InboxController());
    final inbox = Get.find<InboxController>();
    inbox.threads.assignAll([_thread]);

    Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    expect(inbox.threads.first.unreadCount, 0);
  });

  testWidgets('Sending a text message appends it and updates the Inbox preview', (tester) async {
    Get.put(InboxController());
    final inbox = Get.find<InboxController>();
    inbox.threads.assignAll([_thread]);

    final controller = Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'On my way!');
    controller.sendText();
    await tester.pump();

    expect(find.text('On my way!'), findsOneWidget);
    expect(inbox.threads.first.lastMessagePreview, 'On my way!');
  });

  testWidgets('Marking resolved updates the banner and the Inbox thread', (tester) async {
    Get.put(InboxController());
    final inbox = Get.find<InboxController>();
    inbox.threads.assignAll([_thread]);

    final controller = Get.put(ChatThreadController(thread: _thread));

    await tester.pumpWidget(const GetMaterialApp(home: ChatThreadView()));
    await tester.pump();

    controller.markResolved();
    await tester.pump();

    expect(find.text('Marked as resolved'), findsOneWidget);
    expect(inbox.threads.first.isResolved, isTrue);
  });
}
