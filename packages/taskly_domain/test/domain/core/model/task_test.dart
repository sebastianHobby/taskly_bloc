@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';

void main() {
  Value value(String id) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'V$id',
    );
  }

  Task task({
    required String id,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    List<Value> values = const <Value>[],
    String? repeatIcalRrule,
    OccurrenceData? occurrence,
  }) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Task $id',
      completed: completed,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      values: values,
      repeatIcalRrule: repeatIcalRrule,
      occurrence: occurrence,
    );
  }

  testSafe('Task.isRepeating reflects repeatIcalRrule', () async {
    expect(task(id: 't1').isRepeating, isFalse);
    expect(task(id: 't2', repeatIcalRrule: '').isRepeating, isFalse);
    expect(
      task(id: 't3', repeatIcalRrule: 'RRULE:FREQ=DAILY').isRepeating,
      isTrue,
    );
  });

  testSafe('Task.isOccurrenceInstance reflects occurrence presence', () async {
    final base = task(id: 't1');
    final occ = task(
      id: 't2',
      occurrence: OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
      ),
    );

    expect(base.isOccurrenceInstance, isFalse);
    expect(occ.isOccurrenceInstance, isTrue);
  });

  testSafe('Task.copyWith overrides only provided fields', () async {
    final base = task(id: 't1', values: [value('v1')], projectId: 'p1');

    final updated = base.copyWith(
      completed: true,
      values: [value('v2')],
      projectId: 'p2',
    );

    expect(base.completed, isFalse);
    expect(updated.completed, isTrue);
    expect(updated.projectId, 'p2');
    expect(updated.values.single.id, 'v2');
    expect(updated.id, 't1');
  });

  testSafe('Task equality compares list contents of values', () async {
    final a = task(id: 't1', values: [value('v1'), value('v2')]);
    final b = task(id: 't1', values: [value('v1'), value('v2')]);
    final c = task(id: 't1', values: [value('v2')]);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
