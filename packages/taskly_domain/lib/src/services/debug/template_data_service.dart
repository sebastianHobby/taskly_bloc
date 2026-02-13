import 'package:flutter/foundation.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/core/model/value_priority.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/src/queries/project_query.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/time/date_only.dart';
import 'package:taskly_domain/services.dart';
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
    required ValueRatingsWriteService valueRatingsWriteService,
    required UserDataWipeService userDataWipeService,
    required SettingsRepositoryContract settingsRepository,
    Clock clock = systemClock,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _routineRepository = routineRepository,
       _valueRepository = valueRepository,
       _valueRatingsWriteService = valueRatingsWriteService,
       _userDataWipeService = userDataWipeService,
       _settingsRepository = settingsRepository,
       _clock = clock;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final RoutineRepositoryContract _routineRepository;
  final ValueRepositoryContract _valueRepository;
  final ValueRatingsWriteService _valueRatingsWriteService;
  final UserDataWipeService _userDataWipeService;
  final SettingsRepositoryContract _settingsRepository;
  final Clock _clock;

  /// Wipes all user data (local + synced) and recreates template demo data.
  ///
  /// Only callable in debug mode.
  Future<void> resetAndSeed({OperationContext? context}) async {
    if (!kDebugMode) {
      throw StateError('TemplateDataService is debug-only.');
    }

    final baseFields = _logFields(context, const {'step': 'start'});
    AppLog.routineStructured(
      'domain.template_data',
      'resetAndSeed start',
      fields: baseFields,
    );

    // 1) Wipe existing user data (local + synced).
    AppLog.routineStructured(
      'domain.template_data',
      'wipe start',
      fields: _logFields(context, const {'step': 'wipe_start'}),
    );
    await _userDataWipeService.wipeAllUserData();
    AppLog.routineStructured(
      'domain.template_data',
      'wipe complete',
      fields: _logFields(context, const {'step': 'wipe_complete'}),
    );

    // 2) Create Values.
    const seeds = <_TemplateValueSeed>[
      _TemplateValueSeed(
        name: 'Learning',
        color: '#3B82F6',
        priority: ValuePriority.high,
        iconName: 'lightbulb',
      ),
      _TemplateValueSeed(
        name: 'Health',
        color: '#F59E0B',
        priority: ValuePriority.high,
        iconName: 'health',
      ),
      _TemplateValueSeed(
        name: 'Career',
        color: '#8B5CF6',
        priority: ValuePriority.medium,
        iconName: 'work',
      ),
      _TemplateValueSeed(
        name: 'Social',
        color: '#10B981',
        priority: ValuePriority.medium,
        iconName: 'group',
      ),
    ];

    final iconAssigner = _UniqueValueIconAssigner();
    for (final seed in seeds) {
      try {
        await _valueRepository.create(
          name: seed.name,
          color: seed.color,
          iconName: iconAssigner.assign(
            valueName: seed.name,
            preferred: seed.iconName,
          ),
          priority: seed.priority,
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'value create failed',
          e,
          st,
          _logFields(context, {
            'step': 'value_create_failed',
            'valueName': seed.name,
            'color': seed.color,
            'priority': seed.priority.name,
          }),
        );
        rethrow;
      }
    }

    final valueIdByName = await _loadValueIdByName();
    AppLog.routineStructured(
      'domain.template_data',
      'values loaded',
      fields: _logFields(context, {
        'step': 'values_loaded',
        'valueCount': valueIdByName.length,
      }),
    );
    final priorityByValueName = <String, ValuePriority>{
      for (final seed in seeds) seed.name: seed.priority,
    };

    final today = dateOnly(_clock.nowUtc());
    DateTime day(int offset) => today.add(Duration(days: offset));

    final projectSeeds =
        <
          ({
            String name,
            String description,
            int priority,
            int startOffset,
            int deadlineOffset,
            String valueName,
          })
        >[
          (
            name: 'Learning',
            description: 'Courses, reading, and study sessions',
            priority: 1,
            startOffset: -7,
            deadlineOffset: 21,
            valueName: 'Learning',
          ),
          (
            name: 'Self-care',
            description: 'Appointments, movement, and daily energy',
            priority: 2,
            startOffset: -10,
            deadlineOffset: 30,
            valueName: 'Health',
          ),
          (
            name: 'Work',
            description: 'Planning, updates, and delivery',
            priority: 1,
            startOffset: -5,
            deadlineOffset: 14,
            valueName: 'Career',
          ),
          (
            name: 'People',
            description: 'Family, friends, and invites',
            priority: 3,
            startOffset: -3,
            deadlineOffset: 10,
            valueName: 'Social',
          ),
        ];

    for (final seed in projectSeeds) {
      final valueId = valueIdByName[seed.valueName];
      if (valueId == null) {
        AppLog.warnStructured(
          'domain.template_data',
          'project seed skipped (missing value)',
          fields: _logFields(context, {
            'step': 'project_seed_skipped',
            'projectName': seed.name,
            'valueName': seed.valueName,
          }),
        );
        continue;
      }

      try {
        await _projectRepository.create(
          name: seed.name,
          description: seed.description,
          priority: seed.priority,
          startDate: day(seed.startOffset),
          deadlineDate: day(seed.deadlineOffset),
          valueIds: [valueId],
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'project create failed',
          e,
          st,
          _logFields(context, {
            'step': 'project_create_failed',
            'projectName': seed.name,
            'valueName': seed.valueName,
          }),
        );
        rethrow;
      }
    }

    final projectIdByName = await _loadProjectIdByName();
    AppLog.routineStructured(
      'domain.template_data',
      'projects loaded',
      fields: _logFields(context, {
        'step': 'projects_loaded',
        'projectCount': projectIdByName.length,
      }),
    );
    for (final seed in _templateRoutineSeeds) {
      final projectId = projectIdByName[seed.projectName];
      if (projectId == null) continue;

      try {
        await _routineRepository.create(
          name: seed.name,
          projectId: projectId,
          periodType: seed.periodType,
          scheduleMode: seed.scheduleMode,
          targetCount: seed.targetCount,
          scheduleDays: seed.scheduleDays,
          scheduleMonthDays: seed.scheduleMonthDays,
          minSpacingDays: seed.minSpacingDays,
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'routine create failed',
          e,
          st,
          _logFields(context, {
            'step': 'routine_create_failed',
            'routineName': seed.name,
            'projectName': seed.projectName,
            'periodType': seed.periodType.name,
            'scheduleMode': seed.scheduleMode.name,
          }),
        );
        rethrow;
      }
    }

    final projectPrimaryValueIdById = await _loadProjectPrimaryValueIdById();

    final completedTaskNames = <String>[];

    for (final seed in _templateTaskSeeds) {
      final projectId = projectIdByName[seed.projectName];
      if (projectId == null) continue;

      final taskValueIds = _sanitizeTaskValueIds(
        projectId: projectId,
        valueIds: _valueIdsFor(seed.valueNames, valueIdByName),
        projectPrimaryValueIdById: projectPrimaryValueIdById,
      );

      try {
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
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'task create failed',
          e,
          st,
          _logFields(context, {
            'step': 'task_create_failed',
            'taskName': seed.name,
            'projectName': seed.projectName,
            'valueNames': seed.valueNames?.join(','),
          }),
        );
        rethrow;
      }

      if (seed.complete) completedTaskNames.add(seed.name);
    }

    await _completeTasksByName(completedTaskNames, context: context);
    await _snoozeTaskRepeatedly(
      'Grocery list',
      days: const <int>[2, 10, 18],
      context: context,
    );

    await _seedWeeklyRatings(
      valueIdByName: valueIdByName,
      priorityByValueName: priorityByValueName,
      context: context,
    );
    await _forceWeeklyReviewDue(context);

    AppLog.routineStructured(
      'domain.template_data',
      'resetAndSeed complete',
      fields: _logFields(context, const {'step': 'complete'}),
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

  Future<void> _completeTasksByName(
    List<String> names, {
    OperationContext? context,
  }) async {
    if (names.isEmpty) return;
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    final idByName = <String, String>{for (final t in tasks) t.name: t.id};

    for (final name in names) {
      final id = idByName[name];
      if (id == null) continue;
      try {
        await _taskRepository.completeOccurrence(
          taskId: id,
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'task complete failed',
          e,
          st,
          _logFields(context, {
            'step': 'task_complete_failed',
            'taskName': name,
            'taskId': id,
          }),
        );
        rethrow;
      }
    }
  }

  Future<void> _snoozeTaskRepeatedly(
    String name, {
    required List<int> days,
    OperationContext? context,
  }) async {
    if (days.isEmpty) return;
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    final idByName = <String, String>{for (final t in tasks) t.name: t.id};
    final id = idByName[name];
    if (id == null) return;

    for (final offset in days) {
      final until = _clock.nowUtc().add(Duration(days: offset));
      try {
        await _taskRepository.setMyDaySnoozedUntil(
          id: id,
          untilUtc: until,
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'task snooze failed',
          e,
          st,
          _logFields(context, {
            'step': 'task_snooze_failed',
            'taskName': name,
            'taskId': id,
            'snoozeOffsetDays': offset,
          }),
        );
        rethrow;
      }
    }
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

  Future<void> _seedWeeklyRatings({
    required Map<String, String> valueIdByName,
    required Map<String, ValuePriority> priorityByValueName,
    OperationContext? context,
  }) async {
    if (valueIdByName.isEmpty) return;

    const weeksToSeed = 6;
    final weekStart = _weekStartFor(_clock.nowUtc());

    for (var offset = 0; offset < weeksToSeed; offset++) {
      final week = weekStart.subtract(Duration(days: offset * 7));
      final ratings = <String, int>{};

      for (final entry in valueIdByName.entries) {
        final priority = priorityByValueName[entry.key] ?? ValuePriority.medium;
        final rating = _ratingFor(
          valueName: entry.key,
          priority: priority,
          weekOffset: offset,
        );
        ratings[entry.value] = rating;
      }

      try {
        await _valueRatingsWriteService.recordWeeklyRatings(
          weekStartUtc: week,
          ratingsByValueId: ratings,
          context: context,
        );
      } catch (e, st) {
        AppLog.handleStructured(
          'domain.template_data',
          'weekly ratings seed failed',
          e,
          st,
          _logFields(context, {
            'step': 'weekly_ratings_seed_failed',
            'weekStartUtc': week.toIso8601String(),
            'ratingCount': ratings.length,
          }),
        );
        rethrow;
      }
    }
  }

  int _ratingFor({
    required String valueName,
    required ValuePriority priority,
    required int weekOffset,
  }) {
    final base = switch (priority) {
      ValuePriority.high => 8,
      ValuePriority.medium => 6,
      ValuePriority.low => 5,
    };
    final variance = (_stableHash(valueName) + weekOffset) % 3 - 1;
    return (base + variance).clamp(1, 10);
  }

  DateTime _weekStartFor(DateTime nowUtc) {
    final today = dateOnly(nowUtc);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  Future<void> _forceWeeklyReviewDue(OperationContext? context) async {
    final settings = await _settingsRepository.load(SettingsKey.global);
    final nowLocal = _clock.nowLocal();
    final minutesOfDay = (nowLocal.hour * 60 + nowLocal.minute).clamp(0, 1439);

    try {
      await _settingsRepository.save(
        SettingsKey.global,
        settings.copyWith(
          weeklyReviewEnabled: true,
          weeklyReviewDayOfWeek: nowLocal.weekday,
          weeklyReviewTimeMinutes: minutesOfDay,
          weeklyReviewLastCompletedAt: null,
          onboardingCompleted: true,
        ),
        context: context?.copyWith(
          intent: 'weekly_review.force_due',
          operation: 'settings.weekly_review.force_due',
        ),
      );
    } catch (e, st) {
      AppLog.handleStructured(
        'domain.template_data',
        'weekly review force due failed',
        e,
        st,
        _logFields(context, const {'step': 'weekly_review_force_due_failed'}),
      );
      rethrow;
    }
  }

  Map<String, Object?> _logFields(
    OperationContext? context, [
    Map<String, Object?> extra = const <String, Object?>{},
  ]) {
    return <String, Object?>{
      ...?context?.toLogFields(),
      ...extra,
    };
  }
}

const _templateRoutineSeeds = <_TemplateRoutineSeed>[
  _TemplateRoutineSeed(
    name: 'Text a friend',
    projectName: 'People',
    periodType: RoutinePeriodType.week,
    scheduleMode: RoutineScheduleMode.flexible,
    targetCount: 3,
    minSpacingDays: 0,
  ),
  _TemplateRoutineSeed(
    name: 'Study session',
    projectName: 'Learning',
    periodType: RoutinePeriodType.week,
    scheduleMode: RoutineScheduleMode.scheduled,
    targetCount: 1,
    scheduleDays: [6],
  ),
  _TemplateRoutineSeed(
    name: 'Budget review',
    projectName: 'Work',
    periodType: RoutinePeriodType.month,
    scheduleMode: RoutineScheduleMode.scheduled,
    targetCount: 2,
    scheduleMonthDays: [1, 15],
  ),
];

const _templateTaskSeeds = <_TemplateTaskSeed>[
  _TemplateTaskSeed(
    name: 'Read module 2',
    projectName: 'Learning',
    startOffset: 1,
    deadlineOffset: 3,
    priority: 3,
    valueNames: ['Learning'],
  ),
  _TemplateTaskSeed(
    name: 'Quiz prep',
    projectName: 'Learning',
    startOffset: -4,
    deadlineOffset: -1,
    priority: 2,
    valueNames: ['Learning'],
  ),
  _TemplateTaskSeed(
    name: 'Watch lesson 3',
    projectName: 'Learning',
    startOffset: 0,
    deadlineOffset: 1,
    priority: 3,
    valueNames: ['Learning'],
  ),
  _TemplateTaskSeed(
    name: 'Book checkup',
    projectName: 'Self-care',
    startOffset: -3,
    deadlineOffset: -1,
    priority: 2,
    valueNames: ['Health'],
  ),
  _TemplateTaskSeed(
    name: 'Grocery list',
    projectName: 'Self-care',
    startOffset: 0,
    deadlineOffset: 1,
    priority: 3,
    valueNames: ['Health'],
  ),
  _TemplateTaskSeed(
    name: 'Morning walk',
    projectName: 'Self-care',
    repeatIcalRrule: 'FREQ=DAILY',
    priority: 4,
    valueNames: ['Health'],
    complete: true,
  ),
  _TemplateTaskSeed(
    name: 'Send status update',
    projectName: 'Work',
    startOffset: 0,
    deadlineOffset: 0,
    priority: 1,
    valueNames: ['Career'],
  ),
  _TemplateTaskSeed(
    name: 'Review PR comments',
    projectName: 'Work',
    startOffset: 1,
    deadlineOffset: 2,
    priority: 2,
    valueNames: ['Career'],
  ),
  _TemplateTaskSeed(
    name: 'Plan next week',
    projectName: 'Work',
    startOffset: 4,
    deadlineOffset: 8,
    priority: 3,
    valueNames: ['Career'],
  ),
  _TemplateTaskSeed(
    name: 'Call parent',
    projectName: 'People',
    startOffset: -1,
    deadlineOffset: 0,
    priority: 2,
    valueNames: ['Social'],
  ),
  _TemplateTaskSeed(
    name: 'Book dinner',
    projectName: 'People',
    startOffset: 1,
    deadlineOffset: 4,
    priority: 3,
    valueNames: ['Social'],
  ),
  _TemplateTaskSeed(
    name: 'RSVP to invite',
    projectName: 'People',
    startOffset: 0,
    deadlineOffset: 1,
    priority: 2,
    complete: true,
    valueNames: ['Social'],
  ),
];

@immutable
final class _TemplateRoutineSeed {
  const _TemplateRoutineSeed({
    required this.name,
    required this.projectName,
    required this.periodType,
    required this.scheduleMode,
    required this.targetCount,
    this.scheduleDays = const <int>[],
    this.scheduleMonthDays = const <int>[],
    this.minSpacingDays,
  });

  final String name;
  final String projectName;
  final RoutinePeriodType periodType;
  final RoutineScheduleMode scheduleMode;
  final int targetCount;
  final List<int> scheduleDays;
  final List<int> scheduleMonthDays;
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
    this.complete = false,
    this.repeatIcalRrule,
  });

  final String name;
  final String projectName;
  final int? startOffset;
  final int? deadlineOffset;
  final int? priority;
  final List<String>? valueNames;
  final bool complete;
  final String? repeatIcalRrule;
}
