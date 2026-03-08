import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/services/live_sse_service.dart';
import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/l10n/gen/app_localizations.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';

class LiveRaceScreen extends ConsumerWidget {
  const LiveRaceScreen({super.key, required this.raceId});

  final String raceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(liveRaceSseProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.liveRace ?? 'Live Race'),
        backgroundColor: Colors.transparent,
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: liveAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Connecting...', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('$e', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            data: (state) {
              if (!state.isActive || state.positions.isEmpty) {
                return _buildWaitingView(context);
              }
              return _LiveTabbedView(state: state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_motorsports, size: 64, color: AppColors.f1Red),
          const SizedBox(height: 16),
          Text(
            l10n?.waitingForLiveData ?? 'Waiting for live data...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.liveDataAppears ?? 'Race data will appear automatically.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LiveTabbedView extends StatelessWidget {
  const _LiveTabbedView({required this.state});
  final LiveRaceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header: status + lap
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LiveBadge(status: state.status),
                const SizedBox(width: 12),
                if (state.currentLap > 0)
                  Text(
                    'Lap ${state.currentLap}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.f1Turquoise,
                        ),
                  ),
              ],
            ),
          ),
          if (state.status == 'safety_car')
            _StatusBanner(label: 'SAFETY CAR', color: AppColors.jokerGold, icon: Icons.warning_amber_rounded)
                .animate().fadeIn().shake(hz: 2, rotation: 0.01),
          if (state.status == 'red_flag')
            _StatusBanner(label: 'RED FLAG', color: AppColors.errorRed, icon: Icons.flag)
                .animate().fadeIn().shake(hz: 2, rotation: 0.01),
          const SizedBox(height: 12),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.f1Red.withValues(alpha: 0.5), AppColors.f1Red.withValues(alpha: 0.25)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.f1Red.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerHeight: 0,
              splashBorderRadius: BorderRadius.circular(12),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_motorsports_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('${l10n?.liveDriversTab ?? "Drivers"} (${state.positions.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('${l10n?.livePredictorsTab ?? "Predictions"} (${state.userScores.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _DriversTab(positions: state.positions),
                _UsersTab(scores: state.userScores),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Driver Positions ──

class _DriversTab extends StatelessWidget {
  const _DriversTab({required this.positions});
  final List<SseDriverPosition> positions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final pos = positions[index];
        return _DriverTile(pos: pos)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 20), duration: 200.ms)
            .slideX(begin: 0.02, end: 0);
      },
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.pos});
  final SseDriverPosition pos;

  static const _teamColors = <String, Color>{
    'Ferrari': Color(0xFFDC0000),
    'Mercedes': Color(0xFF00D2BE),
    'Red Bull Racing': Color(0xFF0600EF),
    'McLaren': Color(0xFFFF8700),
    'Aston Martin': Color(0xFF006F62),
    'Alpine': Color(0xFF0090FF),
    'Williams': Color(0xFF005AFF),
    'Racing Bulls': Color(0xFF2B4562),
    'Haas': Color(0xFFB6BABD),
    'Audi': Color(0xFF00594F),
  };

  @override
  Widget build(BuildContext context) {
    final isRetired = pos.retired;
    final teamColor = _teamColors[pos.team] ?? Colors.grey;

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
                isRetired ? 'RET' : 'P${pos.position}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isRetired ? 11 : 15,
                  color: isRetired
                      ? AppColors.errorRed
                      : pos.position <= 3
                          ? [AppColors.f1Gold, AppColors.f1Silver, AppColors.f1Bronze][pos.position - 1]
                          : null,
                ),
              ),
            ),
            Container(
              width: 4,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: teamColor, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pos.name.isNotEmpty ? pos.name : pos.acronym,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: isRetired ? TextDecoration.lineThrough : null,
                          color: isRetired ? Colors.grey : null,
                        ),
                  ),
                  Text(
                    pos.team,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                pos.gap,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: User Prediction Scores ──

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.scores});
  final List<SseUserScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(l10n?.predictorsLoading ?? 'Prediction scores loading...',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(l10n?.predictorsQuotaNote ?? 'Scores will appear when data is available.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        return _UserScoreTile(score: score, rank: index + 1)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 30), duration: 200.ms)
            .slideX(begin: 0.02, end: 0);
      },
    );
  }
}

class _UserScoreTile extends StatelessWidget {
  const _UserScoreTile({required this.score, required this.rank});
  final SseUserScore score;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 14,
        opacity: 0.08,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: rank <= 3
                      ? [AppColors.f1Gold, AppColors.f1Silver, AppColors.f1Bronze][rank - 1]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              backgroundImage: score.avatarUrl.isNotEmpty ? NetworkImage(score.avatarUrl) : null,
              child: score.avatarUrl.isEmpty
                  ? Text(score.displayName.isNotEmpty ? score.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          score.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (score.joker) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.bolt, color: AppColors.jokerGold, size: 16),
                      ],
                    ],
                  ),
                  Text(
                    'P1: ${score.predictions['p1'] ?? '?'} · P2: ${score.predictions['p2'] ?? '?'} · P3: ${score.predictions['p3'] ?? '?'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: score.livePoints > 0
                    ? AppColors.successGreen.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${score.livePoints} pt',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: score.livePoints > 0 ? AppColors.successGreen : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ──

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
