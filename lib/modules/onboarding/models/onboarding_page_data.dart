import 'package:flutter/widgets.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.headline,
    required this.body,
    required this.illustrationBuilder,
  });

  final String headline;
  final String body;
  final WidgetBuilder illustrationBuilder;
}
