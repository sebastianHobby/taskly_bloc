import '../../../helpers/test_imports.dart';


import 'package:taskly_domain/taskly_domain.dart';
class _FakeAllocationSnapshotRepository
    implements AllocationSnapshotRepositoryContract {
  int deleteAllCalls = 0;

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
  }

  @override
  Future<AllocationSnapshot?> getLatestForUtcDay(DateTime dayUtc) {
    throw UnimplementedError();
  }

  @override
  Future<List<AllocationSnapshotTaskRef>> getLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AllocationProjectHistoryWindow> getProjectHistoryWindow({
    required DateTime windowEndDayUtc,
    required int windowDays,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> persistAllocatedForUtcDay({
    required DateTime dayUtc,
    required int capAtGeneration,
    required int candidatePoolCountAtGeneration,
    required List<AllocationSnapshotEntryInput> allocated,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AllocationSnapshot?> watchLatestForUtcDay(DateTime dayUtc) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AllocationSnapshotTaskRef>> watchLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  ) {
    throw UnimplementedError();
  }
}

class _FakeSettingsRepository implements SettingsRepositoryContract {
  final saved = <SettingsKey<dynamic>, Object?>{};

  @override
  Future<T> load<T>(SettingsKey<T> key) {
    throw UnimplementedError();
  }

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    saved[key] = value;
  }

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    throw UnimplementedError();
  }
}

class _FakeValueRepository implements ValueRepositoryContract {
  _FakeValueRepository({required List<Value> initialValues})
    : _values = List<Value>.of(initialValues);

  final List<Value> _values;

  final created = <Value>[];
  final deletedIds = <String>[];

  int _id = 0;

  @override
  Future<void> create({
    required String name,
    required String color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
  }) async {
    final value = Value(
      id: 'value-${_id++}',
      name: name,
      color: color,
      iconName: iconName ?? '',
      priority: priority,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    _values.add(value);
    created.add(value);
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    _values.removeWhere((v) => v.id == id);
  }

  @override
  Future<List<Value>> getAll([ValueQuery? query]) async =>
      List<Value>.of(_values);

  @override
  Future<Value?> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Value>> getValuesByIds(List<String> ids) {
    throw UnimplementedError();
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    String? iconName,
    ValuePriority? priority,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Value>> watchAll([ValueQuery? query]) {
    throw UnimplementedError();
  }

  @override
  Stream<Value?> watchById(String id) {
    throw UnimplementedError();
  }
}

class _FakeProjectRepository implements ProjectRepositoryContract {
  _FakeProjectRepository({required List<Project> initialProjects})
    : _projects = List<Project>.of(initialProjects);

  final List<Project> _projects;

  final created = <Project>[];
  final deletedIds = <String>[];

  int _id = 0;

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
  }) async {
    final project = Project(
      id: 'project-${_id++}',
      name: name,
      description: description,
      completed: completed,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      values: const [],
      primaryValueId: valueIds?.isNotEmpty ?? false ? valueIds!.first : null,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      occurrence: null,
      isPinned: false,
    );
    _projects.add(project);
    created.add(project);
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    _projects.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async =>
      List<Project>.of(_projects);

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) {
    throw UnimplementedError();
  }

  @override
  Stream<int> watchAllCount([ProjectQuery? query]) {
    throw UnimplementedError();
  }

  @override
  Stream<Project?> watchById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Project?> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPinned({required String id, required bool isPinned}) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  }) {
    throw UnimplementedError();
  }
}

class _FakeTaskRepository implements TaskRepositoryContract {
  _FakeTaskRepository({required List<Task> initialTasks})
    : _tasks = List<Task>.of(initialTasks);

  final List<Task> _tasks;

  final created = <Task>[];
  final deletedIds = <String>[];
  final pinnedIds = <String>[];

  int _id = 0;

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
  }) async {
    final now = DateTime.utc(2026, 1, 1);
    final task = Task(
      id: 'task-${_id++}',
      name: name,
      completed: completed,
      description: description,
      projectId: projectId,
      priority: priority,
      startDate: startDate,
      deadlineDate: deadlineDate,
      createdAt: now,
      updatedAt: now,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      isPinned: false,
      project: null,
      values: const [],
      overridePrimaryValueId: valueIds?.isNotEmpty ?? false
          ? valueIds!.first
          : null,
      occurrence: null,
    );
    _tasks.add(task);
    created.add(task);
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async => List<Task>.of(_tasks);

  @override
  Future<Task?> getById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Task>> getByIds(Iterable<String> ids) async {
    final idList = ids.toList(growable: false);
    final byId = <String, Task>{for (final t in _tasks) t.id: t};
    return [
      for (final id in idList)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    throw UnimplementedError();
  }

  @override
  Stream<int> watchAllCount([TaskQuery? query]) {
    throw UnimplementedError();
  }

  @override
  Stream<Task?> watchById(String id) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Task>> watchByIds(Iterable<String> ids) {
    throw UnimplementedError();
  }

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
  }) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return Future.value();

    final old = _tasks[idx];
    _tasks[idx] = old.copyWith(
      updatedAt: DateTime.utc(2026, 1, 1),
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? old.repeatFromCompletion,
      seriesEnded: seriesEnded ?? old.seriesEnded,
      isPinned: isPinned ?? old.isPinned,
        overridePrimaryValueId: valueIds == null
          ? old.overridePrimaryValueId
          : (valueIds.isNotEmpty ? valueIds[0] : null),
      overrideSecondaryValueId: valueIds == null
          ? old.overrideSecondaryValueId
          : (valueIds.length > 1 ? valueIds[1] : null),
    );
    return Future.value();
  }

  @override
  Future<void> setPinned({required String id, required bool isPinned}) async {
    pinnedIds.add(id);
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(isPinned: isPinned);
  }

  @override
  Future<List<Task>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Task>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('TemplateDataService', () {
    testSafe('resetAndSeed wipes existing and seeds demo dataset', () async {
      final existingTasks = [
        TestData.task(id: 'existing-task-1', name: 'Old task 1'),
        TestData.task(id: 'existing-task-2', name: 'Old task 2'),
      ];
      final existingProjects = [
        TestData.project(id: 'existing-project-1', name: 'Old project 1'),
      ];
      final existingValues = [
        TestData.value(id: 'existing-value-1', name: 'Old value 1'),
      ];

      final taskRepo = _FakeTaskRepository(initialTasks: existingTasks);
      final projectRepo = _FakeProjectRepository(
        initialProjects: existingProjects,
      );
      final valueRepo = _FakeValueRepository(initialValues: existingValues);
      final settingsRepo = _FakeSettingsRepository();
      final allocationRepo = _FakeAllocationSnapshotRepository();

      final service = TemplateDataService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        valueRepository: valueRepo,
        settingsRepository: settingsRepo,
        allocationSnapshotRepository: allocationRepo,
      );

      await service.resetAndSeed();

      expect(allocationRepo.deleteAllCalls, 1);
      expect(
        taskRepo.deletedIds,
        containsAll(['existing-task-1', 'existing-task-2']),
      );
      expect(projectRepo.deletedIds, contains('existing-project-1'));
      expect(valueRepo.deletedIds, contains('existing-value-1'));

      // Seeds values/projects/tasks.
      expect(valueRepo.created, hasLength(5));
      expect(projectRepo.created, hasLength(5));
      expect(taskRepo.created, hasLength(20));

      // Pins only one task (first pinned candidate).
      expect(taskRepo.pinnedIds, hasLength(1));
      final pinnedId = taskRepo.pinnedIds.single;
      final pinnedTask = (await taskRepo.getAll(
        TaskQuery.all(),
      )).firstWhere((t) => t.id == pinnedId);
      expect(pinnedTask.isPinned, isTrue);
      expect(pinnedTask.name, 'Book passport photo');

      expect(settingsRepo.saved.keys, contains(SettingsKey.allocation));
    });
  });
}
