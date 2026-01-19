@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';

void main() {
  testSafe('Value.copyWith overrides only provided fields', () async {
    final base = Value(
      id: 'v1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Health',
      color: '#00FF00',
      iconName: 'heart',
      priority: ValuePriority.medium,
    );

    final updated = base.copyWith(
      name: 'Fitness',
      priority: ValuePriority.high,
    );

    expect(updated.id, 'v1');
    expect(updated.name, 'Fitness');
    expect(updated.priority, ValuePriority.high);
    expect(updated.color, '#00FF00');
  });

  testSafe('Value equality compares all fields', () async {
    final a = Value(
      id: 'v1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Health',
      color: null,
      iconName: null,
      priority: ValuePriority.low,
    );

    final b = Value(
      id: 'v1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Health',
      color: null,
      iconName: null,
      priority: ValuePriority.low,
    );

    final c = b.copyWith(name: 'Other');

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });

  testSafe('ValuePriority exposes stable weights', () async {
    expect(ValuePriority.low.weight, 1);
    expect(ValuePriority.medium.weight, 3);
    expect(ValuePriority.high.weight, 5);
  });
}
