@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

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
    required String id,
    String? primaryValueId,
    String? secondaryValueId,
    List<Value> values = const <Value>[],
  }) {
    return Project(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Project $id',
      completed: false,
      values: values,
      primaryValueId: primaryValueId,
      secondaryValueId: secondaryValueId,
    );
  }

  Task task({
    required String id,
    Project? project,
    List<Value> values = const <Value>[],
    String? overridePrimaryValueId,
    String? overrideSecondaryValueId,
  }) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Task $id',
      completed: false,
      project: project,
      values: values,
      overridePrimaryValueId: overridePrimaryValueId,
      overrideSecondaryValueId: overrideSecondaryValueId,
    );
  }

  testSafe('Effective values are empty when no ids exist', () async {
    final t = task(id: 't1');

    expect(t.isOverridingValues, isFalse);
    expect(t.isInheritingValues, isFalse);
    expect(t.effectivePrimaryValueId, isNull);
    expect(t.effectiveSecondaryValueId, isNull);
    expect(t.effectiveValues, isEmpty);
    expect(t.isEffectivelyValueless, isTrue);
  });

  testSafe(
    'Effective values inherit from project when task is not overriding',
    () async {
      final v1 = value('v1');
      final v2 = value('v2');

      final p = project(
        id: 'p1',
        primaryValueId: 'v1',
        secondaryValueId: 'v2',
        values: [v1, v2],
      );

      final t = task(id: 't1', project: p);

      expect(t.isOverridingValues, isFalse);
      expect(t.isInheritingValues, isTrue);
      expect(t.effectivePrimaryValueId, 'v1');
      expect(t.effectiveSecondaryValueId, 'v2');
      expect(t.effectiveValues.map((v) => v.id).toList(), ['v1', 'v2']);
      expect(t.effectivePrimaryValue?.id, 'v1');
      expect(t.effectiveSecondaryValues.map((v) => v.id).toList(), ['v2']);
    },
  );

  testSafe(
    'Effective values use task overrides and do not inherit secondary',
    () async {
      final v1 = value('v1');
      final v2 = value('v2');

      final p = project(
        id: 'p1',
        primaryValueId: 'v1',
        secondaryValueId: 'v2',
        values: [v1, v2],
      );

      final t = task(
        id: 't1',
        project: p,
        overridePrimaryValueId: 'v1',
        overrideSecondaryValueId: null,
      );

      expect(t.isOverridingValues, isTrue);
      expect(t.isInheritingValues, isFalse);
      expect(t.effectivePrimaryValueId, 'v1');
      expect(t.effectiveSecondaryValueId, isNull);
      expect(t.effectiveValues.map((v) => v.id).toList(), ['v1']);
      expect(t.effectiveSecondaryValues, isEmpty);
    },
  );

  testSafe(
    'Effective values dedupe secondary when it equals primary',
    () async {
      final v1 = value('v1');

      final t = task(
        id: 't1',
        values: [v1],
        overridePrimaryValueId: 'v1',
        overrideSecondaryValueId: 'v1',
      );

      expect(t.effectiveValues.map((v) => v.id).toList(), ['v1']);
    },
  );
}
