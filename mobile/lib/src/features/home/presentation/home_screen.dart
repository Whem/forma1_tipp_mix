import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:forma1_tipp/src/core/services/update_service.dart';
import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/home/data/home_repository.dart';
import 'package:forma1_tipp/src/features/notifications/data/notification_repository.dart';
import 'package:forma1_tipp/src/features/race/domain/race.dart';
import 'package:forma1_tipp/src/features/season_prediction/data/season_prediction_repository.dart';

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DashboardBody();
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody>
    with TickerProviderStateMixin {
  bool _updateChecked = false;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_updateChecked) {
      _updateChecked = true;
      _checkUpdate();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime target) {
    _updateRemaining(target);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(target);
    });
  }

  void _updateRemaining(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  Future<void> _checkUpdate() async {
    final service = ref.read(updateServiceProvider);
    final update = await service.checkForUpdate();
    if (update != null && mounted) {
      service.showUpdateDialog(context, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final nextRace = ref.watch(nextRaceProvider);
    final theme = Theme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A0000),
            Color(0xFF0D0D0F),
            Color(0xFF0A0A12),
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(theme, user, isHu),
            ),

            // Hero race countdown
            SliverToBoxAdapter(
              child: nextRace.when(
                loading: () => _buildHeroSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (race) {
                  if (race == null) return const SizedBox.shrink();
                  _startCountdown(race.raceDate);
                  return _buildHeroRaceCard(context, theme, race, isHu, size);
                },
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: _buildQuickActions(context, theme, user, isHu, ref),
            ),

            // Stats row
            SliverToBoxAdapter(
              child: _buildStatsRow(theme, user, isHu),
            ),

            // Mini standings
            SliverToBoxAdapter(
              child: _buildMiniStandings(theme, isHu),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, dynamic user, bool isHu) {
    final name = user?.displayName ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // F1 logo style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.f1Red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'F1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHu ? 'Üdv!' : 'Hey!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _NotificationBell(),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildHeroRaceCard(
    BuildContext context,
    ThemeData theme,
    Race race,
    bool isHu,
    Size screenSize,
  ) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final dateStr = DateFormat('yyyy. MMM d. HH:mm').format(race.raceDate.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go('/race/${race.id}/predict');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D0A0A),
                Color(0xFF1A0505),
                Color(0xFF0F0F1A),
              ],
            ),
            border: Border.all(
              color: AppColors.f1Red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.f1Red.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Diagonal red accent
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.f1Red.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Race tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.f1Red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isHu ? 'KÖVETKEZŐ' : 'NEXT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (race.sprintWeekend)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.f1Turquoise.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.f1Turquoise.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'SPRINT',
                                style: TextStyle(
                                  color: AppColors.f1Turquoise,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            'R${race.round}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Race name with flag
                      Row(
                        children: [
                          Text(
                            race.flagEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHu ? race.nameHu : race.nameEn,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${race.circuit} · $dateStr',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Countdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _countdownBlock(days, isHu ? 'NAP' : 'DAY', theme),
                          _countdownSeparator(),
                          _countdownBlock(hours, isHu ? 'ÓRA' : 'HR', theme),
                          _countdownSeparator(),
                          _countdownBlock(minutes, isHu ? 'PERC' : 'MIN', theme),
                          _countdownSeparator(),
                          _countdownBlock(seconds, isHu ? 'MP' : 'SEC', theme),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // CTA button
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.f1Red, Color(0xFFCC0000)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.f1Red.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              context.go('/race/${race.id}/predict');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_note_rounded,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  isHu ? 'TIPPELJ MOST!' : 'PREDICT NOW!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 100.ms)
        .slideY(begin: 0.08, end: 0, duration: 600.ms, delay: 100.ms);
  }

  Widget _countdownBlock(int value, String label, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.f1Red.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _countdownSeparator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppColors.f1Red.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ThemeData theme,
    dynamic user,
    bool isHu,
    WidgetRef ref,
  ) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final hasSeasonPred = uid != null
        ? ref.watch(currentSeasonPredictionProvider(uid)).valueOrNull != null
        : false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _quickActionCard(
              context,
              icon: hasSeasonPred ? Icons.check_circle_rounded : Icons.emoji_events_rounded,
              label: isHu ? 'Szezon tipp' : 'Season tip',
              color: hasSeasonPred ? Colors.green : AppColors.f1Gold,
              onTap: () => context.push('/season-prediction'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickActionCard(
              context,
              icon: Icons.flag_rounded,
              label: isHu ? 'Naptár' : 'Calendar',
              color: AppColors.f1Turquoise,
              onTap: () => context.go('/races'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickActionCard(
              context,
              icon: Icons.military_tech_rounded,
              label: isHu ? 'Eredmények' : 'Achievements',
              color: const Color(0xFFAB47BC),
              onTap: () => context.go('/achievements'),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 250.ms)
        .slideY(begin: 0.06, end: 0, duration: 500.ms, delay: 250.ms);
  }

  Widget _quickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, dynamic user, bool isHu) {
    final streak = user?.streak ?? 0;
    final jokers = user?.jokersRemaining ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Streak card
          Expanded(
            child: _statCard(
              emoji: '🔥',
              value: '$streak',
              label: isHu ? 'Sorozat' : 'Streak',
              accentColor: AppColors.streakFire,
              isActive: streak > 0,
            ),
          ),
          const SizedBox(width: 10),
          // Joker card
          Expanded(
            child: _statCard(
              emoji: '🃏',
              value: '$jokers',
              label: isHu ? 'Joker' : 'Jokers',
              accentColor: AppColors.jokerGold,
              isActive: jokers > 0,
            ),
          ),
          const SizedBox(width: 10),
          // Points card
          Expanded(
            child: _statCard(
              emoji: '🏆',
              value: '0',
              label: isHu ? 'Pont' : 'Points',
              accentColor: AppColors.f1Gold,
              isActive: false,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 350.ms)
        .slideY(begin: 0.06, end: 0, duration: 500.ms, delay: 350.ms);
  }

  Widget _statCard({
    required String emoji,
    required String value,
    required String label,
    required Color accentColor,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isActive ? 0.25 : 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: isActive ? 28 : 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isActive ? accentColor : Colors.white54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStandings(ThemeData theme, bool isHu) {
    final standings = ref.watch(topStandingsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.f1Red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isHu ? 'RANGLISTA' : 'STANDINGS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/standings'),
                  child: Text(
                    isHu ? 'Mind →' : 'All →',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.f1Turquoise,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            standings.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.f1Red,
                  strokeWidth: 2,
                ),
              ),
              error: (_, __) => Text(
                isHu ? 'Nem sikerült betölteni' : 'Failed to load',
                style: TextStyle(color: Colors.white38),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        isHu
                            ? 'Még nincsenek eredmények – kezdj el tippelni!'
                            : 'No results yet – start predicting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: users.asMap().entries.map((e) {
                    final idx = e.key;
                    final user = e.value;
                    const medals = ['🥇', '🥈', '🥉'];
                    const medalColors = [
                      AppColors.f1Gold,
                      AppColors.f1Silver,
                      AppColors.f1Bronze,
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            idx < 3 ? medals[idx] : '${idx + 1}.',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: user.isAI
                                ? const Color(0xFF1A1A2E)
                                : (idx < 3 ? medalColors[idx] : Colors.grey)
                                    .withValues(alpha: 0.2),
                            child: user.isAI
                                ? const Icon(Icons.smart_toy_rounded,
                                    size: 18, color: Color(0xFF00D4FF))
                                : Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: idx < 3
                                          ? medalColors[idx]
                                          : Colors.white54,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: user.isAI
                                          ? const Color(0xFF00D4FF)
                                          : Colors.white,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isAI)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D4FF)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'AI',
                                      style: TextStyle(
                                        color: Color(0xFF00D4FF),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (idx < 3 ? medalColors[idx] : Colors.grey)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${user.totalPoints} pts',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: idx < 3
                                    ? medalColors[idx]
                                    : Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 450.ms)
        .slideY(begin: 0.06, end: 0, duration: 500.ms, delay: 450.ms);
  }

  Widget _buildHeroSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.f1Red,
            strokeWidth: 2,
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
      duration: 1500.ms,
      color: AppColors.f1Red.withValues(alpha: 0.05),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final unreadAsync = uid != null ? ref.watch(unreadCountProvider(uid)) : null;
    final count = unreadAsync?.valueOrNull ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white54),
          onPressed: () => GoRouter.of(context).push('/notifications'),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.f1Red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
