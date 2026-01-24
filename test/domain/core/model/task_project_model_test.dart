@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('Task model', () {
    testSafe('copyWith updates fields and preserves others', () async {
      final task = TestData.task(
        name: 'Original',
        completed: false,
        isPinned: false,
      );

      final updated = task.copyWith(name: 'Updated', completed: true);

      expect(updated.name, 'Updated');
      expect(updated.completed, isTrue);
      expect(updated.isPinned, task.isPinned);
      expect(updated.isOccurrenceInstance, isFalse);
    });

    testSafe('isRepeating reflects repeat rule', () async {
      final repeating = TestData.task(repeatIcalRrule: 'FREQ=DAILY');
      final oneOff = TestData.task(repeatIcalRrule: null);

      expect(repeating.isRepeating, isTrue);
      expect(oneOff.isRepeating, isFalse);
    });

    testSafe('equality compares values and occurrence', () async {
      final occurrence = TestData.occurrenceData(date: DateTime(2025, 1, 1));
      final a = TestData.task(id: 't1', occurrence: occurrence);
      final b = a.copyWith();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Project model', () {
    testSafe('copyWith updates fields and preserves others', () async {
      final project = TestData.project(name: 'Original', completed: false);

      final updated = project.copyWith(name: 'Updated', completed: true);

      expect(updated.name, 'Updated');
      expect(updated.completed, isTrue);
      expect(updated.isPinned, project.isPinned);
    });

    testSafe('isRepeating reflects repeat rule', () async {
      final repeating = TestData.project(repeatIcalRrule: 'FREQ=MONTHLY');
      final oneOff = TestData.project(repeatIcalRrule: null);

      expect(repeating.isRepeating, isTrue);
      expect(oneOff.isRepeating, isFalse);
    });

    testSafe('equality compares values and occurrence', () async {
      final occurrence = TestData.occurrenceData(date: DateTime(2025, 1, 1));
      final a = TestData.project(id: 'p1', occurrence: occurrence);
      final b = a.copyWith();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
