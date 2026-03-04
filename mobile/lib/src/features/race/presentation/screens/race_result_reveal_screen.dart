import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/utils/scoring.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/race/data/race_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/race/domain/race_prediction.dart';
import 'package:forma1_tipp/src/features/race/domain/race_result.dart';
import 'package:forma1_tipp/src/features/race/domain/team.dart';

class RaceResultRevealScreen extends ConsumerStatefulWidget {
  const RaceResultRevealScreen({super.key, required this.raceId});

  final String raceId;

  @override
  ConsumerState<RaceResultRevealScreen> createState() =>
      _RaceResultRevealScreenState();
}

class _RaceResultRevealScreenState
    extends ConsumerState<RaceResultRevealScreen> {
  late final ConfettiController _confettiController;
  int _revealStep = -1;
  bool _revealStarted = false;

  static const _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _startReveal(RacePrediction prediction, RaceResult result) async {
    if (_revealStarted) return;
    _revealStarted = true;

    for (int i = 0; i < _totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _revealStep = i);

      if (i == _totalSteps - 1 && prediction.p1 == result.p1) {
        _confettiController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final raceAsync = ref.watch(raceProvider(widget.raceId));
    final resultAsync = ref.watch(raceResultProvider(widget.raceId));
    final driversAsync = ref.watch(allDriversProvider);
    final teamsAsync = ref.watch(allTeamsProvider);

    final uid =
        ref.watch(authControllerProvider).valueOrNull?.firebaseUser?.uid;
    final predictionAsync = uid != null
        ? ref.watch(
            userPredictionProvider((raceId: widget.raceId, uid: uid)))
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Race Results'),
        backgroundColor: Colors.transparent,
      ),
      body: AppGradientBackground(
        child: Stack(
          children: [
            SafeArea(
              child: _buildContent(
                context,
                raceAsync,
                resultAsync,
                predictionAsync,
                driversAsync,
                teamsAsync,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                maxBlastForce: 40,
                minBlastForce: 15,
                colors: const [
                  AppColors.f1Gold,
                  AppColors.f1Red,
                  AppColors.f1Turquoise,
                  Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<Race?> raceAsync,
    AsyncValue<RaceResult?> resultAsync,
    AsyncValue<RacePrediction?>? predictionAsync,
    AsyncValue<List<Driver>> driversAsync,
    AsyncValue<List<Team>> teamsAsync,
  ) {
    final race = raceAsync.valueOrNull;
    final result = resultAsync.valueOrNull;
    final prediction = predictionAsync?.valueOrNull;
    final drivers = driversAsync.valueOrNull ?? [];
    final teams = teamsAsync.valueOrNull ?? [];

    if (raceAsync.isLoading || resultAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (race == null || result == null) {
      return const Center(child: Text('Results not available yet'));
    }

    if (prediction == null) {
      return const Center(child: Text('No prediction found'));
    }

    if (!_revealStarted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _startReveal(prediction, result));
    }

    final driverMap = {for (final d in drivers) d.id: d};
    final teamMap = {for (final t in teams) t.id: t};
    final breakdown = calculateScoringBreakdown(prediction, result);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(race.flagEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  race.nameEn,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text(
            'Result Reveal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.f1Turquoise,
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          _RevealCard(
            step: 0,
            currentStep: _revealStep,
            label: 'Fastest Lap',
            icon: Icons.timer,
            color: AppColors.f1Red,
            predictedDriverId: prediction.fastestLap,
            actualDriverId: result.fastestLap,
            points: breakdown.fastestLapPoints,
            driverMap: driverMap,
            teamMap: teamMap,
          ),
          const SizedBox(height: 10),
          _RevealCard(
            step: 1,
            currentStep: _revealStep,
            label: 'Pole Position',
            icon: Icons.speed,
            color: AppColors.f1Turquoise,
            predictedDriverId: prediction.pole,
            actualDriverId: result.pole,
            points: breakdown.polePoints,
            driverMap: driverMap,
            teamMap: teamMap,
          ),
          const SizedBox(height: 10),
          _RevealCard(
            step: 2,
            currentStep: _revealStep,
            label: 'P3',
            icon: Icons.emoji_events,
            color: AppColors.f1Bronze,
            predictedDriverId: prediction.p3,
            actualDriverId: result.p3,
            points: breakdown.p3Points,
            driverMap: driverMap,
            teamMap: teamMap,
          ),
          const SizedBox(height: 10),
          _RevealCard(
            step: 3,
            currentStep: _revealStep,
            label: 'P2',
            icon: Icons.emoji_events,
            color: AppColors.f1Silver,
            predictedDriverId: prediction.p2,
            actualDriverId: result.p2,
            points: breakdown.p2Points,
            driverMap: driverMap,
            teamMap: teamMap,
          ),
          const SizedBox(height: 10),
          _RevealCard(
            step: 4,
            currentStep: _revealStep,
            label: 'P1',
            icon: Icons.emoji_events,
            color: AppColors.f1Gold,
            predictedDriverId: prediction.p1,
            actualDriverId: result.p1,
            points: breakdown.p1Points,
            driverMap: driverMap,
            teamMap: teamMap,
          ),
          const SizedBox(height: 24),
          if (_revealStep >= _totalSteps - 1)
            _TotalPointsCard(breakdown: breakdown)
                .animate()
                .fadeIn(duration: 600.ms)
                .scaleXY(begin: 0.8, end: 1.0, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          if (_revealStep >= _totalSteps - 1)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({
    required this.step,
    required this.currentStep,
    required this.label,
    required this.icon,
    required this.color,
    required this.predictedDriverId,
    required this.actualDriverId,
    required this.points,
    required this.driverMap,
    required this.teamMap,
  });

  final int step;
  final int currentStep;
  final String label;
  final IconData icon;
  final Color color;
  final String predictedDriverId;
  final String actualDriverId;
  final int points;
  final Map<String, Driver> driverMap;
  final Map<String, Team> teamMap;

  bool get _isRevealed => currentStep >= step;
  bool get _isCorrect => predictedDriverId == actualDriverId;

  String _driverName(String id) => driverMap[id]?.fullName ?? id;

  Color _teamColor(String driverId) {
    final driver = driverMap[driverId];
    if (driver == null) return Colors.grey;
    final team = teamMap[driver.teamId];
    if (team == null) return Colors.grey;
    return AppColors.teamColors[team.id] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep < step - 1) {
      return GlassCard(
        opacity: 0.04,
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.3), size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Icon(Icons.lock, size: 16, color: Colors.white.withValues(alpha: 0.15)),
          ],
        ),
      );
    }

    if (currentStep == step - 1) {
      return GlassCard(
        opacity: 0.04,
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.5), size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Text(
              'Your pick: ${_driverName(predictedDriverId)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    return GlassCard(
      borderOpacity: _isCorrect ? 0.3 : 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (points > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$points pts',
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: -0.5, end: 0, duration: 500.ms),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DriverSlotLabel(
                  title: 'Your pick',
                  driverName: _driverName(predictedDriverId),
                  teamColor: _teamColor(predictedDriverId),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _isRevealed
                    ? (_isCorrect
                        ? const Icon(Icons.check_circle,
                            color: AppColors.successGreen, size: 28)
                        : (points > 0
                            ? const Icon(Icons.swap_horiz,
                                color: AppColors.jokerGold, size: 28)
                            : const Icon(Icons.cancel,
                                color: AppColors.errorRed, size: 28)))
                    : const SizedBox(width: 28),
              ),
              Expanded(
                child: _DriverSlotLabel(
                  title: 'Actual',
                  driverName: _driverName(actualDriverId),
                  teamColor: _teamColor(actualDriverId),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _DriverSlotLabel extends StatelessWidget {
  const _DriverSlotLabel({
    required this.title,
    required this.driverName,
    required this.teamColor,
    this.alignEnd = false,
  });

  final String title;
  final String driverName;
  final Color teamColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: teamColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                driverName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: teamColor, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TotalPointsCard extends StatelessWidget {
  const _TotalPointsCard({required this.breakdown});
  final ScoringBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderOpacity: 0.2,
      child: Column(
        children: [
          Text(
            'Total Points',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (breakdown.jokerActive) ...[
            Text(
              '${breakdown.subtotal}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.jokerGold, size: 20),
                const SizedBox(width: 6),
                Text(
                  'x2',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.jokerGold,
                        fontWeight: FontWeight.w800,
                      ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        begin: 1.0,
                        end: 1.2,
                        duration: 600.ms,
                        curve: Curves.easeInOut),
              ],
            ),
            const SizedBox(height: 4),
          ],
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: breakdown.total),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '$value',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: breakdown.total > 0
                          ? AppColors.f1Gold
                          : AppColors.errorRed,
                    ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'points',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
