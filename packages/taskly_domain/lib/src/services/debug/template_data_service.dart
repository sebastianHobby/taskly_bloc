import 'package:flutter/foundation.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/core/model/value_priority.dart';
import 'package:taskly_domain/src/queries/project_query.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/routines/model/routine_type.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/time/date_only.dart';
import 'package:taskly_domain/telemetry.dart';

@immutable
class _TemplateValueSeed {
  const _TemplateValueSeed({
    required this.name,
    required this.color,
    required this.priority,
    this.iconName,
  });

  final String name;
  final String color;
  final ValuePriority priority;
  final String? iconName;
}

/// Ensures icons are unique within a single template seed run.
///
/// Uses a small keyword-based mapper first for 'suitable' icons, then falls
/// back to a deterministic selection from a shared pool.
class _UniqueValueIconAssigner {
  _UniqueValueIconAssigner();

  /// Pool of icon *names* that must exist in
  /// `presentation/widgets/icon_picker/icon_picker_dialog.dart`.
  static const _fallbackPool = <String>[
    // Goals & Values
    'values',
    'flag',
    'target',
    'trophy',
    'priority',
    'rocket',
    // Organization
    'projects',
    'folder_open',
    'work',
    'business',
    'labels',
    'tag',
    'category',
    'bookmark',
    // Tasks
    'checklist',
    'task',
    'done',
    'pending',
    // Time
    'schedule',
    'calendar',
    'timer',
    'alarm',
    'history',
    'hourglass',
    // Journal
    'mood',
    'journal',
    'self_care',
    'health',
    'meditation',
    // Misc
    'settings',
    'tune',
    'filter',
    'sort',
    'search',
    'lightbulb',
    'info',
    'home',
    'person',
    'group',
    'trackers',
  ];

  final Set<String> _used = <String>{};

  String assign({required String valueName, String? preferred}) {
    final normalized = valueName.trim();

    if (preferred != null &&
        preferred.isNotEmpty &&
        !_used.contains(preferred)) {
      _used.add(preferred);
      return preferred;
    }

    final suggested = _suggestForName(normalized);
    if (suggested != null && !_used.contains(suggested)) {
      _used.add(suggested);
      return suggested;
    }

    final startIndex = _stableIndex(normalized, _fallbackPool.length);
    for (var offset = 0; offset < _fallbackPool.length; offset++) {
      final candidate =
          _fallbackPool[(startIndex + offset) % _fallbackPool.length];
      if (_used.add(candidate)) {
        return candidate;
      }
    }

    // Should be unreachable unless pool is empty.
    return 'values';
  }

  static String? _suggestForName(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('life admin') ||
        lower.contains('admin') ||
        lower.contains('paper') ||
        lower.contains('documents')) {
      return 'checklist';
    }

    if (lower.contains('home') ||
        lower.contains('comfort') ||
        lower.contains('house') ||
        lower.contains('chores')) {
      return 'home';
    }

    if (lower.contains('relationship') ||
        lower.contains('friends') ||
        lower.contains('family') ||
        lower.contains('social')) {
      return 'group';
    }

    if (lower.contains('health') ||
        lower.contains('energy') ||
        lower.contains('exercise') ||
        lower.contains('fitness')) {
      return 'health';
    }

    if (lower.contains('learning') ||
        lower.contains('curiosity') ||
        lower.contains('study') ||
        lower.contains('read')) {
      return 'lightbulb';
    }

    return null;
  }

  static int _stableIndex(String input, int modulo) {
    // Cheap deterministic hash (no crypto/security needs here).
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    if (modulo <= 0) return 0;
    return hash % modulo;
  }
}

/// Debug-only helper that wipes user task data and seeds a curated dataset.
///
/// This is intended for demos and screenshots. It deliberately uses repositories
/// (instead of raw SQL) so it exercises real app logic and sync behavior.
class TemplateDataService {
  TemplateDataService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required RoutineRepositoryContract routineRepository,
    required ValueRepositoryContract valueRepository,
    required MyDayRepositoryContract myDayRepository,
    Clock clock = systemClock,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _routineRepository = routineRepository,
       _valueRepository = valueRepository,
       _myDayRepository = myDayRepository,
       _clock = clock;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final RoutineRepositoryContract _routineRepository;
  final ValueRepositoryContract _valueRepository;
  final MyDayRepositoryContract _myDayRepository;
  final Clock _clock;

  /// Deletes all user Tasks/Projects/Values and recreates template demo data.
  ///
  /// Only callable in debug mode.
  Future<void> resetAndSeed() async {
    if (!kDebugMode) {
      throw StateError('TemplateDataService is debug-only.');
    }

    final today = dateOnly(_clock.nowUtc());

    // 1) Wipe existing entity data.
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    for (final task in tasks) {
      await _taskRepository.delete(task.id);
    }

    final projects = await _projectRepository.getAll(ProjectQuery.all());
    for (final project in projects) {
      await _projectRepository.delete(project.id);
    }

    final routines = await _routineRepository.getAll(includeInactive: true);
    for (final routine in routines) {
      await _routineRepository.delete(routine.id);
    }

    final values = await _valueRepository.getAll();
    for (final value in values) {
      await _valueRepository.delete(value.id);
    }

    await _clearDayPicks(today);

    // 2) Create Values.
    const seeds = <_TemplateValueSeed>[
      _TemplateValueSeed(
        name: 'Life Admin',
        color: '#3B82F6',
        priority: ValuePriority.high,
        iconName: 'checklist',
      ),
      _TemplateValueSeed(
        name: 'Home & Comfort',
        color: '#EC4899',
        priority: ValuePriority.medium,
        iconName: 'home',
      ),
      _TemplateValueSeed(
        name: 'Health & Energy',
        color: '#F59E0B',
        priority: ValuePriority.high,
        iconName: 'health',
      ),
      _TemplateValueSeed(
        name: 'Focus & Clarity',
        color: '#8B5CF6',
        priority: ValuePriority.medium,
        iconName: 'target',
      ),
      _TemplateValueSeed(
        name: 'Relationships',
        color: '#10B981',
        priority: ValuePriority.medium,
        iconName: 'group',
      ),
      _TemplateValueSeed(
        name: 'Finance & Security',
        color: '#06B6D4',
        priority: ValuePriority.medium,
        iconName: 'business',
      ),
    ];

    final iconAssigner = _UniqueValueIconAssigner();
    for (final seed in seeds) {
      await _valueRepository.create(
        name: seed.name,
        color: seed.color,
        iconName: iconAssigner.assign(
          valueName: seed.name,
          preferred: seed.iconName,
        ),
        priority: seed.priority,
      );
    }

    final valueIdByName = await _loadValueIdByName();

    DateTime day(int offset) => today.add(Duration(days: offset));

    await _projectRepository.create(
      name: 'Home Systems',
      description: 'Maintenance, cleaning, and household upkeep',
      priority: 2,
      startDate: day(-21),
      deadlineDate: day(45),
      valueIds: [valueIdByName['Home & Comfort']!],
    );
    await _projectRepository.create(
      name: 'Personal Admin',
      description: 'Docs, renewals, and planning',
      priority: 1,
      startDate: day(-7),
      deadlineDate: day(30),
      valueIds: [valueIdByName['Life Admin']!],
    );
    await _projectRepository.create(
      name: 'Health Stack',
      description: 'Fitness, recovery, and energy routines',
      priority: 2,
      startDate: day(-14),
      deadlineDate: day(60),
      valueIds: [valueIdByName['Health & Energy']!],
    );
    await _projectRepository.create(
      name: 'Social Plans',
      description: 'Plans, events, and celebrations',
      priority: 3,
      startDate: day(-5),
      deadlineDate: day(20),
      valueIds: [valueIdByName['Relationships']!],
    );

    final projectIdByName = await _loadProjectIdByName();
    final projectPrimaryValueIdById = await _loadProjectPrimaryValueIdById();

    for (final seed in _templateRoutineSeeds) {
      final valueId = valueIdByName[seed.valueName];
      if (valueId == null) continue;

      await _routineRepository.create(
        name: seed.name,
        valueId: valueId,
        routineType: seed.routineType,
        targetCount: seed.targetCount,
        scheduleDays: seed.scheduleDays,
        minSpacingDays: seed.minSpacingDays,
      );
    }

    final pinnedTaskNames = <String>[];
    final completedTaskNames = <String>[];

    for (final seed in _templateTaskSeeds) {
      final projectId = projectIdByName[seed.projectName];
      if (projectId == null) continue;

      final taskValueIds = _sanitizeTaskValueIds(
        projectId: projectId,
        valueIds: _valueIdsFor(seed.valueNames, valueIdByName),
        projectPrimaryValueIdById: projectPrimaryValueIdById,
      );

      await _taskRepository.create(
        name: seed.name,
        projectId: projectId,
        priority: seed.priority,
        startDate: seed.startOffset == null ? null : day(seed.startOffset!),
        deadlineDate: seed.deadlineOffset == null
            ? null
            : day(seed.deadlineOffset!),
        valueIds: taskValueIds,
        repeatIcalRrule: seed.repeatIcalRrule,
      );

      if (seed.pin) pinnedTaskNames.add(seed.name);
      if (seed.complete) completedTaskNames.add(seed.name);
    }

    await _completeTasksByName(completedTaskNames);
    await _pinTasksByName(pinnedTaskNames.take(1).toList());
    await _snoozeTaskRepeatedly(
      'Laundry + bedding',
      days: const <int>[2, 10, 18],
    );
  }

  List<String>? _valueIdsFor(
    List<String>? names,
    Map<String, String> valueIdByName,
  ) {
    if (names == null) return null;
    final ids = <String>[];
    for (final name in names) {
      final id = valueIdByName[name];
      if (id != null) {
        ids.add(id);
      }
    }
    return ids.isEmpty ? null : ids;
  }

  List<String>? _sanitizeTaskValueIds({
    required String projectId,
    required List<String>? valueIds,
    required Map<String, String?> projectPrimaryValueIdById,
  }) {
    if (valueIds == null || valueIds.isEmpty) return null;
    final primaryValueId = projectPrimaryValueIdById[projectId];
    if (primaryValueId == null) return valueIds;

    final filtered = valueIds.where((id) => id != primaryValueId).toList();
    return filtered.isEmpty ? null : filtered;
  }

  Future<void> _completeTasksByName(List<String> names) async {
    if (names.isEmpty) return;
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    final idByName = <String, String>{for (final t in tasks) t.name: t.id};

    for (final name in names) {
      final id = idByName[name];
      if (id == null) continue;
      await _taskRepository.completeOccurrence(
        taskId: id,
        context: _templateContext(
          intent: 'complete_task',
          entityType: 'task',
          entityId: id,
        ),
      );
    }
  }

  Future<void> _snoozeTaskRepeatedly(
    String name, {
    required List<int> days,
  }) async {
    if (days.isEmpty) return;
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    final idByName = <String, String>{for (final t in tasks) t.name: t.id};
    final id = idByName[name];
    if (id == null) return;

    for (final offset in days) {
      final until = _clock.nowUtc().add(Duration(days: offset));
      await _taskRepository.setMyDaySnoozedUntil(
        id: id,
        untilUtc: until,
        context: _templateContext(
          intent: 'snooze_task',
          entityType: 'task',
          entityId: id,
        ),
      );
    }
  }

  Future<void> _clearDayPicks(DateTime dayKeyUtc) async {
    await _myDayRepository.clearDay(
      dayKeyUtc: dayKeyUtc,
      context: _templateContext(
        intent: 'clear_day',
        entityType: 'my_day_day',
        entityId: encodeDateOnly(dayKeyUtc),
      ),
    );
  }

  OperationContext _templateContext({
    required String intent,
    String? entityType,
    String? entityId,
  }) {
    final correlationId = '$intent-${_clock.nowUtc().microsecondsSinceEpoch}';
    return OperationContext(
      correlationId: correlationId,
      feature: 'settings',
      intent: 'template.$intent',
      operation: 'settings.template.$intent',
      entityType: entityType,
      entityId: entityId,
    );
  }

  Future<Map<String, String>> _loadValueIdByName() async {
    final values = await _valueRepository.getAll();
    return {for (final v in values) v.name: v.id};
  }

  Future<Map<String, String>> _loadProjectIdByName() async {
    final projects = await _projectRepository.getAll(ProjectQuery.all());
    return {for (final p in projects) p.name: p.id};
  }

  Future<Map<String, String?>> _loadProjectPrimaryValueIdById() async {
    final projects = await _projectRepository.getAll(ProjectQuery.all());
    return {for (final p in projects) p.id: p.primaryValueId};
  }

  Future<void> _pinTasksByName(List<String> names) async {
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    final idByName = <String, String>{for (final t in tasks) t.name: t.id};

    for (final name in names) {
      final id = idByName[name];
      if (id == null) continue;
      await _taskRepository.setPinned(id: id, isPinned: true);
    }
  }
}

const _templateRoutineSeeds = <_TemplateRoutineSeed>[
  _TemplateRoutineSeed(
    name: 'Morning reset',
    valueName: 'Home & Comfort',
    routineType: RoutineType.weeklyFixed,
    targetCount: 7,
    scheduleDays: [1, 2, 3, 4, 5, 6, 7],
  ),
  _TemplateRoutineSeed(
    name: 'Weekly review prep',
    valueName: 'Focus & Clarity',
    routineType: RoutineType.weeklyFixed,
    targetCount: 1,
    scheduleDays: [5],
  ),
  _TemplateRoutineSeed(
    name: 'Workout block',
    valueName: 'Health & Energy',
    routineType: RoutineType.weeklyFixed,
    targetCount: 2,
    scheduleDays: [2, 4],
  ),
  _TemplateRoutineSeed(
    name: 'Hydration check-in',
    valueName: 'Health & Energy',
    routineType: RoutineType.weeklyFlexible,
    targetCount: 5,
    minSpacingDays: 0,
  ),
  _TemplateRoutineSeed(
    name: 'Tidy 10 minutes',
    valueName: 'Home & Comfort',
    routineType: RoutineType.weeklyFlexible,
    targetCount: 3,
    minSpacingDays: 1,
  ),
  _TemplateRoutineSeed(
    name: 'Read 15 minutes',
    valueName: 'Focus & Clarity',
    routineType: RoutineType.weeklyFlexible,
    targetCount: 4,
    minSpacingDays: 0,
  ),
];

const _templateTaskSeeds = <_TemplateTaskSeed>[
  _TemplateTaskSeed(
    name: 'Laundry + bedding',
    projectName: 'Home Systems',
    startOffset: -3,
    deadlineOffset: 1,
    priority: 3,
    valueNames: ['Health & Energy'],
    repeatIcalRrule: 'FREQ=WEEKLY;BYDAY=SA',
  ),
  _TemplateTaskSeed(
    name: 'Reset pantry inventory',
    projectName: 'Home Systems',
    startOffset: -2,
    deadlineOffset: 3,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Replace air filters',
    projectName: 'Home Systems',
    deadlineOffset: 7,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Deep clean kitchen',
    projectName: 'Home Systems',
    deadlineOffset: 14,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Declutter entryway',
    projectName: 'Home Systems',
    startOffset: 5,
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Schedule home maintenance check',
    projectName: 'Home Systems',
    startOffset: 12,
    deadlineOffset: 30,
    priority: 3,
    valueNames: ['Finance & Security'],
  ),
  _TemplateTaskSeed(
    name: 'Organize cleaning supplies',
    projectName: 'Home Systems',
    startOffset: 1,
    priority: 3,
    valueNames: ['Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Renew car registration',
    projectName: 'Personal Admin',
    startOffset: -4,
    deadlineOffset: 10,
    priority: 2,
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Update insurance documents',
    projectName: 'Personal Admin',
    deadlineOffset: 20,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Back up important files',
    projectName: 'Personal Admin',
    startOffset: 1,
    priority: 3,
    complete: true,
  ),
  _TemplateTaskSeed(
    name: 'Plan quarterly budgeting session',
    projectName: 'Personal Admin',
    startOffset: 3,
    deadlineOffset: 7,
    priority: 2,
    valueNames: ['Finance & Security'],
  ),
  _TemplateTaskSeed(
    name: 'Review subscriptions',
    projectName: 'Personal Admin',
    deadlineOffset: 12,
    priority: 2,
    valueNames: ['Finance & Security'],
  ),
  _TemplateTaskSeed(
    name: 'Set up tax folder',
    projectName: 'Personal Admin',
    priority: 4,
    valueNames: ['Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Consolidate account logins',
    projectName: 'Personal Admin',
    priority: 3,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Book annual checkup',
    projectName: 'Health Stack',
    deadlineOffset: 21,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Plan workouts for next week',
    projectName: 'Health Stack',
    startOffset: 1,
    deadlineOffset: 3,
    priority: 2,
    repeatIcalRrule: 'FREQ=WEEKLY;BYDAY=MO',
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Morning mobility check-in',
    projectName: 'Health Stack',
    startOffset: 0,
    repeatIcalRrule: 'FREQ=DAILY',
    valueNames: ['Health & Energy'],
  ),
  _TemplateTaskSeed(
    name: 'Strength session (biweekly)',
    projectName: 'Health Stack',
    startOffset: 5,
    repeatIcalRrule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=FR',
    priority: 3,
    valueNames: ['Health & Energy'],
  ),
  _TemplateTaskSeed(
    name: 'Grocery list: high-protein staples',
    projectName: 'Health Stack',
    startOffset: -1,
    deadlineOffset: 2,
    priority: 3,
    valueNames: ['Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Meal prep plan (Sun)',
    projectName: 'Health Stack',
    startOffset: 4,
    deadlineOffset: 5,
    priority: 3,
    valueNames: ['Health & Energy'],
  ),
  _TemplateTaskSeed(
    name: 'Hydration target setup',
    projectName: 'Health Stack',
    priority: 3,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Rest day walk',
    projectName: 'Health Stack',
    startOffset: 2,
    priority: 4,
    valueNames: ['Health & Energy'],
  ),
  _TemplateTaskSeed(
    name: 'Confirm weekend plans with Sam',
    projectName: 'Social Plans',
    startOffset: -1,
    deadlineOffset: 1,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Pick a birthday gift',
    projectName: 'Social Plans',
    deadlineOffset: 9,
    priority: 2,
    valueNames: ['Relationships', 'Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Draft invite message',
    projectName: 'Social Plans',
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Book dinner reservation',
    projectName: 'Social Plans',
    startOffset: 2,
    deadlineOffset: 5,
    priority: 2,
    complete: true,
  ),
  _TemplateTaskSeed(
    name: 'Create shared itinerary',
    projectName: 'Social Plans',
    startOffset: 6,
    deadlineOffset: 10,
    priority: 3,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Collect gift ideas from group',
    projectName: 'Social Plans',
    startOffset: -2,
    deadlineOffset: 4,
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Buy tickets for event',
    projectName: 'Social Plans',
    startOffset: 7,
    deadlineOffset: 12,
    priority: 2,
    valueNames: ['Finance & Security'],
  ),
  _TemplateTaskSeed(
    name: 'Check venue accessibility',
    projectName: 'Social Plans',
    startOffset: 5,
    deadlineOffset: 8,
    priority: 3,
  ),
];

@immutable
final class _TemplateRoutineSeed {
  const _TemplateRoutineSeed({
    required this.name,
    required this.valueName,
    required this.routineType,
    required this.targetCount,
    this.scheduleDays = const <int>[],
    this.minSpacingDays,
  });

  final String name;
  final String valueName;
  final RoutineType routineType;
  final int targetCount;
  final List<int> scheduleDays;
  final int? minSpacingDays;
}

@immutable
final class _TemplateTaskSeed {
  const _TemplateTaskSeed({
    required this.name,
    required this.projectName,
    this.startOffset,
    this.deadlineOffset,
    this.priority,
    this.valueNames,
    this.pin = false,
    this.complete = false,
    this.repeatIcalRrule,
  });

  final String name;
  final String projectName;
  final int? startOffset;
  final int? deadlineOffset;
  final int? priority;
  final List<String>? valueNames;
  final bool pin;
  final bool complete;
  final String? repeatIcalRrule;
}
