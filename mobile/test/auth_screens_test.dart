import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/l10n/app_localizations.dart';
import 'package:forma1_tipp/src/features/auth/presentation/screens/welcome_screen.dart';

Widget _buildTestableWidget(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/register', builder: (_, __) => const Scaffold()),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('displays F1 and TIPP MIX branding text', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('F1'), findsOneWidget);
      expect(find.text('TIPP MIX'), findsOneWidget);
    });

    testWidgets('shows login and register buttons', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(
          find.widgetWithText(OutlinedButton, 'Create account'), findsOneWidget);
    });

    testWidgets('login button navigates to /login', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('register button navigates to /register', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WelcomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('displays localized welcome strings', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pick your champions'), findsOneWidget);
      expect(
        find.textContaining('Voting closes'),
        findsOneWidget,
      );
    });
  });
}
