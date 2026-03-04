import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.8, -0.6),
          radius: 1.8,
          colors: isDark
              ? [
                  AppColors.f1Red.withValues(alpha: 0.08),
                  AppColors.f1DarkBg,
                  AppColors.f1Turquoise.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.f1Red.withValues(alpha: 0.05),
                  AppColors.lightBg,
                  Colors.white,
                ],
        ),
      ),
      child: child,
    );
  }
}
