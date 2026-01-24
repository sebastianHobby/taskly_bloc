@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
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
        secondaryValueId: valueIds != null && valueIds.length > 1
            ? valueIds[1]
            : null,
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

class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
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

      final service = TemplateDataService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        valueRepository: valueRepo,
        clock: _FixedClock(DateTime.utc(2026, 1, 1, 12)),
      );

      await service.resetAndSeed();

      final values = await valueRepo.getAll();
      final projects = await projectRepo.getAll();
      final tasks = await taskRepo.getAll();

      expect(values, hasLength(5));
      expect(
        values.map((v) => v.name),
        containsAll(<String>[
          'Life Admin',
          'Home & Comfort',
          'Relationships',
          'Health & Energy',
          'Learning & Curiosity',
        ]),
      );
      expect(projects, hasLength(5));
      expect(tasks, hasLength(20));
      expect(tasks.where((t) => t.isPinned), hasLength(1));
    },
  );
}
