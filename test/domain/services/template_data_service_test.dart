@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class FixedClock implements Clock {
  FixedClock(this.now);

  DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TemplateDataService', () {
    testSafe('seeds values, projects, and tasks', () async {
      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final valueRepo = FakeValueRepository();
      final clock = FixedClock(DateTime(2025, 1, 15, 12));

      final service = TemplateDataService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        valueRepository: valueRepo,
        clock: clock,
      );

      await service.resetAndSeed();

      final values = await valueRepo.getAll();
      final projects = await projectRepo.getAll();
      final tasks = await taskRepo.getAll();

      expect(values.length, greaterThan(0));
      expect(projects.length, greaterThan(0));
      expect(tasks.length, greaterThan(0));
      expect(tasks.where((t) => t.isPinned).length, 1);
    });
  });
}
