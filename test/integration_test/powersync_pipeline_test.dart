@Tags(['pipeline'])
library;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
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

void main() {
  setUpAll(setUpAllTestEnvironment);

  late TasklyDataStack stack;
  late TasklyDataBindings bindings;
  late SupabaseClient supabase;
  late Directory tempDir;

  setUpAll(() async {
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
    await stack.dispose();
    await supabase.auth.signOut();
    await tempDir.delete(recursive: true);
  });

  testSafe('signs in and starts the PowerSync session', () async {
    await stack.startSession();
    await bindings.initialSyncService.waitForFirstSync();

    final status = await stack.syncDb.statusStream.firstWhere(
      (s) => s.connected == true,
    );
    expect(status.connected, isTrue);
  });

  testSafe('uploads offline task after reconnect', () async {
    final repo = bindings.taskRepository;

    await repo.create(name: 'Offline Task', completed: false);
    final created = await repo.getAll();
    expect(created, isNotEmpty);

    final taskId = created.single.id;

    await stack.startSession();
    await bindings.initialSyncService.waitForFirstSync();

    final remote = await _waitForRemoteTask(supabase, taskId);
    expect(remote['name'], 'Offline Task');
  });

  testSafe('downloads remote updates into local database', () async {
    await stack.startSession();
    await bindings.initialSyncService.waitForFirstSync();

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
  });
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
  await client.from('tasks').delete().neq('id', '');
  await client.from('projects').delete().neq('id', '');
  await client.from('values').delete().neq('id', '');
}

Future<void> _clearLocalData(AppDatabase db) async {
  await db.customUpdate('DELETE FROM tasks');
  await db.customUpdate('DELETE FROM projects');
  await db.customUpdate('DELETE FROM values');
}

Future<Map<String, dynamic>> _waitForRemoteTask(
  SupabaseClient client,
  String taskId,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 12));
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('tasks')
        .select('id, name')
        .eq('id', taskId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }
  throw TimeoutException('Timed out waiting for task $taskId to sync.');
}

final class TimeoutException implements Exception {
  TimeoutException(this.message);

  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
