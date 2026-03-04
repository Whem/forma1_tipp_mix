import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/core/widgets/shimmer_loading.dart';
import 'package:forma1_tipp/src/features/race/data/race_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';

class RaceCalendarScreen extends ConsumerWidget {
  const RaceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final racesAsync = ref.watch(allRacesProvider);

    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    return Scaffold(
      appBar: AppBar(title: Text(isHu ? 'Versenynaptár' : 'Race Calendar')),
      body: AppGradientBackground(
        child: racesAsync.when(
          data: (races) => _RaceList(races: races),
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerCard(height: 100),
            ),
          ),
          error: (e, _) => Center(child: Text(isHu ? 'Hiba: $e' : 'Error: $e')),
        ),
      ),
    );
  }
}

class _RaceList extends StatelessWidget {
  const _RaceList({required this.races});

  final List<Race> races;

  int? get _nextRaceIndex {
    final now = DateTime.now();
    for (var i = 0; i < races.length; i++) {
      if (races[i].raceDate.isAfter(now)) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nextIdx = _nextRaceIndex;

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: races.length,
        itemBuilder: (context, index) {
          final race = races[index];
          final isNext = index == nextIdx;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: isNext
                      ? _NextRaceHeroCard(race: race)
                      : _RaceCard(race: race),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NextRaceHeroCard extends StatefulWidget {
  const _NextRaceHeroCard({required this.race});

  final Race race;

  @override
  State<_NextRaceHeroCard> createState() => _NextRaceHeroCardState();
}

class _NextRaceHeroCardState extends State<_NextRaceHeroCard> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final diff = widget.race.raceDate.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/race/${widget.race.id}/predict'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.f1Red.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'KÖVETKEZŐ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  'R${widget.race.round}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  widget.race.flagEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.race.nameHu,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.race.circuit,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CountdownUnit(value: days, label: 'nap'),
                _CountdownUnit(value: hours, label: 'óra'),
                _CountdownUnit(value: minutes, label: 'perc'),
                _CountdownUnit(value: seconds, label: 'mp'),
              ],
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.15, end: 0),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/race/${widget.race.id}/predict'),
                icon: const Icon(Icons.edit_note),
                label: const Text('Tippelj!'),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.f1Red,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}

class _RaceCard extends StatelessWidget {
  const _RaceCard({required this.race});

  final Race race;

  bool get _isLive {
    final now = DateTime.now();
    final raceStart = race.raceDate;
    final raceEnd = raceStart.add(const Duration(hours: 2));
    return now.isAfter(raceStart) && now.isBefore(raceEnd);
  }

  void _onTap(BuildContext context) {
    if (_isLive) {
      context.push('/race/${race.id}/live');
    } else if (race.isPast) {
      context.push('/race/${race.id}/reveal');
    } else {
      context.push('/race/${race.id}/predict');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _isLive;
    final dateStr = _formatDate(race.raceDate);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _onTap(context),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${race.round}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.f1Red.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Text(race.flagEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  race.nameHu,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${race.circuit} · $dateStr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          if (isLive)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.f1Red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ÉLŐ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 800.ms)
          else if (race.isPast)
            Icon(
              Icons.check_circle_outline,
              color: AppColors.successGreen.withValues(alpha: 0.7),
              size: 22,
            )
          else
            Text(
              'Tippelj!',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.f1Turquoise,
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final months = [
      'jan.',
      'feb.',
      'márc.',
      'ápr.',
      'máj.',
      'jún.',
      'júl.',
      'aug.',
      'szept.',
      'okt.',
      'nov.',
      'dec.',
    ];
    return '${local.year}. ${months[local.month - 1]} ${local.day}.';
  }
}
