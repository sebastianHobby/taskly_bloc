/// Helpers for integration tests.
///
/// Integration tests verify that multiple real components work together
/// correctly. Unlike unit tests that isolate with mocks, integration tests
/// use real implementations (database, repositories, BLoCs).
///
/// ## When to use integration tests
///
/// - Testing end-to-end flows (user action → database → UI update)
/// - Verifying repository ↔ BLoC stream contracts
/// - Testing complex state transitions across components
///
/// ## Pattern
///
/// ```dart
/// group('Screen loading flow', () {
///   late IntegrationTestContext ctx;
///
///   setUp(() async {
///     ctx = await IntegrationTestContext.create();
///   });
///
///   tearDown(() async {
///     await ctx.dispose();
///   });
///
///   testIntegration('loads screen from database', () async {
///     // Arrange
///     await ctx.seedScreen(screenKey: 'inbox');
///
///     // Act
///     final bloc = ctx.createScreenDefinitionBloc('inbox');
///     bloc.add(ScreenDefinitionEvent.subscriptionRequested(screenKey: 'inbox'));
///
///     // Assert
///     await expectBlocState<ScreenDefinitionState>(
///       bloc,
///       (s) => s is ScreenDefinitionLoaded,
///     );
///   });
/// });
/// ```
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/screens/default_system_screen_provider.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';

import 'test_db.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Integration Test Wrapper
// ═══════════════════════════════════════════════════════════════════════════

/// Default timeout for integration tests (45 seconds).
///
/// Integration tests involve real I/O and may be slower than unit tests.
const Duration kIntegrationTestTimeout = Duration(seconds: 45);

/// Default timeout for waiting on BLoC state changes.
const Duration kBlocStateTimeout = Duration(seconds: 5);

/// Integration test with timeout protection.
///
/// Use for tests that verify multiple real components working together.
///
/// ```dart
/// testIntegration('screen loads from database', () async {
///   final ctx = await IntegrationTestContext.create();
///   // ... test with real database
///   await ctx.dispose();
/// });
/// ```
@isTest
void testIntegration(
  String description,
  Future<void> Function() callback, {
  Duration timeout = kIntegrationTestTimeout,
  bool skip = false,
  dynamic tags,
}) {
  test(
    description,
    skip: skip,
    tags: tags ?? 'integration',
    () async {
      await callback().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Integration test "$description" exceeded ${timeout.inSeconds}s. '
            'Check for: unclosed streams, missing emissions, deadlocks.',
            timeout,
          );
        },
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Integration Test Context
// ═══════════════════════════════════════════════════════════════════════════

/// Context for integration tests with real database and repositories.
///
/// Provides a clean, isolated environment for each test.
///
/// ## Usage
///
/// ```dart
/// late IntegrationTestContext ctx;
///
/// setUp(() async {
///   ctx = await IntegrationTestContext.create();
/// });
///
/// tearDown(() async {
///   await ctx.dispose();
/// });
///
/// test('example', () async {
///   await ctx.seedSystemScreens();
///   final screens = await ctx.screensRepository.getAll();
///   expect(screens, isNotEmpty);
/// });
/// ```
class IntegrationTestContext {
  IntegrationTestContext._({
    required this.db,
    required this.screensRepository,
    required this.settingsRepository,
  });

  /// Creates a new integration test context with fresh database.
  static Future<IntegrationTestContext> create() async {
    initializeTalkerForTest();
    final db = createTestDb();

    final idGenerator = IdGenerator.withUserId('test-user');
    const systemScreenProvider = DefaultSystemScreenProvider();
    final settingsRepository = SettingsRepository(driftDb: db);

    final screensRepository = ScreenDefinitionsRepository(
      databaseRepository: ScreenDefinitionsRepositoryImpl(
        db,
        idGenerator,
        systemScreenProvider,
      ),
    );

    return IntegrationTestContext._(
      db: db,
      screensRepository: screensRepository,
      settingsRepository: settingsRepository,
    );
  }

  final AppDatabase db;
  final ScreenDefinitionsRepositoryContract screensRepository;
  final SettingsRepositoryContract settingsRepository;

  final List<BlocBase<dynamic>> _createdBlocs = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Sets up preferences for all system screens.
  ///
  /// System screens are code-based and don't need to be seeded into the
  /// database. This method sets up their preferences (isActive, sortOrder).
  Future<void> seedSystemScreens({String userId = 'test-user'}) async {
    for (final screen in SystemScreenDefinitions.all) {
      await screensRepository.updateScreenPreferences(
        screen.screenKey,
        ScreenPreferences(
          isActive: true,
          sortOrder: SystemScreenDefinitions.getDefaultSortOrder(
            screen.screenKey,
          ),
        ),
      );
    }
  }

  /// Seeds a single custom screen definition into the database.
  ///
  /// For system screens, use [seedSystemScreens] or update preferences
  /// directly via [screensRepository.updateScreenPreferences].
  Future<void> seedScreen({
    required ScreenDefinition screen,
    String userId = 'test-user',
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    // Create the custom screen first
    await screensRepository.createCustomScreen(screen);
    // Then set its preferences
    await screensRepository.updateScreenPreferences(
      screen.screenKey,
      ScreenPreferences(
        isActive: isActive,
        sortOrder: sortOrder,
      ),
    );
  }

  /// Tracks a BLoC for automatic cleanup.
  T trackBloc<T extends BlocBase<dynamic>>(T bloc) {
    _createdBlocs.add(bloc);
    return bloc;
  }

  /// Tracks a stream subscription for automatic cleanup.
  StreamSubscription<T> trackSubscription<T>(StreamSubscription<T> sub) {
    _subscriptions.add(sub);
    return sub;
  }

  /// Disposes all resources.
  Future<void> dispose() async {
    // Cancel subscriptions first
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    // Close BLoCs
    for (final bloc in _createdBlocs) {
      await bloc.close();
    }
    _createdBlocs.clear();

    // Close database
    await closeTestDb(db);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BLoC State Utilities
// ═══════════════════════════════════════════════════════════════════════════

/// Waits for a BLoC to emit a state matching [predicate].
///
/// Returns the matching state, or throws [TimeoutException] if not found.
///
/// ```dart
/// final state = await expectBlocState<MyState>(
///   bloc,
///   (s) => s is LoadedState,
/// );
/// expect(state.data, isNotNull);
/// ```
Future<T> expectBlocState<T>(
  BlocBase<T> bloc,
  bool Function(T) predicate, {
  Duration timeout = kBlocStateTimeout,
  String? reason,
}) async {
  // Check current state first
  if (predicate(bloc.state)) {
    return bloc.state;
  }

  // Wait for matching state
  try {
    return await bloc.stream.firstWhere(predicate).timeout(timeout);
  } on TimeoutException {
    final msg = reason ?? 'Expected state matching predicate';
    throw TimeoutException(
      '$msg. Current state: ${bloc.state}',
      timeout,
    );
  }
}

/// Waits for a BLoC to emit states matching [matchers] in order.
///
/// ```dart
/// await expectBlocStatesInOrder<MyState>(
///   bloc,
///   [
///     (s) => s is LoadingState,
///     (s) => s is LoadedState,
///   ],
/// );
/// ```
Future<List<T>> expectBlocStatesInOrder<T>(
  BlocBase<T> bloc,
  List<bool Function(T)> predicates, {
  Duration timeout = kBlocStateTimeout,
}) async {
  final states = <T>[];
  var predicateIndex = 0;

  final completer = Completer<List<T>>();

  final subscription = bloc.stream.listen(
    (state) {
      if (predicateIndex < predicates.length &&
          predicates[predicateIndex](state)) {
        states.add(state);
        predicateIndex++;
        if (predicateIndex >= predicates.length) {
          completer.complete(states);
        }
      }
    },
    onError: completer.completeError,
  );

  try {
    return await completer.future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Only matched ${states.length}/${predicates.length} states. '
          'Last state: ${bloc.state}',
          timeout,
        );
      },
    );
  } finally {
    await subscription.cancel();
  }
}

/// Verifies a BLoC doesn't emit any state matching [predicate] within [duration].
///
/// Useful for verifying error states aren't emitted.
Future<void> expectBlocNeverEmits<T>(
  BlocBase<T> bloc,
  bool Function(T) predicate, {
  Duration duration = const Duration(milliseconds: 500),
}) async {
  final completer = Completer<void>();

  final subscription = bloc.stream.listen(
    (state) {
      if (predicate(state)) {
        completer.completeError(
          StateError('Unexpected state emitted: $state'),
        );
      }
    },
  );

  try {
    await Future.any([
      completer.future,
      Future<void>.delayed(duration),
    ]);
  } finally {
    await subscription.cancel();
  }

  if (completer.isCompleted) {
    // Error was thrown
    await completer.future;
  }
}

/// Exception for integration test timeout.
class TimeoutException implements Exception {
  TimeoutException(this.message, this.duration);
  final String message;
  final Duration duration;

  @override
  String toString() => 'TimeoutException: $message';
}
