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

  test('load returns default settings when no row exists', () async {
    final result = await repository.load();

    expect(result, const AppSettings());

    final rows = await db.select(db.userProfileTable).get();
    expect(rows, hasLength(1));
    expect(rows.first.userId, isNull);
  });

  test('save then load returns persisted settings', () async {
    const saved = AppSettings(
      pageSortPreferences: {
        SettingsPageKey.inbox: SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        ),
      },
    );

    await repository.save(saved);

    final loaded = await repository.load();

    expect(loaded, saved);

    final rows = await db.select(db.userProfileTable).get();
    expect(rows, hasLength(1));
    expect(rows.first.userId, isNull);
  });

  test('watch emits default then updated when settings change', () async {
    const updated = AppSettings(
      pageSortPreferences: {
        SettingsPageKey.today: SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
        ),
      },
    );

    final expectation = expectLater(
      repository.watch(),
      emitsInOrder(<AppSettings>[const AppSettings(), updated]),
    );

    await repository.save(updated);

    await expectation;
  });

  test('persists next actions settings', () async {
    const updated = AppSettings(
      nextActions: NextActionsSettings(
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
      ),
    );

    await repository.save(updated);

    final loaded = await repository.load();

    expect(loaded.nextActions.tasksPerProject, 5);
    expect(loaded.nextActions.bucketRules, updated.nextActions.bucketRules);
  });

  test('load falls back to default when JSON is invalid', () async {
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

    final result = await repository.load();

    expect(result, const AppSettings());
  });
}
