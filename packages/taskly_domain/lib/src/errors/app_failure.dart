import 'package:meta/meta.dart';

/// Domain-level failure taxonomy.
///
/// These are expected failures that can be handled by screens (e.g. validation,
/// auth, connectivity), plus an explicit [UnknownFailure] fallback.
@immutable
sealed class AppFailure implements Exception {
  const AppFailure({this.message, this.code, this.cause});

  /// Human-readable message (not necessarily localized).
  final String? message;

  /// Optional machine-readable code.
  final String? code;

  /// The original exception/error that caused this failure.
  final Object? cause;

  AppFailureKind get kind;

  /// Whether this failure should also be reported as an "unexpected" error.
  ///
  /// Use this for cases like [UnknownFailure] where we want global reporting.
  bool get reportAsUnexpected => false;

  /// A safe, concise message for UI when no localization is available.
  String uiMessage() {
    final m = message;
    if (m != null && m.trim().isNotEmpty) return m;

    return switch (kind) {
      AppFailureKind.auth => 'Authentication failed',
      AppFailureKind.unauthorized => 'You are not signed in',
      AppFailureKind.forbidden => 'You do not have permission',
      AppFailureKind.network => 'Network error. Please try again.',
      AppFailureKind.timeout => 'Request timed out. Please try again.',
      AppFailureKind.rateLimited => 'Too many requests. Try again later.',
      AppFailureKind.storage => 'Storage error. Please try again.',
      AppFailureKind.unknown => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() {
    return 'AppFailure(kind=$kind, code=$code, message=$message, cause=${cause?.runtimeType})';
  }
}

enum AppFailureKind {
  auth,
  unauthorized,
  forbidden,
  network,
  timeout,
  rateLimited,
  storage,
  unknown,
}

final class AuthFailure extends AppFailure {
  const AuthFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.auth;
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.unauthorized;
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.forbidden;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.network;
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.timeout;
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.rateLimited;
}

final class StorageFailure extends AppFailure {
  const StorageFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.storage;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({super.message, super.code, super.cause});

  @override
  AppFailureKind get kind => AppFailureKind.unknown;

  @override
  bool get reportAsUnexpected => true;
}
