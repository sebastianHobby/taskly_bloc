@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/src/values/model/value_assignment.dart';

void main() {
  Value value({required String id, required String name, String? color}) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: name,
      color: color,
    );
  }

  testSafe('ValueAssignment exposes convenience getters', () async {
    final assignment = ValueAssignment(
      value: value(id: 'v1', name: 'Health', color: '#00FF00'),
      isPrimary: true,
    );

    expect(assignment.id, 'v1');
    expect(assignment.name, 'Health');
    expect(assignment.color, '#00FF00');
  });

  testSafe('ValueAssignment.copyWith preserves defaults', () async {
    final base = ValueAssignment(
      value: value(id: 'v1', name: 'Health'),
    );
    final updated = base.copyWith(isPrimary: true);

    expect(base.isPrimary, isFalse);
    expect(updated.isPrimary, isTrue);
    expect(updated.value, base.value);
  });

  testSafe('ValueAssignment equality compares value and isPrimary', () async {
    final a = ValueAssignment(
      value: value(id: 'v1', name: 'Health'),
    );
    final b = ValueAssignment(
      value: value(id: 'v1', name: 'Health'),
    );
    final c = ValueAssignment(
      value: value(id: 'v2', name: 'Other'),
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
