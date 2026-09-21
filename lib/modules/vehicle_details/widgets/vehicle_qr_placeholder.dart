import 'package:flutter/material.dart';

/// Decorative QR-code glyph matching the mockup — a stand-in until FR-03
/// (real per-vehicle QR sticker generation) is implemented.
class VehicleQrPlaceholder extends StatelessWidget {
  const VehicleQrPlaceholder({super.key, this.size = 156});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QrPainter(),
    );
  }
}

class _QrPainter extends CustomPainter {
  static const _dataCells = [
    [6, 0], [8, 0],
    [6, 1], [9, 1],
    [7, 3],
    [6, 6], [7, 6], [8, 6], [9, 6], [10, 6], [11, 6],
    [6, 7], [8, 7], [10, 7],
    [6, 8], [7, 8], [9, 8],
    [11, 9],
    [6, 9], [8, 9], [10, 9],
    [6, 10], [7, 10], [9, 10], [11, 10],
    [6, 11], [8, 11], [10, 11],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF5F1E8);
    canvas.drawRect(Offset.zero & size, bg);

    final cell = size.width / 15;
    final dot = Paint()..color = const Color(0xFF161616);

    for (final finder in [const Offset(0, 0), const Offset(11, 0), const Offset(0, 11)]) {
      final origin = Offset(finder.dx * cell, finder.dy * cell);
      final outer = Rect.fromLTWH(origin.dx, origin.dy, cell * 4, cell * 4);
      canvas.drawRect(
        outer,
        Paint()
          ..color = const Color(0xFF161616)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.6,
      );
      canvas.drawRect(
        Rect.fromLTWH(origin.dx + cell * 1.3, origin.dy + cell * 1.3, cell * 1.4, cell * 1.4),
        dot,
      );
    }

    for (final c in _dataCells) {
      final rect = Rect.fromLTWH(c[0] * cell, c[1] * cell, cell, cell);
      canvas.drawRect(rect, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
