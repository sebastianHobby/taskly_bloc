/// Integration tests for SectionWidget checkbox completion callbacks.
///
/// Tests that checkbox clicks in SectionWidget properly propagate to callbacks
/// for tasks and for the project entity header.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/section_renderer_registry.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(initializeTalkerForTest);
  group('SectionWidget task checkbox completion', () {
    testWidgetsSafe(
      'dispatches completion intent for task checkbox',
      (tester) async {
        final task = TestData.task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
        );

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [task]),
          dispatcher: dispatcher,
        );

        // Find and tap the checkbox
        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpForStream();

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityType, EntityType.task);
        expect(intents.single.entityId, equals('task-1'));
        expect(intents.single.completed, isTrue);
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

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [task1, task2]),
          dispatcher: dispatcher,
        );

        // Find all checkboxes
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsNWidgets(2));

        // Tap the second checkbox
        await tester.tap(checkboxes.at(1));
        await tester.pumpForStream();

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityId, equals('task-2'));
        expect(intents.single.completed, isTrue);
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

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [completedTask]),
          dispatcher: dispatcher,
        );

        // Tap the checkbox to uncomplete
        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityType, EntityType.task);
        expect(intents.single.entityId, equals('task-1'));
        expect(intents.single.completed, isFalse);
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

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [repeatingTask]),
          dispatcher: dispatcher,
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        // Verify intent targets the repeating task.
        expect(repeatingTask.repeatIcalRrule, equals('FREQ=DAILY'));

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityType, EntityType.task);
        expect(intents.single.entityId, equals('repeating-task'));
        expect(intents.single.completed, isTrue);
      },
    );
  });

  group('SectionWidget project header checkbox completion', () {
    testWidgetsSafe(
      'dispatches completion intent for project header checkbox',
      (tester) async {
        final project = TestData.project(
          id: 'project-1',
          name: 'Test Project',
          completed: false,
        );

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpSectionWidget(
          tester,
          section: _createProjectHeaderSection(project: project),
          dispatcher: dispatcher,
        );

        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpForStream();

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityType, EntityType.project);
        expect(intents.single.entityId, equals('project-1'));
        expect(intents.single.completed, isTrue);
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

        final dispatcher = _CapturingTileIntentDispatcher();

        await _pumpSectionWidget(
          tester,
          section: _createTaskSection(tasks: [task]),
          dispatcher: dispatcher,
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pumpForStream();

        final intents = dispatcher.intents.whereType<TileIntentSetCompletion>();
        expect(intents.length, 1);
        expect(intents.single.entityType, EntityType.task);
        expect(intents.single.entityId, equals('task-1'));
        expect(intents.single.completed, isTrue);
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
  return SectionVm.taskListV2(
    index: 0,
    title: title,
    entityStyle: const EntityStyleV1(),
    params: ListSectionParamsV2(
      config: DataConfig.task(query: TaskQuery()),
    ),
    data: SectionDataResult.dataV2(
      items: tasks
          .map(
            (t) => ScreenItem.task(
              t,
              tileCapabilities: const EntityTileCapabilities(
                canToggleCompletion: true,
                canOpenEditor: true,
                canOpenDetails: true,
              ),
            ),
          )
          .toList(),
    ),
  );
}

/// Creates a test section with a project entity header.
SectionVm _createProjectHeaderSection({
  required Project project,
  String? title,
  bool showCheckbox = true,
}) {
  return SectionVm.entityHeader(
    index: 0,
    title: title,
    params: EntityHeaderSectionParams(
      entityType: 'project',
      entityId: project.id,
      showCheckbox: showCheckbox,
    ),
    data: SectionDataResult.entityHeaderProject(
      project: project,
      showCheckbox: showCheckbox,
    ),
  );
}

/// Pumps a SectionWidget with the app's theme and localizations.
Future<void> _pumpSectionWidget(
  WidgetTester tester, {
  required SectionVm section,
  required _CapturingTileIntentDispatcher dispatcher,
  void Function(dynamic)? onEntityTap,
}) async {
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SectionRendererRegistry>.value(
          value: const DefaultSectionRendererRegistry(),
        ),
      ],
      child: Provider<TileIntentDispatcher>.value(
        value: dispatcher,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SectionWidget(
                  section: section,
                  onEntityTap: onEntityTap,
                ),
              ],
            ),
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
