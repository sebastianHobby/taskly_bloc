import 'package:taskly_bloc/core/utils/talker_service.dart';

/// A sealed class representing the result of an operation that can either
/// succeed with a value or fail with a [Failure].
///
/// This is an Either-like type that provides type-safe error handling.
sealed class Result<T> {
  const Result();

  /// Creates a successful result with the given [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result with the given [failure].
  const factory Result.failure(Failure failure) = Failure$<T>;

  /// Returns `true` if this is a successful result.
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a failed result.
  bool get isFailure => this is Failure$<T>;

  /// Returns the value if successful, or `null` if failed.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure$() => null,
  };

  /// Returns the failure if failed, or `null` if successful.
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Failure$(:final failure) => failure,
  };

  /// Maps the success value to a new value using [transform].
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Result.success(transform(value)),
    Failure$(:final failure) => Result.failure(failure),
  };

  /// Flat maps the success value to a new Result using [transform].
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success(:final value) => transform(value),
    Failure$(:final failure) => Result.failure(failure),
  };

  /// Executes [onSuccess] or [onFailure] based on the result.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => switch (this) {
    Success(:final value) => onSuccess(value),
    Failure$(:final failure) => onFailure(failure),
  };

  /// Returns the value if successful, otherwise returns [defaultValue].
  T getOrElse(T defaultValue) => switch (this) {
    Success(:final value) => value,
    Failure$() => defaultValue,
  };
}

/// Represents a successful result containing a [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  /// The successful value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result containing a [failure].
final class Failure$<T> extends Result<T> {
  const Failure$(this.failure);

  /// The failure information.
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure$<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}

/// Base class for all application failures.
///
/// Each failure type contains:
/// - A user-friendly message for display
/// - Optional original error and stack trace for debugging/logging
sealed class Failure {
  const Failure({
    required this.message,
    this.error,
    this.stackTrace,
  });

  /// User-friendly message to display in the UI.
  final String message;

  /// Original error for debugging purposes.
  final Object? error;

  /// Stack trace for debugging purposes.
  final StackTrace? stackTrace;

  /// Logs this failure with full details for debugging.
  void log({String? name}) {
    talker.warning('Failure: $message', error, stackTrace);
  }
}

/// Failure when an entity is not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  /// Creates a not found failure for a task.
  const NotFoundFailure.task()
    : super(message: 'Task not found. It may have been deleted.');

  /// Creates a not found failure for a project.
  const NotFoundFailure.project()
    : super(message: 'Project not found. It may have been deleted.');

  /// Creates a not found failure for a label.
  const NotFoundFailure.label()
    : super(message: 'Label not found. It may have been deleted.');
}

/// Failure during database operations.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  /// Creates a database failure with a generic message.
  factory DatabaseFailure.generic({Object? error, StackTrace? stackTrace}) =>
      DatabaseFailure(
        message: 'Unable to save changes. Please try again.',
        error: error,
        stackTrace: stackTrace,
      );

  /// Creates a failure for database read errors.
  factory DatabaseFailure.read({Object? error, StackTrace? stackTrace}) =>
      DatabaseFailure(
        message: 'Unable to load data. Please try again.',
        error: error,
        stackTrace: stackTrace,
      );

  /// Creates a failure for database write errors.
  factory DatabaseFailure.write({Object? error, StackTrace? stackTrace}) =>
      DatabaseFailure(
        message: 'Unable to save changes. Please try again.',
        error: error,
        stackTrace: stackTrace,
      );

  /// Creates a failure for delete operations.
  factory DatabaseFailure.delete({Object? error, StackTrace? stackTrace}) =>
      DatabaseFailure(
        message: 'Unable to delete. Please try again.',
        error: error,
        stackTrace: stackTrace,
      );
}

/// Failure during network operations.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  /// Creates a network failure for connection issues.
  factory NetworkFailure.noConnection({
    Object? error,
    StackTrace? stackTrace,
  }) => NetworkFailure(
    message: 'No internet connection. Please check your network.',
    error: error,
    stackTrace: stackTrace,
  );

  /// Creates a network failure for server errors.
  factory NetworkFailure.serverError({Object? error, StackTrace? stackTrace}) =>
      NetworkFailure(
        message: 'Server error. Please try again later.',
        error: error,
        stackTrace: stackTrace,
      );

  /// Creates a network failure for sync issues.
  factory NetworkFailure.syncError({Object? error, StackTrace? stackTrace}) =>
      NetworkFailure(
        message: 'Sync failed. Changes saved locally.',
        error: error,
        stackTrace: stackTrace,
      );
}

/// Failure for validation errors.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.error,
    super.stackTrace,
  });

  /// Creates a validation failure for required fields.
  const ValidationFailure.required(String fieldName)
    : super(message: '$fieldName is required.');

  /// Creates a validation failure for invalid data.
  const ValidationFailure.invalid(String message) : super(message: message);
}

/// Failure for unexpected/unknown errors.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Something went wrong. Please try again.',
    super.error,
    super.stackTrace,
  });
}

/// Extension to easily create failures with logging.
extension ResultExtensions<T> on Result<T> {
  /// Logs the failure (if any) and returns the result unchanged.
  Result<T> logFailure({String? name}) {
    if (this case Failure$(:final failure)) {
      failure.log(name: name);
    }
    return this;
  }
}
