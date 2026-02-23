@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/src/services/capabilities/entity_tile_capabilities_resolver.dart';

void main() {
  Value _value(String id) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Value $id',
    );
  }

  testSafe('TaskDraft empty/fromTask/copyWith cover fields', () async {
    final empty = TaskDraft.empty();
    expect(empty.name, isEmpty);
    expect(empty.reminderKind, TaskReminderKind.none);
    expect(empty.valueIds, isEmpty);

    final task = Task(
      id: 't1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Task',
      completed: false,
      description: 'Desc',
      startDate: DateTime.utc(2026, 1, 3),
      deadlineDate: DateTime.utc(2026, 1, 4),
      projectId: 'p1',
      priority: 1,
      reminderKind: TaskReminderKind.absolute,
      reminderAtUtc: DateTime.utc(2026, 1, 2, 8),
      reminderMinutesBeforeDue: 30,
      repeatIcalRrule: 'FREQ=DAILY',
      repeatFromCompletion: true,
      seriesEnded: true,
      values: [_value('v1')],
    );

    final fromTask = TaskDraft.fromTask(task);
    expect(fromTask.name, task.name);
    expect(fromTask.projectId, 'p1');
    expect(fromTask.reminderKind, TaskReminderKind.absolute);
    expect(fromTask.valueIds, ['v1']);

    final updated = fromTask.copyWith(name: 'Task 2', completed: true);
    expect(updated.name, 'Task 2');
    expect(updated.completed, isTrue);
  });

  testSafe('ProjectDraft empty/fromProject/copyWith cover fields', () async {
    final empty = ProjectDraft.empty();
    expect(empty.name, isEmpty);
    expect(empty.valueIds, isEmpty);

    final project = Project(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Project',
      completed: false,
      priority: 2,
      repeatIcalRrule: 'FREQ=WEEKLY',
      repeatFromCompletion: true,
      seriesEnded: true,
      values: [_value('v1')],
    );

    final fromProject = ProjectDraft.fromProject(project);
    expect(fromProject.name, project.name);
    expect(fromProject.priority, 2);
    expect(fromProject.valueIds, ['v1']);

    final updated = fromProject.copyWith(name: 'Project 2', completed: true);
    expect(updated.name, 'Project 2');
    expect(updated.completed, isTrue);
  });

  testSafe('RoutineDraft empty/fromRoutine/copyWith cover fields', () async {
    final empty = RoutineDraft.empty();
    expect(empty.periodType, RoutinePeriodType.week);
    expect(empty.scheduleMode, RoutineScheduleMode.flexible);
    expect(empty.targetCount, 3);

    final routine = Routine(
      id: 'r1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Routine',
      projectId: 'p1',
      periodType: RoutinePeriodType.month,
      scheduleMode: RoutineScheduleMode.scheduled,
      targetCount: 4,
      scheduleDays: const [1, 2],
      scheduleMonthDays: const [10, 20],
      scheduleTimeMinutes: 540,
      minSpacingDays: 1,
      restDayBuffer: 2,
      isActive: false,
      pausedUntil: DateTime.utc(2026, 2, 1),
    );

    final fromRoutine = RoutineDraft.fromRoutine(routine);
    expect(fromRoutine.name, routine.name);
    expect(fromRoutine.scheduleMonthDays, [10, 20]);
    expect(fromRoutine.isActive, isFalse);

    final updated = fromRoutine.copyWith(name: 'Routine 2', targetCount: 5);
    expect(updated.name, 'Routine 2');
    expect(updated.targetCount, 5);
  });

  testSafe('Routine model supports pause check and copyWith', () async {
    final routine = Routine(
      id: 'r2',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Routine',
      projectId: 'p1',
      periodType: RoutinePeriodType.week,
      scheduleMode: RoutineScheduleMode.flexible,
      targetCount: 2,
      pausedUntil: DateTime.utc(2026, 1, 15),
    );

    expect(routine.isPausedOn(DateTime.utc(2026, 1, 10)), isTrue);
    expect(routine.isPausedOn(DateTime.utc(2026, 1, 20)), isFalse);

    final copied = routine.copyWith(name: 'Routine New', isActive: false);
    expect(copied.name, 'Routine New');
    expect(copied.isActive, isFalse);
  });

  testSafe('ProjectAnchorState equality/hash/copyWith', () async {
    final state = ProjectAnchorState(
      id: 'a1',
      projectId: 'p1',
      lastAnchoredAtUtc: DateTime.utc(2026, 1, 1),
      createdAtUtc: DateTime.utc(2026, 1, 1),
      updatedAtUtc: DateTime.utc(2026, 1, 1),
    );

    final same = state.copyWith();
    final changed = state.copyWith(projectId: 'p2');

    expect(same, state);
    expect(same.hashCode, state.hashCode);
    expect(changed.projectId, 'p2');
    expect(changed == state, isFalse);
  });

  testSafe('FocusMode extension strings map expected variants', () async {
    expect(FocusMode.intentional.displayName, 'Invest in values');
    expect(FocusMode.sustainable.displayName, 'Invest in values');
    expect(FocusMode.responsive.displayName, 'Protect deadlines');
    expect(FocusMode.personalized.displayName, 'Invest in values');

    expect(FocusMode.intentional.iconName, 'target');
    expect(FocusMode.responsive.iconName, 'bolt');
    expect(FocusMode.responsive.tagline, contains('time risk'));
    expect(FocusMode.intentional.wizardDescription, contains('value'));
  });

  testSafe(
    'EntityTileCapabilitiesResolver resolves per-entity capabilities',
    () async {
      final task = Task(
        id: 't',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Task',
        completed: false,
        occurrence: OccurrenceData(
          date: DateTime.utc(2026, 1, 1),
          isRescheduled: false,
        ),
      );
      final project = Project(
        id: 'p',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Project',
        completed: false,
        occurrence: OccurrenceData(
          date: DateTime.utc(2026, 1, 1),
          isRescheduled: false,
        ),
      );
      final value = _value('v1');

      final taskCaps = EntityTileCapabilitiesResolver.forTask(task);
      final projectCaps = EntityTileCapabilitiesResolver.forProject(project);
      final valueCaps = EntityTileCapabilitiesResolver.forValue(value);

      expect(taskCaps.completionScope, CompletionScope.occurrence);
      expect(taskCaps.canOpenMoveToProject, isTrue);
      expect(projectCaps.completionScope, CompletionScope.occurrence);
      expect(projectCaps.canOpenDetails, isTrue);
      expect(valueCaps.canOpenEditor, isTrue);

      final override = EntityTileCapabilitiesOverride(
        canDelete: false,
        canOpenEditor: false,
      );
      final overridden = EntityTileCapabilitiesResolver.forEntity(
        entityType: EntityType.task,
        task: task,
        override: override,
      );
      expect(overridden.canDelete, isFalse);
      expect(overridden.canOpenEditor, isFalse);
    },
  );
}
