@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/allocation/engine/allocation_strategy.dart';
import 'package:taskly_domain/src/allocation/engine/suggested_picks_engine.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/core/model/value_priority.dart';

Task _task({
  required String id,
  required DateTime now,
  String? valueId,
  bool completed = false,
}) {
  final value = valueId == null ? null : _value(id: valueId, now: now);
  return Task(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: 'Task $id',
    completed: completed,
    values: value == null ? const <Value>[] : <Value>[value],
    overridePrimaryValueId: valueId,
  );
}

Value _value({required String id, required DateTime now}) {
  return Value(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: 'Value $id',
    color: '#000000',
    priority: ValuePriority.medium,
  );
}

void main() {
  group('SuggestedPicksEngine', () {
    testSafe('returns empty allocation when disabled', () async {
      final engine = SuggestedPicksEngine();
      final now = DateTime(2025, 1, 15, 12);
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: now,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: const [],
          categories: const {},
          maxTasks: 0,
          taskUrgencyThresholdDays: 3,
          keepValuesInBalance: false,
          completionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks, isEmpty);
      expect(result.excludedTasks, isEmpty);
      expect(result.reasoning.explanation, contains('No allocation'));
    });

    testSafe(
      'allocates proportionally by category and excludes valueless',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final tasks = [
          _task(id: 't1', now: now, valueId: 'v1'),
          _task(id: 't2', now: now, valueId: 'v1'),
          _task(id: 't3', now: now, valueId: 'v2'),
          _task(id: 't4', now: now),
        ];

        final engine = SuggestedPicksEngine();
        final result = engine.allocate(
          AllocationParameters(
            nowUtc: now,
            todayDayKeyUtc: DateTime(2025, 1, 15),
            tasks: tasks,
            categories: const {'v1': 2.0, 'v2': 1.0},
            maxTasks: 2,
            taskUrgencyThresholdDays: 3,
            keepValuesInBalance: false,
            completionsByValue: const {},
          ),
        );

        expect(result.allocatedTasks, hasLength(2));
        expect(
          result.excludedTasks.where(
            (e) => e.exclusionType == ExclusionType.noCategory,
          ),
          isNotEmpty,
        );
      },
    );

    testSafe('applies bounded quota repair when enabled', () async {
      final now = DateTime(2025, 1, 15, 12);
      final tasks = [
        _task(id: 't1', now: now, valueId: 'v1'),
        _task(id: 't2', now: now, valueId: 'v1'),
        _task(id: 't3', now: now, valueId: 'v2'),
      ];

      final engine = SuggestedPicksEngine();
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: now,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: tasks,
          categories: const {'v1': 1.0, 'v2': 1.0},
          maxTasks: 2,
          taskUrgencyThresholdDays: 3,
          keepValuesInBalance: true,
          completionsByValue: const {'v1': 10, 'v2': 1},
        ),
      );

      expect(result.reasoning.explanation, contains('balancing'));
    });
  });
}
