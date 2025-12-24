import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/adapters/next_actions_settings_adapter.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import '../helpers/test_db.dart';

void main() {
  group('JSON Format Verification', () {
    late AppDatabase testDb;
    late SettingsRepository repo;
    late NextActionsSettingsAdapter adapter;

    setUp(() {
      testDb = createTestDb();
      repo = SettingsRepository(driftDb: testDb);
      adapter = NextActionsSettingsAdapter(settingsRepository: repo);
    });

    tearDown(() async {
      await closeTestDb(testDb);
    });

    test('includeInboxTasks serializes correctly to JSON', () async {
      // Save settings with includeInboxTasks = true
      const settings = NextActionsSettings(
        tasksPerProject: 5,
        includeInboxTasks: true,
      );
      await adapter.save(settings);

      // Query database directly to get raw JSON
      final profiles = await testDb.select(testDb.userProfileTable).get();
      expect(profiles, isNotEmpty, reason: 'Database should have profile row');

      final rawJson = profiles.first.settings;
      print('Raw JSON from database: $rawJson');

      // Parse and verify JSON structure
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      print('Decoded JSON: $decoded');

      expect(decoded, containsPair('nextActions', isA<Map<String, dynamic>>()));

      final nextActionsJson = decoded['nextActions'] as Map<String, dynamic>;
      print('NextActions JSON: $nextActionsJson');

      expect(
        nextActionsJson,
        containsPair('includeInboxTasks', true),
        reason: 'includeInboxTasks should be true in JSON',
      );
      expect(
        nextActionsJson,
        containsPair('tasksPerProject', 5),
        reason: 'tasksPerProject should be 5 in JSON',
      );
    });

    test('includeInboxTasks deserializes correctly from JSON', () async {
      // Create JSON manually with includeInboxTasks = true
      final jsonString = jsonEncode({
        'pageSortPreferences': <String, dynamic>{},
        'nextActions': {
          'tasksPerProject': 5,
          'includeInboxTasks': true,
          'bucketRules': <Map<String, dynamic>>[],
          'sortPreferences': {
            'criteria': <Map<String, dynamic>>[],
          },
        },
      });

      print('Manual JSON: $jsonString');

      // Insert directly into database
      await testDb
          .into(testDb.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settings: jsonString,
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // Load via adapter
      final loaded = await adapter.load();
      print('Loaded settings: includeInboxTasks=${loaded.includeInboxTasks}');

      expect(
        loaded.includeInboxTasks,
        true,
        reason: 'includeInboxTasks should be true after deserialization',
      );
      expect(loaded.tasksPerProject, 5);
    });

    test('Round-trip: save with true, load back, verify true', () async {
      // Step 1: Save with includeInboxTasks = true
      const original = NextActionsSettings(
        tasksPerProject: 3,
        includeInboxTasks: true,
      );
      await adapter.save(original);
      print('Saved: includeInboxTasks=${original.includeInboxTasks}');

      // Step 2: Verify raw JSON in database
      final profiles = await testDb.select(testDb.userProfileTable).get();
      final rawJson = profiles.first.settings;
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final nextActions = decoded['nextActions'] as Map<String, dynamic>;

      print('JSON includeInboxTasks: ${nextActions['includeInboxTasks']}');
      expect(nextActions['includeInboxTasks'], true);

      // Step 3: Load back via adapter
      final loaded = await adapter.load();
      print('Loaded: includeInboxTasks=${loaded.includeInboxTasks}');

      expect(
        loaded.includeInboxTasks,
        true,
        reason: 'Round-trip should preserve includeInboxTasks=true',
      );
    });

    test('Default value: includeInboxTasks defaults to false', () async {
      // Save with default constructor (includeInboxTasks should be false)
      const settings = NextActionsSettings(
        tasksPerProject: 5,
      );
      await adapter.save(settings);

      // Verify JSON
      final profiles = await testDb.select(testDb.userProfileTable).get();
      final rawJson = profiles.first.settings;
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final nextActions = decoded['nextActions'] as Map<String, dynamic>;

      expect(
        nextActions['includeInboxTasks'],
        false,
        reason: 'Default should be false',
      );

      // Verify loaded value
      final loaded = await adapter.load();
      expect(loaded.includeInboxTasks, false);
    });

    test('Update from false to true preserves other fields', () async {
      // Step 1: Save with includeInboxTasks = false
      const initial = NextActionsSettings(
        tasksPerProject: 10,
      );
      await adapter.save(initial);

      // Step 2: Update to includeInboxTasks = true, keep tasksPerProject
      const updated = NextActionsSettings(
        tasksPerProject: 10,
        includeInboxTasks: true,
      );
      await adapter.save(updated);

      // Step 3: Verify both fields in JSON
      final profiles = await testDb.select(testDb.userProfileTable).get();
      final rawJson = profiles.first.settings;
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final nextActions = decoded['nextActions'] as Map<String, dynamic>;

      print('After update JSON: $nextActions');

      expect(nextActions['includeInboxTasks'], true);
      expect(nextActions['tasksPerProject'], 10);

      // Step 4: Verify loaded values
      final loaded = await adapter.load();
      expect(loaded.includeInboxTasks, true);
      expect(loaded.tasksPerProject, 10);
    });
  });
}
