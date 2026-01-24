@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../helpers/fixed_clock.dart';

import 'dart:async';

import 'package:taskly_data/src/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AnalyticsServiceImpl', () {
    testSafe('mood distribution and summary use tracker events', () async {
      final journalRepo = _FakeJournalRepository(
        definitions: [_trackerDef(systemKey: 'mood', id: 'mood')],
        events: [
          _event(trackerId: 'mood', value: 3),
          _event(trackerId: 'mood', value: 5),
        ],
      );

      final dayKeyService = HomeDayKeyService(
        settingsRepository: _FakeSettingsRepository(),
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );
      final occurrenceReadService = OccurrenceReadService(
        taskRepository: _FakeTaskRepository(const []),
        projectRepository: _FakeProjectRepository(const []),
        dayKeyService: dayKeyService,
        occurrenceExpander: _FakeOccurrenceExpander(),
      );

      final service = AnalyticsServiceImpl(
        analyticsRepo: _FakeAnalyticsRepository(),
        taskRepo: _FakeTaskRepository(const []),
        projectRepo: _FakeProjectRepository(const []),
        valueRepo: _FakeValueRepository(const []),
        journalRepo: journalRepo,
        dayKeyService: dayKeyService,
        occurrenceReadService: occurrenceReadService,
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );

      final range = DateRange(
        start: DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 1, 2),
      );

      final dist = await service.getMoodDistribution(range: range);
      expect(dist[3], equals(1));
      expect(dist[5], equals(1));

      final summary = await service.getMoodSummary(range: range);
      expect(summary.totalEntries, equals(2));
      expect(summary.min, equals(3));
      expect(summary.max, equals(5));
    });

    testSafe('value activity and primary/secondary stats', () async {
      final now = DateTime.utc(2025, 1, 1);
      final v1 = _value('v1', 'Health', now);
      final v2 = _value('v2', 'Work', now);

      final p1 = Project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        name: 'Project 1',
        completed: false,
        values: [v1],
        primaryValueId: 'v1',
      );
      final p2 = Project(
        id: 'p2',
        createdAt: now,
        updatedAt: now,
        name: 'Project 2',
        completed: false,
        values: [v2],
        primaryValueId: 'v2',
      );

      final t1 = Task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        name: 'Task 1',
        completed: false,
        values: [v1],
        overridePrimaryValueId: 'v1',
      );
      final t2 = Task(
        id: 't2',
        createdAt: now,
        updatedAt: now,
        name: 'Task 2',
        completed: false,
        project: p2,
        projectId: 'p2',
      );

      final dayKeyService = HomeDayKeyService(
        settingsRepository: _FakeSettingsRepository(),
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );
      final occurrenceReadService = OccurrenceReadService(
        taskRepository: _FakeTaskRepository(const []),
        projectRepository: _FakeProjectRepository(const []),
        dayKeyService: dayKeyService,
        occurrenceExpander: _FakeOccurrenceExpander(),
      );

      final service = AnalyticsServiceImpl(
        analyticsRepo: _FakeAnalyticsRepository(),
        taskRepo: _FakeTaskRepository([
          _TaskItem(task: t1, completedAt: now),
          _TaskItem(task: t2, completedAt: now),
        ]),
        projectRepo: _FakeProjectRepository([p1, p2]),
        valueRepo: _FakeValueRepository([v1, v2]),
        journalRepo: _FakeJournalRepository(),
        dayKeyService: dayKeyService,
        occurrenceReadService: occurrenceReadService,
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );

      final activity = await service.getValueActivityStats();
      expect(activity['v1']?.taskCount, equals(1));
      expect(activity['v2']?.projectCount, equals(1));

      final primarySecondary = await service.getValuePrimarySecondaryStats();
      expect(primarySecondary['v1']?.primaryTaskCount, equals(1));
      expect(primarySecondary['v2']?.primaryProjectCount, equals(1));
    });

    testSafe('recent completions and weekly trends', () async {
      final now = DateTime.utc(2025, 1, 1);
      final v1 = _value('v1', 'Health', now);
      final v2 = _value('v2', 'Work', now);

      final task1 = Task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        name: 'Task 1',
        completed: true,
        values: [v1],
        overridePrimaryValueId: 'v1',
      );
      final task2 = Task(
        id: 't2',
        createdAt: now,
        updatedAt: now,
        name: 'Task 2',
        completed: true,
        values: [v2],
        overridePrimaryValueId: 'v2',
      );

      final taskRepo = _FakeTaskRepository([
        _TaskItem(
          task: task1,
          completedAt: now.subtract(const Duration(days: 2)),
        ),
        _TaskItem(
          task: task2,
          completedAt: now.subtract(const Duration(days: 9)),
        ),
      ]);

      final dayKeyService = HomeDayKeyService(
        settingsRepository: _FakeSettingsRepository(),
        clock: FixedClock(now),
      );
      final occurrenceReadService = OccurrenceReadService(
        taskRepository: _FakeTaskRepository(const []),
        projectRepository: _FakeProjectRepository(const []),
        dayKeyService: dayKeyService,
        occurrenceExpander: _FakeOccurrenceExpander(),
      );

      final service = AnalyticsServiceImpl(
        analyticsRepo: _FakeAnalyticsRepository(),
        taskRepo: taskRepo,
        projectRepo: _FakeProjectRepository(const []),
        valueRepo: _FakeValueRepository([v1, v2]),
        journalRepo: _FakeJournalRepository(),
        dayKeyService: dayKeyService,
        occurrenceReadService: occurrenceReadService,
        clock: FixedClock(now),
      );

      final recent = await service.getRecentCompletionsByValue(days: 7);
      expect(recent['v1'], equals(1));
      expect(recent.containsKey('v2'), isFalse);

      final total = await service.getTotalRecentCompletions(days: 7);
      expect(total, equals(1));

      final trends = await service.getValueWeeklyTrends(weeks: 2);
      expect(trends.keys, containsAll(<String>['v1', 'v2']));
      expect(trends['v1']!.length, equals(2));
    });
  });
}

TrackerDefinition _trackerDef({required String id, String? systemKey}) {
  return TrackerDefinition(
    id: id,
    name: 'Tracker',
    scope: 'entry',
    valueType: 'number',
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 1),
    systemKey: systemKey,
  );
}

TrackerEvent _event({required String trackerId, required Object value}) {
  return TrackerEvent(
    id: 'e1',
    trackerId: trackerId,
    anchorType: 'entry',
    entryId: 'entry',
    anchorDate: DateTime.utc(2025, 1, 1),
    op: 'set',
    value: value,
    occurredAt: DateTime.utc(2025, 1, 1, 12),
    recordedAt: DateTime.utc(2025, 1, 1, 12),
    userId: null,
  );
}

Value _value(String id, String name, DateTime now) {
  return Value(id: id, name: name, createdAt: now, updatedAt: now);
}

class _TaskItem {
  _TaskItem({required this.task, required this.completedAt});
  final Task task;
  final DateTime completedAt;
}

class _FakeTaskRepository implements TaskRepositoryContract {
  _FakeTaskRepository(List<_TaskItem> items) : _items = items;

  final List<_TaskItem> _items;

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) =>
      Stream.value(_filterTasks(query));

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async => _filterTasks(query);

  List<Task> _filterTasks(TaskQuery? query) {
    final items = _items
        .where((item) {
          final task = item.task;
          final completedAt = item.completedAt;
          if (query == null) return true;
          for (final predicate in query.filter.shared) {
            if (predicate is TaskBoolPredicate &&
                predicate.field == TaskBoolField.completed) {
              final expected = predicate.operator == BoolOperator.isTrue;
              if (task.completed != expected) return false;
            }
            if (predicate is TaskDatePredicate &&
                predicate.field == TaskDateField.completedAt) {
              final date = completedAt;
              switch (predicate.operator) {
                case DateOperator.onOrAfter:
                  if (predicate.date != null &&
                      date.isBefore(predicate.date!)) {
                    return false;
                  }
                case DateOperator.between:
                  if (predicate.startDate != null &&
                      date.isBefore(predicate.startDate!)) {
                    return false;
                  }
                  if (predicate.endDate != null &&
                      date.isAfter(predicate.endDate!)) {
                    return false;
                  }
                default:
                  break;
              }
            }
          }
          return true;
        })
        .map((item) => item.task)
        .toList(growable: false);

    return items;
  }

  Task? _taskById(String id) {
    for (final item in _items) {
      if (item.task.id == id) return item.task;
    }
    return null;
  }

  @override
  Future<Task?> getById(String id) async => _taskById(id);

  @override
  Future<List<Task>> getByIds(Iterable<String> ids) async {
    final byId = {for (final i in _items) i.task.id: i.task};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Stream<Task?> watchById(String id) => Stream.value(_taskById(id));

  @override
  Stream<List<Task>> watchByIds(Iterable<String> ids) =>
      Stream.fromFuture(getByIds(ids));

  @override
  Stream<int> watchAllCount([TaskQuery? query]) =>
      Stream.value(_filterTasks(query).length);

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() =>
      const Stream<List<CompletionHistoryData>>.empty();

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() =>
      const Stream<List<RecurrenceExceptionData>>.empty();

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
  }) async => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<String>? valueIds,
    bool? isPinned,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> setMyDaySnoozedUntil({
    required String id,
    required DateTime? untilUtc,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  }) async => const <String, TaskSnoozeStats>{};

  @override
  Future<void> delete(String id, {OperationContext? context}) async =>
      throw UnimplementedError();

  @override
  Future<List<Task>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async => throw UnimplementedError();

  @override
  Future<List<Task>> getOccurrencesForTask({
    required String taskId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async => throw UnimplementedError();

  @override
  Stream<List<Task>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => const Stream<List<Task>>.empty();

  @override
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    OperationContext? context,
  }) async => throw UnimplementedError();
}

class _FakeProjectRepository implements ProjectRepositoryContract {
  _FakeProjectRepository(this._projects);

  final List<Project> _projects;

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) =>
      Stream.value(_filter(query));

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async => _filter(query);

  List<Project> _filter(ProjectQuery? query) {
    if (query == null) return _projects;
    return _projects
        .where((project) {
          for (final predicate in query.filter.shared) {
            if (predicate is ProjectBoolPredicate &&
                predicate.field == ProjectBoolField.completed) {
              final expected = predicate.operator == BoolOperator.isTrue;
              if (project.completed != expected) return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  Project? _projectById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  @override
  Future<Project?> getById(String id) async => _projectById(id);

  @override
  Stream<Project?> watchById(String id) => Stream.value(_projectById(id));

  @override
  Stream<int> watchAllCount([ProjectQuery? query]) =>
      Stream.value(_filter(query).length);

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
  }) async => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<String>? valueIds,
    int? priority,
    bool? isPinned,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String id, {OperationContext? context}) async =>
      throw UnimplementedError();

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() =>
      const Stream<List<CompletionHistoryData>>.empty();

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() =>
      const Stream<List<RecurrenceExceptionData>>.empty();

  @override
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async => throw UnimplementedError();

  @override
  Future<List<Project>> getOccurrencesForProject({
    required String projectId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async => throw UnimplementedError();

  @override
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => const Stream<List<Project>>.empty();

  @override
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async => throw UnimplementedError();
}

class _FakeValueRepository implements ValueRepositoryContract {
  _FakeValueRepository(this._values);

  final List<Value> _values;

  @override
  Stream<List<Value>> watchAll([ValueQuery? query]) => Stream.value(_values);

  @override
  Future<List<Value>> getAll([ValueQuery? query]) async => _values;

  @override
  Future<Value?> getById(String id) async => _valueById(id);

  @override
  Stream<Value?> watchById(String id) => Stream.value(_valueById(id));

  @override
  Future<List<Value>> getValuesByIds(List<String> ids) async =>
      _values.where((v) => ids.contains(v.id)).toList(growable: false);

  Value? _valueById(String id) {
    for (final value in _values) {
      if (value.id == id) return value;
    }
    return null;
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    ValuePriority priority = ValuePriority.medium,
    String? iconName,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    ValuePriority? priority,
    String? iconName,
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String id, {OperationContext? context}) async =>
      throw UnimplementedError();
}

class _FakeAnalyticsRepository implements AnalyticsRepositoryContract {
  List<AnalyticsSnapshot> lastSnapshots = const [];

  @override
  Future<List<AnalyticsSnapshot>> getSnapshots({
    required String entityType,
    required DateRange range,
    String? entityId,
  }) async => lastSnapshots;

  @override
  Future<void> saveSnapshot(
    AnalyticsSnapshot snapshot, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveSnapshots(
    List<AnalyticsSnapshot> snapshots, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<List<CorrelationResult>> getCachedCorrelations({
    required String correlationType,
    required DateRange range,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveCorrelation(
    CorrelationResult correlation, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveCorrelations(
    List<CorrelationResult> correlations, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<List<AnalyticsInsight>> getRecentInsights({
    required DateRange range,
    int? limit,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveInsight(
    AnalyticsInsight insight, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> dismissInsight(
    String insightId, {
    OperationContext? context,
  }) async => throw UnimplementedError();
}

class _FakeJournalRepository implements JournalRepositoryContract {
  _FakeJournalRepository({this.definitions = const [], this.events = const []});

  final List<TrackerDefinition> definitions;
  final List<TrackerEvent> events;

  @override
  Stream<List<TrackerDefinition>> watchTrackerDefinitions() =>
      Stream.value(definitions);

  @override
  Stream<List<TrackerEvent>> watchTrackerEvents({
    DateRange? range,
    String? anchorType,
    String? entryId,
    DateTime? anchorDate,
    String? trackerId,
  }) {
    final filtered = events
        .where((event) {
          if (trackerId != null && event.trackerId != trackerId) return false;
          return true;
        })
        .toList(growable: false);
    return Stream.value(filtered);
  }

  @override
  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  }) async => <DateTime, double>{};

  @override
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  }) async => <DateTime, double>{};

  @override
  Stream<List<JournalEntry>> watchJournalEntries({DateRange? range}) =>
      const Stream<List<JournalEntry>>.empty();

  @override
  Stream<List<JournalEntry>> watchJournalEntriesByQuery(
    JournalQuery journalQuery,
  ) => const Stream<List<JournalEntry>>.empty();

  @override
  Future<JournalEntry?> getJournalEntryById(String id) async => null;

  @override
  Future<JournalEntry?> getJournalEntryByDate({required DateTime date}) async =>
      null;

  @override
  Future<List<JournalEntry>> getJournalEntriesByDate({
    required DateTime date,
  }) async => const <JournalEntry>[];

  @override
  Future<void> saveJournalEntry(
    JournalEntry entry, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<String> upsertJournalEntry(
    JournalEntry entry, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteJournalEntry(
    String id, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Stream<List<TrackerGroup>> watchTrackerGroups() =>
      const Stream<List<TrackerGroup>>.empty();

  @override
  Stream<List<TrackerPreference>> watchTrackerPreferences() =>
      const Stream<List<TrackerPreference>>.empty();

  @override
  Stream<List<TrackerDefinitionChoice>> watchTrackerDefinitionChoices({
    required String trackerId,
  }) => const Stream<List<TrackerDefinitionChoice>>.empty();

  @override
  Stream<List<TrackerStateDay>> watchTrackerStateDay({
    required DateRange range,
  }) => const Stream<List<TrackerStateDay>>.empty();

  @override
  Stream<List<TrackerStateEntry>> watchTrackerStateEntry({
    required DateRange range,
  }) => const Stream<List<TrackerStateEntry>>.empty();

  @override
  Future<void> saveTrackerDefinition(
    TrackerDefinition definition, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveTrackerGroup(
    TrackerGroup group, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteTrackerGroup(
    String groupId, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveTrackerPreference(
    TrackerPreference preference, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> saveTrackerDefinitionChoice(
    TrackerDefinitionChoice choice, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> appendTrackerEvent(
    TrackerEvent event, {
    OperationContext? context,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteTrackerAndData(
    String trackerId, {
    OperationContext? context,
  }) async => throw UnimplementedError();
}

class _FakeSettingsRepository implements SettingsRepositoryContract {
  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    return Stream.value(_defaultFor(key));
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async => _defaultFor(key);

  @override
  Future<void> save<T>(
    SettingsKey<T> key,
    T value, {
    OperationContext? context,
  }) async {}

  T _defaultFor<T>(SettingsKey<T> key) {
    if (identical(key, SettingsKey.global)) {
      return const GlobalSettings() as T;
    }
    throw ArgumentError('Unsupported settings key: $key');
  }
}

class _FakeOccurrenceExpander implements OccurrenceStreamExpanderContract {
  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) => tasksStream;

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project p1)? postExpansionFilter,
  }) => projectsStream;

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) => tasks;

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project p1)? postExpansionFilter,
  }) => projects;
}
