import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/occurrence_data.dart';

void main() {
  group('OccurrenceData', () {
    final date = DateTime(2025, 12, 26, 10);
    final deadline = DateTime(2025, 12, 31, 23, 59);
    final originalDate = DateTime(2025, 12, 25, 10);
    final completedAt = DateTime(2025, 12, 30, 15, 30);

    test('creates instance with required fields', () {
      final occurrence = OccurrenceData(
        date: date,
        isRescheduled: false,
      );

      expect(occurrence.date, date);
      expect(occurrence.isRescheduled, isFalse);
      expect(occurrence.deadline, isNull);
      expect(occurrence.originalDate, isNull);
      expect(occurrence.completionId, isNull);
      expect(occurrence.completedAt, isNull);
      expect(occurrence.completionNotes, isNull);
      expect(occurrence.isCompleted, isFalse);
    });

    test('creates instance with all fields', () {
      final occurrence = OccurrenceData(
        date: date,
        isRescheduled: true,
        deadline: deadline,
        originalDate: originalDate,
        completionId: 'completion-1',
        completedAt: completedAt,
        completionNotes: 'Completed ahead of schedule',
      );

      expect(occurrence.date, date);
      expect(occurrence.isRescheduled, isTrue);
      expect(occurrence.deadline, deadline);
      expect(occurrence.originalDate, originalDate);
      expect(occurrence.completionId, 'completion-1');
      expect(occurrence.completedAt, completedAt);
      expect(occurrence.completionNotes, 'Completed ahead of schedule');
      expect(occurrence.isCompleted, isTrue);
    });

    group('isCompleted', () {
      test('returns true when completionId is set', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          completionId: 'completion-1',
        );

        expect(occurrence.isCompleted, isTrue);
      });

      test('returns false when completionId is null', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
        );

        expect(occurrence.isCompleted, isFalse);
      });
    });

    group('isOnTime', () {
      test('returns true when completed before deadline', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: deadline,
          completionId: 'completion-1',
          completedAt: DateTime(2025, 12, 30, 12),
        );

        expect(occurrence.isOnTime, isTrue);
      });

      test('returns true when completed exactly at deadline', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: deadline,
          completionId: 'completion-1',
          completedAt: deadline,
        );

        expect(occurrence.isOnTime, isTrue);
      });

      test('returns false when completed after deadline', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: deadline,
          completionId: 'completion-1',
          completedAt: DateTime(2026),
        );

        expect(occurrence.isOnTime, isFalse);
      });

      test('returns null when not completed', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: deadline,
        );

        expect(occurrence.isOnTime, isNull);
      });

      test('returns null when no deadline', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          completionId: 'completion-1',
          completedAt: completedAt,
        );

        expect(occurrence.isOnTime, isNull);
      });

      test('returns null when no completedAt date', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: deadline,
          completionId: 'completion-1',
        );

        expect(occurrence.isOnTime, isNull);
      });
    });

    group('isOverdue', () {
      test('returns false when completed', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: DateTime(2025), // Past deadline
          completionId: 'completion-1',
        );

        expect(occurrence.isOverdue, isFalse);
      });

      test('returns false when no deadline', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
        );

        expect(occurrence.isOverdue, isFalse);
      });

      test('returns true when past deadline and not completed', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: DateTime(2025), // Past deadline
        );

        expect(occurrence.isOverdue, isTrue);
      });

      test('returns false when deadline is in future', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: false,
          deadline: DateTime(2026, 12, 31), // Future deadline
        );

        expect(occurrence.isOverdue, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = OccurrenceData(
          date: date,
          isRescheduled: false,
        );

        final updated = original.copyWith(
          deadline: deadline,
          isRescheduled: true,
          completionId: 'completion-1',
        );

        expect(updated.date, date);
        expect(updated.isRescheduled, isTrue);
        expect(updated.deadline, deadline);
        expect(updated.completionId, 'completion-1');
      });

      test(
        'creates copy without changing fields when no parameters provided',
        () {
          final original = OccurrenceData(
            date: date,
            isRescheduled: true,
            deadline: deadline,
            originalDate: originalDate,
            completionId: 'completion-1',
            completedAt: completedAt,
            completionNotes: 'Notes',
          );

          final copy = original.copyWith();

          expect(copy.date, original.date);
          expect(copy.isRescheduled, original.isRescheduled);
          expect(copy.deadline, original.deadline);
          expect(copy.originalDate, original.originalDate);
          expect(copy.completionId, original.completionId);
          expect(copy.completedAt, original.completedAt);
          expect(copy.completionNotes, original.completionNotes);
        },
      );

      test('can update all fields', () {
        final original = OccurrenceData(
          date: date,
          isRescheduled: false,
        );

        final newDate = DateTime(2025, 12, 27);
        final newDeadline = DateTime(2026);
        final newOriginalDate = DateTime(2025, 12, 26);
        final newCompletedAt = DateTime(2025, 12, 28);

        final updated = original.copyWith(
          date: newDate,
          deadline: newDeadline,
          originalDate: newOriginalDate,
          isRescheduled: true,
          completionId: 'new-completion',
          completedAt: newCompletedAt,
          completionNotes: 'New notes',
        );

        expect(updated.date, newDate);
        expect(updated.deadline, newDeadline);
        expect(updated.originalDate, newOriginalDate);
        expect(updated.isRescheduled, isTrue);
        expect(updated.completionId, 'new-completion');
        expect(updated.completedAt, newCompletedAt);
        expect(updated.completionNotes, 'New notes');
      });
    });

    group('equality', () {
      test('two occurrences with same values are equal', () {
        final occurrence1 = OccurrenceData(
          date: date,
          isRescheduled: true,
          deadline: deadline,
          originalDate: originalDate,
          completionId: 'completion-1',
          completedAt: completedAt,
          completionNotes: 'Notes',
        );

        final occurrence2 = OccurrenceData(
          date: date,
          isRescheduled: true,
          deadline: deadline,
          originalDate: originalDate,
          completionId: 'completion-1',
          completedAt: completedAt,
          completionNotes: 'Notes',
        );

        expect(occurrence1, equals(occurrence2));
      });

      test('two occurrences with different dates are not equal', () {
        final occurrence1 = OccurrenceData(
          date: date,
          isRescheduled: false,
        );

        final occurrence2 = OccurrenceData(
          date: DateTime(2025, 12, 27),
          isRescheduled: false,
        );

        expect(occurrence1, isNot(equals(occurrence2)));
      });

      test('two occurrences with different isRescheduled are not equal', () {
        final occurrence1 = OccurrenceData(
          date: date,
          isRescheduled: false,
        );

        final occurrence2 = OccurrenceData(
          date: date,
          isRescheduled: true,
        );

        expect(occurrence1, isNot(equals(occurrence2)));
      });

      test('props contains all fields', () {
        final occurrence = OccurrenceData(
          date: date,
          isRescheduled: true,
          deadline: deadline,
          originalDate: originalDate,
          completionId: 'completion-1',
          completedAt: completedAt,
          completionNotes: 'Notes',
        );

        expect(occurrence.props, hasLength(7));
        expect(occurrence.props, contains(date));
        expect(occurrence.props, contains(deadline));
        expect(occurrence.props, contains(originalDate));
        expect(occurrence.props, contains(true));
        expect(occurrence.props, contains('completion-1'));
        expect(occurrence.props, contains(completedAt));
        expect(occurrence.props, contains('Notes'));
      });
    });

    test('toString returns formatted string', () {
      final occurrence = OccurrenceData(
        date: date,
        isRescheduled: true,
        deadline: deadline,
        completionId: 'completion-1',
      );

      final string = occurrence.toString();

      expect(string, contains('OccurrenceData'));
      expect(string, contains('date:'));
      expect(string, contains('deadline:'));
      expect(string, contains('isCompleted: true'));
      expect(string, contains('isRescheduled: true'));
    });
  });
}
