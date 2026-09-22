import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/conversation_service.dart';
import 'package:parktag_app/modules/dashboard/controllers/inbox_controller.dart';
import 'package:parktag_app/modules/dashboard/views/inbox_view.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_conversation_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late FakeConversationService fakeConversations;

  setUp(() {
    Get.reset();
    final fakeAuth = FakeAuthService();
    fakeAuth.signInAs(uid: 'resident-1', phone: '+923001234567');
    Get.put<AuthService>(fakeAuth);
    fakeConversations = FakeConversationService();
    Get.put<ConversationService>(fakeConversations);
  });

  void seedThreeThreads() {
    fakeConversations.seed(
      const ConversationSummary(
        conversationId: 'v1_scanner-1',
        vehicleId: 'v1',
        ownerUid: 'resident-1',
        scannerName: 'Anonymous',
        plateNumber: 'LEA-2231',
        colorName: 'White',
        resolved: false,
        unreadForOwner: true,
        lastMessagePreview: 'Please move your car',
        lastMessageAt: null,
      ),
    );
    fakeConversations.seed(
      const ConversationSummary(
        conversationId: 'v2_scanner-2',
        vehicleId: 'v2',
        ownerUid: 'resident-1',
        scannerName: 'Bilal Ahmed',
        plateNumber: 'LEB-4470',
        colorName: 'Black',
        resolved: false,
        unreadForOwner: true,
        lastMessagePreview: 'Voice note',
        lastMessageAt: null,
      ),
    );
    fakeConversations.seed(
      const ConversationSummary(
        conversationId: 'v3_scanner-3',
        vehicleId: 'v3',
        ownerUid: 'resident-1',
        scannerName: 'Sana Malik',
        plateNumber: 'LEC-9102',
        colorName: 'Silver',
        resolved: true,
        unreadForOwner: false,
        lastMessagePreview: 'Thanks, moved it now!',
        lastMessageAt: null,
      ),
    );
  }

  testWidgets('Inbox shows threads with unread and resolved states', (tester) async {
    Get.put(InboxController());
    seedThreeThreads();

    await tester.pumpWidget(const GetMaterialApp(home: InboxView()));
    await tester.pump();

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('2 unread across 3 vehicles'), findsOneWidget);
    expect(find.text('Anonymous'), findsOneWidget);
    expect(find.text('Bilal Ahmed'), findsOneWidget);
    expect(find.text('RESOLVED'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('Mark all read clears every unread badge and the summary', (tester) async {
    final controller = Get.put(InboxController());
    seedThreeThreads();

    await tester.pumpWidget(const GetMaterialApp(home: InboxView()));
    await tester.pump();

    await tester.tap(find.text('Mark all read'));
    await tester.pump();

    expect(controller.unreadThreadCount, 0);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });
}
