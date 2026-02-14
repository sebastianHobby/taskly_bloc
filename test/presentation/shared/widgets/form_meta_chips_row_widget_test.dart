@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';

import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
  });
  setUp(setUpTestEnvironment);

  Widget buildHarness({
    required double width,
    required List<Widget> chips,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          devicePixelRatio: 1,
        ),
        child: Scaffold(
          body: TasklyFormChipRow(chips: chips),
        ),
      ),
    );
  }

  testWidgetsSafe('uses wrap layout on compact width', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        width: 390,
        chips: const [
          Chip(label: Text('A')),
          Chip(label: Text('B')),
        ],
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgetsSafe('uses horizontal scroll row on wider width', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        width: 900,
        chips: const [
          Chip(label: Text('A')),
          Chip(label: Text('B')),
        ],
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Wrap), findsNothing);
  });
}
