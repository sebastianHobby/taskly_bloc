@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('Value model', () {
    testSafe('copyWith updates fields and preserves others', () async {
      final value = TestData.value(
        name: 'Original',
        color: '#123456',
        priority: ValuePriority.low,
      );

      final updated = value.copyWith(name: 'Updated', color: '#654321');

      expect(updated.name, 'Updated');
      expect(updated.color, '#654321');
      expect(updated.priority, value.priority);
      expect(updated.createdAt, value.createdAt);
    });

    testSafe('equality compares values', () async {
      final value = TestData.value(id: 'v1');
      final clone = value.copyWith();

      expect(value, clone);
      expect(value.hashCode, clone.hashCode);
    });
  });

  group('ValueDraft', () {
    testSafe('empty uses default values', () async {
      final draft = ValueDraft.empty();

      expect(draft.name, '');
      expect(draft.color, '#000000');
      expect(draft.priority, ValuePriority.medium);
      expect(draft.iconName, isNull);
    });

    testSafe('fromValue applies fallback color', () async {
      final value = TestData.value(color: null, priority: ValuePriority.high);

      final draft = ValueDraft.fromValue(value);

      expect(draft.name, value.name);
      expect(draft.color, '#000000');
      expect(draft.priority, ValuePriority.high);
    });

    testSafe('copyWith overrides fields', () async {
      final draft = ValueDraft.empty();

      final updated = draft.copyWith(
        name: 'Focus',
        color: '#00FF00',
        priority: ValuePriority.high,
      );

      expect(updated.name, 'Focus');
      expect(updated.color, '#00FF00');
      expect(updated.priority, ValuePriority.high);
      expect(updated.iconName, isNull);
    });
  });
}
