import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';
import 'package:forma1_tipp/src/features/auth/presentation/screens/login_screen.dart';
import 'package:forma1_tipp/src/features/auth/presentation/screens/register_screen.dart';
import 'package:forma1_tipp/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:forma1_tipp/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:forma1_tipp/src/features/home/presentation/home_screen.dart';
import 'package:forma1_tipp/src/features/season_prediction/presentation/screens/season_wizard_screen.dart';
import 'package:forma1_tipp/src/features/race/presentation/screens/race_calendar_screen.dart';
import 'package:forma1_tipp/src/features/race/presentation/screens/race_prediction_screen.dart';
import 'package:forma1_tipp/src/features/race/presentation/screens/live_race_screen.dart';
import 'package:forma1_tipp/src/features/standings/presentation/standings_screen.dart';
import 'package:forma1_tipp/src/features/profile/presentation/profile_screen.dart';
import 'package:forma1_tipp/src/features/gamification/presentation/achievements_screen.dart';
import 'package:forma1_tipp/src/features/race/presentation/screens/race_result_reveal_screen.dart';
import 'package:forma1_tipp/src/features/groups/presentation/groups_screen.dart';
import 'package:forma1_tipp/src/features/groups/presentation/create_group_screen.dart';
import 'package:forma1_tipp/src/features/groups/presentation/group_detail_screen.dart';
import 'package:forma1_tipp/src/features/notifications/presentation/notifications_screen.dart';
import 'package:forma1_tipp/src/routing/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final isLoading = authAsync.isLoading;
      final loggedIn = authAsync.valueOrNull?.isAuthenticated ?? false;

      const publicRoutes = ['/', '/welcome', '/login', '/register'];
      final isPublic = publicRoutes.contains(loc);

      if (isLoading) {
        return loc == '/' ? null : null;
      }

      if (!loggedIn) {
        if (isPublic) {
          return loc == '/' ? '/welcome' : null;
        }
        return '/welcome';
      }

      if (loggedIn && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeContent(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/races',
                builder: (_, __) => const RaceCalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/standings',
                builder: (_, __) => const StandingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Routes outside the shell (full-screen)
      GoRoute(
        path: '/season-prediction',
        builder: (_, __) => const SeasonWizardScreen(),
      ),
      GoRoute(
        path: '/race/:raceId/predict',
        builder: (_, state) => RacePredictionScreen(
          raceId: state.pathParameters['raceId']!,
        ),
      ),
      GoRoute(
        path: '/race/:raceId/live',
        builder: (_, state) => LiveRaceScreen(
          raceId: state.pathParameters['raceId']!,
        ),
      ),
      GoRoute(
        path: '/race/:raceId/reveal',
        builder: (_, state) => RaceResultRevealScreen(
          raceId: state.pathParameters['raceId']!,
        ),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (_, __) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/groups/create',
        builder: (_, __) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => GroupDetailScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );
});
