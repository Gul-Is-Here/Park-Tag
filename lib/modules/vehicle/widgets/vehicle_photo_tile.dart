import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class VehiclePhotoTile extends StatelessWidget {
  const VehiclePhotoTile({
    super.key,
    required this.label,
    this.imagePath,
    required this.onTap,
    this.onRemove,
    this.aspectRatio = 1,
    this.borderRadius = 14,
  });

  final String label;
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  /// Width/height ratio of the tile — e.g. 1.586 for an ID-card (CR80)
  /// shaped box like an RC card or CNIC.
  final double aspectRatio;

  /// Corner radius in logical pixels.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imagePath != null;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GestureDetector(
        onTap: hasPhoto ? null : onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: AppColors.yellow, width: 1.5),
                image: hasPhoto
                    ? DecorationImage(
                        image: imagePath!.startsWith('http')
                            ? NetworkImage(imagePath!) as ImageProvider
                            : FileImage(File(imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasPhoto
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.yellow,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.yellow,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
            ),
            if (hasPhoto && onRemove != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.ink,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
