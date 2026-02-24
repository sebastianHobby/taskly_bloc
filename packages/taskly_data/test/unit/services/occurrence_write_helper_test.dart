@Tags(['unit'])
library;

import 'dart:convert';

import '../../helpers/test_db.dart';
import '../../helpers/test_imports.dart';

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_decision_event_repository_impl.dart';
import 'package:taskly_domain/time.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('OccurrenceWriteHelper checklist metrics', () {
    testSafe(
      'completeTaskOccurrence writes checklist parent_completed event',
      () async {
        final db = createAutoClosingDb();
        final ids = IdGenerator.withUserId('user-1');
        final helper = OccurrenceWriteHelper(driftDb: db, idGenerator: ids);

        await _seedTask(db, id: 'task-1', repeatIcalRrule: 'FREQ=DAILY');
        await db
            .into(db.taskChecklistItemsTable)
            .insert(
              TaskChecklistItemsTableCompanion.insert(
                id: 'item-1',
                taskId: 'task-1',
                title: 'step 1',
                sortIndex: 0,
              ),
            );
        await db
            .into(db.taskChecklistItemsTable)
            .insert(
              TaskChecklistItemsTableCompanion.insert(
                id: 'item-2',
                taskId: 'task-1',
                title: 'step 2',
                sortIndex: 1,
              ),
            );

        final occurrenceDate = DateTime.utc(2025, 1, 10);
        await db
            .into(db.taskChecklistItemStateTable)
            .insert(
              TaskChecklistItemStateTableCompanion.insert(
                id: ids.taskChecklistItemStateId(
                  taskId: 'task-1',
                  checklistItemId: 'item-1',
                  occurrenceDate: occurrenceDate,
                ),
                taskId: 'task-1',
                checklistItemId: 'item-1',
                occurrenceDate: drift.Value(occurrenceDate),
                isChecked: const drift.Value(true),
              ),
            );

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: occurrenceDate,
        );

        final events = await db.select(db.checklistEventsTable).get();
        expect(events, hasLength(1));
        final event = events.single;
        expect(event.parentType, 'task');
        expect(event.parentId, 'task-1');
        expect(event.eventType, 'parent_completed');
        expect(event.scopeDate, occurrenceDate);

        final metrics = jsonDecode(event.metricsJson) as Map<String, dynamic>;
        expect(metrics['checked_items'], 1);
        expect(metrics['total_items'], 2);
        expect(metrics['completion_ratio'], 0.5);
        expect(metrics['completed_with_all_items'], false);
      },
    );

    testSafe(
      'completeTaskOccurrence does not write event when checklist is empty',
      () async {
        final db = createAutoClosingDb();
        final helper = OccurrenceWriteHelper(
          driftDb: db,
          idGenerator: IdGenerator.withUserId('user-1'),
        );
        await _seedTask(db, id: 'task-1');

        await helper.completeTaskOccurrence(taskId: 'task-1');

        final events = await db.select(db.checklistEventsTable).get();
        expect(events, isEmpty);
      },
    );

    testSafe(
      'completeTaskOccurrence emits PMD completed event when task is in today picks',
      () async {
        final db = createAutoClosingDb();
        final ids = IdGenerator.withUserId('user-1');
        final fixedNow = DateTime.utc(2026, 2, 24, 9, 30);
        final decisionRepo = MyDayDecisionEventRepositoryImpl(
          driftDb: db,
          ids: ids,
        );
        final helper = OccurrenceWriteHelper(
          driftDb: db,
          idGenerator: ids,
          decisionEventsRepository: decisionRepo,
          clock: _FixedClock(fixedNow),
        );

        await _seedTask(db, id: 'task-1');

        final dayKey = dateOnly(fixedNow);
        final dayId = ids.myDayDayId(dayUtc: dayKey);
        await db
            .into(db.myDayDaysTable)
            .insert(
              MyDayDaysTableCompanion.insert(
                id: dayId,
                dayUtc: dayKey,
              ),
            );
        await db
            .into(db.myDayPicksTable)
            .insert(
              MyDayPicksTableCompanion.insert(
                id: ids.myDayPickId(
                  dayId: dayId,
                  targetType: 'task',
                  targetId: 'task-1',
                ),
                dayId: dayId,
                taskId: const drift.Value('task-1'),
                bucket: 'due',
                sortIndex: 0,
                pickedAt: fixedNow,
                suggestionRank: const drift.Value(3),
              ),
            );

        await helper.completeTaskOccurrence(taskId: 'task-1');

        final events = await db.select(db.myDayDecisionEventsTable).get();
        expect(events, hasLength(1));
        final event = events.single;
        expect(event.entityType, 'task');
        expect(event.entityId, 'task-1');
        expect(event.action, 'completed');
        expect(event.shelf, 'due');
        expect(event.suggestionRank, 3);
      },
    );
  });

  group('OccurrenceWriteHelper core mutation paths', () {
    testSafe(
      'task occurrence paths mutate completion and recurrence tables',
      () async {
        final db = createAutoClosingDb();
        final ids = IdGenerator.withUserId('user-1');
        final helper = OccurrenceWriteHelper(driftDb: db, idGenerator: ids);
        final now = DateTime.utc(2025, 1, 10);

        await _seedProject(db, id: 'project-1');
        await _seedTask(
          db,
          id: 'task-1',
          projectId: 'project-1',
          repeatIcalRrule: '',
        );

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: now,
          notes: 'done',
        );

        var completion = await db
            .select(db.taskCompletionHistoryTable)
            .getSingle();
        expect(completion.taskId, 'task-1');
        expect(completion.notes, 'done');
        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals('task-1'))).getSingle();
        expect(task.completed, isTrue);
        expect(task.isPinned, isFalse);
        final project = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals('project-1'))).getSingle();
        expect(project.lastProgressAt, isNotNull);

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: now,
          notes: 'updated',
        );
        completion = await db.select(db.taskCompletionHistoryTable).getSingle();
        expect(completion.notes, 'updated');

        await helper.uncompleteTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: now,
        );
        final completionsAfterUncomplete = await db
            .select(db.taskCompletionHistoryTable)
            .get();
        expect(completionsAfterUncomplete, isEmpty);

        final taskAfterUncomplete = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals('task-1'))).getSingle();
        expect(taskAfterUncomplete.completed, isFalse);

        await helper.skipTaskOccurrence(
          taskId: 'task-1',
          originalDate: now,
        );
        await helper.rescheduleTaskOccurrence(
          taskId: 'task-1',
          originalDate: now.add(const Duration(days: 1)),
          newDate: now.add(const Duration(days: 2)),
          newDeadline: now.add(const Duration(days: 3)),
        );

        var exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();
        expect(exceptions, hasLength(2));
        expect(
          exceptions.where((e) => e.exceptionType == ExceptionType.skip).length,
          1,
        );
        expect(
          exceptions
              .where((e) => e.exceptionType == ExceptionType.reschedule)
              .single
              .newDeadline,
          DateTime.utc(2025, 1, 13),
        );

        await helper.removeTaskException(
          taskId: 'task-1',
          originalDate: now,
        );
        exceptions = await db.select(db.taskRecurrenceExceptionsTable).get();
        expect(exceptions, hasLength(1));
      },
    );

    testSafe(
      'task series helpers stop, complete, and convert recurrence',
      () async {
        final db = createAutoClosingDb();
        final ids = IdGenerator.withUserId('user-1');
        final helper = OccurrenceWriteHelper(driftDb: db, idGenerator: ids);

        await _seedTask(
          db,
          id: 'task-series',
          repeatIcalRrule: 'FREQ=DAILY',
          repeatFromCompletion: true,
        );
        await db
            .into(db.taskRecurrenceExceptionsTable)
            .insert(
              TaskRecurrenceExceptionsTableCompanion.insert(
                id: 'e-past',
                taskId: 'task-series',
                originalDate: DateTime.utc(2020, 1, 1),
                exceptionType: ExceptionType.skip,
              ),
            );
        await db
            .into(db.taskRecurrenceExceptionsTable)
            .insert(
              TaskRecurrenceExceptionsTableCompanion.insert(
                id: 'e-future',
                taskId: 'task-series',
                originalDate: DateTime.utc(2100, 1, 1),
                exceptionType: ExceptionType.skip,
              ),
            );

        await helper.stopTaskSeries('task-series');
        var row = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals('task-series'))).getSingle();
        expect(row.seriesEnded, isTrue);

        await helper.completeTaskSeries('task-series');
        row = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals('task-series'))).getSingle();
        expect(row.isPinned, isFalse);

        var exceptions = await (db.select(
          db.taskRecurrenceExceptionsTable,
        )..where((e) => e.taskId.equals('task-series'))).get();
        expect(exceptions.map((e) => e.id).toList(), contains('e-past'));
        expect(
          exceptions.map((e) => e.id).toList(),
          isNot(contains('e-future')),
        );

        await helper.convertTaskToOneTime('task-series');
        row = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals('task-series'))).getSingle();
        expect(row.repeatIcalRrule, isNull);
        expect(row.repeatFromCompletion, isFalse);
      },
    );

    testSafe(
      'project occurrence and series paths mutate expected rows',
      () async {
        final db = createAutoClosingDb();
        final ids = IdGenerator.withUserId('user-1');
        final helper = OccurrenceWriteHelper(driftDb: db, idGenerator: ids);
        final now = DateTime.utc(2025, 2, 1);

        await _seedProject(db, id: 'project-1', repeatIcalRrule: '');
        await helper.completeProjectOccurrence(
          projectId: 'project-1',
          occurrenceDate: now,
          notes: 'done',
        );
        var completion = await db
            .select(db.projectCompletionHistoryTable)
            .getSingle();
        expect(completion.notes, 'done');
        var project = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals('project-1'))).getSingle();
        expect(project.completed, isTrue);
        expect(project.isPinned, isFalse);

        await helper.completeProjectOccurrence(
          projectId: 'project-1',
          occurrenceDate: now,
          notes: 'updated',
        );
        completion = await db
            .select(db.projectCompletionHistoryTable)
            .getSingle();
        expect(completion.notes, 'updated');

        await helper.uncompleteProjectOccurrence(
          projectId: 'project-1',
          occurrenceDate: now,
        );
        final completionsAfterUncomplete = await db
            .select(db.projectCompletionHistoryTable)
            .get();
        expect(completionsAfterUncomplete, isEmpty);
        project = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals('project-1'))).getSingle();
        expect(project.completed, isFalse);

        await helper.skipProjectOccurrence(
          projectId: 'project-1',
          originalDate: now,
        );
        await helper.rescheduleProjectOccurrence(
          projectId: 'project-1',
          originalDate: now.add(const Duration(days: 1)),
          newDate: now.add(const Duration(days: 2)),
          newDeadline: now.add(const Duration(days: 3)),
        );

        var exceptions = await db
            .select(db.projectRecurrenceExceptionsTable)
            .get();
        expect(exceptions, hasLength(2));

        await helper.removeProjectException(
          projectId: 'project-1',
          originalDate: now,
        );
        exceptions = await db.select(db.projectRecurrenceExceptionsTable).get();
        expect(exceptions, hasLength(1));

        await _seedProject(
          db,
          id: 'project-series',
          repeatIcalRrule: 'FREQ=WEEKLY',
          repeatFromCompletion: true,
        );
        await db
            .into(db.projectRecurrenceExceptionsTable)
            .insert(
              ProjectRecurrenceExceptionsTableCompanion.insert(
                id: 'p-past',
                projectId: 'project-series',
                originalDate: DateTime.utc(2020, 1, 1),
                exceptionType: ExceptionType.skip,
              ),
            );
        await db
            .into(db.projectRecurrenceExceptionsTable)
            .insert(
              ProjectRecurrenceExceptionsTableCompanion.insert(
                id: 'p-future',
                projectId: 'project-series',
                originalDate: DateTime.utc(2100, 1, 1),
                exceptionType: ExceptionType.skip,
              ),
            );

        await helper.stopProjectSeries('project-series');
        await helper.completeProjectSeries('project-series');
        await helper.convertProjectToOneTime('project-series');

        final projectSeries = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals('project-series'))).getSingle();
        expect(projectSeries.seriesEnded, isTrue);
        expect(projectSeries.isPinned, isFalse);
        expect(projectSeries.repeatIcalRrule, isNull);
        expect(projectSeries.repeatFromCompletion, isFalse);
      },
    );
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}

Future<void> _seedTask(
  AppDatabase db, {
  required String id,
  String? projectId,
  String? repeatIcalRrule,
  bool repeatFromCompletion = false,
}) async {
  await db
      .into(db.taskTable)
      .insert(
        TaskTableCompanion.insert(
          id: drift.Value(id),
          name: 'Task $id',
          completed: const drift.Value(false),
          projectId: drift.Value(projectId),
          repeatIcalRrule: drift.Value(repeatIcalRrule ?? ''),
          repeatFromCompletion: drift.Value(repeatFromCompletion),
        ),
      );
}

Future<void> _seedProject(
  AppDatabase db, {
  required String id,
  String? repeatIcalRrule,
  bool repeatFromCompletion = false,
}) async {
  await db
      .into(db.projectTable)
      .insert(
        ProjectTableCompanion.insert(
          id: drift.Value(id),
          name: 'Project $id',
          completed: false,
          primaryValueId: const drift.Value('v1'),
          repeatIcalRrule: drift.Value(repeatIcalRrule ?? ''),
          repeatFromCompletion: drift.Value(repeatFromCompletion),
        ),
      );
}
