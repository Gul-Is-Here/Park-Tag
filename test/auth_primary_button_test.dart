import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/theme/app_colors.dart';
import 'package:parktag_app/modules/auth/widgets/auth_primary_button.dart';

/// This single button backs every "submit/save" action in the app — Login,
/// Sign Up, OTP verify, Add Vehicle save, Edit Vehicle save and Profile
/// save all render through it, so its loading behaviour is verified once
/// here rather than duplicated per screen.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

  testWidgets('Shows the label and is tappable when not loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(AuthPrimaryButton(label: 'Send OTP', onPressed: () => tapped = true)),
    );

    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(AuthPrimaryButton));
    expect(tapped, isTrue);
  });

  testWidgets('Swaps the label for a spinner while loading, and blocks taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        AuthPrimaryButton(label: 'Send OTP', isLoading: true, onPressed: () => tapped = true),
      ),
    );

    expect(find.text('Send OTP'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // A tap during the save must not re-fire it — this is what stops a
    // second request going out while the first is still in flight.
    await tester.tap(find.byType(AuthPrimaryButton));
    expect(tapped, isFalse);
  });

  testWidgets('isLoading overrides a null onPressed the same way — always disabled while saving', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AuthPrimaryButton(label: 'Save', isLoading: true, onPressed: null)));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('The spinner reads dark-on-yellow, matching the label it replaces', (tester) async {
    await tester.pumpWidget(
      host(const AuthPrimaryButton(label: 'Save', isLoading: true, onPressed: null)),
    );

    final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
    expect((indicator.valueColor as AlwaysStoppedAnimation<Color>).value, AppColors.background);
  });
}
