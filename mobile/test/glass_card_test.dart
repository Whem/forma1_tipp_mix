import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: RepaintBoundary(child: child),
      ),
    );
  }

  group('GlassCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const GlassCard(child: Text('Hello F1')),
        ),
      );

      expect(find.text('Hello F1'), findsOneWidget);
    });

    testWidgets('applies custom border radius', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const GlassCard(
            borderRadius: 32.0,
            child: Text('Rounded'),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      final borderRadius = clipRRect.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, 32.0);
    });

    testWidgets('has BackdropFilter', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const GlassCard(child: Text('Blur')),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('wraps in GestureDetector when onTap is provided',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          child: GlassCard(
            onTap: () => tapped = true,
            child: const Text('Tappable'),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
      await tester.tap(find.text('Tappable'));
      expect(tapped, true);
    });

    testWidgets('does not wrap in GestureDetector when onTap is null',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const GlassCard(child: Text('Static')),
        ),
      );

      final gestureDetectors = tester
          .widgetList<GestureDetector>(find.byType(GestureDetector))
          .where((gd) => gd.onTap != null);
      expect(gestureDetectors, isEmpty);
    });

    testWidgets('uses default padding and border radius', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const GlassCard(child: Text('Defaults')),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      final borderRadius = clipRRect.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, 20.0);

      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.padding, const EdgeInsets.all(18));
    });
  });
}
