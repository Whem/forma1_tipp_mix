import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/data/auth_repository.dart';
import 'package:forma1_tipp/src/features/groups/data/group_repository.dart';
import 'package:forma1_tipp/src/features/groups/domain/friend_group.dart';
import 'package:forma1_tipp/src/features/standings/data/standings_repository.dart';
import 'package:forma1_tipp/src/features/standings/domain/user_standing.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AIFilter _aiFilter = AIFilter.all;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return Scaffold(
      appBar: AppBar(
        title: Text(isHu ? 'Ranglista' : 'Standings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.f1Red,
          tabs: [
            Tab(text: isHu ? 'Globális' : 'Global'),
            Tab(text: isHu ? 'Csoportjaim' : 'My Groups'),
          ],
        ),
      ),
      body: AppGradientBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _GlobalTab(aiFilter: _aiFilter, onFilterChanged: (f) {
              setState(() => _aiFilter = f);
            }, isHu: isHu),
            _GroupTab(
              selectedGroupId: _selectedGroupId,
              onGroupChanged: (id) => setState(() => _selectedGroupId = id),
              isHu: isHu,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalTab extends ConsumerWidget {
  const _GlobalTab({
    required this.aiFilter,
    required this.onFilterChanged,
    required this.isHu,
  });

  final AIFilter aiFilter;
  final ValueChanged<AIFilter> onFilterChanged;
  final bool isHu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(filteredStandingsProvider(aiFilter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<AIFilter>(
            segments: [
              ButtonSegment(value: AIFilter.all, label: Text(isHu ? 'Mind' : 'All')),
              ButtonSegment(value: AIFilter.humanOnly, label: Text(isHu ? 'Emberi' : 'Human')),
              ButtonSegment(value: AIFilter.aiOnly, label: Text('AI')),
            ],
            selected: {aiFilter},
            onSelectionChanged: (s) => onFilterChanged(s.first),
            style: ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ),
        Expanded(
          child: standingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (standings) => _StandingsList(standings: standings, isHu: isHu),
          ),
        ),
      ],
    );
  }
}

class _GroupTab extends ConsumerWidget {
  const _GroupTab({
    required this.selectedGroupId,
    required this.onGroupChanged,
    required this.isHu,
  });

  final String? selectedGroupId;
  final ValueChanged<String?> onGroupChanged;
  final bool isHu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final groupsAsync = ref.watch(myGroupsProvider(uid));

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Text(
              isHu ? 'Még nincsenek csoportjaid' : 'No groups yet',
              style: const TextStyle(color: Colors.white38),
            ),
          );
        }

        final selected = selectedGroupId ?? (groups.isNotEmpty ? groups.first.id : null);
        final selectedGroup = groups.cast<FriendGroup?>().firstWhere(
              (g) => g?.id == selected,
              orElse: () => groups.first,
            );

        if (selectedGroup == null) return const SizedBox.shrink();

        final groupStandings = ref.watch(
          groupStandingsProvider(selectedGroup.memberUids),
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DropdownButtonFormField<String>(
                value: selected,
                items: groups
                    .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                    .toList(),
                onChanged: onGroupChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.group),
                  labelText: isHu ? 'Csoport' : 'Group',
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: groupStandings.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (standings) => _StandingsList(standings: standings, isHu: isHu),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StandingsList extends StatelessWidget {
  const _StandingsList({required this.standings, required this.isHu});

  final List<UserStanding> standings;
  final bool isHu;

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return Center(
        child: Text(isHu ? 'Még nincsenek eredmények' : 'No standings yet'),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          _Podium(standings: standings),
          if (standings.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: _TopChart(standings: standings.take(5).toList()),
            ),
          ..._buildRemainingList(standings),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildRemainingList(List<UserStanding> standings) {
    if (standings.length <= 3) return [];
    return standings.skip(3).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final user = entry.value;
      return _StandingRow(position: index + 4, user: user)
          .animate()
          .fadeIn(delay: Duration(milliseconds: 80 * index))
          .slideX(begin: 0.15, end: 0);
    }).toList();
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.standings});

  final List<UserStanding> standings;

  @override
  Widget build(BuildContext context) {
    final p1 = standings.isNotEmpty ? standings[0] : null;
    final p2 = standings.length > 1 ? standings[1] : null;
    final p3 = standings.length > 2 ? standings[2] : null;

    return SizedBox(
      height: 320,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (p2 != null)
            Expanded(
              child: _PodiumSlot(
                user: p2,
                position: 2,
                height: 140,
                color: AppColors.f1Silver,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            ),
          if (p1 != null)
            Expanded(
              child: _PodiumSlot(
                user: p1,
                position: 1,
                height: 180,
                color: AppColors.f1Gold,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, end: 0),
            ),
          if (p3 != null)
            Expanded(
              child: _PodiumSlot(
                user: p3,
                position: 3,
                height: 110,
                color: AppColors.f1Bronze,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
            ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.user,
    required this.position,
    required this.height,
    required this.color,
  });

  final UserStanding user;
  final int position;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: position == 1 ? 36 : 28,
                backgroundColor: user.isAI ? const Color(0xFF1A1A2E) : Colors.grey.shade800,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? (user.isAI
                        ? Icon(Icons.smart_toy_rounded,
                            size: position == 1 ? 32 : 24,
                            color: const Color(0xFF00D4FF))
                        : Icon(Icons.person, size: position == 1 ? 32 : 24))
                    : null,
              ),
            ),
            if (user.isAI)
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, size: 10, color: Colors.black),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isAI)
              const Padding(
                padding: EdgeInsets.only(right: 3),
                child: Icon(Icons.smart_toy_rounded, size: 12, color: Color(0xFF00D4FF)),
              ),
            Flexible(
              child: Text(
                user.displayName,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: user.isAI ? const Color(0xFF00D4FF) : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Text(
          '${user.totalPoints} pts',
          style: textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.4)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              'P$position',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.position, required this.user});

  final int position;
  final UserStanding user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$position',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: user.isAI ? const Color(0xFF1A1A2E) : Colors.grey.shade700,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? (user.isAI
                          ? const Icon(Icons.smart_toy_rounded, size: 18, color: Color(0xFF00D4FF))
                          : const Icon(Icons.person, size: 18))
                      : null,
                ),
                if (user.isAI)
                  Positioned(
                    right: -3,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, size: 8, color: Colors.black),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: user.isAI ? const Color(0xFF00D4FF) : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user.isAI)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${user.totalPoints} pts',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.f1Turquoise,
              ),
            ),
            const SizedBox(width: 4),
            _changeIcon(),
          ],
        ),
      ),
    );
  }

  Widget _changeIcon() {
    if (user.correctP1Count > 3) {
      return const Icon(Icons.arrow_upward, color: AppColors.successGreen, size: 16);
    }
    if (user.correctP1Count == 0 && user.racesParticipated > 2) {
      return const Icon(Icons.arrow_downward, color: AppColors.errorRed, size: 16);
    }
    return const Icon(Icons.remove, color: Colors.grey, size: 16);
  }
}

class _TopChart extends StatelessWidget {
  const _TopChart({required this.standings});

  final List<UserStanding> standings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxPts = standings.isNotEmpty
        ? standings.map((s) => s.totalPoints).reduce((a, b) => a > b ? a : b).toDouble()
        : 1.0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxPts * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${standings[group.x].displayName}\n${rod.toY.toInt()} pts',
                    TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= standings.length) {
                      return const SizedBox.shrink();
                    }
                    final name = standings[idx].displayName;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        name.length > 6 ? '${name.substring(0, 6)}.' : name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: standings.asMap().entries.map((entry) {
              final colors = [
                AppColors.f1Gold,
                AppColors.f1Silver,
                AppColors.f1Bronze,
                AppColors.f1Turquoise,
                AppColors.f1Red,
              ];
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.totalPoints.toDouble(),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        colors[entry.key % colors.length].withValues(alpha: 0.5),
                        colors[entry.key % colors.length],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
