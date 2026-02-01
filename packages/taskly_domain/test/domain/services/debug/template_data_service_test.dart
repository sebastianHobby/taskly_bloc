@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_domain/telemetry.dart';

class _InMemoryValueRepo extends Fake implements ValueRepositoryContract {
  _InMemoryValueRepo({List<Value>? seed}) {
    if (seed != null) _values.addAll(seed);
  }

  final List<Value> _values = <Value>[];
  int _idCounter = 0;

  @override
  Future<List<Value>> getAll([ValueQuery? query]) async {
    return List<Value>.from(_values);
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
    OperationContext? context,
  }) async {
    final id = 'v${++_idCounter}';
    _values.add(
      Value(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: name,
        color: color,
        iconName: iconName,
        priority: priority,
      ),
    );
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    _values.removeWhere((value) => value.id == id);
  }
}

class _InMemoryProjectRepo extends Fake implements ProjectRepositoryContract {
  _InMemoryProjectRepo({List<Project>? seed}) {
    if (seed != null) _projects.addAll(seed);
  }

  final List<Project> _projects = <Project>[];
  int _idCounter = 0;

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async {
    return List<Project>.from(_projects);
  }

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    int? priority,
    OperationContext? context,
  }) async {
    final id = 'p${++_idCounter}';
    _projects.add(
      Project(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: name,
        completed: completed,
        description: description,
        startDate: startDate,
        deadlineDate: deadlineDate,
        repeatIcalRrule: repeatIcalRrule,
        repeatFromCompletion: repeatFromCompletion,
        seriesEnded: seriesEnded,
        priority: priority,
        primaryValueId: valueIds?.isNotEmpty == true ? valueIds!.first : null,
      ),
    );
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    _projects.removeWhere((project) => project.id == id);
  }
}

class _InMemoryTaskRepo extends Fake implements TaskRepositoryContract {
  _InMemoryTaskRepo({List<Task>? seed}) {
    if (seed != null) _tasks.addAll(seed);
  }

  final List<Task> _tasks = <Task>[];
  int _idCounter = 0;

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async {
    return List<Task>.from(_tasks);
  }

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    OperationContext? context,
  }) async {
    final id = 't${++_idCounter}';
    _tasks.add(
      Task(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: name,
        completed: completed,
        description: description,
        startDate: startDate,
        deadlineDate: deadlineDate,
        projectId: projectId,
        priority: priority,
        repeatIcalRrule: repeatIcalRrule,
        repeatFromCompletion: repeatFromCompletion,
        seriesEnded: seriesEnded,
        overridePrimaryValueId: valueIds?.isNotEmpty == true
            ? valueIds!.first
            : null,
        overrideSecondaryValueId: valueIds != null && valueIds.length > 1
            ? valueIds[1]
            : null,
      ),
    );
  }

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  }) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(isPinned: isPinned);
  }

  @override
  Future<void> setMyDaySnoozedUntil({
    required String id,
    required DateTime? untilUtc,
    OperationContext? context,
  }) async {
    // No-op for template seeding tests.
  }

  @override
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(completed: true);
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  }) async {
    return const <String, TaskSnoozeStats>{};
  }
}

class _InMemoryRoutineRepo extends Fake implements RoutineRepositoryContract {
  _InMemoryRoutineRepo({List<Routine>? seed}) {
    if (seed != null) _routines.addAll(seed);
  }

  final List<Routine> _routines = <Routine>[];
  int _idCounter = 0;

  @override
  Future<List<Routine>> getAll({bool includeInactive = true}) async {
    return List<Routine>.from(_routines);
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    _routines.removeWhere((routine) => routine.id == id);
  }

  @override
  Stream<List<Routine>> watchAll({bool includeInactive = true}) {
    throw UnimplementedError();
  }

  @override
  Stream<Routine?> watchById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Routine?> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> create({
    required String name,
    required String valueId,
    required RoutineType routineType,
    required int targetCount,
    List<int> scheduleDays = const <int>[],
    int? minSpacingDays,
    int? restDayBuffer,
    List<int> preferredWeeks = const <int>[],
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool isActive = true,
    DateTime? pausedUntilUtc,
    OperationContext? context,
  }) async {
    final id = 'r${++_idCounter}';
    _routines.add(
      Routine(
        id: id,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: name,
        valueId: valueId,
        routineType: routineType,
        targetCount: targetCount,
        scheduleDays: scheduleDays,
        minSpacingDays: minSpacingDays,
        restDayBuffer: restDayBuffer,
        preferredWeeks: preferredWeeks,
        fixedDayOfMonth: fixedDayOfMonth,
        fixedWeekday: fixedWeekday,
        fixedWeekOfMonth: fixedWeekOfMonth,
        isActive: isActive,
        pausedUntil: pausedUntilUtc,
      ),
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String valueId,
    required RoutineType routineType,
    required int targetCount,
    String? projectId,
    List<int>? scheduleDays,
    int? minSpacingDays,
    int? restDayBuffer,
    List<int>? preferredWeeks,
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool? isActive,
    DateTime? pausedUntilUtc,
    OperationContext? context,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<RoutineCompletion>> watchCompletions() {
    throw UnimplementedError();
  }

  @override
  Stream<List<RoutineSkip>> watchSkips() {
    throw UnimplementedError();
  }

  @override
  Future<List<RoutineCompletion>> getCompletions() {
    throw UnimplementedError();
  }

  @override
  Future<List<RoutineSkip>> getSkips() {
    throw UnimplementedError();
  }

  @override
  Future<void> recordCompletion({
    required String routineId,
    DateTime? completedAtUtc,
    OperationContext? context,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeLatestCompletionForDay({
    required String routineId,
    required DateTime dayKeyUtc,
    OperationContext? context,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordSkip({
    required String routineId,
    required RoutineSkipPeriodType periodType,
    required DateTime periodKeyUtc,
    OperationContext? context,
  }) {
    throw UnimplementedError();
  }
}

class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}

class _RecordingUserDataWipeService implements UserDataWipeService {
  _RecordingUserDataWipeService({this.onWipe});

  final void Function()? onWipe;
  int wipeCalls = 0;

  @override
  Future<void> wipeAllUserData({Duration? timeout}) async {
    wipeCalls += 1;
    onWipe?.call();
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
    final now = DateTime.utc(2026, 1, 1);
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
  testSafe(
    'resetAndSeed wipes existing data and seeds template entries',
    () async {
      final valueRepo = _InMemoryValueRepo(
        seed: <Value>[
          Value(
            id: 'v-old',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            name: 'Old Value',
          ),
        ],
      );
      final projectRepo = _InMemoryProjectRepo(
        seed: <Project>[
          Project(
            id: 'p-old',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            name: 'Old Project',
            completed: false,
          ),
        ],
      );
      final taskRepo = _InMemoryTaskRepo(
        seed: <Task>[
          Task(
            id: 't-old',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            name: 'Old Task',
            completed: false,
          ),
        ],
      );

      final routineRepo = _InMemoryRoutineRepo();
      final wipeService = _RecordingUserDataWipeService(
        onWipe: () {
          valueRepo._values.clear();
          projectRepo._projects.clear();
          taskRepo._tasks.clear();
        },
      );
      final ratingsRepo = _InMemoryValueRatingsRepository();
      final ratingsWriteService = ValueRatingsWriteService(
        repository: ratingsRepo,
      );
      final settingsRepo = _InMemorySettingsRepository();
      final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));
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
      final routines = await routineRepo.getAll();

      expect(values, hasLength(4));
      expect(
        values.map((v) => v.name),
        containsAll(<String>[
          'Learning',
          'Health',
          'Career',
          'Social',
        ]),
      );
      expect(projects, hasLength(4));
      expect(tasks, hasLength(12));
      expect(routines, hasLength(2));
      expect(wipeService.wipeCalls, 1);
      expect(ratingsRepo.getAll(), completion(isNotEmpty));
      expect(settingsRepo.settings.weeklyReviewLastCompletedAt, isNull);
      expect(settingsRepo.settings.onboardingCompleted, isTrue);
    },
  );
}
