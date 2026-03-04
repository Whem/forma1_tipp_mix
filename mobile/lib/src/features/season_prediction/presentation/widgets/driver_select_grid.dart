import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/race/domain/driver.dart';

class DriverSelectGrid extends StatelessWidget {
  const DriverSelectGrid({
    super.key,
    required this.drivers,
    required this.selectedDriverId,
    required this.onSelect,
  });

  final List<Driver> drivers;
  final String? selectedDriverId;
  final ValueChanged<String> onSelect;

  Color _teamColor(Driver driver) {
    return AppColors.teamColors[driver.teamId] ?? AppColors.f1Red;
  }

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          final isSelected = driver.id == selectedDriverId;
          final color = _teamColor(driver);

          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 2,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: _DriverCard(
                  driver: driver,
                  teamColor: color,
                  isSelected: isSelected,
                  onTap: () => onSelect(driver.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.teamColor,
    required this.isSelected,
    required this.onTap,
  });

  final Driver driver;
  final Color teamColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials =
        '${driver.firstName[0]}${driver.lastName[0]}'.toUpperCase();

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: teamColor, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: teamColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: teamColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${driver.number}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: teamColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (driver.imageUrl != null)
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(driver.imageUrl!),
                backgroundColor: teamColor.withValues(alpha: 0.2),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: teamColor.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: teamColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              driver.lastName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? teamColor : null,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: teamColor, size: 18)
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                  ),
          ],
        ),
      ),
    );
  }
}
