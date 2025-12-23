import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/data/adapters/next_actions_settings_adapter.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/next_action/bloc/next_actions_bloc.dart';
import 'package:taskly_bloc/features/next_action/services/next_actions_view_builder.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

import '../mocks/repository_mocks.dart';

class _PassthroughTaskSelector extends TaskSelector {
  @override
  List<Task> filter({
    required List<Task> tasks,
    List<TaskRuleSet>? ruleSets,
    List<SortCriterion>? sortCriteria,
    int? limit,
    DateTime? now,
    EvaluationContext? context,
  }) {
    return tasks;
  }
}

class _PassthroughViewBuilder extends NextActionsViewBuilder {
  @override
  NextActionsSelection build({
    required List<Task> tasks,
    required NextActionsSettings settings,
    DateTime? now,
  }) {
    final filtered = settings.includeInboxTasks
        ? tasks
        : tasks.where((t) => t.projectId != null).toList();

    final projectMap = <String, Project>{};
    final bucket = <int, Map<String, List<Task>>>{};
    for (final task in filtered) {
      final key = task.projectId ?? 'inbox';
      projectMap.putIfAbsent(
        key,
        () => Project(
          id: key,
          name: key,
          completed: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      bucket.putIfAbsent(1, () => {});
      bucket[1]!.putIfAbsent(key, () => <Task>[]).add(task);
    }

    return NextActionsSelection(
      priorityBuckets: bucket,
      projectsById: projectMap,
      bucketRuleByPriority: {
        1: TaskPriorityBucketRule(
          priority: 1,
          name: 'p1',
          ruleSets: const [],
          sortCriterion: const SortCriterion(field: SortField.deadlineDate),
        ),
      },
      sortedPriorities: const [1],
      fallbackCriterion: const SortCriterion(field: SortField.deadlineDate),
    );
  }
}

void main() {
  group('NextActionsBloc with repository sources', () {
    late MockTaskRepository taskRepository;
    late MockSettingsRepository settingsRepository;
    late StreamController<NextActionsSettings> settingsController;

    // Inbox task (no project)
    final inboxTask = Task(
      id: '1',
      name: 'Inbox Task',
      description: '',
      completed: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Project task
    final projectTask = Task(
      id: '2',
      name: 'Project Task',
      description: '',
      completed: false,
      projectId: 'proj1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      taskRepository = MockTaskRepository();
      settingsRepository = MockSettingsRepository();
      settingsController = StreamController<NextActionsSettings>.broadcast();

      when(() => taskRepository.watchAll(withRelated: true)).thenAnswer(
        (_) => Stream.value([inboxTask, projectTask]),
      );

      when(
        () => settingsRepository.watchNextActionsSettings(),
      ).thenAnswer((_) => settingsController.stream);
    });

    tearDown(() async {
      await settingsController.close();
    });

    blocTest<NextActionsBloc, NextActionsState>(
      'combines tasks and settings streams - updates when settings change',
      build: () {
        return NextActionsBloc(
          taskRepository: taskRepository,
          settingsAdapter: NextActionsSettingsAdapter(
            settingsRepository: settingsRepository,
          ),
          taskSelector: _PassthroughTaskSelector(),
          viewBuilder: _PassthroughViewBuilder(),
        );
      },
      act: (bloc) async {
        bloc.add(const NextActionsSubscriptionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        settingsController.add(
          const NextActionsSettings(includeInboxTasks: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        settingsController.add(
          const NextActionsSettings(),
        );
      },
      skip: 1, // Skip loading state
      expect: () => [
        // First: inbox included -> both tasks visible (2)
        isA<NextActionsState>().having(
          (s) => s.totalCount,
          'totalCount with inbox',
          2,
        ),
        // Second: inbox excluded -> only project task (1)
        isA<NextActionsState>().having(
          (s) => s.totalCount,
          'totalCount without inbox',
          1,
        ),
      ],
    );
  });
}
