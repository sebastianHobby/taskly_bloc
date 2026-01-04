/// Integration tests for task and project checkbox completion.
///
/// Tests that clicking checkboxes in list views properly completes/uncompletes
/// entities and that the UI updates accordingly.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(initializeTalkerForTest);
  group('Task checkbox completion', () {
    testWidgetsSafe('renders checkbox unchecked for incomplete task', (
      tester,
    ) async {
      final task = TestData.task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
      );

      await _pumpTaskListTile(
        tester,
        task: task,
        onCheckboxChanged: (_, __) {},
      );

      // Find the checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verify it's unchecked
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isFalse);
    });

    testWidgetsSafe('renders checkbox checked for completed task', (
      tester,
    ) async {
      final task = TestData.task(
        id: 'task-1',
        name: 'Test Task',
        completed: true,
      );

      await _pumpTaskListTile(
        tester,
        task: task,
        onCheckboxChanged: (_, __) {},
      );

      // Find the checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verify it's checked
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);
    });

    testWidgetsSafe(
      'calls onCheckboxChanged with true when tapped on incomplete task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
        );

        Task? callbackTask;
        bool? callbackValue;

        await _pumpTaskListTile(
          tester,
          task: task,
          onCheckboxChanged: (t, v) {
            callbackTask = t;
            callbackValue = v;
          },
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback was called with correct values
        expect(callbackTask, isNotNull);
        expect(callbackTask!.id, equals('task-1'));
        expect(callbackValue, isTrue);
      },
    );

    testWidgetsSafe(
      'calls onCheckboxChanged with false when tapped on completed task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'Test Task',
          completed: true,
        );

        Task? callbackTask;
        bool? callbackValue;

        await _pumpTaskListTile(
          tester,
          task: task,
          onCheckboxChanged: (t, v) {
            callbackTask = t;
            callbackValue = v;
          },
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback was called with correct values
        expect(callbackTask, isNotNull);
        expect(callbackTask!.id, equals('task-1'));
        expect(callbackValue, isFalse);
      },
    );

    testWidgetsSafe('shows strikethrough text for completed task', (
      tester,
    ) async {
      final task = TestData.task(
        id: 'task-1',
        name: 'Completed Task',
        completed: true,
      );

      await _pumpTaskListTile(
        tester,
        task: task,
        onCheckboxChanged: (_, __) {},
      );

      // Find the task name text widget
      final textFinder = find.text('Completed Task');
      expect(textFinder, findsOneWidget);

      // Get the Text widget and check its style
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgetsSafe('does not show strikethrough text for incomplete task', (
      tester,
    ) async {
      final task = TestData.task(
        id: 'task-1',
        name: 'Active Task',
        completed: false,
      );

      await _pumpTaskListTile(
        tester,
        task: task,
        onCheckboxChanged: (_, __) {},
      );

      // Find the task name text widget
      final textFinder = find.text('Active Task');
      expect(textFinder, findsOneWidget);

      // Get the Text widget and check its style has no strikethrough
      final textWidget = tester.widget<Text>(textFinder);
      expect(
        textWidget.style?.decoration,
        isNot(equals(TextDecoration.lineThrough)),
      );
    });

    testWidgetsSafe('handles rapid checkbox taps without errors', (
      tester,
    ) async {
      final task = TestData.task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
      );

      var tapCount = 0;

      await _pumpTaskListTile(
        tester,
        task: task,
        onCheckboxChanged: (_, __) {
          tapCount++;
        },
      );

      // Rapidly tap the checkbox multiple times
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(checkbox);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(checkbox);
      await tester.pumpForStream();

      // All taps should have triggered callbacks
      expect(tapCount, equals(3));
    });

    testWidgetsSafe(
      'checkbox callback receives correct task for repeating task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'repeating-task',
          name: 'Repeating Task',
          completed: false,
          repeatIcalRrule: 'FREQ=DAILY;COUNT=5',
        );

        Task? callbackTask;
        bool? callbackValue;

        await _pumpTaskListTile(
          tester,
          task: task,
          onCheckboxChanged: (t, v) {
            callbackTask = t;
            callbackValue = v;
          },
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback received the repeating task
        expect(callbackTask, isNotNull);
        expect(callbackTask!.id, equals('repeating-task'));
        expect(callbackTask!.repeatIcalRrule, equals('FREQ=DAILY;COUNT=5'));
        expect(callbackValue, isTrue);
      },
    );
  });

  group('Project checkbox completion', () {
    testWidgetsSafe('renders checkbox unchecked for incomplete project', (
      tester,
    ) async {
      final project = TestData.project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
      );

      await _pumpProjectListTile(
        tester,
        project: project,
        onCheckboxChanged: (_, __) {},
      );

      // Find the checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verify it's unchecked
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isFalse);
    });

    testWidgetsSafe('renders checkbox checked for completed project', (
      tester,
    ) async {
      final project = TestData.project(
        id: 'project-1',
        name: 'Test Project',
        completed: true,
      );

      await _pumpProjectListTile(
        tester,
        project: project,
        onCheckboxChanged: (_, __) {},
      );

      // Find the checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verify it's checked
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);
    });

    testWidgetsSafe(
      'calls onCheckboxChanged with true when tapped on incomplete project',
      (
        tester,
      ) async {
        final project = TestData.project(
          id: 'project-1',
          name: 'Test Project',
          completed: false,
        );

        Project? callbackProject;
        bool? callbackValue;

        await _pumpProjectListTile(
          tester,
          project: project,
          onCheckboxChanged: (p, v) {
            callbackProject = p;
            callbackValue = v;
          },
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback was called with correct values
        expect(callbackProject, isNotNull);
        expect(callbackProject!.id, equals('project-1'));
        expect(callbackValue, isTrue);
      },
    );

    testWidgetsSafe(
      'calls onCheckboxChanged with false when tapped on completed project',
      (
        tester,
      ) async {
        final project = TestData.project(
          id: 'project-1',
          name: 'Test Project',
          completed: true,
        );

        Project? callbackProject;
        bool? callbackValue;

        await _pumpProjectListTile(
          tester,
          project: project,
          onCheckboxChanged: (p, v) {
            callbackProject = p;
            callbackValue = v;
          },
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback was called with correct values
        expect(callbackProject, isNotNull);
        expect(callbackProject!.id, equals('project-1'));
        expect(callbackValue, isFalse);
      },
    );

    testWidgetsSafe('shows strikethrough text for completed project', (
      tester,
    ) async {
      final project = TestData.project(
        id: 'project-1',
        name: 'Completed Project',
        completed: true,
      );

      await _pumpProjectListTile(
        tester,
        project: project,
        onCheckboxChanged: (_, __) {},
      );

      // Find the project name text widget
      final textFinder = find.text('Completed Project');
      expect(textFinder, findsOneWidget);

      // Get the Text widget and check its style
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgetsSafe('does not show strikethrough text for incomplete project', (
      tester,
    ) async {
      final project = TestData.project(
        id: 'project-1',
        name: 'Active Project',
        completed: false,
      );

      await _pumpProjectListTile(
        tester,
        project: project,
        onCheckboxChanged: (_, __) {},
      );

      // Find the project name text widget
      final textFinder = find.text('Active Project');
      expect(textFinder, findsOneWidget);

      // Get the Text widget and check its style has no strikethrough
      final textWidget = tester.widget<Text>(textFinder);
      expect(
        textWidget.style?.decoration,
        isNot(equals(TextDecoration.lineThrough)),
      );
    });

    testWidgetsSafe(
      'checkbox callback receives correct project for repeating project',
      (
        tester,
      ) async {
        final project = TestData.project(
          id: 'repeating-project',
          name: 'Repeating Project',
          completed: false,
          repeatIcalRrule: 'FREQ=WEEKLY;COUNT=10',
        );

        Project? callbackProject;
        bool? callbackValue;

        await _pumpProjectListTile(
          tester,
          project: project,
          onCheckboxChanged: (p, v) {
            callbackProject = p;
            callbackValue = v;
          },
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback received the repeating project
        expect(callbackProject, isNotNull);
        expect(callbackProject!.id, equals('repeating-project'));
        expect(
          callbackProject!.repeatIcalRrule,
          equals('FREQ=WEEKLY;COUNT=10'),
        );
        expect(callbackValue, isTrue);
      },
    );
  });

  group('Accessibility', () {
    testWidgetsSafe(
      'task checkbox has accessible semantics for incomplete task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'My Task',
          completed: false,
        );

        await _pumpTaskListTile(
          tester,
          task: task,
          onCheckboxChanged: (_, __) {},
        );

        // Check that semantic label contains task completion info
        final semantics = find.bySemanticsLabel(
          RegExp('Mark "My Task" as complete'),
        );
        expect(semantics, findsOneWidget);
      },
    );

    testWidgetsSafe(
      'task checkbox has accessible semantics for completed task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'My Task',
          completed: true,
        );

        await _pumpTaskListTile(
          tester,
          task: task,
          onCheckboxChanged: (_, __) {},
        );

        // Check that semantic label contains task incomplete info
        final semantics = find.bySemanticsLabel(
          RegExp('Mark "My Task" as incomplete'),
        );
        expect(semantics, findsOneWidget);
      },
    );
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Pumps a TaskListTile widget with the app's theme and localizations.
Future<void> _pumpTaskListTile(
  WidgetTester tester, {
  required Task task,
  required void Function(Task, bool?) onCheckboxChanged,
  void Function(Task)? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TaskListTile(
          task: task,
          onCheckboxChanged: onCheckboxChanged,
          onTap: onTap,
        ),
      ),
    ),
  );
  await tester.pumpForStream();
}

/// Pumps a ProjectListTile widget with the app's theme and localizations.
Future<void> _pumpProjectListTile(
  WidgetTester tester, {
  required Project project,
  required void Function(Project, bool?) onCheckboxChanged,
  void Function(Project)? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectListTile(
          project: project,
          onCheckboxChanged: onCheckboxChanged,
          onTap: onTap,
        ),
      ),
    ),
  );
  await tester.pumpForStream();
}
