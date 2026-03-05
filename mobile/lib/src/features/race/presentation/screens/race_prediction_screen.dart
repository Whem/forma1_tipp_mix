import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/race/data/race_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/race/domain/race_prediction.dart';
import 'package:forma1_tipp/src/features/race/domain/team.dart';
import 'package:forma1_tipp/src/features/gamification/data/gamification_repository.dart';
import 'package:forma1_tipp/src/features/race/presentation/widgets/driver_picker_sheet.dart';

class RacePredictionScreen extends ConsumerStatefulWidget {
  const RacePredictionScreen({super.key, required this.raceId});

  final String raceId;

  @override
  ConsumerState<RacePredictionScreen> createState() =>
      _RacePredictionScreenState();
}

class _RacePredictionScreenState extends ConsumerState<RacePredictionScreen> {
  String? _p1, _p2, _p3, _pole, _fastestLap;
  bool _jokerActive = false;
  bool _submitting = false;
  late final ConfettiController _confettiController;
  Timer? _countdownTimer;
  Duration _timeUntilLock = Duration.zero;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(Race race) {
    _countdownTimer?.cancel();
    _updateCountdown(race);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(race);
    });
  }

  void _updateCountdown(Race race) {
    final lockTime = race.raceDate.subtract(const Duration(minutes: 30));
    final remaining = lockTime.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _timeUntilLock = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d <= Duration.zero) return 'Locked';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m';
    if (hours > 0) return '${hours}h ${mins}m ${secs}s';
    return '${mins}m ${secs}s';
  }

  bool get _isComplete =>
      _p1 != null &&
      _p2 != null &&
      _p3 != null &&
      _pole != null &&
      _fastestLap != null;

  Future<void> _pickDriver({
    required List<Driver> drivers,
    required List<Team> teams,
    required String title,
    required ValueChanged<String> onSelected,
    Set<String> excludeIds = const {},
  }) async {
    final driver = await DriverPickerSheet.show(
      context,
      drivers: drivers,
      teams: teams,
      excludeDriverIds: excludeIds,
      title: title,
    );
    if (driver != null && mounted) {
      onSelected(driver.id);
    }
  }

  Future<void> _submit() async {
    if (!_isComplete || _submitting) return;

    final uid =
        ref.read(authControllerProvider).valueOrNull?.firebaseUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);

    try {
      final prediction = RacePrediction(
        raceId: widget.raceId,
        uid: uid,
        p1: _p1!,
        p2: _p2!,
        p3: _p3!,
        pole: _pole!,
        fastestLap: _fastestLap!,
        isJoker: _jokerActive,
        submittedAt: DateTime.now(),
      );

      await ref.read(raceRepositoryProvider).submitPrediction(prediction);

      if (_jokerActive) {
        await ref.read(firestoreProvider).collection('users').doc(uid).update({
          'jokersRemaining': FieldValue.increment(-1),
        });
      }

      await ref.read(gamificationRepositoryProvider).checkAndAwardAchievements(uid);

      _confettiController.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prediction saved!')),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final raceAsync = ref.watch(raceProvider(widget.raceId));
    final driversAsync = ref.watch(allDriversProvider);
    final teamsAsync = ref.watch(allTeamsProvider);
    final uid =
        ref.watch(authControllerProvider).valueOrNull?.firebaseUser?.uid;
    final userAsync = ref.watch(currentUserProvider);

    final predictionAsync = uid != null
        ? ref.watch(
            userPredictionProvider((raceId: widget.raceId, uid: uid)))
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(Localizations.localeOf(context).languageCode == 'hu' ? 'Futam tipp' : 'Race Prediction'),
        backgroundColor: Colors.transparent,
      ),
      body: AppGradientBackground(
        child: Stack(
          children: [
            raceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (race) {
                if (race == null) {
                  return const Center(child: Text('Race not found'));
                }

                if (_countdownTimer == null) _startCountdown(race);

                final isLocked = race.isLocked;
                final existingPrediction = predictionAsync?.valueOrNull;

                if (isLocked && existingPrediction != null) {
                  return _buildLockedView(
                    context,
                    race,
                    existingPrediction,
                    driversAsync.valueOrNull ?? [],
                    teamsAsync.valueOrNull ?? [],
                  );
                }

                if (existingPrediction != null &&
                    _p1 == null &&
                    _p2 == null) {
                  _p1 = existingPrediction.p1;
                  _p2 = existingPrediction.p2;
                  _p3 = existingPrediction.p3;
                  _pole = existingPrediction.pole;
                  _fastestLap = existingPrediction.fastestLap;
                  _jokerActive = existingPrediction.isJoker;
                }

                return driversAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (drivers) => teamsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (teams) => _buildForm(
                      context,
                      race,
                      drivers,
                      teams,
                      isLocked,
                      userAsync.valueOrNull?.jokersRemaining ?? 0,
                    ),
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.f1Red,
                  AppColors.f1Gold,
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

  Widget _buildForm(
    BuildContext context,
    Race race,
    List<Driver> drivers,
    List<Team> teams,
    bool isLocked,
    int jokersRemaining,
  ) {
    final driverMap = {for (final d in drivers) d.id: d};
    final teamMap = {for (final t in teams) t.id: t};

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _RaceHeader(race: race)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1),
            const SizedBox(height: 8),
            _CountdownBadge(
              label: _formatDuration(_timeUntilLock),
              isLocked: isLocked,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.f1Gold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Podium',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PodiumSlot(
                    label: 'P1',
                    color: AppColors.f1Gold,
                    driver: _p1 != null ? driverMap[_p1] : null,
                    team: _p1 != null ? teamMap[driverMap[_p1]?.teamId] : null,
                    onTap: isLocked
                        ? null
                        : () => _pickDriver(
                              drivers: drivers,
                              teams: teams,
                              title: 'Select P1',
                              excludeIds: {
                                if (_p2 != null) _p2!,
                                if (_p3 != null) _p3!,
                              },
                              onSelected: (id) => setState(() => _p1 = id),
                            ),
                  ),
                  const SizedBox(height: 8),
                  _PodiumSlot(
                    label: 'P2',
                    color: AppColors.f1Silver,
                    driver: _p2 != null ? driverMap[_p2] : null,
                    team: _p2 != null ? teamMap[driverMap[_p2]?.teamId] : null,
                    onTap: isLocked
                        ? null
                        : () => _pickDriver(
                              drivers: drivers,
                              teams: teams,
                              title: 'Select P2',
                              excludeIds: {
                                if (_p1 != null) _p1!,
                                if (_p3 != null) _p3!,
                              },
                              onSelected: (id) => setState(() => _p2 = id),
                            ),
                  ),
                  const SizedBox(height: 8),
                  _PodiumSlot(
                    label: 'P3',
                    color: AppColors.f1Bronze,
                    driver: _p3 != null ? driverMap[_p3] : null,
                    team: _p3 != null ? teamMap[driverMap[_p3]?.teamId] : null,
                    onTap: isLocked
                        ? null
                        : () => _pickDriver(
                              drivers: drivers,
                              teams: teams,
                              title: 'Select P3',
                              excludeIds: {
                                if (_p1 != null) _p1!,
                                if (_p2 != null) _p2!,
                              },
                              onSelected: (id) => setState(() => _p3 = id),
                            ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed,
                          color: AppColors.f1Turquoise, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Pole Position',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PodiumSlot(
                    label: 'POLE',
                    color: AppColors.f1Turquoise,
                    driver: _pole != null ? driverMap[_pole] : null,
                    team: _pole != null
                        ? teamMap[driverMap[_pole]?.teamId]
                        : null,
                    onTap: isLocked
                        ? null
                        : () => _pickDriver(
                              drivers: drivers,
                              teams: teams,
                              title: 'Select Pole Position',
                              onSelected: (id) => setState(() => _pole = id),
                            ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          color: AppColors.f1Red, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Fastest Lap',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PodiumSlot(
                    label: 'FL',
                    color: AppColors.f1Red,
                    driver:
                        _fastestLap != null ? driverMap[_fastestLap] : null,
                    team: _fastestLap != null
                        ? teamMap[driverMap[_fastestLap]?.teamId]
                        : null,
                    onTap: isLocked
                        ? null
                        : () => _pickDriver(
                              drivers: drivers,
                              teams: teams,
                              title: 'Select Fastest Lap',
                              onSelected: (id) =>
                                  setState(() => _fastestLap = id),
                            ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05),
            if (jokersRemaining > 0 && !isLocked) ...[
              const SizedBox(height: 14),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.jokerGold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Joker (2x points)',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$jokersRemaining remaining',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _jokerActive,
                      onChanged: (v) => setState(() => _jokerActive = v),
                      activeColor: AppColors.jokerGold,
                      activeTrackColor:
                          AppColors.jokerGold.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ],
            const SizedBox(height: 24),
            if (!isLocked)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isComplete && !_submitting ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Prediction'),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedView(
    BuildContext context,
    Race race,
    RacePrediction prediction,
    List<Driver> drivers,
    List<Team> teams,
  ) {
    final driverMap = {for (final d in drivers) d.id: d};
    final teamMap = {for (final t in teams) t.id: t};

    Widget slot(String label, Color color, String? driverId) {
      final driver = driverId != null ? driverMap[driverId] : null;
      final team = driver != null ? teamMap[driver.teamId] : null;
      return _PodiumSlot(label: label, color: color, driver: driver, team: team);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            _RaceHeader(race: race),
            const SizedBox(height: 8),
            const _CountdownBadge(label: 'Locked', isLocked: true),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Prediction',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (prediction.isJoker) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.jokerGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: AppColors.jokerGold, size: 16),
                          SizedBox(width: 4),
                          Text('Joker Active (2x)',
                              style: TextStyle(
                                  color: AppColors.jokerGold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  slot('P1', AppColors.f1Gold, prediction.p1),
                  const SizedBox(height: 8),
                  slot('P2', AppColors.f1Silver, prediction.p2),
                  const SizedBox(height: 8),
                  slot('P3', AppColors.f1Bronze, prediction.p3),
                  const SizedBox(height: 12),
                  slot('POLE', AppColors.f1Turquoise, prediction.pole),
                  const SizedBox(height: 8),
                  slot('FL', AppColors.f1Red, prediction.fastestLap),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _RaceHeader extends StatelessWidget {
  const _RaceHeader({required this.race});
  final Race race;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(race.flagEmoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            race.nameEn,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.label, required this.isLocked});
  final String label;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.errorRed.withValues(alpha: 0.15)
            : AppColors.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? AppColors.errorRed.withValues(alpha: 0.3)
              : AppColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock : Icons.schedule,
            size: 16,
            color: isLocked ? AppColors.errorRed : AppColors.successGreen,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isLocked ? AppColors.errorRed : AppColors.successGreen,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.label,
    required this.color,
    this.driver,
    this.team,
    this.onTap,
  });

  final String label;
  final Color color;
  final Driver? driver;
  final Team? team;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final teamColor =
        team != null ? (AppColors.teamColors[team!.id] ?? color) : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: driver != null
              ? teamColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: driver != null
                ? teamColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: driver != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver!.fullName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (team != null)
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: teamColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                team!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    )
                  : Text(
                      'Tap to select',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                    ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right,
                  size: 20, color: Colors.grey.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
