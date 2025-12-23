// Test to verify the exact flow of save operation and equality check

import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/settings/bloc/settings_bloc.dart';

void main() {
  group('Settings save equality verification', () {
    late AppDatabase database;
    late SettingsRepository settingsRepository;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      settingsRepository = SettingsRepository(driftDb: database);
    });

    tearDown(() async {
      await database.close();
    });

    test('saved settings equal the settings passed to save', () async {
      // Load initial (creates default entry)
      await settingsRepository.loadAll();

      // Create the exact settings that the UI would create
      final normalizedBuckets = List.generate(
        NextActionsSettings.defaultBucketRules.length,
        (index) => NextActionsSettings.defaultBucketRules[index].copyWith(
          priority: index + 1,
        ),
      );

      final updatedSettings = NextActionsSettings(
        tasksPerProject: 5,
        includeInboxTasks: true,
        bucketRules: normalizedBuckets,
      );

      final appSettings = const AppSettings().updateNextActions(
        updatedSettings,
      );

      // Save
      await settingsRepository.saveNextActionsSettings(updatedSettings);

      // Load and verify equality
      final loaded = await settingsRepository.loadAll();

      print('Saved includeInboxTasks: ${updatedSettings.includeInboxTasks}');
      print(
        'Loaded includeInboxTasks: ${loaded.nextActions.includeInboxTasks}',
      );
      print('Are equal: ${loaded.nextActions == updatedSettings}');
      print(
        'bucketRules lengths: saved=${updatedSettings.bucketRules.length}, loaded=${loaded.nextActions.bucketRules.length}',
      );

      expect(loaded.nextActions.includeInboxTasks, isTrue);
      expect(loaded.nextActions.tasksPerProject, equals(5));
      expect(
        loaded.nextActions == updatedSettings,
        isTrue,
        reason: 'Loaded settings should equal saved settings',
      );
    });

    test('SettingsBloc stream emits state matching saved settings', () async {
      await settingsRepository.loadAll();

      final bloc = SettingsBloc(settingsRepository: settingsRepository);
      bloc.add(const SettingsSubscriptionRequested());

      await bloc.stream.firstWhere((s) => s.status == SettingsStatus.loaded);

      // Create settings like the UI would
      final normalizedBuckets = List.generate(
        NextActionsSettings.defaultBucketRules.length,
        (index) => NextActionsSettings.defaultBucketRules[index].copyWith(
          priority: index + 1,
        ),
      );

      final updatedSettings = NextActionsSettings(
        tasksPerProject: 5,
        includeInboxTasks: true,
        bucketRules: normalizedBuckets,
      );

      // Dispatch update
      bloc.add(SettingsUpdateNextActions(settings: updatedSettings));

      // Wait for state with matching settings
      final completer = Completer<bool>();
      final sub = bloc.stream.listen((state) {
        if (state.settings?.nextActions == updatedSettings) {
          if (!completer.isCompleted) completer.complete(true);
        }
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print(
            'Current state includeInbox: ${bloc.state.settings?.nextActions.includeInboxTasks}',
          );
          print('Expected: ${updatedSettings.includeInboxTasks}');
          print(
            'Are equal: ${bloc.state.settings?.nextActions == updatedSettings}',
          );
          return false;
        },
      );

      await sub.cancel();
      await bloc.close();

      expect(
        result,
        isTrue,
        reason: 'Bloc stream should emit state matching saved settings',
      );
    });

    test('JSON roundtrip preserves NextActionsSettings equality', () {
      final original = NextActionsSettings(
        tasksPerProject: 5,
        includeInboxTasks: true,
        bucketRules: NextActionsSettings.defaultBucketRules,
      );

      // Simulate JSON encoding/decoding (what the repository does)
      final json = original.toJson();
      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = NextActionsSettings.fromJson(decoded);

      print('Original bucketRules count: ${original.bucketRules.length}');
      print('Restored bucketRules count: ${restored.bucketRules.length}');
      print(
        'bucketRules equal: ${original.bucketRules.length == restored.bucketRules.length}',
      );

      // Check each bucket rule
      for (var i = 0; i < original.bucketRules.length; i++) {
        final origRule = original.bucketRules[i];
        final restoredRule = restored.bucketRules[i];
        print('Rule $i equal: ${origRule == restoredRule}');
        if (origRule != restoredRule) {
          print('  Original: ${origRule.toJson()}');
          print('  Restored: ${restoredRule.toJson()}');
        }
      }

      expect(restored.includeInboxTasks, equals(original.includeInboxTasks));
      expect(restored.tasksPerProject, equals(original.tasksPerProject));
      expect(
        restored == original,
        isTrue,
        reason: 'JSON roundtrip should preserve equality',
      );
    });
  });
}
