import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/rule_set_builder.dart';

void main() {
  group('RuleSetBuilder', () {
    testWidgets('displays Add Rule button when empty', (tester) async {
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

      // Verify Add Rule button is visible
      expect(find.text('Add Rule'), findsOneWidget);

      // Tap Add Rule to open the dialog
      await tester.tap(find.text('Add Rule'));
      await tester.pumpAndSettle();

      // Verify dialog opened (has Save and Cancel buttons)
      expect(find.text('Add Rule'), findsWidgets); // Title in dialog
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Save the default rule
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify a new rule was added
      expect(updatedRuleSet, isNotNull);
      expect(updatedRuleSet!.rules.length, equals(1));
    });

    testWidgets('adds default DateRule when Save clicked in dialog', (
      tester,
    ) async {
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

      // Tap Add Rule to open dialog
      await tester.tap(find.text('Add Rule'));
      await tester.pumpAndSettle();

      // Save the rule
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify a DateRule with start date field was created (default)
      expect(updatedRuleSet, isNotNull);
      expect(updatedRuleSet!.rules.length, equals(1));

      final newRule = updatedRuleSet!.rules.first;
      expect(newRule, isA<DateRule>());
      expect((newRule as DateRule).field, DateRuleField.startDate);
    });

    testWidgets('Cancel button closes dialog without adding rule', (
      tester,
    ) async {
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

      // Tap Add Rule to open dialog
      await tester.tap(find.text('Add Rule'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify no rule was added
      expect(updatedRuleSet, isNull);
    });

    test('TaskField enum has correct display names and icons', () {
      expect(TaskField.startDate.displayName, 'Start Date');
      expect(TaskField.startDate.icon, Icons.calendar_today);

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
