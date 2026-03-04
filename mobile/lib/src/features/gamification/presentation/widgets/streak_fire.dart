import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';

enum StreakFireSize { small, large }

class StreakFire extends StatelessWidget {
  const StreakFire({
    super.key,
    required this.streakCount,
    this.size = StreakFireSize.small,
    this.label,
  });

  final int streakCount;
  final StreakFireSize size;
  final String? label;

  bool get _isLarge => size == StreakFireSize.large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconSize = _isLarge ? 40.0 : 22.0;
    final countStyle = _isLarge
        ? textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.streakFire,
          )
        : textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.streakFire,
          );

    final fireIcon = Icon(
      Icons.local_fire_department,
      size: iconSize,
      color: AppColors.streakFire,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.15, duration: 600.ms, curve: Curves.easeInOut)
        .then()
        .shimmer(
          duration: 800.ms,
          color: AppColors.f1Gold.withValues(alpha: 0.4),
        );

    if (_isLarge) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          fireIcon,
          const SizedBox(height: 4),
          Text('$streakCount', style: countStyle),
          if (label != null)
            Text(
              label!,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        fireIcon,
        const SizedBox(width: 4),
        Text('$streakCount', style: countStyle),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
