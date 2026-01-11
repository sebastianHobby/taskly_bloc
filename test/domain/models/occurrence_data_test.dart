import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/core/model/occurrence_data.dart';

void main() {
  group('OccurrenceData', () {
    final testDate = DateTime(2025, 1, 15);
    final testDeadline = DateTime(2025, 1, 20);
    final testOriginalDate = DateTime(2025, 1, 10);
    final testCompletedAt = DateTime(2025, 1, 18);

    group('constructor', () {
      test('creates with required parameters', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
        );

        expect(data.date, testDate);
        expect(data.isRescheduled, false);
        expect(data.deadline, isNull);
        expect(data.originalDate, isNull);
        expect(data.completionId, isNull);
        expect(data.completedAt, isNull);
        expect(data.completionNotes, isNull);
      });

      test('creates with all parameters', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: true,
          deadline: testDeadline,
          originalDate: testOriginalDate,
          completionId: 'completion-123',
          completedAt: testCompletedAt,
          completionNotes: 'Done with notes',
        );

        expect(data.date, testDate);
        expect(data.isRescheduled, true);
        expect(data.deadline, testDeadline);
        expect(data.originalDate, testOriginalDate);
        expect(data.completionId, 'completion-123');
        expect(data.completedAt, testCompletedAt);
        expect(data.completionNotes, 'Done with notes');
      });
    });

    group('isCompleted', () {
      test('returns false when completionId is null', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
        );

        expect(data.isCompleted, false);
      });

      test('returns true when completionId is set', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          completionId: 'completion-123',
        );

        expect(data.isCompleted, true);
      });
    });

    group('isOnTime', () {
      test('returns null when not completed', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: testDeadline,
        );

        expect(data.isOnTime, isNull);
      });

      test('returns null when no deadline', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          completionId: 'completion-123',
          completedAt: testCompletedAt,
        );

        expect(data.isOnTime, isNull);
      });

      test('returns null when completedAt is null', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: testDeadline,
          completionId: 'completion-123',
        );

        expect(data.isOnTime, isNull);
      });

      test('returns true when completed before deadline', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: DateTime(2025, 1, 20),
          completionId: 'completion-123',
          completedAt: DateTime(2025, 1, 18),
        );

        expect(data.isOnTime, true);
      });

      test('returns true when completed on deadline', () {
        final deadline = DateTime(2025, 1, 20);
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: deadline,
          completionId: 'completion-123',
          completedAt: deadline,
        );

        expect(data.isOnTime, true);
      });

      test('returns false when completed after deadline', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: DateTime(2025, 1, 15),
          completionId: 'completion-123',
          completedAt: DateTime(2025, 1, 20),
        );

        expect(data.isOnTime, false);
      });
    });

    group('isOverdue', () {
      test('returns false when no deadline', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
        );

        expect(data.isOverdue, false);
      });

      test('returns false when completed', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: DateTime(2020, 1, 1), // Past deadline
          completionId: 'completion-123',
        );

        expect(data.isOverdue, false);
      });

      test('returns false when deadline is in future', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: DateTime.now().add(const Duration(days: 30)),
        );

        expect(data.isOverdue, false);
      });

      test('returns true when deadline is past and not completed', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: DateTime(2020, 1, 1),
        );

        expect(data.isOverdue, true);
      });
    });

    group('copyWith', () {
      final original = OccurrenceData(
        date: testDate,
        isRescheduled: false,
        deadline: testDeadline,
        originalDate: testOriginalDate,
        completionId: 'original-id',
        completedAt: testCompletedAt,
        completionNotes: 'Original notes',
      );

      test('updates date only', () {
        final newDate = DateTime(2025, 2, 1);
        final copy = original.copyWith(date: newDate);

        expect(copy.date, newDate);
        expect(copy.isRescheduled, original.isRescheduled);
        expect(copy.deadline, original.deadline);
      });

      test('updates deadline only', () {
        final newDeadline = DateTime(2025, 2, 15);
        final copy = original.copyWith(deadline: newDeadline);

        expect(copy.deadline, newDeadline);
        expect(copy.date, original.date);
      });

      test('updates originalDate only', () {
        final newOriginalDate = DateTime(2025, 1, 5);
        final copy = original.copyWith(originalDate: newOriginalDate);

        expect(copy.originalDate, newOriginalDate);
        expect(copy.date, original.date);
      });

      test('updates isRescheduled only', () {
        final copy = original.copyWith(isRescheduled: true);

        expect(copy.isRescheduled, true);
        expect(copy.date, original.date);
      });

      test('updates completionId only', () {
        final copy = original.copyWith(completionId: 'new-id');

        expect(copy.completionId, 'new-id');
        expect(copy.completedAt, original.completedAt);
      });

      test('updates completedAt only', () {
        final newCompletedAt = DateTime(2025, 1, 25);
        final copy = original.copyWith(completedAt: newCompletedAt);

        expect(copy.completedAt, newCompletedAt);
        expect(copy.completionId, original.completionId);
      });

      test('updates completionNotes only', () {
        final copy = original.copyWith(completionNotes: 'New notes');

        expect(copy.completionNotes, 'New notes');
        expect(copy.date, original.date);
      });

      test('returns equivalent when no parameters', () {
        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        final a = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: testDeadline,
        );
        final b = OccurrenceData(
          date: testDate,
          isRescheduled: false,
          deadline: testDeadline,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different date produces different instance', () {
        final a = OccurrenceData(
          date: testDate,
          isRescheduled: false,
        );
        final b = OccurrenceData(
          date: DateTime(2025, 2, 1),
          isRescheduled: false,
        );

        expect(a, isNot(b));
      });

      test('different isRescheduled produces different instance', () {
        final a = OccurrenceData(
          date: testDate,
          isRescheduled: false,
        );
        final b = OccurrenceData(
          date: testDate,
          isRescheduled: true,
        );

        expect(a, isNot(b));
      });
    });

    group('toString', () {
      test('returns string representation', () {
        final data = OccurrenceData(
          date: testDate,
          isRescheduled: true,
          deadline: testDeadline,
          completionId: 'completion-123',
        );

        final str = data.toString();

        expect(str, contains('OccurrenceData'));
        expect(str, contains('date'));
        expect(str, contains('deadline'));
        expect(str, contains('isCompleted'));
        expect(str, contains('isRescheduled'));
      });
    });
  });
}
