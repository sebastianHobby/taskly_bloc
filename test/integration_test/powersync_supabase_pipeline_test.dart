/// PowerSync ⇄ Supabase local E2E pipeline tests.
///
/// These tests are meant to run against the local stack:
/// - Supabase started via `supabase start`
/// - PowerSync started via `tool/e2e/Start-LocalE2EStack.ps1`
///
/// Run (example):
/// `flutter test test/integration_test/powersync_supabase_pipeline_test.dart --dart-define-from-file=dart_defines.local.json --dart-define=RUN_POWERSYNC_SUPABASE_PIPELINE_TESTS=true`
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart' show Tags;
import 'package:taskly_bloc/app/di/dependency_injection.dart'
    show getIt, setupDependencies;
import 'package:taskly_bloc/app/env/env.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/powersync/api_connector.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/data/services/occurrence_stream_expander.dart';
import 'package:taskly_bloc/data/services/occurrence_write_helper.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/settings/settings.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:uuid/uuid.dart';

import 'e2e_test_helpers.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _powersyncUrl = String.fromEnvironment('POWERSYNC_URL');

bool _isLocalUrl(String url) {
  final trimmed = url.trim().toLowerCase();
  return trimmed.startsWith('http://127.0.0.1') ||
      trimmed.startsWith('http://localhost') ||
      trimmed.startsWith('https://127.0.0.1') ||
      trimmed.startsWith('https://localhost');
}

final bool _canRunAgainstLocalStack =
    _supabaseUrl.trim().isNotEmpty &&
    _supabaseAnonKey.trim().isNotEmpty &&
    _powersyncUrl.trim().isNotEmpty &&
    _isLocalUrl(_supabaseUrl) &&
    _isLocalUrl(_powersyncUrl);

@Tags(['integration', 'pipeline'])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late PowerSyncDatabase syncDb;
  late AppDatabase driftDb;
  late SupabaseClient client;
  String? userId;
  String? authEmail;
  String? authPassword;

  setUpAll(() async {
    initializeTalkerForTest();

    if (!_canRunAgainstLocalStack) {
      return;
    }

    await Env.load();
    Env.validateRequired();

    // Ensure we don't accidentally reuse a previous local DB file.
    await _deleteLocalPowerSyncDb();

    await getIt.reset();
    await setupDependencies();

    syncDb = getIt<PowerSyncDatabase>();
    driftDb = getIt<AppDatabase>();
    client = Supabase.instance.client;

    // Sign in (or sign up) and wait for PowerSync to connect.
    authEmail = 'e2e_${DateTime.now().millisecondsSinceEpoch}@example.com';
    authPassword = 'password123!';
    userId = await _ensureSignedIn(
      client,
      email: authEmail!,
      password: authPassword!,
    );
    await _waitForPowerSyncConnected(syncDb);
  });

  tearDownAll(() async {
    if (!_canRunAgainstLocalStack) {
      return;
    }

    // Best-effort cleanup.
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    try {
      await syncDb.disconnect();
    } catch (_) {}

    await getIt.reset();
  });

  group('PowerSync ⇄ Supabase local pipeline', () {
    testWidgetsE2E(
      'upload: Drift write -> PowerSync upload -> PostgREST row matches',
      (tester) async {
        final settings = getIt<SettingsRepositoryContract>();

        const desired = GlobalSettings(
          onboardingCompleted: true,
          textScaleFactor: 1.1,
        );

        await settings.save(SettingsKey.global, desired);

        await _waitForUploadCycle(syncDb, timeout: const Duration(seconds: 30));

        final localProfile = await _selectLatestProfile(driftDb);
        expect(localProfile, isNotNull);
        final profileId = localProfile!.id;

        // Wait for the row to exist and include our override.
        final serverRow = await _waitForServerUserProfile(
          client: client,
          id: profileId,
        );

        expect(serverRow['id'], profileId);
        expect(serverRow['user_id'], userId);

        final overrides = _coerceJsonObject(serverRow['settings_overrides']);
        final global = overrides['global'];
        expect(global, isA<Map<String, dynamic>>());
        expect(
          (global as Map<String, dynamic>)['onboardingCompleted'],
          true,
        );
        expect(
          global['textScaleFactor'],
          anyOf(1.1, closeTo(1.1, 0.0001)),
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'download: PostgREST update -> PowerSync download -> Drift reflects change',
      (tester) async {
        // Create a profile deterministically for this test run.
        // This avoids relying on ordering across tests.
        final settings = getIt<SettingsRepositoryContract>();
        const initial = GlobalSettings(
          onboardingCompleted: true,
          textScaleFactor: 1.1,
        );
        await settings.save(SettingsKey.global, initial);
        await _waitForUploadCycle(syncDb, timeout: const Duration(seconds: 30));

        final localProfile = await _selectLatestProfile(driftDb);
        expect(localProfile, isNotNull);
        final profileId = localProfile!.id;

        // Read current server overrides, then change a value.
        final before = await _waitForServerUserProfile(
          client: client,
          id: profileId,
        );
        final overrides = _coerceJsonObject(before['settings_overrides']);

        final global = <String, dynamic>{
          ...((overrides['global'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
          'onboardingCompleted': false,
          'textScaleFactor': 1.25,
        };

        final updated = <String, dynamic>{...overrides, 'global': global};

        await client.rest
            .from('user_profiles')
            .update({'settings_overrides': updated})
            .eq('id', profileId);

        // Wait until the local Drift view sees the updated settings.
        await _waitFor(
          () async {
            final local = await _selectLatestProfile(driftDb);
            if (local == null) return false;

            final localOverrides = _coerceJsonObject(local.settingsOverrides);
            final localGlobal = localOverrides['global'];
            if (localGlobal is! Map<String, dynamic>) return false;

            final onboarding = localGlobal['onboardingCompleted'];
            final scale = localGlobal['textScaleFactor'];

            return onboarding == false &&
                (scale == 1.25 ||
                    (scale is num && (scale - 1.25).abs() < 0.0001));
          },
          timeout: const Duration(seconds: 45),
          debugLabel: 'local Drift to reflect server update',
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'crud: values/projects/tasks (+ joins) sync via PostgREST',
      (tester) async {
        final valueRepo = getIt<ValueRepositoryContract>();
        final projectRepo = getIt<ProjectRepositoryContract>();
        final taskRepo = getIt<TaskRepositoryContract>();

        // Create two values (deterministic IDs).
        await valueRepo.create(
          name: 'Health',
          color: '#00FF00',
        );
        await valueRepo.create(
          name: 'Urgent',
          color: '#FF0000',
        );

        final health = await _selectValueByName(driftDb, 'Health');
        final urgent = await _selectValueByName(driftDb, 'Urgent');
        expect(health, isNotNull);
        expect(urgent, isNotNull);

        // Create a project referencing both values.
        await projectRepo.create(
          name: 'Project CRUD',
          valueIds: [health!.id, urgent!.id],
        );
        final project = await _selectProjectByName(driftDb, 'Project CRUD');
        expect(project, isNotNull);

        // Create a task referencing the project and one value.
        await taskRepo.create(
          name: 'Task CRUD',
          projectId: project!.id,
          valueIds: [urgent.id],
        );
        final task = await _selectTaskByName(driftDb, 'Task CRUD');
        expect(task, isNotNull);

        // Wait for server rows to exist.
        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: health.id,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: urgent.id,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'projects',
          id: project.id,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'tasks',
          id: task!.id,
        );

        // Join tables should exist too.
        final projectValueUrgentId = getIt<IdGenerator>().projectValueId(
          projectId: project.id,
          valueId: urgent.id,
        );
        final taskValueUrgentId = getIt<IdGenerator>().taskValueId(
          taskId: task.id,
          valueId: urgent.id,
        );

        await _waitForServerRowExists(
          client: client,
          table: 'project_values',
          id: projectValueUrgentId,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: taskValueUrgentId,
        );

        // Update a value and the task.
        await valueRepo.update(
          id: health.id,
          name: 'Health',
          color: '#0000FF',
        );
        await taskRepo.update(
          id: task.id,
          name: 'Task CRUD Updated',
          completed: true,
          projectId: project.id,
          valueIds: [urgent.id],
        );

        final updatedHealth = await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: health.id,
        );
        expect(updatedHealth['color'], '#0000FF');

        final updatedTask = await _waitForServerRowExists(
          client: client,
          table: 'tasks',
          id: task.id,
        );
        expect(updatedTask['name'], 'Task CRUD Updated');
        expect(updatedTask['completed'], anyOf(true, 1));

        // Delete in safe order (tasks -> projects -> values).
        await taskRepo.delete(task.id);
        await projectRepo.delete(project.id);
        await valueRepo.delete(health.id);
        await valueRepo.delete(urgent.id);

        await _waitForServerRowMissing(
          client: client,
          table: 'tasks',
          id: task.id,
        );
        await _waitForServerRowMissing(
          client: client,
          table: 'projects',
          id: project.id,
        );
        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: health.id,
        );
        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: urgent.id,
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'constraints: invalid join upload is discarded and does not block later uploads',
      (tester) async {
        final idGenerator = getIt<IdGenerator>();
        final taskRepo = getIt<TaskRepositoryContract>();
        final valueRepo = getIt<ValueRepositoryContract>();

        // Create a task that will be used for join mutations.
        await taskRepo.create(name: 'Constraint Task');
        final task = await _selectTaskByName(driftDb, 'Constraint Task');
        expect(task, isNotNull);

        // First create an invalid task_value (FK should fail server-side).
        final invalidValueId =
            'value-does-not-exist-${DateTime.now().millisecondsSinceEpoch}';
        final invalidJoinId = idGenerator.taskValueId(
          taskId: task!.id,
          valueId: invalidValueId,
        );

        await valueRepo.addValueToTask(
          taskId: task.id,
          valueId: invalidValueId,
        );

        // Ensure we observed an upload attempt after the invalid change.
        await _waitForUploadCycle(syncDb);

        // The invalid join should not exist on the server.
        await _waitForServerRowMissing(
          client: client,
          table: 'task_values',
          id: invalidJoinId,
        );

        // Now create a valid value + join, which must still upload successfully.
        await valueRepo.create(name: 'Valid Value', color: '#123456');
        final valid = await _selectValueByName(driftDb, 'Valid Value');
        expect(valid, isNotNull);

        final validJoinId = idGenerator.taskValueId(
          taskId: task.id,
          valueId: valid!.id,
        );

        await valueRepo.addValueToTask(taskId: task.id, valueId: valid.id);
        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: validJoinId,
        );

        // Cleanup best-effort.
        await valueRepo.removeValueFromTask(
          taskId: task.id,
          valueId: invalidValueId,
        );
        await valueRepo.removeValueFromTask(taskId: task.id, valueId: valid.id);
        await taskRepo.delete(task.id);
        await valueRepo.delete(valid.id);
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'joins: task valueIds update rewrites task_values on server',
      (tester) async {
        final idGenerator = getIt<IdGenerator>();
        final valueRepo = getIt<ValueRepositoryContract>();
        final projectRepo = getIt<ProjectRepositoryContract>();
        final taskRepo = getIt<TaskRepositoryContract>();

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final valueAName = 'ValueA-$suffix';
        final valueBName = 'ValueB-$suffix';
        final projectName = 'Project-TaskJoinUpdate-$suffix';
        final taskName = 'Task-JoinUpdate-$suffix';

        await valueRepo.create(name: valueAName, color: '#111111');
        await valueRepo.create(name: valueBName, color: '#222222');

        final valueA = await _selectValueByName(driftDb, valueAName);
        final valueB = await _selectValueByName(driftDb, valueBName);
        expect(valueA, isNotNull);
        expect(valueB, isNotNull);

        await projectRepo.create(name: projectName);
        final project = await _selectProjectByName(driftDb, projectName);
        expect(project, isNotNull);

        await taskRepo.create(
          name: taskName,
          projectId: project!.id,
          valueIds: [valueA!.id],
        );
        final task = await _selectTaskByName(driftDb, taskName);
        expect(task, isNotNull);

        await _waitForServerRowExists(
          client: client,
          table: 'tasks',
          id: task!.id,
        );

        final joinAId = idGenerator.taskValueId(
          taskId: task.id,
          valueId: valueA.id,
        );
        final joinBId = idGenerator.taskValueId(
          taskId: task.id,
          valueId: valueB!.id,
        );

        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: joinAId,
        );

        await taskRepo.update(
          id: task.id,
          name: taskName,
          completed: false,
          projectId: project.id,
          valueIds: [valueB.id],
        );

        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: joinBId,
        );
        await _waitForServerRowMissing(
          client: client,
          table: 'task_values',
          id: joinAId,
        );

        await taskRepo.delete(task.id);
        await projectRepo.delete(project.id);
        await valueRepo.delete(valueA.id);
        await valueRepo.delete(valueB.id);
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'joins: project valueIds update rewrites project_values on server',
      (tester) async {
        final idGenerator = getIt<IdGenerator>();
        final valueRepo = getIt<ValueRepositoryContract>();
        final projectRepo = getIt<ProjectRepositoryContract>();

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final valueAName = 'ProjectValueA-$suffix';
        final valueBName = 'ProjectValueB-$suffix';
        final projectName = 'Project-JoinUpdate-$suffix';

        await valueRepo.create(name: valueAName, color: '#333333');
        await valueRepo.create(name: valueBName, color: '#444444');

        final valueA = await _selectValueByName(driftDb, valueAName);
        final valueB = await _selectValueByName(driftDb, valueBName);
        expect(valueA, isNotNull);
        expect(valueB, isNotNull);

        await projectRepo.create(name: projectName, valueIds: [valueA!.id]);
        final project = await _selectProjectByName(driftDb, projectName);
        expect(project, isNotNull);

        await _waitForServerRowExists(
          client: client,
          table: 'projects',
          id: project!.id,
        );

        final joinAId = idGenerator.projectValueId(
          projectId: project.id,
          valueId: valueA.id,
        );
        final joinBId = idGenerator.projectValueId(
          projectId: project.id,
          valueId: valueB!.id,
        );

        await _waitForServerRowExists(
          client: client,
          table: 'project_values',
          id: joinAId,
        );

        await projectRepo.update(
          id: project.id,
          name: projectName,
          completed: false,
          valueIds: [valueB.id],
        );

        await _waitForServerRowExists(
          client: client,
          table: 'project_values',
          id: joinBId,
        );
        await _waitForServerRowMissing(
          client: client,
          table: 'project_values',
          id: joinAId,
        );

        await projectRepo.delete(project.id);
        await valueRepo.delete(valueA.id);
        await valueRepo.delete(valueB.id);
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'server-first: PostgREST task/value edits download into Drift (incl join change)',
      (tester) async {
        final idGenerator = getIt<IdGenerator>();
        final valueRepo = getIt<ValueRepositoryContract>();
        final taskRepo = getIt<TaskRepositoryContract>();

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final valueAName = 'ServerFirstValueA-$suffix';
        final valueBName = 'ServerFirstValueB-$suffix';
        final taskName = 'ServerFirstTask-$suffix';

        await valueRepo.create(name: valueAName, color: '#AA0000');
        await valueRepo.create(name: valueBName, color: '#00AA00');

        final valueA = await _selectValueByName(driftDb, valueAName);
        final valueB = await _selectValueByName(driftDb, valueBName);
        expect(valueA, isNotNull);
        expect(valueB, isNotNull);

        await taskRepo.create(
          name: taskName,
          completed: false,
          valueIds: [valueA!.id],
        );
        final task = await _selectTaskByName(driftDb, taskName);
        expect(task, isNotNull);

        await _waitForServerRowExists(
          client: client,
          table: 'tasks',
          id: task!.id,
        );

        // Server-first: update value color + task completion + rename.
        await client.rest
            .from('values')
            .update({'color': '#0000AA'})
            .eq('id', valueA.id);
        await client.rest
            .from('tasks')
            .update({'completed': true, 'name': '$taskName-updated'})
            .eq('id', task.id);

        await _waitFor(
          () async {
            final localValue = await _selectValueById(driftDb, valueA.id);
            final localTask = await _selectTaskById(driftDb, task.id);
            return localValue?.color == '#0000AA' &&
                (localTask?.completed ?? false) &&
                localTask?.name == '$taskName-updated';
          },
          timeout: const Duration(seconds: 60),
          debugLabel: 'Drift to reflect server-first task/value updates',
        );

        // Server-first: change task_values join from A -> B.
        final joinAId = idGenerator.taskValueId(
          taskId: task.id,
          valueId: valueA.id,
        );
        final joinBId = idGenerator.taskValueId(
          taskId: task.id,
          valueId: valueB!.id,
        );

        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: joinAId,
        );

        await client.rest.from('task_values').delete().eq('id', joinAId);
        await client.rest.from('task_values').upsert({
          'id': joinBId,
          'task_id': task.id,
          'value_id': valueB.id,
          'is_primary': true,
          'user_id': userId,
        });

        await _waitFor(
          () async {
            final localJoinA = await _selectTaskValueJoin(
              driftDb,
              taskId: task.id,
              valueId: valueA.id,
            );
            final localJoinB = await _selectTaskValueJoin(
              driftDb,
              taskId: task.id,
              valueId: valueB.id,
            );
            return localJoinA == null && localJoinB != null;
          },
          timeout: const Duration(seconds: 60),
          debugLabel: 'Drift to reflect server-first join change',
        );

        // Cleanup.
        await taskRepo.delete(task.id);
        await valueRepo.delete(valueA.id);
        await valueRepo.delete(valueB.id);
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'two-client: domain CRUD sync A→B and B→A (isolated local DBs)',
      (tester) async {
        if (userId == null) {
          fail('Missing userId from setUpAll');
        }

        final deviceA = await _TestDevice.create(
          name: 'A',
          userId: userId!,
        );
        addTearDown(deviceA.dispose);

        final deviceB = await _TestDevice.create(
          name: 'B',
          userId: userId!,
        );
        addTearDown(deviceB.dispose);

        await _waitForPowerSyncConnected(deviceA.syncDb);
        await _waitForPowerSyncConnected(deviceB.syncDb);

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final valueName = 'TwoClientValue-$suffix';

        // A creates -> server -> B downloads.
        await deviceA.valueRepo.create(name: valueName, color: '#0A0A0A');
        final valueA = await _waitForLocalValueByName(
          deviceA.driftDb,
          valueName,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: valueA.id,
        );

        await _waitFor(
          () async =>
              (await _selectValueById(deviceB.driftDb, valueA.id)) != null,
          timeout: const Duration(seconds: 60),
          debugLabel: 'Device B to download value created on A',
        );

        // B updates -> server -> A downloads.
        await deviceB.valueRepo.update(
          id: valueA.id,
          name: valueName,
          color: '#0B0B0B',
        );
        await _waitFor(
          () async {
            final server = await _waitForServerRowExists(
              client: client,
              table: 'values',
              id: valueA.id,
            );
            return server['color'] == '#0B0B0B';
          },
          timeout: const Duration(seconds: 60),
          debugLabel: 'Server to reflect device B value update',
        );

        await _waitFor(
          () async =>
              (await _selectValueById(deviceA.driftDb, valueA.id))?.color ==
              '#0B0B0B',
          timeout: const Duration(seconds: 60),
          debugLabel: 'Device A to download value update from B',
        );

        // A deletes -> server -> B downloads deletion.
        await deviceA.valueRepo.delete(valueA.id);
        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: valueA.id,
        );
        await _waitFor(
          () async =>
              (await _selectValueById(deviceB.driftDb, valueA.id)) == null,
          timeout: const Duration(seconds: 60),
          debugLabel: 'Device B to download value deletion from A',
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'rls: forbidden upload (user_id mismatch) is discarded and later uploads succeed',
      (tester) async {
        final valueRepo = getIt<ValueRepositoryContract>();

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final badId = 'rls_bad_$suffix';

        // Insert a row with an invalid user_id. If RLS is configured as expected
        // (user_id must match auth.uid()), this should fail with 42501.
        await driftDb
            .into(driftDb.valueTable)
            .insert(
              ValueTableCompanion.insert(
                id: badId,
                name: 'RLS Bad $suffix',
                color: '#ABCDEF',
                userId: const Value('someone-else'),
              ),
            );

        await _waitForUploadCycle(syncDb, timeout: const Duration(seconds: 30));
        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: badId,
        );

        // Then do a valid write and ensure it still uploads (queue not wedged).
        final okName = 'RLS Ok $suffix';
        await valueRepo.create(name: okName, color: '#101010');
        final okLocal = await _waitForLocalValueByName(driftDb, okName);
        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: okLocal.id,
        );

        await valueRepo.delete(okLocal.id);
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'stress: batch create 75 tasks + joins uploads and matches server counts',
      (tester) async {
        final valueRepo = getIt<ValueRepositoryContract>();
        final taskRepo = getIt<TaskRepositoryContract>();

        const taskCount = 75;
        final suffix = DateTime.now().millisecondsSinceEpoch;
        final prefix = 'BatchTask-$suffix-';

        await valueRepo.create(name: 'BatchValue-$suffix', color: '#121212');
        final value = await _waitForLocalValueByName(
          driftDb,
          'BatchValue-$suffix',
        );

        for (var i = 0; i < taskCount; i++) {
          await taskRepo.create(
            name: '$prefix$i',
            completed: false,
            valueIds: [value.id],
          );
        }

        await _waitFor(
          () async {
            final tasks = await client.rest
                .from('tasks')
                .select('id,name')
                .like('name', '$prefix%');
            if (tasks.length != taskCount) return false;

            final joins = await client.rest
                .from('task_values')
                .select('id')
                .eq('value_id', value.id);
            return joins.length >= taskCount;
          },
          timeout: const Duration(seconds: 120),
          debugLabel: 'server to contain $taskCount batch tasks and joins',
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'two-client: 23505 conflict on deterministic table is handled and converges',
      (tester) async {
        if (userId == null) {
          fail('Missing userId from setUpAll');
        }

        final deviceA = await _TestDevice.create(
          name: 'A_23505',
          userId: userId!,
        );
        addTearDown(deviceA.dispose);

        final deviceB = await _TestDevice.create(
          name: 'B_23505',
          userId: userId!,
        );
        addTearDown(deviceB.dispose);

        await _waitForPowerSyncConnected(deviceA.syncDb);
        await _waitForPowerSyncConnected(deviceB.syncDb);

        final suffix = DateTime.now().millisecondsSinceEpoch;

        // Create shared domain rows (task is v4, value is v5) on A.
        await deviceA.valueRepo.create(
          name: 'ConflictValue-$suffix',
          color: '#0C0C0C',
        );
        final value = await _waitForLocalValueByName(
          deviceA.driftDb,
          'ConflictValue-$suffix',
        );

        await deviceA.taskRepo.create(name: 'ConflictTask-$suffix');
        final task = await _selectTaskByName(
          deviceA.driftDb,
          'ConflictTask-$suffix',
        );
        expect(task, isNotNull);

        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: value.id,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'tasks',
          id: task!.id,
        );

        // Wait for B to download them.
        await _waitFor(
          () async =>
              (await _selectValueById(deviceB.driftDb, value.id)) != null &&
              (await _selectTaskById(deviceB.driftDb, task.id)) != null,
          timeout: const Duration(seconds: 60),
          debugLabel: 'Device B to download seed task/value',
        );

        // A creates the correct deterministic join via repository.
        await deviceA.valueRepo.addValueToTask(
          taskId: task.id,
          valueId: value.id,
        );
        final deterministicJoinId = IdGenerator.withUserId(userId!).taskValueId(
          taskId: task.id,
          valueId: value.id,
        );

        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: deterministicJoinId,
        );

        // B attempts to create the same natural key with a DIFFERENT id.
        // This should trigger a 23505 on server (unique(task_id,value_id)).
        final conflictingJoinId = const Uuid().v4();
        await deviceB.driftDb
            .into(deviceB.driftDb.taskValuesTable)
            .insert(
              TaskValuesTableCompanion.insert(
                id: conflictingJoinId,
                taskId: task.id,
                valueId: value.id,
                isPrimary: const Value(true),
                userId: Value(userId),
              ),
            );

        await _waitForUploadCycle(
          deviceB.syncDb,
          timeout: const Duration(seconds: 30),
        );

        // Server should still have only the deterministic join row.
        await _waitForServerRowMissing(
          client: client,
          table: 'task_values',
          id: conflictingJoinId,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: deterministicJoinId,
        );

        // And B should converge by downloading the deterministic join.
        await _waitFor(
          () async {
            final localJoin = await _selectTaskValueJoin(
              deviceB.driftDb,
              taskId: task.id,
              valueId: value.id,
            );
            return localJoin != null;
          },
          timeout: const Duration(seconds: 60),
          debugLabel: 'Device B to converge on deterministic join',
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'server-first: PostgREST project edits download into Drift (incl join change)',
      (tester) async {
        final idGenerator = getIt<IdGenerator>();
        final valueRepo = getIt<ValueRepositoryContract>();
        final projectRepo = getIt<ProjectRepositoryContract>();

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final valueAName = 'ServerFirstProjectValueA-$suffix';
        final valueBName = 'ServerFirstProjectValueB-$suffix';
        final projectName = 'ServerFirstProject-$suffix';

        await valueRepo.create(name: valueAName, color: '#110000');
        await valueRepo.create(name: valueBName, color: '#001100');
        final valueA = await _selectValueByName(driftDb, valueAName);
        final valueB = await _selectValueByName(driftDb, valueBName);
        expect(valueA, isNotNull);
        expect(valueB, isNotNull);

        await projectRepo.create(
          name: projectName,
          completed: false,
          valueIds: [valueA!.id],
          priority: 4,
        );
        final project = await _selectProjectByName(driftDb, projectName);
        expect(project, isNotNull);

        await _waitForServerRowExists(
          client: client,
          table: 'projects',
          id: project!.id,
        );

        // Server-first: update project fields.
        await client.rest
            .from('projects')
            .update({
              'name': '$projectName-updated',
              'completed': true,
              'priority': 1,
              'pinned': true,
            })
            .eq('id', project.id);

        await _waitFor(
          () async {
            final localProject = await _selectProjectByName(
              driftDb,
              '$projectName-updated',
            );
            if (localProject == null) return false;
            return localProject.completed &&
                localProject.priority == 1 &&
                localProject.isPinned;
          },
          timeout: const Duration(seconds: 60),
          debugLabel: 'Drift to reflect server-first project updates',
        );

        // Server-first: swap project_values join from A -> B.
        final joinAId = idGenerator.projectValueId(
          projectId: project.id,
          valueId: valueA.id,
        );
        final joinBId = idGenerator.projectValueId(
          projectId: project.id,
          valueId: valueB!.id,
        );

        await _waitForServerRowExists(
          client: client,
          table: 'project_values',
          id: joinAId,
        );

        await client.rest.from('project_values').delete().eq('id', joinAId);
        await client.rest.from('project_values').upsert({
          'id': joinBId,
          'project_id': project.id,
          'value_id': valueB.id,
          'is_primary': true,
          'user_id': userId,
        });

        await _waitFor(
          () async {
            final localJoinA = await _selectProjectValueJoin(
              driftDb,
              projectId: project.id,
              valueId: valueA.id,
            );
            final localJoinB = await _selectProjectValueJoin(
              driftDb,
              projectId: project.id,
              valueId: valueB.id,
            );
            return localJoinA == null && localJoinB != null;
          },
          timeout: const Duration(seconds: 60),
          debugLabel: 'Drift to reflect server-first project join change',
        );

        await projectRepo.delete(project.id);
        await valueRepo.delete(valueA.id);
        await valueRepo.delete(valueB.id);
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'auth boundary: offline writes while signed out are not discarded and upload after sign-in',
      (tester) async {
        if (authEmail == null || authPassword == null || userId == null) {
          fail('Missing auth credentials from setUpAll');
        }

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final queuedId = 'auth_boundary_$suffix';
        final queuedName = 'Auth Boundary $suffix';

        await client.auth.signOut();
        await syncDb.statusStream
            .firstWhere((s) => !s.connected)
            .timeout(const Duration(seconds: 15));

        // Write directly to Drift while signed out (repositories may require user).
        await driftDb
            .into(driftDb.valueTable)
            .insert(
              ValueTableCompanion.insert(
                id: queuedId,
                name: queuedName,
                color: '#555555',
                userId: Value(userId),
              ),
            );

        await _expectNoUploadAttempt(syncDb);
        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: queuedId,
          timeout: const Duration(seconds: 10),
        );

        await client.auth.signInWithPassword(
          email: authEmail,
          password: authPassword!,
        );
        await _waitForPowerSyncConnected(
          syncDb,
          timeout: const Duration(seconds: 45),
        );
        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: queuedId,
          timeout: const Duration(seconds: 60),
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'batching: mixed put/patch/delete across tables yields expected final server state',
      (tester) async {
        if (userId == null) {
          fail('Missing userId from setUpAll');
        }

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final idGen = IdGenerator.withUserId(userId!);

        final valueAId = idGen.valueId(name: 'BatchValueA-$suffix');
        final valueBId = idGen.valueId(name: 'BatchValueB-$suffix');
        final projectId = const Uuid().v4();
        final taskId = const Uuid().v4();

        final projectValueId = idGen.projectValueId(
          projectId: projectId,
          valueId: valueAId,
        );
        final taskValueId = idGen.taskValueId(
          taskId: taskId,
          valueId: valueAId,
        );

        await driftDb.transaction(() async {
          await driftDb
              .into(driftDb.valueTable)
              .insert(
                ValueTableCompanion.insert(
                  id: valueAId,
                  name: 'BatchValueA-$suffix',
                  color: '#0A0A0A',
                  userId: Value(userId),
                ),
              );
          await driftDb
              .into(driftDb.valueTable)
              .insert(
                ValueTableCompanion.insert(
                  id: valueBId,
                  name: 'BatchValueB-$suffix',
                  color: '#0B0B0B',
                  userId: Value(userId),
                ),
              );

          await driftDb
              .into(driftDb.projectTable)
              .insert(
                ProjectTableCompanion.insert(
                  name: 'BatchProject-$suffix',
                  completed: false,
                  id: Value(projectId),
                  userId: Value(userId),
                  priority: const Value(4),
                  isPinned: const Value(false),
                ),
              );

          await driftDb
              .into(driftDb.taskTable)
              .insert(
                TaskTableCompanion.insert(
                  name: 'BatchTask-$suffix',
                  id: Value(taskId),
                  completed: const Value(false),
                  projectId: Value(projectId),
                  userId: Value(userId),
                ),
              );

          await driftDb
              .into(driftDb.projectValuesTable)
              .insert(
                ProjectValuesTableCompanion.insert(
                  id: projectValueId,
                  projectId: projectId,
                  valueId: valueAId,
                  userId: Value(userId),
                  isPrimary: const Value(true),
                ),
              );
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion.insert(
                  id: taskValueId,
                  taskId: taskId,
                  valueId: valueAId,
                  userId: Value(userId),
                  isPrimary: const Value(true),
                ),
              );

          // Patch-like updates.
          await (driftDb.update(
            driftDb.taskTable,
          )..where((t) => t.id.equals(taskId))).write(
            TaskTableCompanion(
              name: Value('BatchTask-$suffix-updated'),
              completed: const Value(true),
            ),
          );

          // Delete valueB (should be delete op).
          await (driftDb.delete(
            driftDb.valueTable,
          )..where((v) => v.id.equals(valueBId))).go();
        });

        await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: valueAId,
        );
        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: valueBId,
        );
        final serverTask = await _waitForServerRowExists(
          client: client,
          table: 'tasks',
          id: taskId,
        );
        expect(serverTask['name'], 'BatchTask-$suffix-updated');
        expect(serverTask['completed'], anyOf(true, 1));

        await _waitForServerRowExists(
          client: client,
          table: 'project_values',
          id: projectValueId,
        );
        await _waitForServerRowExists(
          client: client,
          table: 'task_values',
          id: taskValueId,
        );
      },
      skip: !_canRunAgainstLocalStack,
    );

    testWidgetsE2E(
      'resilience: disconnect/reconnect mid-queue eventually uploads without duplicates',
      (tester) async {
        if (userId == null) {
          fail('Missing userId from setUpAll');
        }

        final suffix = DateTime.now().millisecondsSinceEpoch;
        final idGen = IdGenerator.withUserId(userId!);
        final valueId = idGen.valueId(name: 'Transient-$suffix');

        await syncDb.disconnect();

        await driftDb
            .into(driftDb.valueTable)
            .insert(
              ValueTableCompanion.insert(
                id: valueId,
                name: 'Transient-$suffix',
                color: '#777777',
                userId: Value(userId),
              ),
            );

        await _waitForServerRowMissing(
          client: client,
          table: 'values',
          id: valueId,
          timeout: const Duration(seconds: 10),
        );

        await syncDb.connect(connector: SupabaseConnector(syncDb));
        await _waitForPowerSyncConnected(
          syncDb,
          timeout: const Duration(seconds: 45),
        );

        final server = await _waitForServerRowExists(
          client: client,
          table: 'values',
          id: valueId,
          timeout: const Duration(seconds: 60),
        );
        expect(server['id'], valueId);

        final dupRows = await client.rest
            .from('values')
            .select('id')
            .eq('id', valueId);
        expect(dupRows.length, 1);
      },
      skip: !_canRunAgainstLocalStack,
    );
  });
}

class _TestDevice {
  _TestDevice({
    required this.syncDb,
    required this.driftDb,
    required this.valueRepo,
    required this.taskRepo,
    required this.projectRepo,
    required this.tempDir,
  });

  final PowerSyncDatabase syncDb;
  final AppDatabase driftDb;
  final ValueRepositoryContract valueRepo;
  final TaskRepositoryContract taskRepo;
  final ProjectRepositoryContract projectRepo;
  final Directory tempDir;

  static Future<_TestDevice> create({
    required String name,
    required String userId,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('taskly_e2e_$name');
    final dbPath = p.join(tempDir.path, 'powersync_$name.db');

    final syncDb = await openDatabase(pathOverride: dbPath);
    final driftDb = AppDatabase(
      DatabaseConnection(SqliteAsyncDriftConnection(syncDb)),
    );

    final idGenerator = IdGenerator(() => userId);
    final occurrenceExpander = OccurrenceStreamExpander();
    final occurrenceWriteHelper = OccurrenceWriteHelper(
      driftDb: driftDb,
      idGenerator: idGenerator,
    );

    return _TestDevice(
      syncDb: syncDb,
      driftDb: driftDb,
      valueRepo: ValueRepository(driftDb: driftDb, idGenerator: idGenerator),
      taskRepo: TaskRepository(
        driftDb: driftDb,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      ),
      projectRepo: ProjectRepository(
        driftDb: driftDb,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      ),
      tempDir: tempDir,
    );
  }

  Future<void> dispose() async {
    try {
      await syncDb.disconnect();
    } catch (_) {}

    try {
      await driftDb.close();
    } catch (_) {}

    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}

Future<void> _deleteLocalPowerSyncDb() async {
  try {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Best-effort only (platform differences).
  }
}

Future<String> _ensureSignedIn(
  SupabaseClient client, {
  required String email,
  required String password,
}) async {
  try {
    final response = await client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw StateError('signUp succeeded but returned null user');
    }
    return user.id;
  } on AuthException {
    // Fallback for reruns without a DB reset.
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('signIn succeeded but returned null user');
    }
    return user.id;
  }
}

Future<void> _waitForPowerSyncConnected(
  PowerSyncDatabase db, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await db.statusStream
      .firstWhere((s) => s.connected)
      .timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'PowerSync did not connect within timeout',
            timeout,
          );
        },
      );
}

Future<UserProfileTableData?> _selectLatestProfile(AppDatabase db) {
  final query = db.select(db.userProfileTable)
    ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
    ..limit(1);
  return query.getSingleOrNull();
}

Future<ValueTableData?> _selectValueByName(AppDatabase db, String name) {
  final query = db.select(db.valueTable)
    ..where((row) => row.name.equals(name))
    ..limit(1);
  return query.getSingleOrNull();
}

Future<ValueTableData?> _selectValueById(AppDatabase db, String id) {
  final query = db.select(db.valueTable)
    ..where((row) => row.id.equals(id))
    ..limit(1);
  return query.getSingleOrNull();
}

Future<ProjectTableData?> _selectProjectByName(AppDatabase db, String name) {
  final query = db.select(db.projectTable)
    ..where((row) => row.name.equals(name))
    ..limit(1);
  return query.getSingleOrNull();
}

Future<TaskTableData?> _selectTaskByName(AppDatabase db, String name) {
  final query = db.select(db.taskTable)
    ..where((row) => row.name.equals(name))
    ..limit(1);
  return query.getSingleOrNull();
}

Future<TaskTableData?> _selectTaskById(AppDatabase db, String id) {
  final query = db.select(db.taskTable)
    ..where((row) => row.id.equals(id))
    ..limit(1);
  return query.getSingleOrNull();
}

Future<TaskValuesTableData?> _selectTaskValueJoin(
  AppDatabase db, {
  required String taskId,
  required String valueId,
}) {
  final query = db.select(db.taskValuesTable)
    ..where((row) => row.taskId.equals(taskId) & row.valueId.equals(valueId))
    ..limit(1);
  return query.getSingleOrNull();
}

Future<ProjectValuesTableData?> _selectProjectValueJoin(
  AppDatabase db, {
  required String projectId,
  required String valueId,
}) {
  final query = db.select(db.projectValuesTable)
    ..where(
      (row) => row.projectId.equals(projectId) & row.valueId.equals(valueId),
    )
    ..limit(1);
  return query.getSingleOrNull();
}

Future<ValueTableData> _waitForLocalValueByName(
  AppDatabase db,
  String name,
) async {
  late ValueTableData found;
  await _waitFor(
    () async {
      final row = await _selectValueByName(db, name);
      if (row == null) return false;
      found = row;
      return true;
    },
    timeout: const Duration(seconds: 45),
    debugLabel: 'local value by name: $name',
  );
  return found;
}

Future<Map<String, dynamic>> _waitForServerRowExists({
  required SupabaseClient client,
  required String table,
  required String id,
  Duration timeout = const Duration(seconds: 45),
}) async {
  late Map<String, dynamic> last;

  await _waitFor(
    () async {
      final rows = await client.rest.from(table).select().eq('id', id);
      if (rows.isNotEmpty) {
        last = (rows.first as Map).cast<String, dynamic>();
        return true;
      }
      return false;
    },
    timeout: timeout,
    debugLabel: 'server row exists: $table/$id',
  );

  return last;
}

Future<void> _waitForServerRowMissing({
  required SupabaseClient client,
  required String table,
  required String id,
  Duration timeout = const Duration(seconds: 45),
}) async {
  await _waitFor(
    () async {
      final rows = await client.rest.from(table).select('id').eq('id', id);
      return rows.isEmpty;
    },
    timeout: timeout,
    debugLabel: 'server row missing: $table/$id',
  );
}

Future<void> _waitForUploadCycle(
  PowerSyncDatabase db, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  // Wait until we observe at least one upload attempt.
  await db.statusStream
      .firstWhere((s) => s.uploading)
      .timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Did not observe PowerSync uploading=true within timeout',
          timeout,
        ),
      );

  // Then wait for upload to stop (success, discard, or error).
  await db.statusStream
      .firstWhere((s) => !s.uploading)
      .timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'PowerSync did not leave uploading state within timeout',
          timeout,
        ),
      );
}

Future<void> _expectNoUploadAttempt(
  PowerSyncDatabase db, {
  Duration window = const Duration(seconds: 3),
}) async {
  try {
    await db.statusStream.firstWhere((s) => s.uploading).timeout(window);
    fail('Expected no upload attempt, but uploading became true');
  } on TimeoutException {
    // Expected.
  }
}

Future<Map<String, dynamic>> _waitForServerUserProfile({
  required SupabaseClient client,
  required String id,
  Duration timeout = const Duration(seconds: 45),
}) async {
  late Map<String, dynamic> last;

  await _waitFor(
    () async {
      final rows = await client.rest
          .from('user_profiles')
          .select('id,user_id,settings_overrides,updated_at')
          .eq('id', id);

      if (rows.isNotEmpty) {
        final row = rows.first;
        last = row.cast<String, dynamic>();

        final overrides = _coerceJsonObject(last['settings_overrides']);
        final global = overrides['global'];
        if (global is Map && global['onboardingCompleted'] == true) {
          return true;
        }
      }

      return false;
    },
    timeout: timeout,
    debugLabel: 'server user_profiles row to exist and include overrides',
  );

  return last;
}

Future<void> _waitFor(
  Future<bool> Function() predicate, {
  required Duration timeout,
  required String debugLabel,
  Duration pollInterval = const Duration(milliseconds: 750),
}) async {
  final deadline = DateTime.now().add(timeout);
  Object? lastError;

  while (DateTime.now().isBefore(deadline)) {
    try {
      final ok = await predicate();
      if (ok) return;
    } catch (e) {
      lastError = e;
    }

    await Future<void>.delayed(pollInterval);
  }

  if (lastError != null) {
    throw TimeoutException(
      'Timed out waiting for $debugLabel (last error: $lastError)',
      timeout,
    );
  }

  throw TimeoutException('Timed out waiting for $debugLabel', timeout);
}

Map<String, dynamic> _coerceJsonObject(Object? value) {
  if (value == null) return <String, dynamic>{};

  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.cast<String, dynamic>();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }

  throw FormatException('Expected JSON object, got ${value.runtimeType}');
}
