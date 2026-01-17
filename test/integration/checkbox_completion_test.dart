/// Integration tests for task and project checkbox completion.
///
/// Tests that clicking checkboxes in list views properly completes/uncompletes
/// entities and that the UI updates accordingly.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_helpers.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(initializeLoggingForTest);
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
      );

      // Find the checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verify it's checked
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);
    });

    testWidgetsSafe(
      'dispatches completion intent with true when tapped on incomplete task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
        );

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpTaskListTile(
          tester,
          task: task,
          dispatcher: dispatcher,
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        final intent = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intent.length, 1);
        expect(intent.single.entityType, EntityType.task);
        expect(intent.single.entityId, 'task-1');
        expect(intent.single.completed, isTrue);
      },
    );

    testWidgetsSafe(
      'dispatches completion intent with false when tapped on completed task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'Test Task',
          completed: true,
        );

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpTaskListTile(
          tester,
          task: task,
          dispatcher: dispatcher,
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        final intent = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intent.length, 1);
        expect(intent.single.entityType, EntityType.task);
        expect(intent.single.entityId, 'task-1');
        expect(intent.single.completed, isFalse);
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

      final dispatcher = _CapturingTileIntentDispatcher();

      await _pumpTaskListTile(
        tester,
        task: task,
        dispatcher: dispatcher,
      );

      // Rapidly tap the checkbox multiple times
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(checkbox);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(checkbox);
      await tester.pumpForStream();

      // All taps should dispatch intents.
      expect(
        dispatcher.intents.whereType<TileIntentSetCompletion>(),
        hasLength(3),
      );
    });

    testWidgetsSafe(
      'dispatches completion intent for repeating task',
      (
        tester,
      ) async {
        final task = TestData.task(
          id: 'repeating-task',
          name: 'Repeating Task',
          completed: false,
          repeatIcalRrule: 'FREQ=DAILY;COUNT=5',
        );

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpTaskListTile(
          tester,
          task: task,
          dispatcher: dispatcher,
        );

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        expect(task.repeatIcalRrule, equals('FREQ=DAILY;COUNT=5'));

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityType, EntityType.task);
        expect(intents.single.entityId, equals('repeating-task'));
        expect(intents.single.completed, isTrue);
      },
    );
  });

  group('Project tile progress', () {
    testWidgetsSafe('does not render a checkbox for incomplete project', (
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
      );

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });

    testWidgetsSafe('does not render a checkbox for completed project', (
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
      );

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });

    testWidgetsSafe(
      'tapping the tile calls onTap with the project',
      (
        tester,
      ) async {
        final project = TestData.project(
          id: 'project-1',
          name: 'Test Project',
          completed: false,
        );

        Project? tappedProject;

        await _pumpProjectListTile(
          tester,
          project: project,
          onTap: (p) => tappedProject = p,
        );

        await tester.tap(find.byKey(const Key('project-project-1')));
        await tester.pumpForStream();

        expect(tappedProject, isNotNull);
        expect(tappedProject!.id, equals('project-1'));
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
  void Function(Task)? onTap,
  _CapturingTileIntentDispatcher? dispatcher,
}) async {
  final effectiveDispatcher = dispatcher ?? _CapturingTileIntentDispatcher();

  await tester.pumpWidget(
    Provider<TileIntentDispatcher>.value(
      value: effectiveDispatcher,
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TaskView(
            task: task,
            tileCapabilities: const EntityTileCapabilities(
              canToggleCompletion: true,
              canOpenEditor: true,
              canOpenDetails: true,
            ),
            onTap: onTap,
          ),
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
  void Function(Project)? onTap,
  _CapturingTileIntentDispatcher? dispatcher,
}) async {
  final effectiveDispatcher = dispatcher ?? _CapturingTileIntentDispatcher();

  await tester.pumpWidget(
    Provider<TileIntentDispatcher>.value(
      value: effectiveDispatcher,
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectView(
            project: project,
            tileCapabilities: const EntityTileCapabilities(
              canToggleCompletion: true,
              canOpenEditor: true,
              canOpenDetails: true,
            ),
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
  await tester.pumpForStream();
}

final class _CapturingTileIntentDispatcher implements TileIntentDispatcher {
  final List<TileIntent> intents = [];

  @override
  Future<void> dispatch(BuildContext context, TileIntent intent) {
    intents.add(intent);
    return Future<void>.value();
  }
}
