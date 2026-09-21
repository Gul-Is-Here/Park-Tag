import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.yellow, width: 2.5),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(17, 17),
              painter: _CarMarkPainter(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            style: AppTextStyles.headingSm.copyWith(color: AppColors.ink),
            children: [
              const TextSpan(text: 'Park'),
              TextSpan(text: 'Tag', style: TextStyle(color: AppColors.yellow)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * (size.width / 24)
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
