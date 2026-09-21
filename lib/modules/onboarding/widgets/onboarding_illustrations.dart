import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF262622)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, Color(0xFF191919)],
        ),
      ),
      child: Center(child: child),
    );
  }
}

/// Step 1 — car silhouette with a QR sticker on the windshield.
class TagCarIllustration extends StatelessWidget {
  const TagCarIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(220, 120), painter: _CarSilhouettePainter()),
          Positioned(
            top: 46,
            right: 40,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(color: AppColors.yellow.withValues(alpha: 0.32), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.qr_code_2, color: AppColors.background, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF3A3A34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roof = Path()
      ..moveTo(20, 90)
      ..lineTo(34, 55)
      ..quadraticBezierTo(40, 44, 54, 44)
      ..lineTo(166, 44)
      ..quadraticBezierTo(180, 44, 186, 55)
      ..lineTo(200, 90);
    canvas.drawPath(roof, stroke);

    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 90, 200, 14), const Radius.circular(6));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF242420));
    canvas.drawRRect(body, stroke);

    canvas.drawCircle(const Offset(52, 104), 14, Paint()..color = AppColors.background);
    canvas.drawCircle(const Offset(52, 104), 14, stroke);
    canvas.drawCircle(const Offset(168, 104), 14, Paint()..color = AppColors.background);
    canvas.drawCircle(const Offset(168, 104), 14, stroke);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(56, 52, 108, 30), const Radius.circular(4)),
      Paint()..color = const Color(0xFF1A1A17),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(56, 52, 108, 30), const Radius.circular(4)),
      stroke..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Step 2 — phone with an incoming anonymous message + bell badge.
class NotifiedIllustration extends StatelessWidget {
  const NotifiedIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 232,
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF33332E), width: 2),
            ),
            child: Column(
              children: [
                Container(width: 34, height: 4, decoration: BoxDecoration(color: const Color(0xFF3A3A34), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 22),
                Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF242420), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Anonymous', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 3),
                      Text('Please move your car', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 46,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.yellow.withValues(alpha: 0.32), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.notifications, color: AppColors.background, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 3 — a two-bubble chat thread ending in a Resolved pill.
class ResolveIllustration extends StatelessWidget {
  const ResolveIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _bubble("You're blocking my exit", const Color(0xFF242420), AppColors.ink, BorderRadius.circular(12).copyWith(bottomLeft: const Radius.circular(4))),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _bubble('On my way!', AppColors.yellow, AppColors.background, BorderRadius.circular(12).copyWith(bottomRight: const Radius.circular(4)), bold: true),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF7FBF7F).withValues(alpha: 0.14),
                border: Border.all(color: const Color(0xFF2A3D2A)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 13, color: Color(0xFF7FBF7F)),
                  SizedBox(width: 6),
                  Text('Resolved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7FBF7F))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, Color bg, Color fg, BorderRadius radius, {bool bold = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: fg)),
    );
  }
}
