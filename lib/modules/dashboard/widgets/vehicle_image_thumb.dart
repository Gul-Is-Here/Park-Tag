import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Vehicle photo thumbnail for a vehicle card. Falls back to a car glyph
/// when no vehicle photo was captured (FR-02.1 — vehicle photos are optional).
class VehicleImageThumb extends StatelessWidget {
  const VehicleImageThumb({super.key, required this.photoPaths});

  final List<String> photoPaths;

  @override
  Widget build(BuildContext context) {
    final path = photoPaths.isEmpty ? null : photoPaths.first;

    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF33332E), width: 1.5),
      ),
      child: path == null
          ? const Center(child: Icon(Icons.directions_car_rounded, color: AppColors.faint, size: 26))
          : _buildImage(path),
    );
  }

  Widget _buildImage(String path) {
    const fallback = Center(child: Icon(Icons.directions_car_rounded, color: AppColors.faint, size: 26));
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
    }
    return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
  }
}
