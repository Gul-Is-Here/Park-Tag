import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A lightweight shimmer, deliberately not a new dependency — the project
/// pulls in no shimmer package and this is a single sweeping gradient.
///
/// Wrap a skeleton layout in one [Shimmer]; every [ShimmerBox] beneath it
/// shares that single animation controller, so a screenful of placeholders
/// costs one ticker rather than one per box.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();

  static _ShimmerState? _of(BuildContext context) =>
      context.findAncestorStateOfType<_ShimmerState>();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One placeholder block. Give it the same size and radius as the real
/// widget it stands in for, so nothing shifts when the content arrives.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final animation = Shimmer._of(context)?.controller;
    // Outside a Shimmer, render a flat block rather than throwing — a
    // skeleton that does not animate is still a usable placeholder.
    if (animation == null) return _box(const AlwaysStoppedAnimation(0.5));
    return AnimatedBuilder(animation: animation, builder: (_, _) => _box(animation));
  }

  Widget _box(Animation<double> animation) {
    // Sweep a highlight left-to-right across the block.
    final t = animation.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.6 + (t * 3.2), 0),
          end: Alignment(-0.6 + (t * 3.2), 0),
          colors: const [Color(0xFF232320), Color(0xFF32322C), Color(0xFF232320)],
        ),
      ),
    );
  }
}

/// Shared chrome for the Home tab's empty and error states.
class HomeStateBlock extends StatelessWidget {
  const HomeStateBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: const Color(0xFF2E2E29)),
            ),
            child: Icon(icon, size: 31, color: AppColors.faint),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSm.copyWith(color: AppColors.ink, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(color: AppColors.muted, fontSize: 13, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}
