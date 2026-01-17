import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/taskly_domain.dart';
class _FakeTaskRepository implements TaskRepositoryContract {
  _FakeTaskRepository({required this.overdue, required this.scheduled});

  final BehaviorSubject<List<Task>> overdue;
  final BehaviorSubject<List<Task>> scheduled;

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async {
    return _subjectFor(query).value;
  }

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    return _subjectFor(query).stream;
  }

  BehaviorSubject<List<Task>> _subjectFor(TaskQuery? query) {
    if (query == null) return scheduled;

    if (query.occurrenceExpansion != null) {
      return scheduled;
    }

    final shared = query.filter.shared;
    final hasOverduePredicate = shared.any(
      (p) =>
          p is TaskDatePredicate &&
          p.field == TaskDateField.deadlineDate &&
          p.operator == DateOperator.before,
    );

    return hasOverduePredicate ? overdue : scheduled;
  }

  @override
  Future<List<Task>> getByIds(Iterable<String> ids) =>
      throw UnimplementedError();

  @override
  Future<Task?> getById(String id) => throw UnimplementedError();

  @override
  Stream<Task?> watchById(String id) => throw UnimplementedError();

  @override
  Stream<List<Task>> watchByIds(Iterable<String> ids) =>
      throw UnimplementedError();

  @override
  Stream<int> watchAllCount([TaskQuery? query]) => throw UnimplementedError();

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
  _FakeProjectRepository({required this.overdue, required this.scheduled});

  final BehaviorSubject<List<Project>> overdue;
  final BehaviorSubject<List<Project>> scheduled;

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async {
    return _subjectFor(query).value;
  }

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) {
    return _subjectFor(query).stream;
  }

  BehaviorSubject<List<Project>> _subjectFor(ProjectQuery? query) {
    if (query == null) return scheduled;

    if (query.occurrenceExpansion != null) {
      return scheduled;
    }

    final shared = query.filter.shared;
    final hasOverduePredicate = shared.any(
      (p) =>
          p is ProjectDatePredicate &&
          p.field == ProjectDateField.deadlineDate &&
          p.operator == DateOperator.before,
    );

    return hasOverduePredicate ? overdue : scheduled;
  }

  @override
  Stream<int> watchAllCount([ProjectQuery? query]) =>
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

Task _task({
  required String id,
  required String name,
  required bool completed,
  DateTime? startDate,
  DateTime? deadlineDate,
  String? repeatIcalRrule,
  bool repeatFromCompletion = false,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Task(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: name,
    completed: completed,
    startDate: startDate,
    deadlineDate: deadlineDate,
    repeatIcalRrule: repeatIcalRrule,
    repeatFromCompletion: repeatFromCompletion,
  );
}

Project _project({
  required String id,
  required String name,
  required bool completed,
  DateTime? startDate,
  DateTime? deadlineDate,
  String? repeatIcalRrule,
  bool repeatFromCompletion = false,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Project(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: name,
    completed: completed,
    startDate: startDate,
    deadlineDate: deadlineDate,
    repeatIcalRrule: repeatIcalRrule,
    repeatFromCompletion: repeatFromCompletion,
  );
}

AgendaItem? _findItem(
  AgendaDateGroup group, {
  required String entityId,
  required AgendaDateTag tag,
}) {
  return group.items.cast<AgendaItem?>().firstWhere(
    (i) => i?.entityId == entityId && i?.tag == tag,
    orElse: () => null,
  );
}

void main() {
  group('AgendaSectionDataService', () {
    testSafe('getAgendaData groups and tags items', () async {
      final today = DateTime(2026, 1, 10);
      final horizonEnd = today.add(const Duration(days: 10));

      final overdue$ = BehaviorSubject<List<Task>>.seeded(const []);
      final scheduled$ = BehaviorSubject<List<Task>>.seeded(const []);
      addTearDown(overdue$.close);
      addTearDown(scheduled$.close);

      final overdueProjects$ = BehaviorSubject<List<Project>>.seeded(const []);
      final scheduledProjects$ = BehaviorSubject<List<Project>>.seeded(
        const [],
      );
      addTearDown(overdueProjects$.close);
      addTearDown(scheduledProjects$.close);

      final taskRepo = _FakeTaskRepository(
        overdue: overdue$,
        scheduled: scheduled$,
      );
      final projectRepo = _FakeProjectRepository(
        overdue: overdueProjects$,
        scheduled: scheduledProjects$,
      );

      final service = AgendaSectionDataService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        nearTermDays: 3,
      );

      final tOverdue = _task(
        id: 't-overdue',
        name: 'Overdue Task',
        completed: false,
        deadlineDate: today.subtract(const Duration(days: 1)),
      );
      final pOverdue = _project(
        id: 'p-overdue',
        name: 'Overdue Project',
        completed: false,
        deadlineDate: today.subtract(const Duration(days: 2)),
      );

      overdue$.add([tOverdue]);
      overdueProjects$.add([pOverdue]);

      final tSpan = _task(
        id: 't-span',
        name: 'Span Task',
        completed: false,
        startDate: today,
        deadlineDate: today.add(const Duration(days: 2)),
      );
      final tSameDay = _task(
        id: 't-same',
        name: 'Same-day Task',
        completed: false,
        startDate: today,
        deadlineDate: today,
      );
      final tAfterCompletion = _task(
        id: 't-ac',
        name: 'After completion repeating',
        completed: false,
        startDate: today.add(const Duration(days: 1)),
        repeatIcalRrule: 'FREQ=DAILY;INTERVAL=1',
        repeatFromCompletion: true,
      );
      final pSpan = _project(
        id: 'p-span',
        name: 'Span Project',
        completed: false,
        startDate: today.add(const Duration(days: 1)),
        deadlineDate: today.add(const Duration(days: 3)),
      );

      scheduled$.add([tSpan, tSameDay, tAfterCompletion]);
      scheduledProjects$.add([pSpan]);

      final agenda = await service.getAgendaData(
        referenceDate: today,
        focusDate: today,
        rangeStart: today,
        rangeEnd: horizonEnd,
      );

      expect(agenda.overdueItems, hasLength(2));
      expect(
        agenda.overdueItems.map((i) => i.tag),
        everyElement(AgendaDateTag.due),
      );

      expect(agenda.groups, hasLength(4));

      final day0 = agenda.groups[0];
      expect(day0.semanticLabel, 'Today');
      expect(
        _findItem(day0, entityId: 't-span', tag: AgendaDateTag.starts),
        isNotNull,
      );
      expect(
        _findItem(day0, entityId: 't-same', tag: AgendaDateTag.due),
        isNotNull,
      );

      final day1 = agenda.groups[1];
      expect(day1.semanticLabel, 'Tomorrow');
      final inProgress = _findItem(
        day1,
        entityId: 't-span',
        tag: AgendaDateTag.inProgress,
      );
      expect(inProgress, isNotNull);
      expect(inProgress!.isCondensed, isTrue);

      final afterCompletion = _findItem(
        day1,
        entityId: 't-ac',
        tag: AgendaDateTag.starts,
      );
      expect(afterCompletion, isNotNull);
      expect(afterCompletion!.isAfterCompletionRepeat, isTrue);

      final day2 = agenda.groups[2];
      expect(
        _findItem(day2, entityId: 't-span', tag: AgendaDateTag.due),
        isNotNull,
      );

      final day3 = agenda.groups[3];
      expect(
        _findItem(day3, entityId: 'p-span', tag: AgendaDateTag.due),
        isNotNull,
      );
    });

    testSafe('jumpToDate sets loaded horizon end', () async {
      final overdue$ = BehaviorSubject<List<Task>>.seeded(const []);
      final scheduled$ = BehaviorSubject<List<Task>>.seeded(const []);
      addTearDown(overdue$.close);
      addTearDown(scheduled$.close);

      final overdueProjects$ = BehaviorSubject<List<Project>>.seeded(const []);
      final scheduledProjects$ = BehaviorSubject<List<Project>>.seeded(
        const [],
      );
      addTearDown(overdueProjects$.close);
      addTearDown(scheduledProjects$.close);

      final service = AgendaSectionDataService(
        taskRepository: _FakeTaskRepository(
          overdue: overdue$,
          scheduled: scheduled$,
        ),
        projectRepository: _FakeProjectRepository(
          overdue: overdueProjects$,
          scheduled: scheduledProjects$,
        ),
        nearTermDays: 0,
      );

      final target = DateTime(2026, 2, 2);
      final agenda = await service.jumpToDate(target);

      expect(agenda.focusDate, target);
      expect(agenda.loadedHorizonEnd, target.add(const Duration(days: 30)));
    });
  });
}
