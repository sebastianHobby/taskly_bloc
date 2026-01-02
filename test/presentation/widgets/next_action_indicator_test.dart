import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/next_action_indicator.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('NextActionIndicator', () {
    Widget buildTestWidget({
      VoidCallback? onUnpin,
      bool showInfoOnTap = true,
      NextActionIndicatorSize size = NextActionIndicatorSize.small,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NextActionIndicator(
            onUnpin: onUnpin,
            showInfoOnTap: showInfoOnTap,
            size: size,
          ),
        ),
      );
    }

    testWidgetsSafe('displays push pin icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(onUnpin: () {}));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgetsSafe('shows tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(onUnpin: () {}));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgetsSafe('is tappable when showInfoOnTap is true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          onUnpin: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsOneWidget);

      // Tap to open dialog
      await tester.tap(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgetsSafe('shows dialog with Cancel and Remove Next Action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          onUnpin: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      // Uses localized cancel label
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Remove Next Action'), findsOneWidget);
    });

    testWidgetsSafe('calls onUnpin when Remove Next Action button pressed', (
      tester,
    ) async {
      var unpinCalled = false;
      await tester.pumpWidget(
        buildTestWidget(
          onUnpin: () => unpinCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove Next Action'));
      await tester.pumpAndSettle();

      expect(unpinCalled, isTrue);
    });

    testWidgetsSafe('does not call onUnpin when Cancel pressed', (
      tester,
    ) async {
      var unpinCalled = false;
      await tester.pumpWidget(
        buildTestWidget(
          onUnpin: () => unpinCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      // Tap the TextButton (Cancel)
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(unpinCalled, isFalse);
    });

    group('sizes', () {
      testWidgetsSafe('small size uses 14.0 icon size', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            onUnpin: () {},
          ),
        );
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
        expect(icon.size, 14.0);
      });

      testWidgetsSafe('medium size uses 18.0 icon size', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            onUnpin: () {},
            size: NextActionIndicatorSize.medium,
          ),
        );
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
        expect(icon.size, 18.0);
      });

      testWidgetsSafe('large size uses 22.0 icon size', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            onUnpin: () {},
            size: NextActionIndicatorSize.large,
          ),
        );
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
        expect(icon.size, 22.0);
      });
    });
  });

  group('NextActionIndicatorSize', () {
    test('has three values', () {
      expect(NextActionIndicatorSize.values, hasLength(3));
    });

    test('has small value', () {
      expect(NextActionIndicatorSize.small, isNotNull);
    });

    test('has medium value', () {
      expect(NextActionIndicatorSize.medium, isNotNull);
    });

    test('has large value', () {
      expect(NextActionIndicatorSize.large, isNotNull);
    });
  });
}
