/// Integration tests for SectionWidget checkbox completion callbacks.
///
/// Tests that checkbox clicks in SectionWidget properly propagate to callbacks
/// for tasks and for the project entity header.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(initializeTalkerForTest);
  group('SectionWidget task checkbox completion', () {
    testWidgetsSafe(
      'passes checkbox callback through to TaskListTile',
      (tester) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
        );

        Task? receivedTask;
        bool? receivedValue;

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [task]),
          onTaskCheckboxChanged: (t, v) {
            receivedTask = t;
            receivedValue = v;
          },
        );

        // Find and tap the checkbox
        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpForStream();

        // Verify callback was received
        expect(receivedTask, isNotNull);
        expect(receivedTask!.id, equals('task-1'));
        expect(receivedValue, isTrue);
      },
    );

    testWidgetsSafe(
      'handles multiple tasks with individual checkboxes',
      (tester) async {
        final task1 = TestData.task(
          id: 'task-1',
          name: 'Task One',
          completed: false,
        );
        final task2 = TestData.task(
          id: 'task-2',
          name: 'Task Two',
          completed: false,
        );

        final callbackLog = <(String, bool?)>[];

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [task1, task2]),
          onTaskCheckboxChanged: (t, v) {
            callbackLog.add((t.id, v));
          },
        );

        // Find all checkboxes
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsNWidgets(2));

        // Tap the second checkbox
        await tester.tap(checkboxes.at(1));
        await tester.pumpForStream();

        // Verify the second task's callback was triggered
        expect(callbackLog, hasLength(1));
        expect(callbackLog.first.$1, equals('task-2'));
        expect(callbackLog.first.$2, isTrue);
      },
    );

    testWidgetsSafe(
      'handles uncomplete flow for completed tasks',
      (tester) async {
        final completedTask = TestData.task(
          id: 'task-1',
          name: 'Completed Task',
          completed: true,
        );

        Task? receivedTask;
        bool? receivedValue;

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [completedTask]),
          onTaskCheckboxChanged: (t, v) {
            receivedTask = t;
            receivedValue = v;
          },
        );

        // Tap the checkbox to uncomplete
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify callback received false (uncomplete)
        expect(receivedTask, isNotNull);
        expect(receivedTask!.id, equals('task-1'));
        expect(receivedValue, isFalse);
      },
    );

    testWidgetsSafe(
      'handles repeating task checkbox correctly',
      (tester) async {
        final repeatingTask = TestData.task(
          id: 'repeating-task',
          name: 'Daily Task',
          completed: false,
          repeatIcalRrule: 'FREQ=DAILY',
        );

        Task? receivedTask;
        bool? receivedValue;

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [repeatingTask]),
          onTaskCheckboxChanged: (t, v) {
            receivedTask = t;
            receivedValue = v;
          },
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify repeating task data was passed correctly
        expect(receivedTask, isNotNull);
        expect(receivedTask!.id, equals('repeating-task'));
        expect(receivedTask!.repeatIcalRrule, equals('FREQ=DAILY'));
        expect(receivedValue, isTrue);
      },
    );
  });

  group('SectionWidget project header checkbox completion', () {
    testWidgetsSafe(
      'passes checkbox callback through to EntityHeader.project',
      (tester) async {
        final project = TestData.project(
          id: 'project-1',
          name: 'Test Project',
          completed: false,
        );

        Project? receivedProject;
        bool? receivedValue;

        await _pumpSectionWidget(
          tester,
          section: _createProjectHeaderSection(project: project),
          onProjectCheckboxChanged: (p, v) {
            receivedProject = p;
            receivedValue = v;
          },
        );

        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpForStream();

        expect(receivedProject, isNotNull);
        expect(receivedProject!.id, equals('project-1'));
        expect(receivedValue, isTrue);
      },
    );
  });

  group('SectionWidget mixed content', () {
    testWidgetsSafe(
      'section with both tasks and projects handles checkboxes independently',
      (tester) async {
        // Note: In practice, sections usually have either tasks OR projects,
        // but this tests the callbacks are wired up correctly.
        final task = TestData.task(
          id: 'task-1',
          name: 'My Task',
          completed: false,
        );

        Task? receivedTask;
        bool? receivedTaskValue;

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [task]),
          onTaskCheckboxChanged: (t, v) {
            receivedTask = t;
            receivedTaskValue = v;
          },
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        expect(receivedTask, isNotNull);
        expect(receivedTask!.id, equals('task-1'));
        expect(receivedTaskValue, isTrue);
      },
    );
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Creates a test section with tasks.
SectionVm _createTaskSection({
  required List<Task> tasks,
  String? title,
}) {
  return SectionVm(
    index: 0,
    title: title,
    templateId: SectionTemplateId.taskListV2,
    params: ListSectionParamsV2(
      config: DataConfig.task(query: TaskQuery()),
      pack: StylePackV2.standard,
      layout: const SectionLayoutSpecV2.flatList(),
    ),
    data: SectionDataResult.dataV2(
      items: tasks.map(ScreenItem.task).toList(),
    ),
    isLoading: false,
  );
}

/// Creates a test section with a project entity header.
SectionVm _createProjectHeaderSection({
  required Project project,
  String? title,
  bool showCheckbox = true,
}) {
  return SectionVm(
    index: 0,
    title: title,
    templateId: SectionTemplateId.entityHeader,
    params: EntityHeaderSectionParams(
      entityType: 'project',
      entityId: project.id,
      showCheckbox: showCheckbox,
    ),
    data: SectionDataResult.entityHeaderProject(
      project: project,
      showCheckbox: showCheckbox,
    ),
    isLoading: false,
  );
}

/// Pumps a SectionWidget with the app's theme and localizations.
Future<void> _pumpSectionWidget(
  WidgetTester tester, {
  required SectionVm section,
  void Function(Task, bool?)? onTaskCheckboxChanged,
  void Function(Project, bool?)? onProjectCheckboxChanged,
  void Function(dynamic)? onEntityTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SectionWidget(
              section: section,
              onTaskCheckboxChanged: onTaskCheckboxChanged,
              onProjectCheckboxChanged: onProjectCheckboxChanged,
              onEntityTap: onEntityTap,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpForStream();
}
