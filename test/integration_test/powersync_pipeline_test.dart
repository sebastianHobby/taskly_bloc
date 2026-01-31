@Tags(['pipeline'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_imports.dart';
import 'package:taskly_bloc/bootstrap/local_dev_host.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_data/data_stack.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_domain/taskly_domain.dart';

const _localAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.'
    'CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
const _zeroUuid = '00000000-0000-0000-0000-000000000000';
const _pipelineTestTimeout = Duration(minutes: 2);
const _initialSyncTimeout = Duration(seconds: 90);
const _remoteSyncTimeout = Duration(seconds: 25);
const _remotePollInterval = Duration(milliseconds: 350);

void main() {
  setUpAll(setUpAllIntegrationTestEnvironment);

  late TasklyDataStack stack;
  late TasklyDataBindings bindings;
  late SupabaseClient supabase;
  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    Env.resetForTest();
    final host = localDevHost();
    Env.config = EnvConfig(
      name: 'local',
      supabaseUrl: 'http://$host:54321',
      supabasePublishableKey: _localAnonKey,
      powersyncUrl: 'http://$host:8080',
    );
    await Env.load();

    tempDir = await Directory.systemTemp.createTemp('taskly_pipeline_');
    final dbPath = p.join(tempDir.path, 'powersync.db');

    stack = await TasklyDataStack.initialize(
      powersyncPathOverride: dbPath,
    );
    supabase = Supabase.instance.client;

    final email =
        'pipeline_${DateTime.now().millisecondsSinceEpoch}@taskly.test';
    const password = 'Passw0rd!local';
    await _ensureSignedIn(supabase, email, password);

    bindings = stack.createBindings();
  });

  setUp(() async {
    await stack.stopSession(reason: 'test reset', clearLocalData: false);
    await _clearRemoteData(supabase);
    await _clearLocalData(bindings.driftDb);
  });

  tearDownAll(() async {
    await stack.stopSession(reason: 'test teardown', clearLocalData: false);
    await stack.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await supabase.auth.signOut();
    await _deleteTempDir(tempDir);
  });

  testSafe(
    'signs in and starts the PowerSync session',
    timeout: _pipelineTestTimeout,
    () async {
      await _startSessionAndWaitForSync(stack, bindings);

      final status = await stack.syncDb.statusStream.firstWhere(
        (s) => s.connected == true,
      );
      expect(status.connected, isTrue);
    },
  );

  testSafe(
    'uploads offline task after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final repo = bindings.taskRepository;

      await repo.create(name: 'Offline Task', completed: false);
      final created = await repo.getAll();
      expect(created, isNotEmpty);

      final taskId = created.single.id;

      await _startSessionAndWaitForSync(stack, bindings);

      final remote = await _waitForRemoteTask(supabase, taskId);
      expect(remote['name'], 'Offline Task');
    },
  );

  testSafe(
    'downloads remote updates into local database',
    timeout: _pipelineTestTimeout,
    () async {
      await _startSessionAndWaitForSync(stack, bindings);

      final repo = bindings.taskRepository;
      await repo.create(name: 'Local Task', completed: false);
      final created = await repo.getAll();
      final taskId = created.single.id;

      await _waitForRemoteTask(supabase, taskId);

      await supabase
          .from('tasks')
          .update({'name': 'Remote Rename'})
          .eq('id', taskId);

      final updated = await repo
          .watchById(taskId)
          .firstWhere((task) => task?.name == 'Remote Rename');

      expect(updated?.name, 'Remote Rename');
    },
  );

  testSafe(
    'uploads offline project after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final repo = bindings.projectRepository;

      await repo.create(name: 'Offline Project');
      final created = await repo.getAll();
      expect(created, isNotEmpty);

      final projectId = created.single.id;

      await _startSessionAndWaitForSync(stack, bindings);

      final remote = await _waitForRemoteProject(supabase, projectId);
      expect(remote['name'], 'Offline Project');
    },
  );

  testSafe(
    'downloads remote project updates into local database',
    timeout: _pipelineTestTimeout,
    () async {
      await _startSessionAndWaitForSync(stack, bindings);

      final repo = bindings.projectRepository;
      await repo.create(name: 'Local Project');
      final created = await repo.getAll();
      final projectId = created.single.id;

      await _waitForRemoteProject(supabase, projectId);

      await supabase
          .from('projects')
          .update({'name': 'Remote Project Rename'})
          .eq('id', projectId);

      final updated = await repo
          .watchById(projectId)
          .firstWhere((project) => project?.name == 'Remote Project Rename');

      expect(updated?.name, 'Remote Project Rename');
    },
  );

  testSafe(
    'uploads offline value after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final repo = bindings.valueRepository;

      await repo.create(name: 'Offline Value', color: '#123456');
      final created = await repo.getAll();
      expect(created, isNotEmpty);

      final valueId = created.single.id;

      await _startSessionAndWaitForSync(stack, bindings);

      final remote = await _waitForRemoteValue(supabase, valueId);
      expect(remote['name'], 'Offline Value');
    },
  );

  testSafe(
    'uploads offline routine after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final values = bindings.valueRepository;
      final routines = bindings.routineRepository;

      await values.create(name: 'Health', color: '#00CC66');
      final valueId = (await values.getAll()).single.id;

      await routines.create(
        name: 'Morning walk',
        valueId: valueId,
        routineType: RoutineType.weeklyFixed,
        targetCount: 3,
        scheduleDays: const [1, 3, 5],
      );

      final routineId = (await routines.getAll(
        includeInactive: true,
      )).single.id;

      await _startSessionAndWaitForSync(stack, bindings);

      final remote = await _waitForRemoteRoutine(supabase, routineId);
      expect(remote['name'], 'Morning walk');
    },
  );

  testSafe(
    'downloads remote routine updates into local database',
    timeout: _pipelineTestTimeout,
    () async {
      final values = bindings.valueRepository;
      final routines = bindings.routineRepository;

      await values.create(name: 'Work', color: '#3366FF');
      final valueId = (await values.getAll()).single.id;

      await routines.create(
        name: 'Focus time',
        valueId: valueId,
        routineType: RoutineType.weeklyFixed,
        targetCount: 2,
        scheduleDays: const [2, 4],
      );

      final routineId = (await routines.getAll(
        includeInactive: true,
      )).single.id;

      await _startSessionAndWaitForSync(stack, bindings);

      await _waitForRemoteRoutine(supabase, routineId);

      await supabase
          .from('routines')
          .update({'name': 'Remote Routine Rename'})
          .eq('id', routineId);

      final updated = await routines
          .watchById(routineId)
          .firstWhere((routine) => routine?.name == 'Remote Routine Rename');

      expect(updated?.name, 'Remote Routine Rename');
    },
  );

  testSafe(
    'uploads offline journal entry after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final journal = bindings.journalRepository;

      final now = DateTime.utc(2025, 1, 15, 12);
      final entry = JournalEntry(
        id: '',
        entryDate: dateOnly(now),
        entryTime: now,
        occurredAt: now,
        localDate: dateOnly(now),
        createdAt: now,
        updatedAt: now,
        journalText: 'Pipeline entry',
        deletedAt: null,
      );

      final entryId = await journal.upsertJournalEntry(entry);

      await _startSessionAndWaitForSync(stack, bindings);

      final remote = await _waitForRemoteJournalEntry(supabase, entryId);
      expect(remote['journal_text'], 'Pipeline entry');
    },
  );

  testSafe(
    'uploads global settings overrides after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final settings = bindings.settingsRepository;

      const updated = GlobalSettings(
        maintenanceEnabled: false,
        maintenanceDeadlineRiskEnabled: false,
        maintenanceTaskStaleThresholdDays: 10,
        maintenanceProjectIdleThresholdDays: 20,
      );

      await settings.save(SettingsKey.global, updated);

      await _startSessionAndWaitForSync(stack, bindings);

      final overrides = await _waitForRemoteSettingsOverrides(supabase);
      final global = overrides['global'] as Map<String, dynamic>?;
      expect(global, isNotNull);
      expect(global?['maintenanceEnabled'], isFalse);
      expect(global?['maintenanceTaskStaleThresholdDays'], 10);
    },
  );

  testSafe(
    'uploads task recurrence exception after reconnect',
    timeout: _pipelineTestTimeout,
    () async {
      final tasks = bindings.taskRepository;

      await tasks.create(
        name: 'Recurring Task',
        completed: false,
        repeatIcalRrule: 'FREQ=DAILY',
        repeatFromCompletion: true,
      );

      final taskId = (await tasks.getAll()).single.id;
      final originalDate = DateTime.utc(2025, 1, 10);

      await tasks.skipOccurrence(
        taskId: taskId,
        originalDate: originalDate,
      );

      await _startSessionAndWaitForSync(stack, bindings);

      final remote = await _waitForRemoteTaskException(supabase, taskId);
      expect(remote['exception_type'], 'skip');
    },
  );
}

Future<void> _startSessionAndWaitForSync(
  TasklyDataStack stack,
  TasklyDataBindings bindings,
) async {
  await stack.startSession();
  await bindings.initialSyncService.waitForFirstSync().timeout(
    _initialSyncTimeout,
    onTimeout: () {
      throw TimeoutException(
        'Timed out waiting for the initial PowerSync sync checkpoint.',
      );
    },
  );
}

Future<void> _ensureSignedIn(
  SupabaseClient client,
  String email,
  String password,
) async {
  try {
    final signIn = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (signIn.session != null) return;
  } on AuthException {
    // Fall through to sign-up.
  }

  await client.auth.signUp(email: email, password: password);
  final signIn = await client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  if (signIn.session == null) {
    throw StateError('Supabase sign-in failed for pipeline tests.');
  }
}

Future<void> _clearRemoteData(SupabaseClient client) async {
  await client.from('task_recurrence_exceptions').delete().neq('id', _zeroUuid);
  await client
      .from('project_recurrence_exceptions')
      .delete()
      .neq('id', _zeroUuid);
  await client.from('routine_completions').delete().neq('id', _zeroUuid);
  await client.from('routine_skips').delete().neq('id', _zeroUuid);
  await client.from('routines').delete().neq('id', _zeroUuid);
  await client.from('tasks').delete().neq('id', _zeroUuid);
  await client.from('projects').delete().neq('id', _zeroUuid);
  await client.from('values').delete().neq('id', _zeroUuid);
  await client.from('journal_entries').delete().neq('id', _zeroUuid);
}

Future<void> _clearLocalData(AppDatabase db) async {
  await db.customUpdate('DELETE FROM tasks');
  await db.customUpdate('DELETE FROM projects');
  await db.customUpdate('DELETE FROM "values"');
  await db.customUpdate('DELETE FROM task_recurrence_exceptions');
  await db.customUpdate('DELETE FROM project_recurrence_exceptions');
  await db.customUpdate('DELETE FROM routines');
  await db.customUpdate('DELETE FROM routine_completions');
  await db.customUpdate('DELETE FROM routine_skips');
  await db.customUpdate('DELETE FROM journal_entries');
}

Future<Map<String, dynamic>> _waitForRemoteTask(
  SupabaseClient client,
  String taskId,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('tasks')
        .select('id, name')
        .eq('id', taskId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException('Timed out waiting for task $taskId to sync.');
}

Future<Map<String, dynamic>> _waitForRemoteProject(
  SupabaseClient client,
  String projectId,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('projects')
        .select('id, name')
        .eq('id', projectId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException('Timed out waiting for project $projectId to sync.');
}

Future<Map<String, dynamic>> _waitForRemoteValue(
  SupabaseClient client,
  String valueId,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('values')
        .select('id, name')
        .eq('id', valueId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException('Timed out waiting for value $valueId to sync.');
}

Future<Map<String, dynamic>> _waitForRemoteRoutine(
  SupabaseClient client,
  String routineId,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('routines')
        .select('id, name')
        .eq('id', routineId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException('Timed out waiting for routine $routineId to sync.');
}

Future<Map<String, dynamic>> _waitForRemoteJournalEntry(
  SupabaseClient client,
  String entryId,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('journal_entries')
        .select('id, journal_text')
        .eq('id', entryId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException(
    'Timed out waiting for journal entry $entryId to sync.',
  );
}

Future<Map<String, dynamic>> _waitForRemoteTaskException(
  SupabaseClient client,
  String taskId,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('task_recurrence_exceptions')
        .select('id, task_id, exception_type')
        .eq('task_id', taskId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException(
    'Timed out waiting for task recurrence exception for $taskId to sync.',
  );
}

Future<Map<String, dynamic>> _waitForRemoteSettingsOverrides(
  SupabaseClient client,
) async {
  final deadline = DateTime.now().add(_remoteSyncTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('user_profiles')
        .select('id, settings_overrides')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      await Future<void>.delayed(_remotePollInterval);
      continue;
    }
    final overrides = row['settings_overrides'];
    if (overrides is Map<String, dynamic>) return overrides;
    if (overrides is String && overrides.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(overrides));
    }
    await Future<void>.delayed(_remotePollInterval);
  }
  throw TimeoutException('Timed out waiting for settings overrides to sync.');
}

final class TimeoutException implements Exception {
  TimeoutException(this.message);

  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}

Future<void> _deleteTempDir(Directory dir) async {
  const attempts = 10;
  for (var i = 0; i < attempts; i++) {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return;
    } on FileSystemException {
      if (i == attempts - 1) rethrow;
      final delayMs = 200 * (i + 1);
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}
