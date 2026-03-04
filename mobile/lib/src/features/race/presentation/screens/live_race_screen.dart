import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/race/data/race_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';
import 'package:forma1_tipp/src/features/race/domain/live_race_data.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/race/domain/team.dart';

class LiveRaceScreen extends ConsumerWidget {
  const LiveRaceScreen({super.key, required this.raceId});

  final String raceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(raceProvider(raceId));
    final liveAsync = ref.watch(liveRaceProvider(raceId));
    final driversAsync = ref.watch(allDriversProvider);
    final teamsAsync = ref.watch(allTeamsProvider);

    final uid =
        ref.watch(authControllerProvider).valueOrNull?.firebaseUser?.uid;
    final predictionAsync = uid != null
        ? ref.watch(userPredictionProvider((raceId: raceId, uid: uid)))
        : null;

    final predictedPodium = <String>{};
    final prediction = predictionAsync?.valueOrNull;
    if (prediction != null) {
      predictedPodium.addAll([prediction.p1, prediction.p2, prediction.p3]);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live Race'),
        backgroundColor: Colors.transparent,
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: raceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (race) {
              if (race == null) {
                return const Center(child: Text('Race not found'));
              }

              return liveAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (liveData) {
                  if (liveData == null) {
                    return _buildWaitingView(context, race);
                  }

                  final drivers = driversAsync.valueOrNull ?? [];
                  final teams = teamsAsync.valueOrNull ?? [];

                  return _buildLiveView(
                    context,
                    race,
                    liveData,
                    drivers,
                    teams,
                    predictedPodium,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingView(BuildContext context, Race race) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(race.flagEmoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            race.nameEn,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          const Text('Waiting for live data...'),
        ],
      ),
    );
  }

  Widget _buildLiveView(
    BuildContext context,
    Race race,
    LiveRaceData liveData,
    List<Driver> drivers,
    List<Team> teams,
    Set<String> predictedPodium,
  ) {
    final driverMap = {for (final d in drivers) d.id: d};
    final teamMap = {for (final t in teams) t.id: t};

    final sortedPositions = List.of(liveData.positions)
      ..sort((a, b) => a.position.compareTo(b.position));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(race.flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  race.nameEn,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _LiveBadge(status: liveData.status),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Lap ${liveData.currentLap} / ${liveData.totalLaps}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.f1Turquoise,
                ),
          ),
        ),
        if (liveData.status == 'safety_car')
          _StatusBanner(
            label: 'SAFETY CAR',
            color: AppColors.jokerGold,
            icon: Icons.warning_amber_rounded,
          ).animate().fadeIn().shake(hz: 2, rotation: 0.01),
        if (liveData.status == 'red_flag')
          _StatusBanner(
            label: 'RED FLAG',
            color: AppColors.errorRed,
            icon: Icons.flag,
          ).animate().fadeIn().shake(hz: 2, rotation: 0.01),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: sortedPositions.length,
            itemBuilder: (context, index) {
              final pos = sortedPositions[index];
              final driver = driverMap[pos.driverId];
              final team = driver != null ? teamMap[driver.teamId] : null;
              final isPredicted = predictedPodium.contains(pos.driverId);
              final teamColor =
                  team != null ? (AppColors.teamColors[team.id]) : null;

              return _PositionTile(
                key: ValueKey(pos.driverId),
                position: pos,
                driver: driver,
                teamColor: teamColor ?? Colors.grey,
                teamName: team?.name ?? '',
                isPredicted: isPredicted,
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: index * 30),
                    duration: 300.ms,
                  )
                  .slideX(begin: 0.03, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.status});
  final String status;

  String get _label {
    switch (status) {
      case 'racing':
        return 'LIVE';
      case 'safety_car':
        return 'SC';
      case 'red_flag':
        return 'RED';
      case 'finished':
        return 'FINISHED';
      default:
        return 'PRE-RACE';
    }
  }

  Color get _color {
    switch (status) {
      case 'racing':
        return AppColors.f1Red;
      case 'safety_car':
        return AppColors.jokerGold;
      case 'red_flag':
        return AppColors.errorRed;
      case 'finished':
        return AppColors.successGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    if (status == 'racing') {
      return badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 800.ms);
    }
    return badge;
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  const _PositionTile({
    super.key,
    required this.position,
    this.driver,
    required this.teamColor,
    required this.teamName,
    required this.isPredicted,
  });

  final LivePosition position;
  final Driver? driver;
  final Color teamColor;
  final String teamName;
  final bool isPredicted;

  @override
  Widget build(BuildContext context) {
    final isRetired = position.retired;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 14,
        opacity: isRetired ? 0.04 : 0.08,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                isRetired ? 'RET' : 'P${position.position}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isRetired ? 11 : 15,
                  color: isRetired
                      ? AppColors.errorRed
                      : position.position <= 3
                          ? [
                              AppColors.f1Gold,
                              AppColors.f1Silver,
                              AppColors.f1Bronze,
                            ][position.position - 1]
                          : null,
                ),
              ),
            ),
            Container(
              width: 4,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver?.fullName ?? position.driverId,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration:
                              isRetired ? TextDecoration.lineThrough : null,
                          color: isRetired
                              ? Colors.grey
                              : null,
                        ),
                  ),
                  Text(
                    teamName,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (position.pitStops > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tire_repair,
                        size: 14,
                        color: Colors.grey.withValues(alpha: 0.6)),
                    const SizedBox(width: 2),
                    Text(
                      '${position.pitStops}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: 70,
              child: Text(
                position.position == 1 ? 'LEADER' : position.gap,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
              ),
            ),
            if (isPredicted) ...[
              const SizedBox(width: 6),
              const Icon(Icons.star, color: AppColors.f1Gold, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
