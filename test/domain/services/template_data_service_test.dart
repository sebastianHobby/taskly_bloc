@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import '../../mocks/repository_mocks.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/routines.dart';
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
      final routineRepo = MockRoutineRepositoryContract();
      final valueRepo = FakeValueRepository();
      final myDayRepo = _RecordingMyDayRepository();
      final clock = FixedClock(DateTime(2025, 1, 15, 12));

      when(
        () => routineRepo.getAll(includeInactive: true),
      ).thenAnswer((_) async => const <Routine>[]);
      when(
        () => routineRepo.delete(any(), context: any(named: 'context')),
      ).thenAnswer((_) async {});
      when(
        () => routineRepo.create(
          name: any(named: 'name'),
          valueId: any(named: 'valueId'),
          routineType: any(named: 'routineType'),
          targetCount: any(named: 'targetCount'),
          scheduleDays: any(named: 'scheduleDays'),
          minSpacingDays: any(named: 'minSpacingDays'),
          restDayBuffer: any(named: 'restDayBuffer'),
          preferredWeeks: any(named: 'preferredWeeks'),
          fixedDayOfMonth: any(named: 'fixedDayOfMonth'),
          fixedWeekday: any(named: 'fixedWeekday'),
          fixedWeekOfMonth: any(named: 'fixedWeekOfMonth'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final service = TemplateDataService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        routineRepository: routineRepo,
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
