import 'package:flutter/foundation.dart';
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
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;

  /// Deletes all user Tasks/Projects/Values and recreates template demo data.
  ///
  /// Only callable in debug mode.
  Future<void> resetAndSeed() async {
    if (!kDebugMode) {
      throw StateError('TemplateDataService is debug-only.');
    }

    // 1) Wipe existing entity data.
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
    await _valueRepository.create(
      name: 'Life Admin',
      color: '#455A64',
      iconName: '🧾',
      priority: ValuePriority.high,
    );
    await _valueRepository.create(
      name: 'Home & Comfort',
      color: '#FB8C00',
      iconName: '🏠',
      priority: ValuePriority.medium,
    );
    await _valueRepository.create(
      name: 'Relationships',
      color: '#E91E63',
      iconName: '🎉',
      priority: ValuePriority.medium,
    );
    await _valueRepository.create(
      name: 'Health & Energy',
      color: '#43A047',
      iconName: '💪',
      priority: ValuePriority.high,
    );
    await _valueRepository.create(
      name: 'Learning & Curiosity',
      color: '#1E88E5',
      iconName: '📚',
      priority: ValuePriority.low,
    );

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

    // 6) Pin the two "Scheduled" tasks per project (10 total).
    await _pinTasksByName(pinnedTaskNames);
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
