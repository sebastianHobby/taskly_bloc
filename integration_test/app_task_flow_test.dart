@Tags(['e2e', 'pipeline', 'slow'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/bootstrap/local_dev_host.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/presentation/features/app/app.dart';
import 'package:taskly_bloc/presentation/shared/session/presentation_session_services_coordinator.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_data/data_stack.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../test/helpers/test_imports.dart' hide TimeoutException;

const _localAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.'
    'CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

const _password = 'Passw0rd!local';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpAllTestEnvironment);

  late TasklyDataStack dataStack;
  late SupabaseClient supabase;
  late String email;

  setUpAll(() async {
    await _configureLocalEnv();
    await setupDependencies();

    dataStack = getIt<TasklyDataStack>();
    supabase = Supabase.instance.client;

    email = 'e2e_${DateTime.now().millisecondsSinceEpoch}@taskly.test';
    await _ensureSignedIn(supabase, email, _password);
  });

  setUp(() async {
    await dataStack.stopSession(reason: 'test reset', clearLocalData: true);
    await _clearRemoteData(supabase);
  });

  tearDownAll(() async {
    await dataStack.stopSession(reason: 'test teardown', clearLocalData: false);
    await supabase.auth.signOut();
    await dataStack.dispose();
  });

  testWidgetsSafe(
    'app flow: create/complete task persists and syncs',
    (tester) async {
      final taskName = 'E2E Task ${DateTime.now().millisecondsSinceEpoch}';

      await tester.pumpWidget(const App());
      await tester.pumpForStream(20);

      await _waitForNavigation(tester);
      await _openInboxProjectDetail(tester);

      await _createTaskViaUi(tester, taskName);
      await _assertTaskVisible(tester, taskName);

      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await _toggleTaskCompletion(tester, taskName);

      final taskId = await _findTaskId(taskName);
      final remote = await _waitForRemoteTask(supabase, taskId);
      expect(remote['completed'], isTrue);

      await _restartApp(tester);

      await _waitForNavigation(tester);
      await _openInboxProjectDetail(tester);
      await _assertTaskCompletedVisible(tester, taskName);
    },
    timeout: const Duration(minutes: 2),
  );
}

Future<void> _configureLocalEnv() async {
  Env.resetForTest();
  final host = localDevHost();
  Env.config = EnvConfig(
    name: 'local',
    supabaseUrl: 'http://$host:54321',
    supabasePublishableKey: _localAnonKey,
    powersyncUrl: 'http://$host:8080',
  );
  await Env.load();
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
    throw StateError('Supabase sign-in failed for app E2E tests.');
  }
}

Future<void> _clearRemoteData(SupabaseClient client) async {
  await client.from('task_completion_history').delete().neq('id', '');
  await client.from('task_recurrence_exceptions').delete().neq('id', '');
  await client.from('tasks').delete().neq('id', '');
}

Future<void> _waitForNavigation(WidgetTester tester) async {
  final found = await tester.pumpUntilFound(
    find.text('Anytime'),
    timeout: const Duration(seconds: 40),
  );
  expect(found, isTrue);
}

Future<void> _openInboxProjectDetail(WidgetTester tester) async {
  await tester.tap(find.text('Anytime'));
  await tester.pumpForStream(20);

  final foundInbox = await tester.pumpUntilFound(
    find.text('Inbox'),
    timeout: const Duration(seconds: 20),
  );
  expect(foundInbox, isTrue);

  await tester.tap(find.text('Inbox'));
  await tester.pumpForStream(20);

  final foundProjectDetail = await tester.pumpUntilFound(
    find.text('Project details'),
    timeout: const Duration(seconds: 20),
  );
  expect(foundProjectDetail, isTrue);
}

Future<void> _createTaskViaUi(WidgetTester tester, String taskName) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpForStream(10);

  await tester.tap(find.text('Add task'));
  await tester.pumpForStream(20);

  final nameField = find.byWidgetPredicate(
    (widget) =>
        widget is FormBuilderTextField &&
        widget.decoration.hintText == 'What needs to be done?',
  );
  expect(nameField, findsOneWidget);

  await tester.enterText(nameField, taskName);
  await tester.pumpForStream(10);

  final saveButton = find.widgetWithText(FilledButton, 'Save');
  expect(saveButton, findsOneWidget);
  await tester.tap(saveButton);
  await tester.pumpForStream(20);
}

Future<void> _assertTaskVisible(WidgetTester tester, String taskName) async {
  final found = await tester.pumpUntilFound(
    find.text(taskName),
    timeout: const Duration(seconds: 20),
  );
  expect(found, isTrue);
}

Future<void> _toggleTaskCompletion(WidgetTester tester, String taskName) async {
  final completeLabel = 'Mark "$taskName" as complete';
  final found = await tester.pumpUntilFound(
    find.bySemanticsLabel(completeLabel),
    timeout: const Duration(seconds: 20),
  );
  expect(found, isTrue);

  await tester.tap(find.bySemanticsLabel(completeLabel));
  await tester.pumpForStream(20);
}

Future<void> _assertTaskCompletedVisible(
  WidgetTester tester,
  String taskName,
) async {
  final incompleteLabel = 'Mark "$taskName" as incomplete';
  final found = await tester.pumpUntilFound(
    find.bySemanticsLabel(incompleteLabel),
    timeout: const Duration(seconds: 20),
  );
  expect(found, isTrue);
}

Future<String> _findTaskId(String taskName) async {
  final repo = getIt<TaskRepositoryContract>();
  final tasks = await repo.getAll(TaskQuery.all());
  final task = tasks.firstWhere((t) => t.name == taskName);
  return task.id;
}

Future<Map<String, dynamic>> _waitForRemoteTask(
  SupabaseClient client,
  String taskId,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final row = await client
        .from('tasks')
        .select('id, name, completed')
        .eq('id', taskId)
        .maybeSingle();
    if (row != null) return Map<String, dynamic>.from(row);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
  throw TimeoutException('Timed out waiting for task $taskId to sync.');
}

Future<void> _restartApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await getIt<PresentationSessionServicesCoordinator>().stop();
  await getIt<AuthenticatedAppServicesCoordinator>().stopWithReason(
    reason: 'e2e restart',
    clearLocalData: false,
  );

  await tester.pumpWidget(const App());
  await tester.pumpForStream(20);
}
