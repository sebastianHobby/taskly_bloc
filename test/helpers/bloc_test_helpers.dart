import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../mocks/feature_mocks.dart';
import '../mocks/repository_mocks.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Async Test Helpers
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Waits for a stream to emit at least [count] values, with a timeout.
///
/// More reliable than `Future.delayed` for testing stream emissions.
/// Returns the collected values.
Future<List<T>> waitForStreamEmissions<T>(
  Stream<T> stream, {
  int count = 1,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final values = <T>[];
  final completer = Completer<List<T>>();

  final subscription = stream.listen(
    (value) {
      values.add(value);
      if (values.length >= count && !completer.isCompleted) {
        completer.complete(values);
      }
    },
    onError: (Object error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(values);
      }
    },
  );

  try {
    return await completer.future.timeout(
      timeout,
      onTimeout: () => values,
    );
  } finally {
    await subscription.cancel();
  }
}

/// Waits for a stream to emit a value matching [predicate], with a timeout.
///
/// Useful for waiting for a specific state transition.
Future<T?> waitForStreamMatch<T>(
  Stream<T> stream,
  bool Function(T) predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    return await stream.firstWhere(predicate).timeout(timeout);
  } on TimeoutException {
    return null;
  } on StateError {
    return null;
  }
}

/// Expects a stream to emit a value matching the given matcher.
///
/// Returns the emitted value for further assertions.
///
/// Usage:
/// ```dart
/// final state = await expectStreamEmits(
///   bloc.stream,
///   isA<SuccessState>(),
/// );
/// expect(state.data, isNotNull);
/// ```
Future<T> expectStreamEmits<T>(
  Stream<T> stream,
  Matcher matcher, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final value = await stream.first.timeout(timeout);
  expect(value, matcher);
  return value;
}

/// Expects a stream to emit values matching the given matchers in order.
///
/// Usage:
/// ```dart
/// await expectStreamEmitsInOrder(
///   bloc.stream,
///   [isLoadingState(), isSuccessState()],
/// );
/// ```
Future<void> expectStreamEmitsInOrder<T>(
  Stream<T> stream,
  List<Matcher> matchers, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final values = await waitForStreamEmissions(
    stream,
    count: matchers.length,
    timeout: timeout,
  );

  for (var i = 0; i < matchers.length; i++) {
    expect(
      values[i],
      matchers[i],
      reason: 'Emission $i did not match expected pattern',
    );
  }
}

/// Expects a stream to complete without emitting any values.
///
/// Usage:
/// ```dart
/// await expectStreamEmpty(emptyStream);
/// ```
Future<void> expectStreamEmpty<T>(
  Stream<T> stream, {
  Duration timeout = const Duration(milliseconds: 500),
}) async {
  try {
    await stream.first.timeout(timeout);
    fail('Expected empty stream, but it emitted a value');
  } on TimeoutException {
    // Success - stream didn't emit
  } on StateError {
    // Success - stream completed without emitting
  }
}

/// Helper class for setting up BLoC tests with common dependencies.
///
/// Reduces boilerplate in BLoC tests by providing pre-configured mocks
/// and default stub behaviors.
class BlocTestContext {
  BlocTestContext() {
    taskRepo = MockTaskRepositoryContract();
    projectRepo = MockProjectRepositoryContract();
    labelRepo = MockLabelRepositoryContract();
    settingsRepo = MockSettingsRepositoryContract();
    analyticsRepo = MockAnalyticsRepositoryContract();
    wellbeingRepo = MockWellbeingRepositoryContract();

    // Default stubs for common repository calls
    _stubDefaultBehaviors();
  }
  late MockTaskRepositoryContract taskRepo;
  late MockProjectRepositoryContract projectRepo;
  late MockLabelRepositoryContract labelRepo;
  late MockSettingsRepositoryContract settingsRepo;
  late MockAnalyticsRepositoryContract analyticsRepo;
  late MockWellbeingRepositoryContract wellbeingRepo;

  void _stubDefaultBehaviors() {
    // Empty lists for get operations
    when(() => projectRepo.getAll()).thenAnswer((_) async => []);
    when(() => labelRepo.getAll()).thenAnswer((_) async => []);
  }

  /// Stub common task repository operations with default behaviors
  void stubTaskOperations({bool throwOnUpdate = false}) {
    if (throwOnUpdate) {
      when(
        () => taskRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenThrow(Exception('update failed'));
    } else {
      when(
        () => taskRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    }

    when(
      () => taskRepo.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        projectId: any(named: 'projectId'),
        labelIds: any(named: 'labelIds'),
      ),
    ).thenAnswer((_) async {});

    when(() => taskRepo.delete(any())).thenAnswer((_) async {});
  }

  /// Stub project repository update operation
  void stubProjectUpdate({bool shouldThrow = false}) {
    if (shouldThrow) {
      when(
        () => projectRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenThrow(Exception('update failed'));
    } else {
      when(
        () => projectRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async {});
    }
  }

  /// Stub project repository create operation
  void stubProjectCreate({bool shouldThrow = false}) {
    if (shouldThrow) {
      when(
        () => projectRepo.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenThrow(Exception('create failed'));
    } else {
      when(
        () => projectRepo.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    }
  }

  /// Stub project repository delete operation
  void stubProjectDelete({bool shouldThrow = false}) {
    if (shouldThrow) {
      when(
        () => projectRepo.delete(any()),
      ).thenThrow(Exception('delete failed'));
    } else {
      when(() => projectRepo.delete(any())).thenAnswer((_) async {});
    }
  }

  /// Register custom stubs for this test context
  void stub(void Function() stubFn) {
    stubFn();
  }
}

/// Helper for analytics-specific BLoC tests
class AnalyticsBlocTestContext extends BlocTestContext {
  AnalyticsBlocTestContext() : super();
}

/// Helper for wellbeing-specific BLoC tests
class WellbeingBlocTestContext extends BlocTestContext {
  WellbeingBlocTestContext() : super() {
    // Add wellbeing-specific default stubs if needed
  }
}

/// Helper for reviews-specific BLoC tests
class ReviewsBlocTestContext extends BlocTestContext {
  ReviewsBlocTestContext() : super() {
    // Add reviews-specific default stubs if needed
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BlocTestContext Extensions
// ──────────────────────────────────────────────────────────────────────────────

/// Extension methods for BlocTestContext to reduce boilerplate.
extension BlocTestContextExtensions on BlocTestContext {
  /// Stub all repositories to return empty responses.
  ///
  /// Useful for tests that don't care about data, only behavior.
  void stubAllEmpty() {
    when(() => taskRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => projectRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    when(() => projectRepo.getAll()).thenAnswer((_) async => []);
    when(() => labelRepo.getAll()).thenAnswer((_) async => []);
  }

  /// Stub all repositories to throw the specified error.
  ///
  /// Useful for testing error handling scenarios.
  void stubAllThrow(Exception error) {
    when(() => taskRepo.watchAll()).thenThrow(error);
    when(() => projectRepo.watchAll()).thenThrow(error);
    when(() => projectRepo.getAll()).thenThrow(error);
    when(() => labelRepo.getAll()).thenThrow(error);
  }

  /// Verify no unexpected repository calls were made.
  ///
  /// Call this at the end of tests to ensure the test only made
  /// expected repository calls.
  void verifyNoMoreRepoInteractions() {
    verifyNoMoreInteractions(taskRepo);
    verifyNoMoreInteractions(projectRepo);
    verifyNoMoreInteractions(labelRepo);
  }

  /// Stub task repository to return specific tasks.
  void stubTasksReturn(List<Task> tasks) {
    when(() => taskRepo.watchAll()).thenAnswer((_) => Stream.value(tasks));
  }

  /// Stub project repository to return specific projects.
  void stubProjectsReturn(List<Project> projects) {
    when(
      () => projectRepo.watchAll(),
    ).thenAnswer((_) => Stream.value(projects));
    when(() => projectRepo.getAll()).thenAnswer((_) async => projects);
  }

  /// Stub label repository to return specific labels.
  void stubLabelsReturn(List<Label> labels) {
    when(() => labelRepo.getAll()).thenAnswer((_) async => labels);
  }

  /// Stub a single task by ID.
  void stubTaskById(String id, Task task) {
    when(() => taskRepo.getById(id)).thenAnswer((_) async => task);
    when(() => taskRepo.watchById(id)).thenAnswer((_) => Stream.value(task));
  }

  /// Stub task creation to succeed.
  void stubTaskCreateSuccess() {
    when(
      () => taskRepo.create(
        name: any(named: 'name'),
        description: any(named: 'description'),
        completed: any(named: 'completed'),
        startDate: any(named: 'startDate'),
        deadlineDate: any(named: 'deadlineDate'),
        projectId: any(named: 'projectId'),
        repeatIcalRrule: any(named: 'repeatIcalRrule'),
        repeatFromCompletion: any(named: 'repeatFromCompletion'),
        labelIds: any(named: 'labelIds'),
      ),
    ).thenAnswer((_) async {});
  }

  /// Stub task update to succeed.
  void stubTaskUpdateSuccess() {
    when(
      () => taskRepo.update(
        id: any(named: 'id'),
        name: any(named: 'name'),
        completed: any(named: 'completed'),
        description: any(named: 'description'),
        startDate: any(named: 'startDate'),
        deadlineDate: any(named: 'deadlineDate'),
        projectId: any(named: 'projectId'),
        repeatIcalRrule: any(named: 'repeatIcalRrule'),
        repeatFromCompletion: any(named: 'repeatFromCompletion'),
        labelIds: any(named: 'labelIds'),
      ),
    ).thenAnswer((_) async {});
  }

  /// Stub task delete to succeed.
  void stubTaskDeleteSuccess() {
    when(() => taskRepo.delete(any())).thenAnswer((_) async {});
  }
}
