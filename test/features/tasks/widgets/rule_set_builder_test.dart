import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/features/tasks/widgets/rule_set_builder.dart';

void main() {
  group('RuleSetBuilder - Field First Selection', () {
    testWidgets('displays field-based rule selector', (tester) async {
      TaskRuleSet? updatedRuleSet;

      final initialRuleSet = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RuleSetBuilder(
                ruleSet: initialRuleSet,
                onChanged: (ruleSet) => updatedRuleSet = ruleSet,
              ),
            ),
          ),
        ),
      );

      // Find and tap the add rule button
      expect(find.text('Add Rule'), findsOneWidget);
      await tester.tap(find.text('Add Rule'));
      await tester.pumpAndSettle();

      // Verify field options are available in popup menu
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('Deadline Date'), findsOneWidget);
      expect(find.text('Completed Status'), findsOneWidget);
      expect(find.text('Labels'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);

      // Select Start Date to test that rule creation works
      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();

      // Verify a new rule was added
      expect(updatedRuleSet, isNotNull);
      expect(updatedRuleSet!.rules.length, equals(1));

      // Verify the new rule is a DateRule with start date field
      final newRule = updatedRuleSet!.rules.first;
      expect(newRule, isA<DateRule>());
      expect((newRule as DateRule).field, DateRuleField.startDate);
    });

    testWidgets('creates DateRule for start date field', (tester) async {
      TaskRuleSet? updatedRuleSet;

      final initialRuleSet = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RuleSetBuilder(
                ruleSet: initialRuleSet,
                onChanged: (ruleSet) => updatedRuleSet = ruleSet,
              ),
            ),
          ),
        ),
      );

      // Find and tap the add rule button
      await tester.tap(find.text('Add Rule'));
      await tester.pumpAndSettle();

      // Select start date field
      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();

      // Verify a DateRule with start date field was created
      expect(updatedRuleSet, isNotNull);
      expect(updatedRuleSet!.rules.length, equals(1));

      final newRule = updatedRuleSet!.rules.first;
      expect(newRule, isA<DateRule>());
      expect((newRule as DateRule).field, DateRuleField.startDate);
    });

    testWidgets('creates BooleanRule for completed field', (tester) async {
      TaskRuleSet? updatedRuleSet;

      final initialRuleSet = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RuleSetBuilder(
                ruleSet: initialRuleSet,
                onChanged: (ruleSet) => updatedRuleSet = ruleSet,
              ),
            ),
          ),
        ),
      );

      // Find and tap the add rule button
      await tester.tap(find.text('Add Rule'));
      await tester.pumpAndSettle();

      // Select completed field
      await tester.tap(find.text('Completed Status'));
      await tester.pumpAndSettle();

      // Verify a BooleanRule was created
      expect(updatedRuleSet, isNotNull);
      expect(updatedRuleSet!.rules.length, equals(1));

      final newRule = updatedRuleSet!.rules.first;
      expect(newRule, isA<BooleanRule>());
      expect((newRule as BooleanRule).field, BooleanRuleField.completed);
    });

    test('TaskField enum has correct display names and icons', () {
      expect(TaskField.startDate.displayName, 'Start Date');
      expect(TaskField.startDate.icon, Icons.play_arrow);

      expect(TaskField.deadlineDate.displayName, 'Deadline Date');
      expect(TaskField.deadlineDate.icon, Icons.flag);

      expect(TaskField.completed.displayName, 'Completed Status');
      expect(TaskField.completed.icon, Icons.check_circle);

      expect(TaskField.labels.displayName, 'Labels');
      expect(TaskField.labels.icon, Icons.label);

      expect(TaskField.project.displayName, 'Project');
      expect(TaskField.project.icon, Icons.folder);
    });
  });
}
