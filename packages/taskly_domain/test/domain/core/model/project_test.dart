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

  Project project({
    String? primaryValueId,
    String? secondaryValueId,
    List<Value> values = const <Value>[],
    String? repeatIcalRrule,
    OccurrenceData? occurrence,
  }) {
    return Project(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Project',
      completed: false,
      values: values,
      primaryValueId: primaryValueId,
      secondaryValueId: secondaryValueId,
      repeatIcalRrule: repeatIcalRrule,
      occurrence: occurrence,
    );
  }

  testSafe('Project.isRepeating reflects repeatIcalRrule', () async {
    expect(project().isRepeating, isFalse);
    expect(project(repeatIcalRrule: '').isRepeating, isFalse);
    expect(project(repeatIcalRrule: 'RRULE:FREQ=WEEKLY').isRepeating, isTrue);
  });

  testSafe('Project.isOccurrenceInstance reflects occurrence presence', () async {
    expect(project().isOccurrenceInstance, isFalse);

    final withOcc = project(
      occurrence: OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
      ),
    );

    expect(withOcc.isOccurrenceInstance, isTrue);
  });

  testSafe('Project.primaryValue/secondaryValue resolve by id', () async {
    final v1 = value('v1');
    final v2 = value('v2');

    final p = project(
      values: [v1, v2],
      primaryValueId: 'v1',
      secondaryValueId: 'v2',
    );

    expect(p.primaryValue, v1);
    expect(p.secondaryValue, v2);
  });

  testSafe('Project.secondaryValues excludes primary when no secondary slot', () async {
    final v1 = value('v1');
    final v2 = value('v2');

    final p = project(values: [v1, v2], primaryValueId: 'v1');
    expect(p.secondaryValues, [v2]);
  });

  testSafe('Project.secondaryValues returns all when no primary', () async {
    final v1 = value('v1');
    final v2 = value('v2');

    final p = project(values: [v1, v2]);
    expect(p.secondaryValues, [v1, v2]);
  });

  testSafe('Project.copyWith overrides only provided fields', () async {
    final base = project(values: [value('v1')]);

    final updated = base.copyWith(name: 'New', isPinned: true);

    expect(base.isPinned, isFalse);
    expect(updated.isPinned, isTrue);
    expect(updated.name, 'New');
    expect(updated.values, base.values);
  });

  testSafe('Project equality compares list contents of values', () async {
    final a = project(values: [value('v1'), value('v2')]);
    final b = project(values: [value('v1'), value('v2')]);
    final c = project(values: [value('v2')]);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
