import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_project_history_window.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/domain/settings/model/global_settings.dart';

import '../../../helpers/test_imports.dart';

class _FakeSettingsRepository implements SettingsRepositoryContract {
  _FakeSettingsRepository({required GlobalSettings initialSettings})
    : _settings$ = BehaviorSubject.seeded(initialSettings);

  final BehaviorSubject<GlobalSettings> _settings$;

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (key.toString() != SettingsKey.global.toString()) {
      throw UnimplementedError('Only SettingsKey.global is supported');
    }
    return _settings$.value as T;
  }

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    if (key.toString() != SettingsKey.global.toString()) {
      throw UnimplementedError('Only SettingsKey.global is supported');
    }
    return _settings$.stream.cast<T>();
  }

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    if (key.toString() != SettingsKey.global.toString()) {
      throw UnimplementedError('Only SettingsKey.global is supported');
    }
    if (value is GlobalSettings) {
      _settings$.add(value);
      return;
    }
    throw StateError('Unexpected settings type: ${value.runtimeType}');
  }

  Future<void> dispose() async {
    await _settings$.close();
  }
}

class _FakeTaskRepository implements TaskRepositoryContract {
  _FakeTaskRepository({required this.tasks});

  final List<Task> tasks;

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) => Stream.value(tasks);

  @override
  Future<List<Task>> getByIds(Iterable<String> ids) async {
    final byId = {for (final t in tasks) t.id: t};
    return ids.map((id) => byId[id]).whereType<Task>().toList(growable: false);
  }

  @override
  Future<List<Task>> getAll([TaskQuery? query]) => throw UnimplementedError();

  @override
  Stream<int> watchAllCount([TaskQuery? query]) => throw UnimplementedError();

  @override
  Future<Task?> getById(String id) => throw UnimplementedError();

  @override
  Stream<Task?> watchById(String id) => throw UnimplementedError();

  @override
  Stream<List<Task>> watchByIds(Iterable<String> ids) =>
      throw UnimplementedError();

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    bool seriesEnded = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? valueIds,
  }) => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    bool? seriesEnded,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? valueIds,
    bool? isPinned,
  }) => throw UnimplementedError();

  @override
  Future<void> setPinned({required String id, required bool isPinned}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<List<Task>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => throw UnimplementedError();

  @override
  Stream<List<Task>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => throw UnimplementedError();

  @override
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) => throw UnimplementedError();

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  }) => throw UnimplementedError();

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
  }) => throw UnimplementedError();

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
  }) => throw UnimplementedError();
}

class _FakeProjectRepository implements ProjectRepositoryContract {
  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) =>
      throw UnimplementedError();

  @override
  Stream<int> watchAllCount([ProjectQuery? query]) =>
      throw UnimplementedError();

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) =>
      throw UnimplementedError();

  @override
  Stream<Project?> watchById(String id) => throw UnimplementedError();

  @override
  Future<Project?> getById(String id) => throw UnimplementedError();

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    bool seriesEnded = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? valueIds,
    int? priority,
  }) => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    bool? seriesEnded,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? valueIds,
    int? priority,
    bool? isPinned,
  }) => throw UnimplementedError();

  @override
  Future<void> setPinned({required String id, required bool isPinned}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => throw UnimplementedError();

  @override
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => throw UnimplementedError();

  @override
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) => throw UnimplementedError();

  @override
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  }) => throw UnimplementedError();

  @override
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
  }) => throw UnimplementedError();

  @override
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
  }) => throw UnimplementedError();
}

class _FakeValueRepository implements ValueRepositoryContract {
  @override
  Future<List<Value>> getAll([ValueQuery? query]) async => const [];

  @override
  Stream<List<Value>> watchAll([ValueQuery? query]) =>
      const Stream<List<Value>>.empty();

  @override
  Future<Value?> getById(String id) => throw UnimplementedError();

  @override
  Stream<Value?> watchById(String id) => throw UnimplementedError();

  @override
  Future<List<Value>> getValuesByIds(List<String> ids) =>
      throw UnimplementedError();

  @override
  Future<void> create({
    required String name,
    required String color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
  }) => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    String? iconName,
    ValuePriority? priority,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> addValueToTask({
    required String taskId,
    required String valueId,
  }) => throw UnimplementedError();

  @override
  Future<void> removeValueFromTask({
    required String taskId,
    required String valueId,
  }) => throw UnimplementedError();
}

class _FakeAllocationSnapshotRepository
    implements AllocationSnapshotRepositoryContract {
  _FakeAllocationSnapshotRepository({required this.refs});

  final List<AllocationSnapshotTaskRef> refs;

  @override
  Future<List<AllocationSnapshotTaskRef>> getLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  ) async {
    return refs;
  }

  @override
  Future<AllocationSnapshot?> getLatestForUtcDay(DateTime dayUtc) =>
      throw UnimplementedError();

  @override
  Stream<AllocationSnapshot?> watchLatestForUtcDay(DateTime dayUtc) =>
      throw UnimplementedError();

  @override
  Stream<List<AllocationSnapshotTaskRef>> watchLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  ) => throw UnimplementedError();

  @override
  Future<void> persistAllocatedForUtcDay({
    required DateTime dayUtc,
    required int capAtGeneration,
    required int candidatePoolCountAtGeneration,
    required List<AllocationSnapshotEntryInput> allocated,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteAll() => throw UnimplementedError();

  @override
  Future<AllocationProjectHistoryWindow> getProjectHistoryWindow({
    required DateTime windowEndDayUtc,
    required int windowDays,
  }) => throw UnimplementedError();
}

Task _task(String id) {
  final now = DateTime.utc(2026, 1, 1);
  return Task(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: id,
    completed: false,
  );
}

void main() {
  group('SectionDataService', () {
    testSafe('fetchInterleavedListV2 returns empty when no sources', () async {
      final settingsRepo = _FakeSettingsRepository(
        initialSettings: const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
      );
      addTearDown(settingsRepo.dispose);
      final dayKeyService = HomeDayKeyService(settingsRepository: settingsRepo);

      final service = SectionDataService(
        taskRepository: _FakeTaskRepository(tasks: const []),
        projectRepository: _FakeProjectRepository(),
        valueRepository: _FakeValueRepository(),
        allocationSnapshotRepository: _FakeAllocationSnapshotRepository(
          refs: const [],
        ),
        agendaDataService: AgendaSectionDataService(
          taskRepository: _FakeTaskRepository(tasks: const []),
          projectRepository: _FakeProjectRepository(),
        ),
        dayKeyService: dayKeyService,
        settingsRepository: settingsRepo,
        journalRepository: null,
      );

      final result = await service.fetchInterleavedListV2(
        InterleavedListSectionParamsV2(
          sources: const [],
          pack: StylePackV2.standard,
        ),
      );

      expect(result, isA<DataV2SectionResult>());
      expect((result as DataV2SectionResult).items, isEmpty);
    });

    testSafe(
      'fetchDataListV2 with journal config returns empty when repo absent',
      () async {
        final settingsRepo = _FakeSettingsRepository(
          initialSettings: const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
        );
        addTearDown(settingsRepo.dispose);
        final dayKeyService = HomeDayKeyService(
          settingsRepository: settingsRepo,
        );

        final service = SectionDataService(
          taskRepository: _FakeTaskRepository(tasks: const []),
          projectRepository: _FakeProjectRepository(),
          valueRepository: _FakeValueRepository(),
          allocationSnapshotRepository: _FakeAllocationSnapshotRepository(
            refs: const [],
          ),
          agendaDataService: AgendaSectionDataService(
            taskRepository: _FakeTaskRepository(tasks: const []),
            projectRepository: _FakeProjectRepository(),
          ),
          dayKeyService: dayKeyService,
          settingsRepository: settingsRepo,
          journalRepository: null,
        );

        final result = await service.fetchDataListV2(
          ListSectionParamsV2(
            config: DataConfig.journal(query: JournalQuery.all()),
            pack: StylePackV2.standard,
          ),
        );

        expect(result, isA<DataV2SectionResult>());
        expect((result as DataV2SectionResult).items, isEmpty);
      },
    );

    testSafe(
      'allocation_snapshot_tasks_today hydrates tasks by ref order',
      () async {
        final settingsRepo = _FakeSettingsRepository(
          initialSettings: const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
        );
        addTearDown(settingsRepo.dispose);
        final dayKeyService = HomeDayKeyService(
          settingsRepository: settingsRepo,
        );

        final tasks = [_task('t1'), _task('t2')];
        final taskRepo = _FakeTaskRepository(tasks: tasks);

        final service = SectionDataService(
          taskRepository: taskRepo,
          projectRepository: _FakeProjectRepository(),
          valueRepository: _FakeValueRepository(),
          allocationSnapshotRepository: _FakeAllocationSnapshotRepository(
            refs: const [
              AllocationSnapshotTaskRef(taskId: 't2', allocationRank: 0),
              AllocationSnapshotTaskRef(taskId: 't1', allocationRank: 1),
            ],
          ),
          agendaDataService: AgendaSectionDataService(
            taskRepository: taskRepo,
            projectRepository: _FakeProjectRepository(),
          ),
          dayKeyService: dayKeyService,
          settingsRepository: settingsRepo,
          journalRepository: null,
        );

        final result = await service.fetchDataListV2(
          ListSectionParamsV2(
            config: const DataConfig.allocationSnapshotTasksToday(),
            pack: StylePackV2.standard,
          ),
        );

        expect(result, isA<DataV2SectionResult>());
        expect(result.allTasks.map((t) => t.id), ['t2', 't1']);
      },
    );
  });
}
