import 'dart:async';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
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

    if (error is SqliteException) {
      return StorageFailure(message: error.message, cause: error);
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

    if (error is SocketException) {
      return NetworkFailure(message: error.message, cause: error);
    }

    return UnknownFailure(cause: error);
  }
}
