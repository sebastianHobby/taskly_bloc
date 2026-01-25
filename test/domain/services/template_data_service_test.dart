@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

class FixedClock implements Clock {
  FixedClock(this.now);

  DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

class _RecordingMyDayRepository implements MyDayRepositoryContract {
  final List<DateTime> clearedDays = [];

  @override
  Future<void> clearDay({
    required DateTime dayKeyUtc,
    OperationContext? context,
  }) async {
    clearedDays.add(dayKeyUtc);
  }

  @override
  Stream<MyDayDayPicks> watchDay(DateTime dayKeyUtc) {
    throw UnimplementedError();
  }

  @override
  Future<MyDayDayPicks> loadDay(DateTime dayKeyUtc) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDayPicks({
    required DateTime dayKeyUtc,
    required DateTime ritualCompletedAtUtc,
    required List<MyDayPick> picks,
    required OperationContext context,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> appendPick({
    required DateTime dayKeyUtc,
    required String taskId,
    required MyDayPickBucket bucket,
    required OperationContext context,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TemplateDataService', () {
    testSafe('seeds values, projects, and tasks', () async {
      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final valueRepo = FakeValueRepository();
      final myDayRepo = _RecordingMyDayRepository();
      final clock = FixedClock(DateTime(2025, 1, 15, 12));

      final service = TemplateDataService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        valueRepository: valueRepo,
        myDayRepository: myDayRepo,
        clock: clock,
      );

      await service.resetAndSeed();

      final values = await valueRepo.getAll();
      final projects = await projectRepo.getAll();
      final tasks = await taskRepo.getAll();

      expect(values.length, greaterThan(0));
      expect(projects.length, equals(6));
      expect(tasks.length, greaterThanOrEqualTo(30));
      expect(tasks.where((t) => t.isPinned).length, 1);
      expect(
        myDayRepo.clearedDays,
        contains(dateOnly(clock.now)),
      );
    });
  });
}
