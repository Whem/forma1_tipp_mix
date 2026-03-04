import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';

class StreakWidget extends ConsumerWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final streak = user?.streak ?? 0;
    final theme = Theme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          children: [
            _fireIcon(streak),
            const SizedBox(height: 6),
            Text(
              '$streak',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: streak > 0 ? AppColors.streakFire : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isHu ? 'Sorozat' : 'Streak',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fireIcon(int streak) {
    final icon = Text(
      '🔥',
      style: TextStyle(fontSize: streak > 0 ? 30 : 24),
    );

    if (streak <= 0) return icon;

    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms)
        .then()
        .shimmer(
          duration: 1200.ms,
          color: AppColors.streakFire.withValues(alpha: 0.4),
        );
  }
}

class JokerWidget extends ConsumerWidget {
  const JokerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final jokersLeft = user?.jokersRemaining ?? 0;
    final theme = Theme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          children: [
            Text(
              '🃏',
              style: TextStyle(fontSize: jokersLeft > 0 ? 30 : 24),
            ),
            const SizedBox(height: 6),
            Text(
              '$jokersLeft',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: jokersLeft > 0 ? AppColors.jokerGold : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isHu ? 'Joker' : 'Jokers',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
