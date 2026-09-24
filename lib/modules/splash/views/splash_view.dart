import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _HazardStripe(alignTop: true),
          const _HazardStripe(alignTop: false),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Mark(),
                const SizedBox(height: 28),
                _Wordmark(),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: _LoadingIndicator(),
          ),
        ],
      ),
    );
  }
}

class _HazardStripe extends StatelessWidget {
  const _HazardStripe({required this.alignTop});

  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignTop ? 0 : null,
      bottom: alignTop ? null : 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 10,
        width: double.infinity,
        child: CustomPaint(painter: _StripePainter()),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  static const _bandWidth = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final paint = Paint()..color = AppColors.yellow;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -size.height; x < size.width + size.height; x += _bandWidth * 2) {
      final band = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + _bandWidth, 0)
        ..lineTo(x + _bandWidth, size.height)
        ..close();
      canvas.drawPath(band, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.yellow, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(56, 56),
          painter: _CarPinPainter(),
        ),
      ),
    );
  }
}

class _CarPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * (size.width / 24)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final s = size.width / 24;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final body = Path()
      ..moveTo(p(4, 16.5).dx, p(4, 16.5).dy)
      ..lineTo(p(4, 11).dx, p(4, 11).dy)
      ..lineTo(p(5.8, 5.8).dx, p(5.8, 5.8).dy)
      ..quadraticBezierTo(
        p(6.6, 4.4).dx,
        p(6.6, 4.4).dy,
        p(7.7, 4.4).dx,
        p(7.7, 4.4).dy,
      )
      ..lineTo(p(16.3, 4.4).dx, p(16.3, 4.4).dy)
      ..quadraticBezierTo(
        p(17.4, 4.4).dx,
        p(17.4, 4.4).dy,
        p(18.2, 5.8).dx,
        p(18.2, 5.8).dy,
      )
      ..lineTo(p(20, 11).dx, p(20, 11).dy)
      ..lineTo(p(20, 16.5).dx, p(20, 16.5).dy);
    canvas.drawPath(body, stroke);

    final chassis = RRect.fromRectAndRadius(
      Rect.fromLTWH(p(3.2, 11).dx, p(3.2, 11).dy, 17.6 * s, 6.6 * s),
      Radius.circular(2 * s),
    );
    canvas.drawRRect(chassis, stroke);

    canvas.drawCircle(p(7, 17.6), 1.7 * s, fill);
    canvas.drawCircle(p(7, 17.6), 1.7 * s, stroke);
    canvas.drawCircle(p(17, 17.6), 1.7 * s, fill);
    canvas.drawCircle(p(17, 17.6), 1.7 * s, stroke);

    canvas.drawLine(p(8.6, 8.4), p(15.4, 8.4), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Wordmark extends StatelessWidget {
  _Wordmark();

  final wordmarkStyle = AppTextStyles.displayLg.copyWith(color: AppColors.ink);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: wordmarkStyle,
            children: [
              const TextSpan(text: 'Park'),
              TextSpan(
                text: 'Tag',
                style: wordmarkStyle.copyWith(color: AppColors.yellow),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan. Message. Move on.',
          style: AppTextStyles.tagline.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
            backgroundColor: Color(0x38F4C21B),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'GETTING THINGS READY',
          style: AppTextStyles.overline.copyWith(color: AppColors.faint),
        ),
      ],
    );
  }
}
