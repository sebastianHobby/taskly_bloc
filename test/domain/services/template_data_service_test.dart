@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import '../../mocks/repository_mocks.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/preferences.dart';
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

class _RecordingUserDataWipeService implements UserDataWipeService {
  int wipeCalls = 0;

  @override
  Future<void> wipeAllUserData({Duration? timeout}) async {
    wipeCalls += 1;
  }
}

class _InMemorySettingsRepository implements SettingsRepositoryContract {
  GlobalSettings settings = const GlobalSettings();

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    throw UnimplementedError();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (key == SettingsKey.global) return settings as T;
    throw UnimplementedError();
  }

  @override
  Future<void> save<T>(
    SettingsKey<T> key,
    T value, {
    OperationContext? context,
  }) async {
    if (key != SettingsKey.global) throw UnimplementedError();
    settings = value as GlobalSettings;
  }
}

class _InMemoryValueRatingsRepository extends Fake
    implements ValueRatingsRepositoryContract {
  final Map<String, ValueWeeklyRating> _ratings = <String, ValueWeeklyRating>{};

  @override
  Future<void> upsertWeeklyRating({
    required String valueId,
    required DateTime weekStartUtc,
    required int rating,
    OperationContext? context,
  }) async {
    final week = dateOnly(weekStartUtc);
    final key = '$valueId-${week.toIso8601String()}';
    final now = DateTime.utc(2025, 1, 15, 12);
    _ratings[key] = ValueWeeklyRating(
      id: key,
      valueId: valueId,
      weekStartUtc: week,
      rating: rating,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  @override
  Future<List<ValueWeeklyRating>> getAll({int weeks = 4}) async {
    return _ratings.values.toList(growable: false);
  }

  @override
  Future<List<ValueWeeklyRating>> getForValue(
    String valueId, {
    int weeks = 4,
  }) async {
    return _ratings.values
        .where((entry) => entry.valueId == valueId)
        .toList(growable: false);
  }

  @override
  Stream<List<ValueWeeklyRating>> watchAll({int weeks = 4}) {
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
      final ratingsRepo = _InMemoryValueRatingsRepository();
      final ratingsWriteService = ValueRatingsWriteService(
        repository: ratingsRepo,
      );
      final wipeService = _RecordingUserDataWipeService();
      final settingsRepo = _InMemorySettingsRepository();
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
        valueRatingsWriteService: ratingsWriteService,
        userDataWipeService: wipeService,
        settingsRepository: settingsRepo,
        clock: clock,
      );

      await service.resetAndSeed();

      final values = await valueRepo.getAll();
      final projects = await projectRepo.getAll();
      final tasks = await taskRepo.getAll();

      expect(values.length, greaterThan(0));
      expect(projects.length, equals(4));
      expect(tasks.length, greaterThanOrEqualTo(30));
      expect(tasks.where((t) => t.isPinned).length, 1);
      expect(wipeService.wipeCalls, 1);
      expect(ratingsRepo.getAll(), completion(isNotEmpty));
      expect(settingsRepo.settings.weeklyReviewLastCompletedAt, isNull);
      expect(settingsRepo.settings.onboardingCompleted, isTrue);
    });
  });
}
