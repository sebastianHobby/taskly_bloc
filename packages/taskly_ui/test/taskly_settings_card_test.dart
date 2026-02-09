@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgetsSafe('shows header content and toggles expansion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _SettingsCardHarness(),
        ),
      ),
    );

    expect(find.text('Weekly review'), findsOneWidget);
    expect(find.text('Summary text'), findsOneWidget);
    expect(find.text('Details'), findsNothing);

    await tester.tap(find.text('Configure'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Details'), findsOneWidget);
  });
}

class _SettingsCardHarness extends StatefulWidget {
  const _SettingsCardHarness();

  @override
  State<_SettingsCardHarness> createState() => _SettingsCardHarnessState();
}

class _SettingsCardHarnessState extends State<_SettingsCardHarness> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return TasklySettingsCard(
      title: 'Weekly review',
      subtitle: 'A gentle check-in.',
      summary: 'Summary text',
      isExpanded: _expanded,
      onExpandedChanged: (next) => setState(() => _expanded = next),
      trailing: Switch.adaptive(
        value: true,
        onChanged: (_) {},
      ),
      child: const Text('Details'),
    );
  }
}
