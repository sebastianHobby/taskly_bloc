import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/occurrence_data.dart';
import 'package:taskly_bloc/domain/models/project.dart';

void main() {
  group('Project', () {
    final now = DateTime(2025, 12, 26);

    test('creates instance with required fields', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project.id, 'project-1');
      expect(project.name, 'Test Project');
      expect(project.completed, isFalse);
      expect(project.createdAt, now);
      expect(project.updatedAt, now);
      expect(project.description, isNull);
      expect(project.startDate, isNull);
      expect(project.deadlineDate, isNull);
      expect(project.repeatIcalRrule, isNull);
      expect(project.repeatFromCompletion, isFalse);
      expect(project.seriesEnded, isFalse);
      expect(project.labels, isEmpty);
      expect(project.occurrence, isNull);
    });

    test('creates instance with all fields', () {
      final startDate = DateTime(2025, 12, 25);
      final deadlineDate = DateTime(2025, 12, 31);
      final labels = [
        Label(
          id: 'label-1',
          name: 'Important',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final occurrence = OccurrenceData(
        date: deadlineDate,
        deadline: deadlineDate,
        originalDate: startDate,
        isRescheduled: true,
      );

      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: true,
        createdAt: now,
        updatedAt: now,
        description: 'Test description',
        startDate: startDate,
        deadlineDate: deadlineDate,
        repeatIcalRrule: 'FREQ=WEEKLY',
        repeatFromCompletion: true,
        seriesEnded: true,
        labels: labels,
        occurrence: occurrence,
      );

      expect(project.description, 'Test description');
      expect(project.startDate, startDate);
      expect(project.deadlineDate, deadlineDate);
      expect(project.repeatIcalRrule, 'FREQ=WEEKLY');
      expect(project.repeatFromCompletion, isTrue);
      expect(project.seriesEnded, isTrue);
      expect(project.labels, labels);
      expect(project.occurrence, occurrence);
    });

    test('isOccurrenceInstance returns false when occurrence is null', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project.isOccurrenceInstance, isFalse);
    });

    test('isOccurrenceInstance returns true when occurrence is set', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
        occurrence: OccurrenceData(
          date: now,
          originalDate: now,
          isRescheduled: false,
        ),
      );

      expect(project.isOccurrenceInstance, isTrue);
    });

    test('isRepeating returns false when repeatIcalRrule is null', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project.isRepeating, isFalse);
    });

    test('isRepeating returns false when repeatIcalRrule is empty', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
        repeatIcalRrule: '',
      );

      expect(project.isRepeating, isFalse);
    });

    test('isRepeating returns true when repeatIcalRrule is set', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
        repeatIcalRrule: 'FREQ=MONTHLY',
      );

      expect(project.isRepeating, isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      final project = Project(
        id: 'project-1',
        name: 'Original Name',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = project.copyWith(
        name: 'Updated Name',
        completed: true,
        description: 'New description',
      );

      expect(updated.id, project.id);
      expect(updated.name, 'Updated Name');
      expect(updated.completed, isTrue);
      expect(updated.description, 'New description');
      expect(updated.createdAt, project.createdAt);
      expect(updated.updatedAt, project.updatedAt);
    });

    test('copyWith preserves unchanged fields', () {
      final startDate = DateTime(2025, 12, 25);
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
        startDate: startDate,
        description: 'Original description',
      );

      final updated = project.copyWith(name: 'Updated Name');

      expect(updated.name, 'Updated Name');
      expect(updated.description, project.description);
      expect(updated.startDate, project.startDate);
      expect(updated.completed, project.completed);
    });

    test('equality compares all fields', () {
      final project1 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final project2 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project1, equals(project2));
    });

    test('equality returns false for different projects', () {
      final project1 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final project2 = Project(
        id: 'project-2',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project1, isNot(equals(project2)));
    });

    test('equality considers labels', () {
      final labels = [
        Label(
          id: 'label-1',
          name: 'Important',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final project1 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
        labels: labels,
      );

      final project2 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project1, isNot(equals(project2)));
    });

    test('hashCode is consistent with equality', () {
      final project1 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final project2 = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(project1.hashCode, equals(project2.hashCode));
    });

    test('copyWith updates labels', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final labels = [
        Label(
          id: 'label-1',
          name: 'Important',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final updated = project.copyWith(labels: labels);

      expect(updated.labels, equals(labels));
    });

    test('copyWith updates occurrence', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final occurrence = OccurrenceData(
        date: now.add(const Duration(days: 14)),
        originalDate: now,
        isRescheduled: true,
      );

      final updated = project.copyWith(occurrence: occurrence);

      expect(updated.occurrence, equals(occurrence));
    });

    test('copyWith with repeatFromCompletion', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = project.copyWith(repeatFromCompletion: true);

      expect(updated.repeatFromCompletion, isTrue);
    });

    test('copyWith with seriesEnded', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = project.copyWith(seriesEnded: true);

      expect(updated.seriesEnded, isTrue);
    });

    test('copyWith updates all date fields', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final newStart = DateTime(2026);
      final newDeadline = DateTime(2026, 6, 30);

      final updated = project.copyWith(
        startDate: newStart,
        deadlineDate: newDeadline,
      );

      expect(updated.startDate, newStart);
      expect(updated.deadlineDate, newDeadline);
    });

    test('copyWith with same values creates equal object', () {
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
        description: 'Description',
      );

      final updated = project.copyWith(
        name: project.name,
        description: project.description,
      );

      expect(updated, equals(project));
    });
  });
}
