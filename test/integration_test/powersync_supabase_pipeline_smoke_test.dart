/// PowerSync ⇄ Supabase local pipeline smoke tests.
///
/// These tests are meant to run against the local stack:
/// - Supabase started via `supabase start`
/// - PowerSync started via `tool/e2e/Start-LocalE2EStack.ps1`
///
/// Run (example):
/// `flutter test test/integration_test/powersync_supabase_pipeline_smoke_test.dart --dart-define-from-file=dart_defines.local.json --dart-define=RUN_POWERSYNC_SUPABASE_PIPELINE_TESTS=true --tags=pipeline`
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart' show Tags;
import 'package:taskly_bloc/app/di/dependency_injection.dart'
  show getIt, setupDependencies;
import 'package:taskly_domain/preferences.dart' show SettingsKey;
import 'package:taskly_bloc/app/env/env.dart';
import 'package:taskly_bloc/data/infrastructure/powersync/api_connector.dart'
    show getDatabasePath;
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import 'e2e_test_helpers.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _powersyncUrl = String.fromEnvironment('POWERSYNC_URL');
const _pipelineOptIn = bool.fromEnvironment(
  'RUN_POWERSYNC_SUPABASE_PIPELINE_TESTS',
  defaultValue: false,
);

bool _isLocalUrl(String url) {
  final trimmed = url.trim().toLowerCase();
  return trimmed.startsWith('http://127.0.0.1') ||
      trimmed.startsWith('http://localhost') ||
      trimmed.startsWith('https://127.0.0.1') ||
      trimmed.startsWith('https://localhost');
}

final bool _canRunAgainstLocalStack =
    _pipelineOptIn &&
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
    initializeLoggingForTest();

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

  group('PowerSync ⇄ Supabase local pipeline (smoke)', () {
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
  });
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
