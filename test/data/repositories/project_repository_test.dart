import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

import '../../helpers/test_db.dart';
import '../../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repo;

  setUp(() {
    db = createTestDb();
    repo = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CRUD operations', () {
    test('creates project with required fields only', () async {
      await repo.create(name: 'Test Project');

      final projects = await repo.getAll();
      expect(projects, hasLength(1));
      expect(projects.first.name, 'Test Project');
      expect(projects.first.completed, isFalse);
      expect(projects.first.description, isNull);
    });

    test('creates project with all fields', () async {
      final startDate = DateTime(2025, 1, 1);
      final deadline = DateTime(2025, 12, 31);

      await repo.create(
        name: 'Full Project',
        description: 'Complete description',
        completed: true,
        startDate: startDate,
        deadlineDate: deadline,
        repeatIcalRrule: 'FREQ=WEEKLY',
        repeatFromCompletion: true,
      );

      final projects = await repo.getAll();
      final project = projects.first;
      expect(project.name, 'Full Project');
      expect(project.description, 'Complete description');
      expect(project.completed, isTrue);
      expect(project.repeatIcalRrule, 'FREQ=WEEKLY');
      expect(project.repeatFromCompletion, isTrue);
    });

    test('get returns project when exists', () async {
      await repo.create(name: 'Test Project');
      final projects = await repo.getAll();
      final projectId = projects.first.id;

      final result = await repo.get(projectId);

      expect(result, isNotNull);
      expect(result!.name, 'Test Project');
    });

    test('get returns null when not found', () async {
      final result = await repo.get('non-existent-id');
      expect(result, isNull);
    });

    test('getAll returns all projects', () async {
      await repo.create(name: 'Project 1');
      await repo.create(name: 'Project 2');
      await repo.create(name: 'Project 3');

      final projects = await repo.getAll();
      expect(projects, hasLength(3));
    });

    test('watch emits project when exists', () async {
      await repo.create(name: 'Watch Test');
      final projects = await repo.getAll();
      final projectId = projects.first.id;

      final stream = repo.watch(projectId);
      final result = await stream.first;

      expect(result, isNotNull);
      expect(result!.name, 'Watch Test');
    });

    test('watch emits updates on project changes', () async {
      await repo.create(name: 'Original');
      final projects = await repo.getAll();
      final projectId = projects.first.id;

      final stream = repo.watch(projectId);

      // First emission
      final initial = await stream.first;
      expect(initial?.name, 'Original');

      // Update and check next emission
      await repo.update(
        id: projectId,
        name: 'Updated',
        completed: false,
      );

      final updated = await stream.first;
      expect(updated?.name, 'Updated');
    });

    test('updates project successfully', () async {
      await repo.create(name: 'Original');
      final projects = await repo.getAll();
      final projectId = projects.first.id;

      await repo.update(
        id: projectId,
        name: 'Updated Project',
        completed: true,
        description: 'New description',
      );

      final updated = await repo.get(projectId);
      expect(updated!.name, 'Updated Project');
      expect(updated.completed, isTrue);
      expect(updated.description, 'New description');
    });

    test('update throws RepositoryNotFoundException for non-existent project',
        () async {
      expect(
        () => repo.update(
          id: 'non-existent',
          name: 'Test',
          completed: false,
        ),
        throwsA(isA<RepositoryNotFoundException>()),
      );
    });

    test('deletes project successfully', () async {
      await repo.create(name: 'To Delete');
      final projects = await repo.getAll();
      final projectId = projects.first.id;

      await repo.delete(projectId);

      final result = await repo.get(projectId);
      expect(result, isNull);
    });

    test('delete throws RepositoryNotFoundException for non-existent project',
        () async {
      expect(
        () => repo.delete('non-existent'),
        throwsA(isA<RepositoryNotFoundException>()),
      );
    });
  });

  group('watchAll operations', () {
    test('watchAll emits all projects', () async {
      await repo.create(name: 'Project 1');
      await repo.create(name: 'Project 2');

      final stream = repo.watchAll();
      final projects = await stream.first;

      expect(projects, hasLength(2));
    });

    test('watchAll without related entities', () async {
      await repo.create(name: 'Simple');

      final stream = repo.watchAll(withRelated: false);
      final projects = await stream.first;

      expect(projects, hasLength(1));
      expect(projects.first.name, 'Simple');
    });

    test('watchAll with related entities', () async {
      await repo.create(name: 'With Related');

      final stream = repo.watchAll(withRelated: true);
      final projects = await stream.first;

      expect(projects, hasLength(1));
      expect(projects.first.name, 'With Related');
    });

    test('watchAll emits updates on changes', () async {
      await repo.create(name: 'Initial');

      final stream = repo.watchAll();
      final first = await stream.first;
      expect(first, hasLength(1));

      await repo.create(name: 'Second');

      final second = await stream.first;
      expect(second, hasLength(2));
    });
  });

  group('count operations', () {
    test('count returns total project count', () async {
      await repo.create(name: 'Project 1');
      await repo.create(name: 'Project 2');

      final count = await repo.count();
      expect(count, equals(2));
    });

    test('watchCount emits count updates', () async {
      final stream = repo.watchCount();

      final initial = await stream.first;
      expect(initial, equals(0));

      await repo.create(name: 'Project');

      final afterCreate = await stream.first;
      expect(afterCreate, equals(1));
    });
  });

  group('edge cases', () {
    test('handles null description', () async {
      await repo.create(name: 'Project', description: null);
      final projects = await repo.getAll();
      expect(projects.first.description, isNull);
    });

    test('handles null dates', () async {
      await repo.create(
        name: 'Project',
        startDate: null,
        deadlineDate: null,
      );
      final projects = await repo.getAll();
      expect(projects.first.startDate, isNull);
      expect(projects.first.deadlineDate, isNull);
    });

    test('normalizes dates to dateOnly', () async {
      final dateWithTime = DateTime(2025, 1, 15, 14, 30, 45);
      await repo.create(
        name: 'Project',
        startDate: dateWithTime,
      );

      final projects = await repo.getAll();
      final startDate = projects.first.startDate;
      expect(startDate?.hour, equals(0));
      expect(startDate?.minute, equals(0));
      expect(startDate?.second, equals(0));
    });

  });
}
