// This is a helper file, not a test file - it has no main() function
// @dart=2.12
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Base class for BLoC tests that handles common setup and teardown.
///
/// Extend this class to automatically handle bloc lifecycle management:
///
/// ```dart
/// class TaskDetailBlocTest extends BaseBlocTest<TaskDetailBloc, TaskDetailState> {
///   late MockTaskRepositoryContract mockTaskRepo;
///
///   @override
///   void setUp() {
///     mockTaskRepo = MockTaskRepositoryContract();
///     // Stub default behaviors
///     when(() => mockTaskRepo.getAll()).thenAnswer((_) async => []);
///     super.setUp(); // Creates the bloc
///   }
///
///   @override
///   TaskDetailBloc createBloc() {
///     return TaskDetailBloc(
///       taskRepository: mockTaskRepo,
///       projectRepository: mockProjectRepo,
///       labelRepository: mockLabelRepo,
///     );
///   }
///
///   // Your test methods...
/// }
/// ```
abstract class BaseBlocTest<B extends BlocBase<S>, S> {
  /// The bloc instance being tested.
  late B bloc;

  /// Called before each test to set up the bloc.
  ///
  /// Override this to set up mocks and dependencies, then call super.setUp()
  /// to create the bloc instance.
  void setUp() {
    bloc = createBloc();
  }

  /// Called after each test to clean up the bloc.
  ///
  /// Override this if you need additional cleanup, but always call
  /// super.tearDown() to close the bloc.
  Future<void> tearDown() async {
    await bloc.close();
  }

  /// Create the bloc instance with all required dependencies.
  ///
  /// This method is called during setUp() and should return a new
  /// bloc instance with mocked dependencies.
  B createBloc();

  /// Helper to get the current state of the bloc.
  S get currentState => bloc.state;

  /// Helper to wait for the bloc to emit a state matching the predicate.
  ///
  /// ```dart
  /// final state = await waitForState((s) => s is SuccessState);
  /// expect(state.data, isNotNull);
  /// ```
  Future<S> waitForState(
    bool Function(S) predicate, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return bloc.stream.firstWhere(predicate).timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Bloc did not emit expected state within $timeout',
          ),
        );
  }

  /// Helper to collect all emitted states until the stream completes or timeout.
  ///
  /// ```dart
  /// final states = await collectStates(count: 3);
  /// expect(states, hasLength(3));
  /// ```
  Future<List<S>> collectStates({
    int? count,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final states = <S>[];
    final subscription = bloc.stream.listen(states.add);

    try {
      if (count != null) {
        await Future.doWhile(() async {
          if (states.length >= count) return false;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return true;
        }).timeout(timeout);
      } else {
        await Future<void>.delayed(timeout);
      }
    } finally {
      await subscription.cancel();
    }

    return states;
  }
}

/// Extension methods for bloc testing.
extension BlocTestExtensions<S> on BlocBase<S> {
  /// Wait for the bloc to emit any state.
  ///
  /// ```dart
  /// await bloc.waitForAnyEmission();
  /// ```
  Future<S> waitForAnyEmission({
    Duration timeout = const Duration(seconds: 5),
  }) {
    return stream.first.timeout(timeout);
  }

  /// Check if the bloc has emitted any states.
  Future<bool> hasEmitted({
    Duration timeout = const Duration(milliseconds: 100),
  }) async {
    try {
      await stream.first.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}
