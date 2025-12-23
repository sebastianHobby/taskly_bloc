import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = createTestDb();
    repository = SettingsRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('loadAll returns default settings when no row exists', () async {
    final result = await repository.loadAll();

    expect(result, const AppSettings());

    // Without cache, we don't auto-insert a row anymore
    final rows = await db.select(db.userProfileTable).get();
    expect(rows, isEmpty);
  });

  test('savePageSort then loadAll returns persisted settings', () async {
    const sortPrefs = SortPreferences(
      criteria: [SortCriterion(field: SortField.name)],
    );

    await repository.savePageSort(SettingsPageKey.inbox, sortPrefs);

    final loaded = await repository.loadAll();

    expect(loaded.sortFor(SettingsPageKey.inbox), sortPrefs);

    final rows = await db.select(db.userProfileTable).get();
    expect(rows, hasLength(1));
    expect(rows.first.userId, isNull);
  });

  test('watchAll emits updated settings when changed', () async {
    const sortPrefs = SortPreferences(
      criteria: [
        SortCriterion(field: SortField.deadlineDate),
        SortCriterion(field: SortField.name),
      ],
    );

    // Just verify that the stream eventually emits the saved settings
    final stream = repository.watchAll();

    await repository.savePageSort(SettingsPageKey.today, sortPrefs);

    // Wait for stream to emit the updated value
    final result = await stream.firstWhere(
      (settings) => settings.sortFor(SettingsPageKey.today) == sortPrefs,
    );

    expect(result.sortFor(SettingsPageKey.today), sortPrefs);
  });

  test('persists next actions settings', () async {
    const nextActionsSettings = NextActionsSettings(
      tasksPerProject: 5,
      bucketRules: [
        TaskPriorityBucketRule(
          priority: 1,
          name: 'Deadline Soon',
          ruleSets: [
            TaskRuleSet(
              operator: RuleSetOperator.and,

              rules: [
                DateRule(
                  field: DateRuleField.deadlineDate,
                  operator: DateRuleOperator.relative,
                  relativeComparison: RelativeComparison.before,
                  relativeDays: 7,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await repository.saveNextActionsSettings(nextActionsSettings);

    final loaded = await repository.loadAll();

    expect(loaded.nextActions.tasksPerProject, 5);
    expect(loaded.nextActions.bucketRules, nextActionsSettings.bucketRules);
  });

  test('loadAll falls back to default when JSON is invalid', () async {
    final now = DateTime.now();
    await db.customInsert(
      'INSERT INTO user_profiles (id, user_id, settings, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
      variables: <Variable<Object>>[
        const Variable<String>('profile-1'),
        const Variable<String>('test-user'),
        const Variable<String>('not json'),
        Variable<DateTime>(now),
        Variable<DateTime>(now),
      ],
      updates: {db.userProfileTable},
    );

    final result = await repository.loadAll();

    expect(result, const AppSettings());
  });
}
