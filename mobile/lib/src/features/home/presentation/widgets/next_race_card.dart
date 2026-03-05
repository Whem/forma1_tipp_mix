import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/core/widgets/shimmer_loading.dart';
import 'package:forma1_tipp/src/features/home/data/home_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';

class NextRaceCard extends ConsumerStatefulWidget {
  const NextRaceCard({super.key});

  @override
  ConsumerState<NextRaceCard> createState() => _NextRaceCardState();
}

class _NextRaceCardState extends ConsumerState<NextRaceCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  void _startCountdown(DateTime raceDate) {
    _updateRemaining(raceDate);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(raceDate);
    });
  }

  void _updateRemaining(DateTime raceDate) {
    final diff = raceDate.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextRace = ref.watch(nextRaceProvider);
    final theme = Theme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return nextRace.when(
      loading: () => const ShimmerCard(height: 180),
      error: (_, __) => const SizedBox.shrink(),
      data: (race) {
        if (race == null) return const SizedBox.shrink();
        _startCountdown(race.raceDate);
        return _buildCard(context, theme, race, isHu);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    Race race,
    bool isHu,
  ) {
    final isLive = _remaining <= const Duration(hours: 2) &&
        _remaining > Duration.zero;
    final dateStr = DateFormat('yyyy. MMM d. – HH:mm').format(race.raceDate);

    return GlassCard(
      onTap: () => context.push('/race/${race.id}/predict'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.f1Red.withValues(alpha: 0.08),
              AppColors.f1Turquoise.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  race.flagEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHu ? race.nameHu : race.nameEn,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        race.circuit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLive) _liveBadge(),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              dateStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            _countdownRow(theme),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/race/${race.id}/predict'),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(isHu ? 'Tippelj!' : 'Predict!'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.f1Red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countdownRow(ThemeData theme) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _countdownUnit(theme, days.toString().padLeft(2, '0'), 'D'),
        _separator(theme),
        _countdownUnit(theme, hours.toString().padLeft(2, '0'), 'H'),
        _separator(theme),
        _countdownUnit(theme, minutes.toString().padLeft(2, '0'), 'M'),
        _separator(theme),
        _countdownUnit(theme, seconds.toString().padLeft(2, '0'), 'S'),
      ],
    );
  }

  Widget _separator(ThemeData theme) {
    return Text(
      ':',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.f1Red.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _countdownUnit(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.f1Red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}
