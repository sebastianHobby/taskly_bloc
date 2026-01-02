import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/section_header.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'My Section'),
          ),
        ),
      );

      expect(find.text('My Section'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'My Section',
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('hides icon when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'My Section'),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('displays trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'My Section',
              trailing: const Text('See all'),
            ),
          ),
        ),
      );

      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('is tappable when onTap provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'My Section',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('My Section'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('uses InkWell when onTap provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'My Section',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not use InkWell when onTap null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'My Section'),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    group('named constructors', () {
      testWidgets('simple creates header with just title', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SectionHeader.simple(title: 'Simple'),
            ),
          ),
        );

        expect(find.text('Simple'), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      });

      testWidgets('withAction creates header with action button', (
        tester,
      ) async {
        var actionCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SectionHeader.withAction(
                title: 'With Action',
                actionLabel: 'View All',
                onAction: () => actionCalled = true,
              ),
            ),
          ),
        );

        expect(find.text('With Action'), findsOneWidget);
        expect(find.text('View All'), findsOneWidget);

        await tester.tap(find.text('View All'));
        await tester.pump();

        expect(actionCalled, isTrue);
      });
    });
  });

  group('SectionCountBadge', () {
    testWidgets('displays count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionCountBadge(count: 42),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays zero count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionCountBadge(count: 0),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });
}
