@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class _MockTaskRepo extends Mock implements TaskRepositoryContract {}

class _MockProjectRepo extends Mock implements ProjectRepositoryContract {}

class _MockProjectAnchorStateRepo extends Mock
    implements ProjectAnchorStateRepositoryContract {}

class _MockValueRepo extends Mock implements ValueRepositoryContract {}

class _MockValueRatingsRepo extends Mock
    implements ValueRatingsRepositoryContract {}

class _MockSettingsRepo extends Mock implements SettingsRepositoryContract {}

class _FakeDayKeyService extends Fake implements HomeDayKeyService {
  _FakeDayKeyService(this._todayUtc);

  DateTime _todayUtc;

  void setToday(DateTime day) {
    _todayUtc = day;
  }

  @override
  DateTime todayDayKeyUtc({DateTime? nowUtc}) {
    return dateOnly(nowUtc ?? _todayUtc);
  }
}

class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  DateTime _nowUtc;

  void setNow(DateTime now) {
    _nowUtc = now;
  }

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}

void main() {
  setUpAll(initializeLoggingForTest);

  setUpAll(() {
    registerFallbackValue(TaskQuery.all());
  });

  Task buildTask({
    required String id,
    bool completed = false,
    bool isPinned = false,
    List<Value> values = const <Value>[],
    String? overridePrimaryValueId,
    Project? project,
    String? projectId,
  }) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Task $id',
      completed: completed,
      isPinned: isPinned,
      projectId: projectId ?? project?.id,
      project: project,
      values: values,
      overridePrimaryValueId: overridePrimaryValueId,
    );
  }

  Value buildValue({
    required String id,
    ValuePriority priority = ValuePriority.high,
  }) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Value $id',
      priority: priority,
    );
  }

  Project buildProject({
    required String id,
    bool isPinned = false,
    List<Value> values = const <Value>[],
    String? primaryValueId,
  }) {
    return Project(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Project $id',
      completed: false,
      isPinned: isPinned,
      values: values,
      primaryValueId: primaryValueId,
    );
  }

  testSafe(
    'getAllocationSnapshot returns requiresValueSetup when no values',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final projectAnchorStateRepo = _MockProjectAnchorStateRepo();
      final valueRepo = _MockValueRepo();
      final valueRatingsRepo = _MockValueRatingsRepo();
      final settingsRepo = _MockSettingsRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 1));
      final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));

      when(
        () => taskRepo.getAll(any()),
      ).thenAnswer((_) async => <Task>[buildTask(id: 't1')]);
      when(
        () => projectRepo.getAll(),
      ).thenAnswer((_) async => <Project>[buildProject(id: 'p1')]);
      when(
        () => projectAnchorStateRepo.getAll(),
      ).thenAnswer((_) async => const <ProjectAnchorState>[]);
      when(
        () => settingsRepo.load(SettingsKey.allocation),
      ).thenAnswer((_) async => const AllocationConfig());
      when(() => valueRepo.getAll()).thenAnswer((_) async => const <Value>[]);
      when(
        () => valueRatingsRepo.getAll(weeks: any(named: 'weeks')),
      ).thenAnswer((_) async => const <ValueWeeklyRating>[]);

      final orchestrator = AllocationOrchestrator(
        taskRepository: taskRepo,
        valueRepository: valueRepo,
        valueRatingsRepository: valueRatingsRepo,
        settingsRepository: settingsRepo,
        projectRepository: projectRepo,
        projectAnchorStateRepository: projectAnchorStateRepo,
        dayKeyService: dayKeyService,
        clock: clock,
      );

      final result = await orchestrator.getAllocationSnapshot();

      expect(result.requiresValueSetup, isTrue);
      expect(result.allocatedTasks, isEmpty);
    },
  );

  testSafe('getAllocationSnapshot respects maxTasksOverride <= 0', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final projectAnchorStateRepo = _MockProjectAnchorStateRepo();
    final valueRepo = _MockValueRepo();
    final valueRatingsRepo = _MockValueRatingsRepo();
    final settingsRepo = _MockSettingsRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 1));
    final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));
    final value = buildValue(id: 'v1');

    when(
      () => taskRepo.getAll(any()),
    ).thenAnswer((_) async => <Task>[buildTask(id: 't1')]);
    when(() => projectRepo.getAll()).thenAnswer((_) async => const <Project>[]);
    when(
      () => settingsRepo.load(SettingsKey.allocation),
    ).thenAnswer((_) async => const AllocationConfig());
    when(() => valueRepo.getAll()).thenAnswer(
      (_) async => <Value>[
        value,
      ],
    );
    when(
      () => projectAnchorStateRepo.getAll(),
    ).thenAnswer((_) async => const <ProjectAnchorState>[]);
    when(
      () => valueRatingsRepo.getAll(weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => const <ValueWeeklyRating>[]);

    final orchestrator = AllocationOrchestrator(
      taskRepository: taskRepo,
      valueRepository: valueRepo,
      valueRatingsRepository: valueRatingsRepo,
      settingsRepository: settingsRepo,
      projectRepository: projectRepo,
      projectAnchorStateRepository: projectAnchorStateRepo,
      dayKeyService: dayKeyService,
      clock: clock,
    );

    final result = await orchestrator.getAllocationSnapshot(
      maxTasksOverride: 0,
    );

    expect(result.allocatedTasks, isEmpty);
    expect(
      result.reasoning.explanation,
      'No allocation preferences configured',
    );
  });

  testSafe('allocateRegularTasks excludes when no categories', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final projectAnchorStateRepo = _MockProjectAnchorStateRepo();
    final valueRepo = _MockValueRepo();
    final valueRatingsRepo = _MockValueRatingsRepo();
    final settingsRepo = _MockSettingsRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 1));
    final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));

    when(() => valueRepo.getAll()).thenAnswer((_) async => const <Value>[]);
    when(
      () => projectAnchorStateRepo.getAll(),
    ).thenAnswer((_) async => const <ProjectAnchorState>[]);
    when(
      () => valueRatingsRepo.getAll(weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => const <ValueWeeklyRating>[]);

    final orchestrator = AllocationOrchestrator(
      taskRepository: taskRepo,
      valueRepository: valueRepo,
      valueRatingsRepository: valueRatingsRepo,
      settingsRepository: settingsRepo,
      projectRepository: projectRepo,
      projectAnchorStateRepository: projectAnchorStateRepo,
      dayKeyService: dayKeyService,
      clock: clock,
    );

    const allocationConfig = AllocationConfig();
    final result = await orchestrator.allocateRegularTasks(
      [buildTask(id: 't1'), buildTask(id: 't2')],
      projects: const <Project>[],
      projectAnchorStates: const <ProjectAnchorState>[],
      allocationConfig: allocationConfig,
      nowUtc: DateTime.utc(2026, 1, 1),
      todayDayKeyUtc: DateTime.utc(2026, 1, 1),
      maxTasksOverride: allocationConfig.suggestionsPerBatch,
      anchorCountOverride: allocationConfig.strategySettings.anchorCount,
    );

    expect(result.allocatedTasks, isEmpty);
    expect(result.excludedTasks, hasLength(2));
    expect(
      result.excludedTasks.every(
        (e) => e.exclusionType == ExclusionType.noCategory,
      ),
      isTrue,
    );
  });

  testSafe(
    'allocateRegularTasks returns empty when no eligible projects',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final projectAnchorStateRepo = _MockProjectAnchorStateRepo();
      final valueRepo = _MockValueRepo();
      final valueRatingsRepo = _MockValueRatingsRepo();
      final settingsRepo = _MockSettingsRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 1));
      final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));

      final value = buildValue(id: 'v1');
      when(() => valueRepo.getAll()).thenAnswer((_) async => <Value>[value]);
      when(
        () => projectAnchorStateRepo.getAll(),
      ).thenAnswer((_) async => const <ProjectAnchorState>[]);
      when(
        () => valueRatingsRepo.getAll(weeks: any(named: 'weeks')),
      ).thenAnswer((_) async => const <ValueWeeklyRating>[]);

      final project = buildProject(
        id: 'p1',
        values: [value],
        primaryValueId: value.id,
      );
      final task = buildTask(
        id: 't1',
        projectId: project.id,
        project: project,
        values: [value],
      );

      final orchestrator = AllocationOrchestrator(
        taskRepository: taskRepo,
        valueRepository: valueRepo,
        valueRatingsRepository: valueRatingsRepo,
        settingsRepository: settingsRepo,
        projectRepository: projectRepo,
        projectAnchorStateRepository: projectAnchorStateRepo,
        dayKeyService: dayKeyService,
        clock: clock,
      );

      const allocationConfig = AllocationConfig(
        suggestionsPerBatch: 1,
        strategySettings: StrategySettings(
          anchorCount: 1,
          tasksPerAnchorMin: 1,
          tasksPerAnchorMax: 1,
          freeSlots: 0,
        ),
      );
      final result = await orchestrator.allocateRegularTasks(
        [task],
        projects: [project],
        projectAnchorStates: const <ProjectAnchorState>[],
        allocationConfig: allocationConfig,
        nowUtc: DateTime.utc(2026, 1, 1),
        todayDayKeyUtc: DateTime.utc(2026, 1, 1),
        maxTasksOverride: allocationConfig.suggestionsPerBatch,
        anchorCountOverride: allocationConfig.strategySettings.anchorCount,
      );

      expect(result.allocatedTasks, isEmpty);
    },
  );

  testSafe('toggleTaskCompletion updates task when found', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final projectAnchorStateRepo = _MockProjectAnchorStateRepo();
    final valueRepo = _MockValueRepo();
    final valueRatingsRepo = _MockValueRatingsRepo();
    final settingsRepo = _MockSettingsRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 1));
    final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));

    final task = buildTask(id: 't9', completed: false);
    when(() => taskRepo.getById('t9')).thenAnswer((_) async => task);
    when(
      () => taskRepo.update(
        id: any(named: 'id'),
        name: any(named: 'name'),
        completed: any(named: 'completed'),
        description: any(named: 'description'),
        startDate: any(named: 'startDate'),
        deadlineDate: any(named: 'deadlineDate'),
        projectId: any(named: 'projectId'),
        priority: any(named: 'priority'),
        repeatIcalRrule: any(named: 'repeatIcalRrule'),
        repeatFromCompletion: any(named: 'repeatFromCompletion'),
        seriesEnded: any(named: 'seriesEnded'),
        valueIds: any(named: 'valueIds'),
        isPinned: any(named: 'isPinned'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final orchestrator = AllocationOrchestrator(
      taskRepository: taskRepo,
      valueRepository: valueRepo,
      valueRatingsRepository: valueRatingsRepo,
      settingsRepository: settingsRepo,
      projectRepository: projectRepo,
      projectAnchorStateRepository: projectAnchorStateRepo,
      dayKeyService: dayKeyService,
      clock: clock,
    );

    await orchestrator.toggleTaskCompletion('t9');

    verify(
      () => taskRepo.update(
        id: 't9',
        name: task.name,
        completed: true,
        description: task.description,
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        projectId: task.projectId,
        priority: task.priority,
        repeatIcalRrule: task.repeatIcalRrule,
        repeatFromCompletion: null,
        seriesEnded: null,
        valueIds: null,
        isPinned: null,
        context: null,
      ),
    ).called(1);
  });

  testSafe('toggleTaskCompletion no-ops when task missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final projectAnchorStateRepo = _MockProjectAnchorStateRepo();
    final valueRepo = _MockValueRepo();
    final valueRatingsRepo = _MockValueRatingsRepo();
    final settingsRepo = _MockSettingsRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 1));
    final clock = _FixedClock(DateTime.utc(2026, 1, 1, 12));

    when(() => taskRepo.getById('missing')).thenAnswer((_) async => null);

    final orchestrator = AllocationOrchestrator(
      taskRepository: taskRepo,
      valueRepository: valueRepo,
      valueRatingsRepository: valueRatingsRepo,
      settingsRepository: settingsRepo,
      projectRepository: projectRepo,
      projectAnchorStateRepository: projectAnchorStateRepo,
      dayKeyService: dayKeyService,
      clock: clock,
    );

    await orchestrator.toggleTaskCompletion('missing');

    verifyNever(
      () => taskRepo.update(
        id: any(named: 'id'),
        name: any(named: 'name'),
        completed: any(named: 'completed'),
        description: any(named: 'description'),
        startDate: any(named: 'startDate'),
        deadlineDate: any(named: 'deadlineDate'),
        projectId: any(named: 'projectId'),
        priority: any(named: 'priority'),
        repeatIcalRrule: any(named: 'repeatIcalRrule'),
        repeatFromCompletion: any(named: 'repeatFromCompletion'),
        seriesEnded: any(named: 'seriesEnded'),
        valueIds: any(named: 'valueIds'),
        isPinned: any(named: 'isPinned'),
        context: any(named: 'context'),
      ),
    );
  });
}
