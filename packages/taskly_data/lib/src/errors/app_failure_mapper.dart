import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_domain/errors.dart';

/// Maps implementation-layer exceptions into domain [AppFailure] types.
abstract final class AppFailureMapper {
  static AppFailure fromException(Object error) {
    if (error is AppFailure) return error;

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
