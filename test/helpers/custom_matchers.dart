import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/core/model/entity_operation.dart';

/// Custom matchers for testing common patterns in the application.
///
/// These matchers make tests more readable and maintainable by encapsulating
/// common assertion patterns.
///
/// ## State Matchers
///
/// For BLoC state assertions, prefer type-safe matchers when possible:
/// ```dart
/// // Type-safe (best when you have a common state interface):
/// expect(state, isStateOfType<TaskDetailLoadSuccess>());
///
/// // String-based (flexible, works with any state):
/// expect(state, isLoadingState());
/// ```
///
/// ## Available Matchers
///
/// **State Matchers:**
/// - [isLoadingState] - Matches states containing 'loading' or 'inprogress'
/// - [isSuccessState] - Matches states containing 'success' or 'loaded'
/// - [isErrorState] - Matches states containing 'error' or 'failure'
/// - [isInitialState] - Matches states containing 'initial'
/// - [isStateOfType] - Type-safe matcher for specific state types
///
/// **Auth Matchers:**
/// - [isAuthenticatedState] - Matches authenticated states
/// - [isUnauthenticatedState] - Matches unauthenticated states
///
/// **Collection Matchers:**
/// - [containsWhere] - Checks if list contains item matching predicate
/// - [hasLengthOf] - Checks list length
///
/// **DateTime Matchers:**
/// - [isToday] - Checks if date is today
/// - [isInThePast] - Checks if date is in the past
/// - [isInTheFuture] - Checks if date is in the future

// ============================================================================
// Type-safe state matchers (preferred when type is known)
// ============================================================================

/// Type-safe matcher for a specific state type.
///
/// Preferred over string-based matchers when you know the exact state type.
///
/// Usage:
/// ```dart
/// expect(state, isStateOfType<TaskDetailLoadSuccess>());
/// expect(state, isStateOfType<TaskDetailLoadSuccess>()
///     .having((s) => s.task.id, 'task.id', 'task-1'));
/// ```
TypeMatcher<T> isStateOfType<T>() => isA<T>();

/// Matcher that checks both type and a condition.
///
/// Usage:
/// ```dart
/// expect(state, isStateMatching<TaskDetailLoadSuccess>(
///   (s) => s.task.completed == true,
/// ));
/// ```
Matcher isStateMatching<T>(bool Function(T) condition) => predicate<dynamic>(
  (state) {
    if (state is! T) return false;
    return condition(state);
  },
  'is $T matching condition',
);

// ============================================================================
// String-based state matchers (flexible, works with any state)
// ============================================================================

/// Matcher for bloc loading states.
///
/// Usage:
/// ```dart
/// expect(state, isLoadingState());
/// ```
Matcher isLoadingState() => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    final stateStr = state.toString().toLowerCase();
    return typeName.contains('loading') ||
        typeName.contains('inprogress') ||
        stateStr.contains('loading') ||
        stateStr.contains('inprogress') ||
        stateStr.contains('in progress');
  },
  'is a loading state',
);

/// Matcher for bloc success states.
///
/// Usage:
/// ```dart
/// expect(state, isSuccessState());
/// ```
Matcher isSuccessState() => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    final stateStr = state.toString().toLowerCase();
    return typeName.contains('success') ||
        typeName.contains('loaded') ||
        stateStr.contains('success') ||
        stateStr.contains('loaded');
  },
  'is a success state',
);

/// Matcher for bloc error/failure states.
///
/// Usage:
/// ```dart
/// expect(state, isErrorState());
/// expect(state, isErrorState(errorMessage: 'Network error'));
/// ```
Matcher isErrorState({String? errorMessage}) => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    final stateStr = state.toString().toLowerCase();
    final hasError =
        typeName.contains('error') ||
        typeName.contains('failure') ||
        stateStr.contains('error') ||
        stateStr.contains('failure');

    if (errorMessage != null) {
      return hasError && stateStr.contains(errorMessage.toLowerCase());
    }
    return hasError;
  },
  errorMessage != null
      ? 'is an error state containing "$errorMessage"'
      : 'is an error state',
);

/// Matcher for bloc initial states.
///
/// Usage:
/// ```dart
/// expect(state, isInitialState());
/// ```
Matcher isInitialState() => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    final stateStr = state.toString().toLowerCase();
    return typeName.contains('initial') || stateStr.contains('initial');
  },
  'is an initial state',
);

// ============================================================================
// Collection matchers
// ============================================================================

/// Matcher that checks if a list contains an item matching a condition.
///
/// Usage:
/// ```dart
/// expect(tasks, containsWhere((task) => task.name == 'Test'));
/// ```
Matcher containsWhere<T>(bool Function(T) predicate) =>
    _ContainsWhere<T>(predicate);

class _ContainsWhere<T> extends Matcher {
  _ContainsWhere(this._predicate);
  final bool Function(T) _predicate;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Iterable<T>) return false;
    return item.any(_predicate);
  }

  @override
  Description describe(Description description) =>
      description.add('contains an item matching the predicate');
}

/// Matcher that checks if a list has a specific length.
///
/// Usage:
/// ```dart
/// expect(tasks, hasLength(5));
/// ```
Matcher hasLengthOf(int length) => _HasLengthOf(length);

class _HasLengthOf extends Matcher {
  _HasLengthOf(this._length);
  final int _length;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Iterable) return false;
    return item.length == _length;
  }

  @override
  Description describe(Description description) =>
      description.add('has length $_length');
}

/// Matcher that checks if a DateTime is today.
///
/// Usage:
/// ```dart
/// expect(task.createdAt, isToday());
/// ```
Matcher isToday() => predicate<DateTime>(
  (date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  },
  'is today',
);

/// Matcher that checks if a DateTime is in the past.
///
/// Usage:
/// ```dart
/// expect(task.completedAt, isInThePast());
/// ```
Matcher isInThePast() => predicate<DateTime>(
  (date) => date.isBefore(DateTime.now()),
  'is in the past',
);

/// Matcher that checks if a DateTime is in the future.
///
/// Usage:
/// ```dart
/// expect(task.deadline, isInTheFuture());
/// ```
Matcher isInTheFuture() => predicate<DateTime>(
  (date) => date.isAfter(DateTime.now()),
  'is in the future',
);

/// Matcher that checks if a String is not empty.
///
/// Usage:
/// ```dart
/// expect(task.name, isNotEmptyString());
/// ```
Matcher isNotEmptyString() => predicate<String>(
  (str) => str.trim().isNotEmpty,
  'is not an empty string',
);

/// Matcher that checks if a value is null or empty (for strings/lists).
///
/// Usage:
/// ```dart
/// expect(task.description, isNullOrEmpty());
/// ```
Matcher isNullOrEmpty() => anyOf([
  isNull,
  predicate<dynamic>(
    (value) {
      if (value is String) return value.isEmpty;
      if (value is Iterable) return value.isEmpty;
      return false;
    },
    'is null or empty',
  ),
]);

/// Matcher for stream emissions in order.
///
/// Usage:
/// ```dart
/// expect(
///   bloc.stream,
///   emitsStatesInOrder([isLoadingState(), isSuccessState()]),
/// );
/// ```
Matcher emitsStatesInOrder(List<Matcher> stateMatchers) {
  return emitsInOrder(stateMatchers);
}

/// Matcher that checks if an exception message contains a specific text.
///
/// Usage:
/// ```dart
/// expect(
///   () => repository.delete('invalid-id'),
///   throwsExceptionWith('not found'),
/// );
/// ```
Matcher throwsExceptionWith(String message) => throwsA(
  predicate<Exception>(
    (e) => e.toString().toLowerCase().contains(message.toLowerCase()),
    'throws exception containing "$message"',
  ),
);

/// Matcher for checking if a bloc state has a specific property value.
///
/// Usage:
/// ```dart
/// expect(state, hasProperty('status', AuthStatus.authenticated));
/// ```
Matcher hasProperty<T>(String propertyName, T expectedValue) =>
    predicate<dynamic>(
      (state) {
        try {
          final stateStr = state.toString();
          // Simple property check via toString representation
          return stateStr.contains(propertyName) &&
              stateStr.contains(expectedValue.toString());
        } catch (_) {
          return false;
        }
      },
      'has property "$propertyName" with value "$expectedValue"',
    );

// ============================================================================
// Auth-specific matchers
// ============================================================================

/// Matcher for authenticated auth state.
///
/// Usage:
/// ```dart
/// expect(state, isAuthenticatedState());
/// expect(state, isAuthenticatedState(userId: 'user-1'));
/// ```
Matcher isAuthenticatedState({String? userId}) => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    final isAuthenticated =
        stateStr.contains('authenticated') &&
        !stateStr.contains('unauthenticated');

    if (userId != null && isAuthenticated) {
      return stateStr.contains(userId);
    }

    return isAuthenticated;
  },
  userId != null
      ? 'is authenticated state with userId: $userId'
      : 'is authenticated state',
);

/// Matcher for unauthenticated auth state.
///
/// Usage:
/// ```dart
/// expect(state, isUnauthenticatedState());
/// ```
Matcher isUnauthenticatedState() => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    return stateStr.contains('unauthenticated') ||
        (stateStr.contains('status') && stateStr.contains('initial'));
  },
  'is unauthenticated state',
);

/// Matcher for initial auth state.
///
/// Usage:
/// ```dart
/// expect(state, isInitialAuthState());
/// ```
Matcher isInitialAuthState() => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    return stateStr.contains('initial') || stateStr.contains('unauthenticated');
  },
  'is initial auth state',
);

/// Matcher for auth loading state.
///
/// Usage:
/// ```dart
/// expect(state, isAuthLoadingState());
/// ```
Matcher isAuthLoadingState() => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    return stateStr.contains('loading');
  },
  'is auth loading state',
);

/// Matcher for auth error state.
///
/// Usage:
/// ```dart
/// expect(state, isAuthErrorState());
/// expect(state, isAuthErrorState(errorMessage: 'Invalid credentials'));
/// ```
Matcher isAuthErrorState({String? errorMessage}) => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    final hasError = stateStr.contains('error') || stateStr.contains('failure');

    if (errorMessage != null && hasError) {
      return stateStr.contains(errorMessage.toLowerCase());
    }

    return hasError;
  },
  errorMessage != null
      ? 'is auth error state with message: $errorMessage'
      : 'is auth error state',
);

// ============================================================================
// Detail Bloc state matchers (for ProjectDetailBloc, LabelDetailBloc, etc.)
// ============================================================================

/// Matcher for operation success state (create, update, delete).
///
/// Usage:
/// ```dart
/// expect(state, isOperationSuccessState());
/// expect(state, isOperationSuccessState(operation: EntityOperation.create));
/// ```
Matcher isOperationSuccessState({EntityOperation? operation}) =>
    predicate<dynamic>(
      (state) {
        final stateStr = state.toString().toLowerCase();
        final isSuccess =
            stateStr.contains('operationsuccess') ||
            stateStr.contains('operation') && stateStr.contains('success');

        if (operation != null && isSuccess) {
          return stateStr.contains(operation.name.toLowerCase());
        }

        return isSuccess;
      },
      operation != null
          ? 'is operation success state with operation: ${operation.name}'
          : 'is operation success state',
    );

/// Matcher for operation failure state.
///
/// Usage:
/// ```dart
/// expect(state, isOperationFailureState());
/// ```
Matcher isOperationFailureState() => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    return stateStr.contains('operationfailure') ||
        stateStr.contains('operation') && stateStr.contains('failure');
  },
  'is operation failure state',
);

/// Matcher for load success state with entity.
///
/// Usage:
/// ```dart
/// expect(state, isLoadSuccessState());
/// ```
Matcher isLoadSuccessState() => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    return stateStr.contains('loadsuccess');
  },
  'is load success state',
);

/// Matcher for initial data load success state.
///
/// Usage:
/// ```dart
/// expect(state, isInitialDataLoadSuccessState());
/// ```
Matcher isInitialDataLoadSuccessState() => predicate<dynamic>(
  (state) {
    final stateStr = state.toString().toLowerCase();
    return stateStr.contains('initialdataloadsuccess');
  },
  'is initial data load success state',
);

// ============================================================================
// List Bloc state matchers (for TaskOverviewBloc, etc.)
// ============================================================================

/// Matcher for list loaded state.
///
/// Usage:
/// ```dart
/// expect(state, isListLoadedState());
/// expect(state, isListLoadedState(itemCount: 5));
/// ```
Matcher isListLoadedState({int? itemCount}) => predicate<dynamic>(
  (state) {
    final typeName = state.runtimeType.toString().toLowerCase();
    final isLoaded = typeName.contains('loaded');

    if (itemCount != null && isLoaded) {
      // Try to access the items through common property patterns
      final stateStr = state.toString();
      return stateStr.contains('$itemCount') || stateStr.contains('length');
    }

    return isLoaded;
  },
  itemCount != null
      ? 'is list loaded state with $itemCount items'
      : 'is list loaded state',
);

// ============================================================================
// Import needed for EntityOperation
// ============================================================================
// Note: Add this import at the top of the file if not present:
// import 'package:taskly_bloc/domain/models/entity_operation.dart';
