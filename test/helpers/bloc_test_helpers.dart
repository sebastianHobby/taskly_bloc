import 'dart:async';

import 'package:mocktail/mocktail.dart';

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

/// Helper class for setting up BLoC tests with common dependencies.
///
/// Reduces boilerplate in BLoC tests by providing pre-configured mocks
/// and default stub behaviors.
class BlocTestContext {
  BlocTestContext() {
    taskRepo = MockTaskRepository();
    projectRepo = MockProjectRepository();
    labelRepo = MockLabelRepository();
    settingsRepo = MockSettingsRepository();
    analyticsRepo = MockAnalyticsRepository();
    wellbeingRepo = MockWellbeingRepository();

    // Default stubs for common repository calls
    _stubDefaultBehaviors();
  }
  late MockTaskRepository taskRepo;
  late MockProjectRepository projectRepo;
  late MockLabelRepository labelRepo;
  late MockSettingsRepository settingsRepo;
  late MockAnalyticsRepository analyticsRepo;
  late MockWellbeingRepository wellbeingRepo;

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
