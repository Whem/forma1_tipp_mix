import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/src/core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) {
          HapticFeedback.lightImpact();
          navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
        },
        backgroundColor:
            isDark ? Colors.black.withValues(alpha: 0.95) : AppColors.lightSurface,
        indicatorColor: AppColors.f1Red.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.speed_rounded),
            selectedIcon:
                const Icon(Icons.speed_rounded, color: AppColors.f1Red),
            label: isHu ? 'Főoldal' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_rounded),
            selectedIcon:
                const Icon(Icons.flag_rounded, color: AppColors.f1Red),
            label: isHu ? 'Versenyek' : 'Races',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_rounded),
            selectedIcon:
                const Icon(Icons.leaderboard_rounded, color: AppColors.f1Red),
            label: isHu ? 'Ranglista' : 'Standings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            selectedIcon:
                const Icon(Icons.person_rounded, color: AppColors.f1Red),
            label: isHu ? 'Profil' : 'Profile',
          ),
        ],
      ),
    );
  }
}
