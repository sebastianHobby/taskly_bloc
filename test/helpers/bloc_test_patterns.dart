/// BLoC test patterns and base classes.
///
/// Provides consistent structure for testing BLoCs with proper
/// timeout handling, state verification, and cleanup.
///
/// ## Pattern Overview
///
/// All BLoC tests should follow this structure:
///
/// ```dart
/// void main() {
///   group('MyBloc', () {
///     late MockRepository mockRepo;
///     late MyBloc bloc;
///
///     setUpAll(() {
///       setUpAllTestEnvironment();
///     });
///
///     setUp(() {
///       mockRepo = MockRepository();
///       // Set up default stubs
///     });
///
///     tearDown(() async {
///       await bloc.close();
///     });
///
///     MyBloc buildBloc() {
///       bloc = MyBloc(repository: mockRepo);
///       return bloc;
///     }
///
///     test('initial state is correct', () {
///       final bloc = buildBloc();
///       expect(bloc.state, equals(MyState.initial()));
///     });
///
///     blocTestSafe<MyBloc, MyState>(
///       'emits [loading, loaded] when event added',
///       build: () {
///         when(() => mockRepo.getData()).thenAnswer((_) async => data);
///         return buildBloc();
///       },
///       act: (bloc) => bloc.add(MyEvent.fetch()),
///       expect: () => [
///         MyState.loading(),
///         MyState.loaded(data),
///       ],
///     );
///   });
/// }
/// ```
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BLoC Test Constants
// ═══════════════════════════════════════════════════════════════════════════

/// Default timeout for BLoC tests (15 seconds).
///
/// BLoC tests should be fast. If exceeding this, likely an issue with:
/// - Unclosed streams
/// - Missing mock stubs
/// - Infinite state emissions
const Duration kBlocTestTimeout = Duration(seconds: 15);

/// Default wait duration for BLoC state emissions.
const Duration kBlocWaitDuration = Duration(milliseconds: 300);

// ═══════════════════════════════════════════════════════════════════════════
// Safe BLoC Test Wrapper
// ═══════════════════════════════════════════════════════════════════════════

/// blocTest with timeout protection.
///
/// Wraps the standard blocTest with a hard timeout to prevent hangs.
/// Use this instead of blocTest for all BLoC tests.
///
/// ```dart
/// blocTestSafe<MyBloc, MyState>(
///   'emits loaded when data fetched',
///   build: () => MyBloc(repo: mockRepo),
///   act: (bloc) => bloc.add(FetchEvent()),
///   expect: () => [LoadingState(), LoadedState(data)],
/// );
/// ```
@isTest
void blocTestSafe<B extends BlocBase<S>, S>(
  String description, {
  required B Function() build,
  FutureOr<void> Function()? setUp,
  S Function()? seed,
  FutureOr<void> Function(B bloc)? act,
  Duration? wait,
  int skip = 0,
  // NOTE: Using dynamic to allow matchers like isA<>().having()
  // bloc_test's expect parameter accepts both state instances and matchers
  Iterable<dynamic> Function()? expect,
  FutureOr<void> Function(B bloc)? verify,
  Object? Function()? errors,
  FutureOr<void> Function()? tearDown,
  dynamic tags,
  Duration timeout = kBlocTestTimeout,
}) {
  blocTest<B, S>(
    description,
    build: build,
    setUp: () async {
      initializeTalkerForTest();
      if (setUp != null) await setUp();
    },
    seed: seed,
    act: act != null
        ? (bloc) async {
            await Future(() async {
              await act(bloc);
            }).timeout(
              timeout,
              onTimeout: () {
                throw TimeoutException(
                  'BLoC test "$description" act() exceeded ${timeout.inSeconds}s. '
                  'Check for blocking operations or missing mock stubs.',
                  timeout,
                );
              },
            );
          }
        : null,
    wait: wait ?? kBlocWaitDuration,
    skip: skip,
    expect: expect,
    verify: verify,
    errors: errors,
    tearDown: tearDown,
    tags: tags,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// BLoC Test Utilities
// ═══════════════════════════════════════════════════════════════════════════

/// Verifies a BLoC's initial state without triggering any events.
///
/// ```dart
/// verifyInitialState(
///   build: () => MyBloc(repo: mockRepo),
///   expected: MyState.initial(),
/// );
/// ```
void verifyInitialState<B extends BlocBase<S>, S>({
  required B Function() build,
  required S expected,
}) {
  test('initial state is $expected', () {
    initializeTalkerForTest();
    final bloc = build();
    expect(bloc.state, equals(expected));
    bloc.close();
  });
}

/// Creates a stream that completes after emitting values.
///
/// Useful for mocking repository watch methods that should complete.
///
/// ```dart
/// when(() => repo.watchAll()).thenAnswer(
///   (_) => completingStream([task1, task2]),
/// );
/// ```
Stream<T> completingStream<T>(List<T> values) {
  return Stream.fromIterable(values);
}

/// Creates a stream that emits values with delays.
///
/// Useful for testing loading states and transitions.
///
/// ```dart
/// when(() => repo.watchAll()).thenAnswer(
///   (_) => delayedStream([
///     (Duration(milliseconds: 100), [task1]),
///     (Duration(milliseconds: 200), [task1, task2]),
///   ]),
/// );
/// ```
Stream<T> delayedStream<T>(List<(Duration, T)> emissions) async* {
  for (final (delay, value) in emissions) {
    await Future<void>.delayed(delay);
    yield value;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Test Stream Controller
// ═══════════════════════════════════════════════════════════════════════════

/// Standard stream controller for bloc tests.
///
/// Uses [BehaviorSubject] internally so late subscribers receive the last
/// emitted value - eliminating race condition hangs that occur when a bloc
/// subscribes after data has been emitted.
///
/// ## Why use this instead of StreamController?
///
/// Raw `StreamController` causes test hangs because:
/// 1. `act()` fires event AND emits data simultaneously
/// 2. Bloc's event handler subscribes to stream AFTER emit
/// 3. Data is lost - test waits forever for states that never arrive
///
/// `TestStreamController` uses `BehaviorSubject` which replays the last
/// value to new subscribers, eliminating timing issues.
///
/// ## Usage
///
/// ```dart
/// late TestStreamController<List<Task>> tasksController;
///
/// setUp(() {
///   tasksController = TestStreamController();
///   when(() => repo.watchAll()).thenAnswer((_) => tasksController.stream);
/// });
///
/// tearDown(() async {
///   await tasksController.close();
/// });
///
/// blocTestSafe<MyBloc, MyState>(
///   'loads tasks',
///   build: buildBloc,
///   act: (bloc) {
///     bloc.add(LoadTasks());
///     tasksController.emit([task1, task2]); // Safe - replays to late subscribers
///   },
///   expect: () => [/* states */],
/// );
/// ```
///
/// ## Seeded variant
///
/// Use [TestStreamController.seeded] when subscribers should immediately
/// receive an initial value:
///
/// ```dart
/// tasksController = TestStreamController.seeded([]); // Starts with empty list
/// ```
class TestStreamController<T> {
  /// Create a test stream controller.
  ///
  /// Subscribers will receive the last emitted value when they subscribe.
  /// If no value has been emitted, they wait for the first emission.
  TestStreamController() : _subject = BehaviorSubject<T>();

  /// Create a test stream controller with an initial value.
  ///
  /// Subscribers immediately receive [initialValue] when they subscribe.
  TestStreamController.seeded(T initialValue)
    : _subject = BehaviorSubject<T>.seeded(initialValue);

  final BehaviorSubject<T> _subject;

  /// The stream to pass to mocks.
  ///
  /// ```dart
  /// when(() => repo.watchAll()).thenAnswer((_) => controller.stream);
  /// ```
  Stream<T> get stream => _subject.stream;

  /// Emit data to the stream.
  ///
  /// Safe to call before bloc subscribes - [BehaviorSubject] replays
  /// the last value to new subscribers.
  void emit(T data) => _subject.add(data);

  /// Emit an error to the stream.
  void emitError(Object error, [StackTrace? stackTrace]) {
    _subject.addError(error, stackTrace);
  }

  /// The last emitted value, or null if none.
  T? get value => _subject.valueOrNull;

  /// Whether a value has been emitted.
  bool get hasValue => _subject.hasValue;

  /// Close the controller.
  ///
  /// Always call in `tearDown()`:
  /// ```dart
  /// tearDown(() async {
  ///   await controller.close();
  /// });
  /// ```
  Future<void> close() => _subject.close();

  /// Whether the controller is closed.
  bool get isClosed => _subject.isClosed;

  /// Whether the stream has any listeners.
  bool get hasListener => _subject.hasListener;
}

/// Creates a broadcast stream controller for testing.
///
/// @Deprecated('Use TestStreamController instead - prevents race condition hangs')
///
/// Useful when multiple listeners need the same stream.
///
/// ```dart
/// final controller = createBroadcastController<List<Task>>();
/// when(() => repo.watchAll()).thenAnswer((_) => controller.stream);
///
/// // Emit values during test
/// controller.add([task1]);
/// ```
@Deprecated('Use TestStreamController instead - prevents race condition hangs')
StreamController<T> createBroadcastController<T>() {
  return StreamController<T>.broadcast();
}

// ═══════════════════════════════════════════════════════════════════════════
// State Matchers
// ═══════════════════════════════════════════════════════════════════════════

/// Matches a BLoC state by type.
///
/// ```dart
/// expect: () => [
///   isA<LoadingState>(),
///   isA<LoadedState>().having((s) => s.data, 'data', isNotEmpty),
/// ],
/// ```
TypeMatcher<T> isStateType<T>() => isA<T>();

/// Matches any loading state (by convention).
///
/// Looks for states with 'loading' or 'inProgress' in their type name.
Matcher isAnyLoadingState() => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    return typeName.contains('loading') || typeName.contains('inprogress');
  },
  'is a loading state',
);

/// Matches any error state (by convention).
///
/// Looks for states with 'error' or 'failure' in their type name.
Matcher isAnyErrorState() => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    return typeName.contains('error') || typeName.contains('failure');
  },
  'is an error state',
);

/// Matches any success state (by convention).
///
/// Looks for states with 'success', 'loaded', or 'complete' in their type name.
Matcher isAnySuccessState() => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    return typeName.contains('success') ||
        typeName.contains('loaded') ||
        typeName.contains('complete');
  },
  'is a success state',
);

/// Exception for BLoC test timeout.
class TimeoutException implements Exception {
  TimeoutException(this.message, this.duration);
  final String message;
  final Duration duration;

  @override
  String toString() => 'TimeoutException: $message';
}
