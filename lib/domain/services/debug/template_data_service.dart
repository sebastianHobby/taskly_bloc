import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

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
/// Uses a small keyword-based mapper first for “suitable” icons, then falls
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
    required ValueRepositoryContract valueRepository,
    required SettingsRepositoryContract settingsRepository,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;

  /// Deletes all user Tasks/Projects/Values and recreates template demo data.
  ///
  /// Only callable in debug mode.
  Future<void> resetAndSeed() async {
    if (!kDebugMode) {
      throw StateError('TemplateDataService is debug-only.');
    }

    // 1) Wipe existing entity data.
    // Allocation snapshots are snapshot-first for My Day; clearing them ensures
    // the allocator produces a fresh snapshot for the new demo dataset.
    await _allocationSnapshotRepository.deleteAll();

    // Delete tasks first to avoid FK/join constraints.
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    for (final task in tasks) {
      await _taskRepository.delete(task.id);
    }

    final projects = await _projectRepository.getAll(ProjectQuery.all());
    for (final project in projects) {
      await _projectRepository.delete(project.id);
    }

    final values = await _valueRepository.getAll();
    for (final value in values) {
      await _valueRepository.delete(value.id);
    }

    // 2) Seed allocation settings for the demo.
    const focusMode = FocusMode.sustainable;
    await _settingsRepository.save(
      SettingsKey.allocation,
      AllocationConfig(
        dailyLimit: 10,
        focusMode: focusMode,
        strategySettings: StrategySettings.forFocusMode(focusMode),
      ),
    );

    // 3) Create Values (must exist or allocation soft-gates).
    const seeds = <_TemplateValueSeed>[
      _TemplateValueSeed(
        name: 'Life Admin',
        color: '#455A64',
        priority: ValuePriority.high,
        iconName: 'checklist',
      ),
      _TemplateValueSeed(
        name: 'Home & Comfort',
        color: '#FB8C00',
        priority: ValuePriority.medium,
        iconName: 'home',
      ),
      _TemplateValueSeed(
        name: 'Relationships',
        color: '#E91E63',
        priority: ValuePriority.medium,
        iconName: 'group',
      ),
      _TemplateValueSeed(
        name: 'Health & Energy',
        color: '#43A047',
        priority: ValuePriority.high,
        iconName: 'health',
      ),
      _TemplateValueSeed(
        name: 'Learning & Curiosity',
        color: '#1E88E5',
        priority: ValuePriority.low,
        iconName: 'lightbulb',
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

    // 4) Create Projects (linked to values via valueIds; first value is primary).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime day(int offset) => today.add(Duration(days: offset));

    await _projectRepository.create(
      name: 'Get a passport',
      description: 'Everything needed to renew/apply',
      priority: 1,
      startDate: day(-14),
      deadlineDate: day(21),
      valueIds: [
        valueIdByName['Life Admin']!,
        valueIdByName['Relationships']!,
      ],
    );
    await _projectRepository.create(
      name: 'Home chores',
      description: 'Household admin + weekly chores',
      priority: 2,
      startDate: day(-30),
      deadlineDate: day(60),
      valueIds: [
        valueIdByName['Home & Comfort']!,
        valueIdByName['Life Admin']!,
      ],
    );
    await _projectRepository.create(
      name: 'Organise birthday for Sam',
      description: 'Plan, invite, gifts, and schedule',
      priority: 2,
      startDate: day(-10),
      deadlineDate: day(10),
      valueIds: [
        valueIdByName['Relationships']!,
        valueIdByName['Home & Comfort']!,
      ],
    );
    await _projectRepository.create(
      name: 'Exercise Routines',
      description: 'Recurring training and mobility habits',
      priority: 2,
      startDate: day(-21),
      deadlineDate: day(90),
      valueIds: [
        valueIdByName['Health & Energy']!,
        valueIdByName['Learning & Curiosity']!,
      ],
    );
    await _projectRepository.create(
      name: 'Learn capital city names',
      description: 'Flashcards and weekly quizzes',
      priority: 3,
      startDate: day(-5),
      deadlineDate: day(45),
      valueIds: [
        valueIdByName['Learning & Curiosity']!,
        valueIdByName['Health & Energy']!,
      ],
    );

    final projectIdByName = await _loadProjectIdByName();

    // 5) Create Tasks.
    // Most tasks inherit their effective values from their project.
    // Only a few tasks explicitly override project values to demo that behavior.

    final pinnedTaskNames = <String>[];

    // --- Get a passport (2 scheduled, 2 someday)
    await _taskRepository.create(
      name: 'Book passport photo',
      projectId: projectIdByName['Get a passport'],
      priority: 2,
      startDate: day(-1),
      deadlineDate: day(2),
    );
    pinnedTaskNames.add('Book passport photo');

    await _taskRepository.create(
      name: 'Submit application',
      projectId: projectIdByName['Get a passport'],
      priority: 1,
      startDate: day(9),
      deadlineDate: day(12),
    );
    pinnedTaskNames.add('Submit application');

    await _taskRepository.create(
      name: 'Check renewal requirements',
      projectId: projectIdByName['Get a passport'],
      priority: 3,
    );

    await _taskRepository.create(
      name: 'Make a documents checklist',
      projectId: projectIdByName['Get a passport'],
      priority: 4,
    );

    // --- Home chores
    await _taskRepository.create(
      name: 'Laundry + bedding',
      projectId: projectIdByName['Home chores'],
      priority: 3,
      startDate: day(-7),
      deadlineDate: day(-1),
      // Explicit override (not inherited from project).
      valueIds: [valueIdByName['Health & Energy']!],
    );
    pinnedTaskNames.add('Laundry + bedding');

    await _taskRepository.create(
      name: 'Deep clean kitchen',
      projectId: projectIdByName['Home chores'],
      priority: 2,
      startDate: day(14),
      deadlineDate: day(16),
    );
    pinnedTaskNames.add('Deep clean kitchen');

    await _taskRepository.create(
      name: 'Declutter “misc” drawer',
      projectId: projectIdByName['Home chores'],
      priority: 4,
    );

    await _taskRepository.create(
      name: 'Organize cleaning supplies',
      projectId: projectIdByName['Home chores'],
      priority: 3,
    );

    // --- Organise birthday for Sam
    await _taskRepository.create(
      name: 'Book dinner reservation',
      projectId: projectIdByName['Organise birthday for Sam'],
      priority: 2,
      startDate: day(2),
      deadlineDate: day(5),
    );
    pinnedTaskNames.add('Book dinner reservation');

    await _taskRepository.create(
      name: 'Buy birthday gift for Sam',
      projectId: projectIdByName['Organise birthday for Sam'],
      priority: 1,
      startDate: day(-5),
      deadlineDate: day(3),
      // Explicit override (not inherited from project).
      valueIds: [valueIdByName['Life Admin']!],
    );
    pinnedTaskNames.add('Buy birthday gift for Sam');

    await _taskRepository.create(
      name: 'Draft invite message',
      projectId: projectIdByName['Organise birthday for Sam'],
      priority: 3,
    );

    await _taskRepository.create(
      name: 'Ideas list: gift + activities',
      projectId: projectIdByName['Organise birthday for Sam'],
      priority: 4,
    );

    // --- Exercise Routines
    await _taskRepository.create(
      name: 'Plan workouts for next week',
      projectId: projectIdByName['Exercise Routines'],
      priority: 2,
      startDate: day(1),
      deadlineDate: day(4),
    );
    pinnedTaskNames.add('Plan workouts for next week');

    await _taskRepository.create(
      name: 'Buy resistance bands',
      projectId: projectIdByName['Exercise Routines'],
      priority: 3,
      startDate: day(20),
      deadlineDate: day(25),
      // Explicit override (not inherited from project).
      valueIds: [valueIdByName['Home & Comfort']!],
    );
    pinnedTaskNames.add('Buy resistance bands');

    await _taskRepository.create(
      name: 'Create a warm-up checklist',
      projectId: projectIdByName['Exercise Routines'],
      priority: 4,
    );

    await _taskRepository.create(
      name: 'Research a beginner mobility routine',
      projectId: projectIdByName['Exercise Routines'],
      priority: 3,
    );

    // --- Learn capital city names
    await _taskRepository.create(
      name: 'Europe capitals: set 1 (15)',
      projectId: projectIdByName['Learn capital city names'],
      priority: 3,
      startDate: day(4),
      deadlineDate: day(6),
    );
    pinnedTaskNames.add('Europe capitals: set 1 (15)');

    await _taskRepository.create(
      name: 'Africa capitals: set 1 (12)',
      projectId: projectIdByName['Learn capital city names'],
      priority: 3,
      startDate: day(35),
      deadlineDate: day(40),
    );
    pinnedTaskNames.add('Africa capitals: set 1 (12)');

    await _taskRepository.create(
      name: 'Make flashcards format (template)',
      projectId: projectIdByName['Learn capital city names'],
      priority: 4,
    );

    await _taskRepository.create(
      name: 'List “hard ones” to revisit',
      projectId: projectIdByName['Learn capital city names'],
      priority: 4,
    );

    // 6) Pin only one task total to keep the demo focused.
    await _pinTasksByName(pinnedTaskNames.take(1).toList());
  }

  Future<Map<String, String>> _loadValueIdByName() async {
    final values = await _valueRepository.getAll();
    return {
      for (final v in values) v.name: v.id,
    };
  }

  Future<Map<String, String>> _loadProjectIdByName() async {
    final projects = await _projectRepository.getAll(ProjectQuery.all());
    return {
      for (final p in projects) p.name: p.id,
    };
  }

  Future<void> _pinTasksByName(List<String> names) async {
    final tasks = await _taskRepository.getAll(TaskQuery.all());
    final idByName = <String, String>{
      for (final t in tasks) t.name: t.id,
    };

    for (final name in names) {
      final id = idByName[name];
      if (id == null) continue;
      await _taskRepository.setPinned(id: id, isPinned: true);
    }
  }
}
