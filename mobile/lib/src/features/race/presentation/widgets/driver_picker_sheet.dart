import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';
import 'package:forma1_tipp/src/features/race/domain/team.dart';

class DriverPickerSheet extends StatefulWidget {
  const DriverPickerSheet({
    super.key,
    required this.drivers,
    required this.teams,
    this.excludeDriverIds = const {},
    this.title,
  });

  final List<Driver> drivers;
  final List<Team> teams;
  final Set<String> excludeDriverIds;
  final String? title;

  static Future<Driver?> show(
    BuildContext context, {
    required List<Driver> drivers,
    required List<Team> teams,
    Set<String> excludeDriverIds = const {},
    String? title,
  }) {
    return showModalBottomSheet<Driver>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverPickerSheet(
        drivers: drivers,
        teams: teams,
        excludeDriverIds: excludeDriverIds,
        title: title,
      ),
    );
  }

  @override
  State<DriverPickerSheet> createState() => _DriverPickerSheetState();
}

class _DriverPickerSheetState extends State<DriverPickerSheet> {
  String _query = '';

  Map<Team, List<Driver>> get _groupedDrivers {
    final teamMap = {for (final t in widget.teams) t.id: t};
    final filtered = widget.drivers
        .where((d) => !widget.excludeDriverIds.contains(d.id))
        .where((d) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return d.fullName.toLowerCase().contains(q) ||
          d.shortCode.toLowerCase().contains(q);
    }).toList();

    final grouped = <Team, List<Driver>>{};
    for (final driver in filtered) {
      final team = teamMap[driver.teamId];
      if (team != null) {
        grouped.putIfAbsent(team, () => []).add(driver);
      }
    }
    return grouped;
  }

  Color _teamColor(Team team) {
    return AppColors.teamColors[team.id] ??
        Color(int.parse('FF${team.color}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _groupedDrivers;
    final sortedTeams = groups.keys.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.f1DarkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.title ?? 'Select Driver',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search driver...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: sortedTeams.length,
                  itemBuilder: (context, teamIdx) {
                    final team = sortedTeams[teamIdx];
                    final drivers = groups[team]!;
                    final color = _teamColor(team);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8, top: 8, bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  team.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          ...drivers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final driver = entry.value;
                            return _DriverTile(
                              driver: driver,
                              teamColor: color,
                              onTap: () => Navigator.of(context).pop(driver),
                            )
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: (teamIdx * 80) + (idx * 40),
                                  ),
                                  duration: 250.ms,
                                )
                                .slideX(begin: 0.05, end: 0);
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({
    required this.driver,
    required this.teamColor,
    required this.onTap,
  });

  final Driver driver;
  final Color teamColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: teamColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${driver.number}',
                style: TextStyle(
                  color: teamColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    driver.shortCode,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: Colors.grey.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
