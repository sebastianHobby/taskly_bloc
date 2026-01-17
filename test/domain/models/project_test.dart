import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/test_data.dart';
import '../../helpers/fallback_values.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(registerAllFallbackValues);

  group('Project', () {
    group('construction', () {
      test('creates with required fields', () {
        final now = DateTime.now();
        final project = Project(
          id: 'project-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test Project',
          completed: false,
        );

        expect(project.id, 'project-1');
        expect(project.name, 'Test Project');
        expect(project.completed, false);
        expect(project.createdAt, now);
        expect(project.updatedAt, now);
      });

      test('creates with all optional fields', () {
        final now = DateTime.now();
        final deadline = now.add(const Duration(days: 30));
        final project = Project(
          id: 'project-1',
          createdAt: now,
          updatedAt: now,
          name: 'Full Project',
          completed: true,
          description: 'A full description',
          startDate: now,
          deadlineDate: deadline,
          priority: 2,
          repeatIcalRrule: 'FREQ=MONTHLY',
          repeatFromCompletion: true,
          seriesEnded: true,
        );

        expect(project.description, 'A full description');
        expect(project.startDate, now);
        expect(project.deadlineDate, deadline);
        expect(project.priority, 2);
        expect(project.repeatIcalRrule, 'FREQ=MONTHLY');
        expect(project.repeatFromCompletion, true);
        expect(project.seriesEnded, true);
      });

      test('defaults values to empty list', () {
        final project = TestData.project();
        expect(project.values, isEmpty);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final now = DateTime(2025, 1, 15, 12);
        final project1 = Project(
          id: 'project-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );
        final project2 = Project(
          id: 'project-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );

        expect(project1, equals(project2));
        expect(project1.hashCode, equals(project2.hashCode));
      });

      test('not equal when id differs', () {
        final now = DateTime(2025, 1, 15, 12);
        final project1 = Project(
          id: 'project-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );
        final project2 = Project(
          id: 'project-2',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );

        expect(project1, isNot(equals(project2)));
      });

      test('handles null optional fields', () {
        final project1 = TestData.project();
        final project2 = TestData.project();

        expect(project1.description, isNull);
        expect(project2.description, isNull);
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final project = TestData.project(name: 'Original');
        final copied = project.copyWith(name: 'Changed');

        expect(copied.name, 'Changed');
        expect(copied.id, project.id);
      });

      test('copies with new priority', () {
        final project = TestData.project(priority: null);
        final copied = project.copyWith(priority: 3);

        expect(copied.priority, 3);
      });

      test('preserves unchanged fields', () {
        final project = TestData.project(
          name: 'Test',
          description: 'Desc',
        );
        final copied = project.copyWith(name: 'New Name');

        expect(copied.description, 'Desc');
      });
    });

    group('computed properties', () {
      test('isOccurrenceInstance returns true when occurrence is set', () {
        final project = TestData.project().copyWith(
          occurrence: TestData.occurrenceData(),
        );
        expect(project.isOccurrenceInstance, true);
      });

      test('isOccurrenceInstance returns false when occurrence is null', () {
        final project = TestData.project();
        expect(project.isOccurrenceInstance, false);
      });

      test('isRepeating returns true when repeatIcalRrule is set', () {
        final project = TestData.project(repeatIcalRrule: 'FREQ=MONTHLY');
        expect(project.isRepeating, true);
      });

      test('isRepeating returns false when repeatIcalRrule is null', () {
        final project = TestData.project();
        expect(project.isRepeating, false);
      });

      test('isRepeating returns false when repeatIcalRrule is empty', () {
        final project = TestData.project(repeatIcalRrule: '');
        expect(project.isRepeating, false);
      });
    });

    group('priority', () {
      test('accepts P1-P4 range', () {
        expect(TestData.project(priority: 1).priority, 1);
        expect(TestData.project(priority: 2).priority, 2);
        expect(TestData.project(priority: 3).priority, 3);
        expect(TestData.project(priority: 4).priority, 4);
      });

      test('accepts null for no priority', () {
        final project = TestData.project(priority: null);
        expect(project.priority, isNull);
      });
    });
  });
}
