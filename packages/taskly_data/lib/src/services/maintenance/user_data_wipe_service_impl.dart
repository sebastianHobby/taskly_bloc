import 'dart:async';

import 'package:powersync/powersync.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

final class PowerSyncUserDataWipeService implements UserDataWipeService {
  PowerSyncUserDataWipeService({
    required AppDatabase driftDb,
    required PowerSyncDatabase syncDb,
    Clock clock = systemClock,
  }) : _driftDb = driftDb,
       _syncDb = syncDb,
       _clock = clock;

  final AppDatabase _driftDb;
  final PowerSyncDatabase _syncDb;
  final Clock _clock;

  static const Duration _defaultTimeout = Duration(seconds: 20);
  static const Duration _pollInterval = Duration(milliseconds: 350);

  @override
  Future<void> wipeAllUserData({Duration timeout = _defaultTimeout}) async {
    if (!_syncDb.connected) {
      throw StateError('PowerSync is not connected; cannot upload deletions.');
    }

    await _driftDb.transaction(() async {
      // Attention system (children -> parent).
      await _deleteAll('attention_rule_runtime_state');
      await _deleteAll('attention_resolutions');
      await _deleteAll('attention_rules');

      // Notifications.
      await _deleteAll('pending_notifications');

      // Analytics.
      await _deleteAll('analytics_correlations');
      await _deleteAll('analytics_insights');
      await _deleteAll('analytics_snapshots');

      // Tracker data (children -> parents).
      await _deleteAll('tracker_state_entry');
      await _deleteAll('tracker_state_day');
      await _deleteAll('tracker_events');
      await _deleteAll('tracker_definition_choices');
      await _deleteAll('tracker_preferences');
      await _deleteAll('tracker_definitions');
      await _deleteAll('tracker_groups');

      // Journal.
      await _deleteAll('journal_entries');

      // Task/project history and exceptions.
      await _deleteAll('task_completion_history');
      await _deleteAll('task_snooze_events');
      await _deleteAll('task_recurrence_exceptions');
      await _deleteAll('project_completion_history');
      await _deleteAll('project_recurrence_exceptions');

      // Project helpers.
      await _deleteAll('project_anchor_state');

      // Routine history.
      await _deleteAll('routine_completions');
      await _deleteAll('routine_skips');

      // My Day.
      await _deleteAll('my_day_decision_events');
      await _deleteAll('my_day_picks');
      await _deleteAll('my_day_days');

      // Core entities.
      await _deleteAll('routines');
      await _deleteAll('value_ratings_weekly');
      await _deleteAll('tasks');
      await _deleteAll('projects');
      await _deleteAll('values');

      // User settings/profile.
      await _deleteAll('user_profiles');
    });

    await _waitForUploadQueue(timeout: timeout);
  }

  Future<void> _deleteAll(String table) {
    final escaped = table.replaceAll('"', '""');
    return _driftDb.customStatement('DELETE FROM "$escaped"');
  }

  Future<void> _waitForUploadQueue({required Duration timeout}) async {
    final deadline = _clock.nowUtc().add(timeout);

    while (true) {
      final stats = await _syncDb.getUploadQueueStats();
      if (stats.count == 0) return;

      if (_clock.nowUtc().isAfter(deadline)) {
        throw StateError(
          'Timed out waiting for PowerSync uploads (remaining ${stats.count}).',
        );
      }

      await Future<void>.delayed(_pollInterval);
    }
  }
}
