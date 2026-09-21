import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/modules/dashboard/controllers/inbox_controller.dart';
import 'package:parktag_app/modules/dashboard/views/inbox_view.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(Get.reset);

  testWidgets('Inbox shows threads with unread and resolved states', (tester) async {
    Get.put(InboxController());

    await tester.pumpWidget(const GetMaterialApp(home: InboxView()));
    await tester.pump();

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('3 unread across 3 vehicles'), findsOneWidget);
    expect(find.text('Anonymous'), findsNWidgets(2));
    expect(find.text('Bilal Ahmed'), findsOneWidget);
    expect(find.text('RESOLVED'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('Mark all read clears every unread badge and the summary', (tester) async {
    final controller = Get.put(InboxController());

    await tester.pumpWidget(const GetMaterialApp(home: InboxView()));
    await tester.pump();

    await tester.tap(find.text('Mark all read'));
    await tester.pump();

    expect(controller.unreadThreadCount, 0);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
  });
}
