import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_domain/errors.dart';

import 'package:taskly_data/src/repositories/repository_exceptions.dart';

/// Maps implementation-layer exceptions into domain [AppFailure] types.
abstract final class AppFailureMapper {
  static AppFailure fromException(Object error) {
    if (error is AppFailure) return error;

    if (error is RepositoryValidationException) {
      return InputValidationFailure(message: error.message, cause: error);
    }

    if (error is RepositoryNotFoundException) {
      return NotFoundFailure(message: error.message, cause: error);
    }

    if (_isSqliteException(error)) {
      return StorageFailure(message: _extractMessage(error), cause: error);
    }

    if (error is AuthException) {
      return AuthFailure(
        message: error.message,
        code: error.statusCode?.toString(),
        cause: error,
      );
    }

    if (error is PostgrestException) {
      // PostgREST failures are remote/API failures; keep them in the taxonomy so
      // presentation can handle them predictably.
      return NetworkFailure(
        message: error.message,
        code: error.code,
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return TimeoutFailure(message: error.message, cause: error);
    }

    if (_isSocketException(error)) {
      return NetworkFailure(message: _extractMessage(error), cause: error);
    }

    return UnknownFailure(cause: error);
  }

  static bool _isSqliteException(Object error) {
    return error.runtimeType.toString() == 'SqliteException';
  }

  static bool _isSocketException(Object error) {
    return error.runtimeType.toString() == 'SocketException';
  }

  static String _extractMessage(Object error) {
    try {
      final dynamicError = error as dynamic;
      final message = dynamicError.message;
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // Ignore: best-effort extraction without importing platform-only types.
    }

    return error.toString();
  }
}
