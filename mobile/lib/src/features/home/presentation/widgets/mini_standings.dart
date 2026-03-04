import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/core/widgets/shimmer_loading.dart';
import 'package:forma1_tipp/src/features/home/data/home_repository.dart';
import 'package:forma1_tipp/src/features/standings/domain/user_standing.dart';

class MiniStandings extends ConsumerWidget {
  const MiniStandings({super.key});

  static const _medalColors = [
    AppColors.f1Gold,
    AppColors.f1Silver,
    AppColors.f1Bronze,
  ];

  static const _medalIcons = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(topStandingsProvider);
    final theme = Theme.of(context);
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return standings.when(
      loading: () => const ShimmerCard(height: 140),
      error: (_, __) => const SizedBox.shrink(),
      data: (users) {
        if (users.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isHu ? 'Ranglista' : 'Standings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...users.asMap().entries.map(
                    (e) => _standingRow(context, theme, e.key, e.value),
                  ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/standings'),
                  child: Text(
                    isHu ? 'Teljes ranglista →' : 'Full standings →',
                    style: TextStyle(
                      color: AppColors.f1Turquoise,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _standingRow(
    BuildContext context,
    ThemeData theme,
    int index,
    UserStanding user,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(_medalIcons[index], style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: user.isAI
                ? const Color(0xFF1A1A2E)
                : _medalColors[index].withValues(alpha: 0.2),
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? (user.isAI
                    ? const Icon(Icons.smart_toy_rounded,
                        size: 16, color: Color(0xFF00D4FF))
                    : Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _medalColors[index],
                          fontSize: 14,
                        ),
                      ))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    user.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: user.isAI ? const Color(0xFF00D4FF) : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.isAI)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
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
          Text(
            '${user.totalPoints} pts',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _medalColors[index],
            ),
          ),
        ],
      ),
    );
  }
}
