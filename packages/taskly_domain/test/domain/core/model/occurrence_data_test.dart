@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';

void main() {
  testSafe(
    'OccurrenceData.isCompleted reflects completionId presence',
    () async {
      final o1 = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        completionId: null,
      );

      final o2 = o1.copyWith(
        completionId: 'c1',
        completedAt: DateTime.utc(2026, 1, 18, 9),
      );

      expect(o1.isCompleted, isFalse);
      expect(o2.isCompleted, isTrue);
    },
  );

  testSafe(
    'OccurrenceData.isOnTime returns null when insufficient info',
    () async {
      final o = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        deadline: DateTime.utc(2026, 1, 18, 12),
        completionId: 'c1',
        completedAt: null,
      );

      expect(o.isOnTime, isNull);
    },
  );

  testSafe(
    'OccurrenceData.isOnTime true when completed on/before deadline',
    () async {
      final o = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        deadline: DateTime.utc(2026, 1, 18, 12),
        completionId: 'c1',
        completedAt: DateTime.utc(2026, 1, 18, 12),
      );

      expect(o.isOnTime, isTrue);
    },
  );

  testSafe(
    'OccurrenceData.isOnTime false when completed after deadline',
    () async {
      final o = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        deadline: DateTime.utc(2026, 1, 18, 12),
        completionId: 'c1',
        completedAt: DateTime.utc(2026, 1, 18, 13),
      );

      expect(o.isOnTime, isFalse);
    },
  );

  testSafe(
    'OccurrenceData.isOverdueAt true when past deadline and not completed',
    () async {
      final o = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        deadline: DateTime.utc(2026, 1, 18, 12),
      );

      expect(o.isOverdueAt(nowUtc: DateTime.utc(2026, 1, 18, 13)), isTrue);
      expect(o.isOverdueAt(nowUtc: DateTime.utc(2026, 1, 18, 11)), isFalse);
    },
  );

  testSafe(
    'OccurrenceData.isOverdueAt false when completed or no deadline',
    () async {
      final completed = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        deadline: DateTime.utc(2026, 1, 18, 12),
        completionId: 'c1',
        completedAt: DateTime.utc(2026, 1, 18, 11),
      );

      final noDeadline = OccurrenceData(
        date: DateTime.utc(2026, 1, 18),
        isRescheduled: false,
        deadline: null,
      );

      expect(
        completed.isOverdueAt(nowUtc: DateTime.utc(2026, 1, 18, 13)),
        isFalse,
      );
      expect(
        noDeadline.isOverdueAt(nowUtc: DateTime.utc(2026, 1, 18, 13)),
        isFalse,
      );
    },
  );
}
