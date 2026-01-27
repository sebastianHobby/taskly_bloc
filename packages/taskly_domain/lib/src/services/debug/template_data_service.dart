import 'package:flutter/foundation.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/core/model/value_priority.dart';
import 'package:taskly_domain/src/queries/project_query.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
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
        name: 'Career & Growth',
        color: '#10B981',
        priority: ValuePriority.high,
        iconName: 'work',
      ),
      _TemplateValueSeed(
        name: 'Relationships',
        color: '#8B5CF6',
        priority: ValuePriority.medium,
        iconName: 'group',
      ),
      _TemplateValueSeed(
        name: 'Health & Energy',
        color: '#F59E0B',
        priority: ValuePriority.high,
        iconName: 'health',
      ),
      _TemplateValueSeed(
        name: 'Home & Comfort',
        color: '#EC4899',
        priority: ValuePriority.medium,
        iconName: 'home',
      ),
      _TemplateValueSeed(
        name: 'Finance & Security',
        color: '#06B6D4',
        priority: ValuePriority.medium,
        iconName: 'business',
      ),
      _TemplateValueSeed(
        name: 'Community',
        color: '#14B8A6',
        priority: ValuePriority.medium,
        iconName: 'person',
      ),
      _TemplateValueSeed(
        name: 'Creativity',
        color: '#EF4444',
        priority: ValuePriority.low,
        iconName: 'rocket',
      ),
      _TemplateValueSeed(
        name: 'Learning & Curiosity',
        color: '#3B82F6',
        priority: ValuePriority.medium,
        iconName: 'lightbulb',
      ),
      _TemplateValueSeed(
        name: 'Mindfulness',
        color: '#10B981',
        priority: ValuePriority.medium,
        iconName: 'meditation',
      ),
      _TemplateValueSeed(
        name: 'Focus & Clarity',
        color: '#8B5CF6',
        priority: ValuePriority.medium,
        iconName: 'target',
      ),
      _TemplateValueSeed(
        name: 'Adventure',
        color: '#F59E0B',
        priority: ValuePriority.low,
        iconName: 'flag',
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
      name: 'Get a passport',
      description: 'Everything needed to renew/apply',
      priority: 1,
      startDate: day(-14),
      deadlineDate: day(21),
      valueIds: [valueIdByName['Life Admin']!],
    );
    await _projectRepository.create(
      name: 'Home chores',
      description: 'Household admin + weekly chores',
      priority: 2,
      startDate: day(-30),
      deadlineDate: day(60),
      valueIds: [valueIdByName['Home & Comfort']!],
    );
    await _projectRepository.create(
      name: 'Organise birthday for Sam',
      description: 'Plan, invite, gifts, and schedule',
      priority: 2,
      startDate: day(-10),
      deadlineDate: day(10),
      valueIds: [valueIdByName['Relationships']!],
    );
    await _projectRepository.create(
      name: 'Exercise Routines',
      description: 'Recurring training and mobility habits',
      priority: 2,
      startDate: day(-21),
      deadlineDate: day(90),
      valueIds: [valueIdByName['Health & Energy']!],
    );
    await _projectRepository.create(
      name: 'Learn capital city names',
      description: 'Flashcards and weekly quizzes',
      priority: 3,
      startDate: day(-5),
      deadlineDate: day(45),
      valueIds: [valueIdByName['Learning & Curiosity']!],
    );
    await _projectRepository.create(
      name: 'Weekly Review Prep',
      description: 'Sample data so the weekly review flow has things to show',
      priority: 1,
      startDate: day(-3),
      deadlineDate: day(7),
      valueIds: [valueIdByName['Focus & Clarity']!],
    );

    final projectIdByName = await _loadProjectIdByName();
    final projectPrimaryValueIdById = await _loadProjectPrimaryValueIdById();

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

const _templateTaskSeeds = <_TemplateTaskSeed>[
  _TemplateTaskSeed(
    name: 'Book passport photo',
    projectName: 'Get a passport',
    startOffset: -1,
    deadlineOffset: 2,
    priority: 2,
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Check photo size requirements',
    projectName: 'Get a passport',
    deadlineOffset: 1,
  ),
  _TemplateTaskSeed(
    name: 'Confirm appointment location',
    projectName: 'Get a passport',
    startOffset: 3,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Submit application',
    projectName: 'Get a passport',
    startOffset: 9,
    deadlineOffset: 12,
    priority: 1,
    complete: true,
  ),
  _TemplateTaskSeed(
    name: 'Check renewal requirements',
    projectName: 'Get a passport',
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Make a documents checklist',
    projectName: 'Get a passport',
    startOffset: -2,
    priority: 4,
  ),
  _TemplateTaskSeed(
    name: 'Translate supporting documents',
    projectName: 'Get a passport',
    deadlineOffset: 5,
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Track application status',
    projectName: 'Get a passport',
  ),
  _TemplateTaskSeed(
    name: 'Laundry + bedding',
    projectName: 'Home chores',
    startOffset: -7,
    deadlineOffset: -1,
    priority: 3,
    valueNames: ['Health & Energy', 'Mindfulness'],
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Deep clean kitchen',
    projectName: 'Home chores',
    startOffset: 14,
    deadlineOffset: 16,
    priority: 2,
    complete: true,
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Declutter miscellaneous drawer',
    projectName: 'Home chores',
    priority: 4,
  ),
  _TemplateTaskSeed(
    name: 'Organize cleaning supplies',
    projectName: 'Home chores',
    startOffset: -2,
    priority: 3,
    valueNames: ['Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Prep seasonal cleaning plan',
    projectName: 'Home chores',
    deadlineOffset: 7,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Inventory cleaning supplies',
    projectName: 'Home chores',
    startOffset: -4,
  ),
  _TemplateTaskSeed(
    name: 'Replace air filters',
    projectName: 'Home chores',
    deadlineOffset: -3,
    priority: 2,
  ),
  _TemplateTaskSeed(
    name: 'Schedule pest control check',
    projectName: 'Home chores',
    startOffset: 30,
    deadlineOffset: 45,
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Book dinner reservation',
    projectName: 'Organise birthday for Sam',
    startOffset: 2,
    deadlineOffset: 5,
    priority: 2,
    complete: true,
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Buy birthday gift for Sam',
    projectName: 'Organise birthday for Sam',
    startOffset: -5,
    deadlineOffset: 3,
    priority: 1,
    valueNames: ['Community', 'Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Draft invite message',
    projectName: 'Organise birthday for Sam',
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Ideas list: gift + activities',
    projectName: 'Organise birthday for Sam',
    priority: 4,
  ),
  _TemplateTaskSeed(
    name: 'Confirm entertainment plan',
    projectName: 'Organise birthday for Sam',
    deadlineOffset: 6,
    priority: 3,
  ),
  _TemplateTaskSeed(
    name: 'Finalize guest list',
    projectName: 'Organise birthday for Sam',
    startOffset: -1,
  ),
  _TemplateTaskSeed(
    name: 'Order birthday cake',
    projectName: 'Organise birthday for Sam',
    deadlineOffset: 4,
    priority: 2,
    valueNames: ['Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Plan workouts for next week',
    projectName: 'Exercise Routines',
    startOffset: 1,
    deadlineOffset: 4,
    priority: 2,
    repeatIcalRrule: 'FREQ=WEEKLY;BYDAY=MO',
    valueNames: ['Focus & Clarity'],
    complete: true,
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Buy resistance bands',
    projectName: 'Exercise Routines',
    startOffset: 20,
    deadlineOffset: 25,
    priority: 3,
    valueNames: ['Finance & Security'],
  ),
  _TemplateTaskSeed(
    name: 'Create a warm-up checklist',
    projectName: 'Exercise Routines',
    priority: 4,
    valueNames: ['Mindfulness'],
  ),
  _TemplateTaskSeed(
    name: 'Research a beginner mobility routine',
    projectName: 'Exercise Routines',
    priority: 3,
    valueNames: ['Learning & Curiosity'],
  ),
  _TemplateTaskSeed(
    name: 'Log progress snapshot',
    projectName: 'Exercise Routines',
    deadlineOffset: 2,
    priority: 3,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Morning mobility check-in',
    projectName: 'Exercise Routines',
    startOffset: 0,
    repeatIcalRrule: 'FREQ=DAILY',
    valueNames: ['Mindfulness'],
  ),
  _TemplateTaskSeed(
    name: 'Strength session (biweekly)',
    projectName: 'Exercise Routines',
    startOffset: 5,
    repeatIcalRrule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=FR',
    priority: 3,
    valueNames: ['Mindfulness'],
  ),
  _TemplateTaskSeed(
    name: 'Set training reminder',
    projectName: 'Exercise Routines',
    deadlineOffset: 1,
  ),
  _TemplateTaskSeed(
    name: 'Europe capitals: set 1 (15)',
    projectName: 'Learn capital city names',
    startOffset: 4,
    deadlineOffset: 6,
    priority: 3,
    valueNames: ['Career & Growth'],
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Africa capitals: set 1 (12)',
    projectName: 'Learn capital city names',
    startOffset: 35,
    deadlineOffset: 40,
    priority: 3,
    valueNames: ['Career & Growth'],
    pin: true,
  ),
  _TemplateTaskSeed(
    name: 'Make flashcards format (template)',
    projectName: 'Learn capital city names',
    priority: 4,
    valueNames: ['Creativity'],
  ),
  _TemplateTaskSeed(
    name: 'List "hard ones" to revisit',
    projectName: 'Learn capital city names',
    priority: 4,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Schedule review quiz',
    projectName: 'Learn capital city names',
    deadlineOffset: 12,
    priority: 3,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Capitals quiz reminder',
    projectName: 'Learn capital city names',
    deadlineOffset: 1,
    valueNames: ['Focus & Clarity'],
  ),
  _TemplateTaskSeed(
    name: 'Quick review: Europe set 1',
    projectName: 'Learn capital city names',
    startOffset: 8,
    priority: 2,
    valueNames: ['Adventure'],
  ),
  _TemplateTaskSeed(
    name: 'Create quiz scoring sheet',
    projectName: 'Learn capital city names',
    valueNames: ['Creativity'],
  ),
  _TemplateTaskSeed(
    name: "Review last week's highlights",
    projectName: 'Weekly Review Prep',
    priority: 3,
    valueNames: ['Mindfulness'],
  ),
  _TemplateTaskSeed(
    name: 'Collect community wins',
    projectName: 'Weekly Review Prep',
    priority: 3,
    valueNames: ['Community'],
  ),
  _TemplateTaskSeed(
    name: "Draft next week's focus",
    projectName: 'Weekly Review Prep',
    priority: 3,
    valueNames: ['Career & Growth'],
  ),
  _TemplateTaskSeed(
    name: 'Summarize lessons learned',
    projectName: 'Weekly Review Prep',
    priority: 3,
    valueNames: ['Learning & Curiosity'],
  ),
  _TemplateTaskSeed(
    name: 'Update weekly metrics dashboard',
    projectName: 'Weekly Review Prep',
    priority: 3,
    valueNames: ['Finance & Security'],
  ),
  _TemplateTaskSeed(
    name: 'Plan reflection prompts',
    projectName: 'Weekly Review Prep',
    priority: 3,
    valueNames: ['Creativity'],
  ),
  _TemplateTaskSeed(
    name: 'Review task backlogs',
    projectName: 'Weekly Review Prep',
    startOffset: -6,
    priority: 2,
    valueNames: ['Life Admin'],
  ),
  _TemplateTaskSeed(
    name: 'Identify deadline risks',
    projectName: 'Weekly Review Prep',
    deadlineOffset: 2,
    priority: 2,
    valueNames: ['Finance & Security'],
  ),
];

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
