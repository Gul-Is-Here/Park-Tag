import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/theme/app_colors.dart';
import 'package:parktag_app/app/widgets/app_snackbar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('Snackbars are brand yellow with black title and message text', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await tester.pump();

    AppSnackbar.show('Vehicle saved', 'Its QR sticker is ready.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Vehicle saved'), findsOneWidget);
    expect(find.text('Its QR sticker is ready.'), findsOneWidget);

    // Background is the existing brand yellow, not a new colour.
    final bar = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
    expect(bar.backgroundColor, AppColors.yellow);

    // Both lines of text are black, for contrast against that yellow.
    for (final label in ['Vehicle saved', 'Its QR sticker is ready.']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, Colors.black, reason: '"$label" must be black on yellow');
    }

    // Let the 3s snackbar expire so the overlay's ticker is disposed
    // before the tree is torn down. (Awaiting closeCurrentSnackbar()
    // instead would deadlock: its future only completes once pumped.)
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('A tap callback still fires, so behaviour is unchanged', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await tester.pump();

    var tapped = false;
    AppSnackbar.show('New message', 'Please move your car', onTap: (_) => tapped = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('New message'));
    await tester.pump();

    expect(tapped, isTrue);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('Defaults to the bottom, but TOP can be requested per call', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await tester.pump();

    AppSnackbar.show('Vehicle saved', 'Its QR sticker is ready.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.widget<GetSnackBar>(find.byType(GetSnackBar)).snackPosition,
      SnackPosition.BOTTOM,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // A new-message alert, e.g. from PushNotificationService, is shown at
    // the top so it reads as a notification rather than feedback on
    // something the resident just did at the bottom of the screen.
    AppSnackbar.show('New message', 'Please move your car', position: SnackPosition.TOP);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.widget<GetSnackBar>(find.byType(GetSnackBar)).snackPosition,
      SnackPosition.TOP,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
