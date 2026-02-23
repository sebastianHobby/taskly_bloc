@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';

class _MockAttentionRepository extends Mock
    implements AttentionRepositoryContract {}

class _MockTaskRepository extends Mock implements TaskRepositoryContract {}

class _MockProjectRepository extends Mock
    implements ProjectRepositoryContract {}

class _MockRoutineRepository extends Mock
    implements RoutineRepositoryContract {}

class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);
  final DateTime _nowUtc;
  @override
  DateTime nowLocal() => _nowUtc.toLocal();
  @override
  DateTime nowUtc() => _nowUtc;
}

void main() {
  group('AttentionEngine', () {
    late _MockAttentionRepository attentionRepository;
    late _MockTaskRepository taskRepository;
    late _MockProjectRepository projectRepository;
    late _MockRoutineRepository routineRepository;
    late DateTime now;

    setUp(() {
      attentionRepository = _MockAttentionRepository();
      taskRepository = _MockTaskRepository();
      projectRepository = _MockProjectRepository();
      routineRepository = _MockRoutineRepository();
      now = DateTime.utc(2026, 1, 20, 12);

      when(
        () => attentionRepository.watchRuntimeStateForRule(any()),
      ).thenAnswer((_) => Stream.value(const <AttentionRuleRuntimeState>[]));
      when(
        () => attentionRepository.watchResolutionsForRule(any()),
      ).thenAnswer((_) => Stream.value(const <AttentionResolution>[]));
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(const <Task>[]),
      );
      when(() => projectRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(const <Project>[]),
      );
      when(
        () => routineRepository.watchAll(includeInactive: true),
      ).thenAnswer((_) => Stream.value(const <Routine>[]));
      when(() => routineRepository.watchCompletions()).thenAnswer(
        (_) => Stream.value(const <RoutineCompletion>[]),
      );
    });

    testSafe('evaluates stale tasks and enriches metadata', () async {
      final staleTask = _task(
        id: 't-stale',
        name: 'Alpha',
        updatedAt: now.subtract(const Duration(days: 45)),
      );
      final freshTask = _task(
        id: 't-fresh',
        name: 'Beta',
        updatedAt: now.subtract(const Duration(days: 2)),
      );

      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Task>[staleTask, freshTask]),
      );
      when(
        () => attentionRepository.watchActiveRules(),
      ).thenAnswer((_) => Stream.value([_staleTaskRule(now)]));

      final engine = AttentionEngine(
        attentionRepository: attentionRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        routineRepository: routineRepository,
        invalidations: const Stream<void>.empty(),
        clock: _FixedClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;

      expect(items, hasLength(1));
      final item = items.single;
      expect(item.entityType, AttentionEntityType.task);
      expect(item.entityId, 't-stale');
      expect(item.description, 'Stale task: Alpha');
      expect(item.availableActions, <AttentionResolutionAction>[
        AttentionResolutionAction.dismissed,
        AttentionResolutionAction.reviewed,
      ]);
      expect(item.metadata?['entity_display_name'], 'Alpha');
      expect(item.metadata?['state_hash'], isA<String>());
      expect(item.sortKey, contains('|task|t-stale'));
    });

    testSafe(
      'runtime and resolution suppression hide evaluated items',
      () async {
        final task = _task(
          id: 't-suppressed',
          name: 'Suppressed',
          updatedAt: now.subtract(const Duration(days: 60)),
        );
        final rule = _staleTaskRule(now);
        final snoozeUntil = now.add(const Duration(hours: 12));

        when(() => taskRepository.watchAll(any())).thenAnswer(
          (_) => Stream.value(<Task>[task]),
        );
        when(
          () => attentionRepository.watchActiveRules(),
        ).thenAnswer((_) => Stream.value([rule]));
        when(
          () => attentionRepository.watchRuntimeStateForRule(rule.id),
        ).thenAnswer(
          (_) => Stream.value(<AttentionRuleRuntimeState>[
            AttentionRuleRuntimeState(
              id: 'rt1',
              ruleId: rule.id,
              entityType: AttentionEntityType.task,
              entityId: task.id,
              createdAt: now,
              updatedAt: now,
              nextEvaluateAfter: now.add(const Duration(days: 1)),
            ),
          ]),
        );

        final engine = AttentionEngine(
          attentionRepository: attentionRepository,
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          routineRepository: routineRepository,
          invalidations: const Stream<void>.empty(),
          clock: _FixedClock(now),
        );

        final suppressedByRuntime = await engine
            .watch(const AttentionQuery())
            .first;
        expect(suppressedByRuntime, isEmpty);

        when(
          () => attentionRepository.watchRuntimeStateForRule(rule.id),
        ).thenAnswer((_) => Stream.value(const <AttentionRuleRuntimeState>[]));
        when(
          () => attentionRepository.watchResolutionsForRule(rule.id),
        ).thenAnswer(
          (_) => Stream.value(<AttentionResolution>[
            AttentionResolution(
              id: 'res-1',
              ruleId: rule.id,
              entityId: task.id,
              entityType: AttentionEntityType.task,
              resolvedAt: now.subtract(const Duration(hours: 1)),
              resolutionAction: AttentionResolutionAction.snoozed,
              createdAt: now.subtract(const Duration(hours: 1)),
              actionDetails: <String, dynamic>{
                'snooze_until': snoozeUntil.toIso8601String(),
              },
            ),
          ]),
        );

        final suppressedBySnooze = await engine
            .watch(const AttentionQuery())
            .first;
        expect(suppressedBySnooze, isEmpty);
      },
    );

    testSafe('filters by severity and entity type', () async {
      final task = _task(
        id: 't-1',
        name: 'Filtered',
        updatedAt: now.subtract(const Duration(days: 60)),
      );
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Task>[task]),
      );
      when(
        () => attentionRepository.watchActiveRules(),
      ).thenAnswer((_) => Stream.value([_staleTaskRule(now)]));

      final engine = AttentionEngine(
        attentionRepository: attentionRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        routineRepository: routineRepository,
        invalidations: const Stream<void>.empty(),
        clock: _FixedClock(now),
      );

      final minSeverityFiltered = await engine
          .watch(const AttentionQuery(minSeverity: AttentionSeverity.critical))
          .first;
      expect(minSeverityFiltered, isEmpty);

      final entityFiltered = await engine
          .watch(
            const AttentionQuery(
              entityTypes: <AttentionEntityType>{
                AttentionEntityType.project,
              },
            ),
          )
          .first;
      expect(entityFiltered, isEmpty);
    });

    testSafe('evaluates project due-soon unscheduled rule details', () async {
      final project = _project(
        id: 'p-1',
        name: 'Project X',
        deadlineDate: now.add(const Duration(days: 2)),
      );
      final unscheduledNoDates = _task(
        id: 't-a',
        projectId: project.id,
        updatedAt: now,
      );
      final unscheduledPastStart = _task(
        id: 't-b',
        projectId: project.id,
        startDate: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );
      final scheduled = _task(
        id: 't-c',
        projectId: project.id,
        startDate: now.add(const Duration(days: 1)),
        deadlineDate: now.add(const Duration(days: 3)),
        updatedAt: now,
      );

      when(() => projectRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Project>[project]),
      );
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Task>[
          unscheduledNoDates,
          unscheduledPastStart,
          scheduled,
        ]),
      );
      when(
        () => attentionRepository.watchActiveRules(),
      ).thenAnswer((_) => Stream.value([_projectDueSoonRule(now)]));

      final engine = AttentionEngine(
        attentionRepository: attentionRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        routineRepository: routineRepository,
        invalidations: const Stream<void>.empty(),
        clock: _FixedClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;

      expect(items, hasLength(1));
      final item = items.single;
      expect(item.entityType, AttentionEntityType.project);
      expect(item.entityId, project.id);
      expect(item.metadata?['unscheduled_tasks_count'], 2);
      expect(item.metadata?['due_within_days'], 5);
      expect(item.metadata?['min_unscheduled_count'], 2);
      expect(item.metadata?['detail_lines'], isA<List<String>>());
      expect(item.sortKey, contains('|project|'));
    });

    testSafe(
      'evaluates routine support building card with suggestion',
      () async {
        final routine = Routine(
          id: 'r-1',
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now,
          name: 'Walk',
          projectId: 'p1',
          periodType: RoutinePeriodType.day,
          scheduleMode: RoutineScheduleMode.scheduled,
          targetCount: 1,
          scheduleDays: const <int>[
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
        );
        final completions = <RoutineCompletion>[
          _completion(
            id: 'c1',
            routineId: routine.id,
            day: now.subtract(const Duration(days: 2)),
          ),
          _completion(
            id: 'c2',
            routineId: routine.id,
            day: now.subtract(const Duration(days: 9)),
          ),
          _completion(
            id: 'c3',
            routineId: routine.id,
            day: now.subtract(const Duration(days: 13)),
          ),
          _completion(
            id: 'c4',
            routineId: routine.id,
            day: now.subtract(const Duration(days: 16)),
          ),
        ];

        when(
          () => routineRepository.watchAll(includeInactive: true),
        ).thenAnswer((_) => Stream.value(<Routine>[routine]));
        when(() => routineRepository.watchCompletions()).thenAnswer(
          (_) => Stream.value(completions),
        );
        when(
          () => attentionRepository.watchActiveRules(),
        ).thenAnswer((_) => Stream.value([_routineSupportRule(now)]));

        final engine = AttentionEngine(
          attentionRepository: attentionRepository,
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          routineRepository: routineRepository,
          invalidations: const Stream<void>.empty(),
          clock: _FixedClock(now),
        );

        final items = await engine.watch(const AttentionQuery()).first;

        expect(items, hasLength(1));
        final item = items.single;
        expect(item.entityType, AttentionEntityType.routine);
        expect(item.metadata?['support_state'], 'building');
        expect(item.metadata?['suggestion_type'], 'reschedule_day');
        expect(item.metadata?['state_hash'], isA<String>());
      },
    );

    testSafe('ignores rules with unknown evaluator', () async {
      final task = _task(
        id: 't-x',
        name: 'Unknown evaluator',
        updatedAt: now.subtract(const Duration(days: 90)),
      );
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Task>[task]),
      );
      when(() => attentionRepository.watchActiveRules()).thenAnswer(
        (_) => Stream.value(<AttentionRule>[
          AttentionRule(
            id: 'rule-unknown',
            ruleKey: 'unknown_rule',
            bucket: AttentionBucket.action,
            evaluator: 'no_such_evaluator',
            evaluatorParams: const <String, dynamic>{},
            severity: AttentionSeverity.warning,
            displayConfig: const <String, dynamic>{},
            resolutionActions: const <String>['reviewed'],
            active: true,
            source: AttentionEntitySource.systemTemplate,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      );

      final engine = AttentionEngine(
        attentionRepository: attentionRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        routineRepository: routineRepository,
        invalidations: const Stream<void>.empty(),
        clock: _FixedClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;
      expect(items, isEmpty);
    });

    testSafe('evaluates project idle predicate path', () async {
      final idleProject = _project(
        id: 'p-idle',
        name: 'Idle Project',
        deadlineDate: null,
      ).copyWith(updatedAt: now.subtract(const Duration(days: 45)));

      when(() => projectRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Project>[idleProject]),
      );
      when(
        () => attentionRepository.watchActiveRules(),
      ).thenAnswer(
        (_) => Stream.value(<AttentionRule>[
          AttentionRule(
            id: 'rule-project-idle',
            ruleKey: 'project_idle',
            bucket: AttentionBucket.review,
            evaluator: 'project_predicate_v1',
            evaluatorParams: const <String, dynamic>{
              'predicate': 'isIdle',
              'thresholdDays': 30,
            },
            severity: AttentionSeverity.warning,
            displayConfig: const <String, dynamic>{
              'title': 'Idle project',
              'description': 'Project {project_name} is idle',
            },
            resolutionActions: const <String>['reviewed'],
            active: true,
            source: AttentionEntitySource.systemTemplate,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: now,
          ),
        ]),
      );

      final engine = AttentionEngine(
        attentionRepository: attentionRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        routineRepository: routineRepository,
        invalidations: const Stream<void>.empty(),
        clock: _FixedClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;
      expect(items, hasLength(1));
      expect(items.single.entityType, AttentionEntityType.project);
      expect(items.single.description, contains('Idle Project'));
    });

    testSafe('reviewed resolution does not suppress matching item', () async {
      final staleTask = _task(
        id: 't-reviewed',
        name: 'Reviewed task',
        updatedAt: now.subtract(const Duration(days: 60)),
      );
      final rule = _staleTaskRule(now).copyWith(id: 'rule-reviewed');
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value(<Task>[staleTask]),
      );
      when(
        () => attentionRepository.watchActiveRules(),
      ).thenAnswer((_) => Stream.value(<AttentionRule>[rule]));
      when(
        () => attentionRepository.watchResolutionsForRule(rule.id),
      ).thenAnswer(
        (_) => Stream.value(<AttentionResolution>[
          AttentionResolution(
            id: 'res-reviewed',
            ruleId: rule.id,
            entityId: staleTask.id,
            entityType: AttentionEntityType.task,
            resolvedAt: now.subtract(const Duration(hours: 1)),
            resolutionAction: AttentionResolutionAction.reviewed,
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ]),
      );

      final engine = AttentionEngine(
        attentionRepository: attentionRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        routineRepository: routineRepository,
        invalidations: const Stream<void>.empty(),
        clock: _FixedClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;
      expect(items, hasLength(1));
      expect(items.single.entityId, staleTask.id);
    });
  });
}

AttentionRule _staleTaskRule(DateTime now) {
  return AttentionRule(
    id: 'rule-task',
    ruleKey: 'task_stale',
    bucket: AttentionBucket.action,
    evaluator: 'task_predicate_v1',
    evaluatorParams: const <String, dynamic>{
      'predicate': 'isStale',
      'thresholdDays': 30,
    },
    severity: AttentionSeverity.warning,
    displayConfig: const <String, dynamic>{
      'title': 'Stale',
      'description': 'Stale task: {name}',
    },
    resolutionActions: const <String>[
      'dismissed',
      'unknown_action',
    ],
    active: true,
    source: AttentionEntitySource.systemTemplate,
    createdAt: now.subtract(const Duration(days: 10)),
    updatedAt: now,
  );
}

AttentionRule _projectDueSoonRule(DateTime now) {
  return AttentionRule(
    id: 'rule-project',
    ruleKey: 'project_due_soon',
    bucket: AttentionBucket.review,
    evaluator: 'project_predicate_v1',
    evaluatorParams: const <String, dynamic>{
      'predicate': 'dueSoonManyUnscheduledTasks',
      'dueWithinDays': 5,
      'minUnscheduledCount': 2,
    },
    severity: AttentionSeverity.critical,
    displayConfig: const <String, dynamic>{
      'title': 'Deadline risk',
      'description': 'Project {project_name} is at risk',
    },
    resolutionActions: const <String>['reviewed'],
    active: true,
    source: AttentionEntitySource.systemTemplate,
    createdAt: now.subtract(const Duration(days: 12)),
    updatedAt: now,
  );
}

AttentionRule _routineSupportRule(DateTime now) {
  return AttentionRule(
    id: 'rule-routine',
    ruleKey: 'routine_support',
    bucket: AttentionBucket.review,
    evaluator: 'routine_support_v1',
    evaluatorParams: const <String, dynamic>{
      'buildingMinAgeDays': 7,
      'buildingMaxAgeDays': 28,
      'needsHelpDropPp': 80,
      'needsHelpRecentAdherenceMax': 60,
      'maxCards': 2,
    },
    severity: AttentionSeverity.info,
    displayConfig: const <String, dynamic>{},
    resolutionActions: const <String>['reviewed'],
    active: true,
    source: AttentionEntitySource.systemTemplate,
    createdAt: now.subtract(const Duration(days: 30)),
    updatedAt: now,
  );
}

Task _task({
  required String id,
  required DateTime updatedAt,
  String name = 'Task',
  String? projectId,
  DateTime? startDate,
  DateTime? deadlineDate,
}) {
  return Task(
    id: id,
    createdAt: updatedAt.subtract(const Duration(days: 30)),
    updatedAt: updatedAt,
    name: name,
    completed: false,
    projectId: projectId,
    startDate: startDate,
    deadlineDate: deadlineDate,
  );
}

Project _project({
  required String id,
  required String name,
  DateTime? deadlineDate,
}) {
  final now = DateTime.utc(2026, 1, 20, 12);
  return Project(
    id: id,
    createdAt: now.subtract(const Duration(days: 100)),
    updatedAt: now,
    name: name,
    completed: false,
    deadlineDate: deadlineDate,
  );
}

RoutineCompletion _completion({
  required String id,
  required String routineId,
  required DateTime day,
}) {
  final localDay = DateTime.utc(day.year, day.month, day.day);
  return RoutineCompletion(
    id: id,
    routineId: routineId,
    completedAtUtc: localDay.add(const Duration(hours: 9)),
    createdAtUtc: localDay.add(const Duration(hours: 9)),
    completedDayLocal: localDay,
  );
}
