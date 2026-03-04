import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma1_tipp/src/core/widgets/shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );
  }

  group('ShimmerLoading', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const ShimmerLoading()),
      );

      expect(find.byType(Shimmer), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxHeight, 16);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ShimmerLoading(width: 200, height: 40),
        ),
      );

      final box =
          tester.renderObject<RenderBox>(find.byType(ShimmerLoading));
      await tester.pump();

      expect(box.size.height, 40.0);
    });
  });

  group('ShimmerCard', () {
    testWidgets('renders with default height', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const ShimmerCard()),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders with custom height', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const ShimmerCard(height: 200)),
      );

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('wraps ShimmerLoading in vertical padding', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const ShimmerCard()),
      );

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(ShimmerLoading),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.symmetric(vertical: 6));
    });
  });
}
