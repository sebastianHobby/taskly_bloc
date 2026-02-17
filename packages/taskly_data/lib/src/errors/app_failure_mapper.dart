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

    if (error is RepositoryException) {
      return StorageFailure(message: error.message, cause: error);
    }

    if (_isSqliteException(error)) {
      return StorageFailure(message: _extractMessage(error), cause: error);
    }

    if (error is AuthException) {
      return _fromAuthException(error);
    }

    if (error is PostgrestException) {
      return _fromPostgrestException(error);
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

  static AppFailure _fromAuthException(AuthException error) {
    final status = _parseHttpStatus(error.statusCode);
    final code = _firstNonEmpty(error.statusCode, error.code);
    return switch (status) {
      401 => UnauthorizedFailure(
        message: error.message,
        code: code,
        cause: error,
      ),
      403 => ForbiddenFailure(message: error.message, code: code, cause: error),
      429 => RateLimitedFailure(
        message: error.message,
        code: code,
        cause: error,
      ),
      _ => AuthFailure(message: error.message, code: code, cause: error),
    };
  }

  static AppFailure _fromPostgrestException(PostgrestException error) {
    final code = error.code;
    final status = _parseHttpStatus(code);
    if (status == 401) {
      return UnauthorizedFailure(
        message: error.message,
        code: code,
        cause: error,
      );
    }
    if (status == 403 || code == '42501') {
      return ForbiddenFailure(message: error.message, code: code, cause: error);
    }
    if (status == 429) {
      return RateLimitedFailure(
        message: error.message,
        code: code,
        cause: error,
      );
    }

    // PostgREST failures are remote/API failures; keep them in the taxonomy so
    // presentation can handle them predictably.
    return NetworkFailure(message: error.message, code: code, cause: error);
  }

  static int? _parseHttpStatus(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;
    final match = RegExp(r'\b(401|403|429)\b').firstMatch(trimmed);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String? _firstNonEmpty(String? a, String? b) {
    final first = a?.trim();
    if (first != null && first.isNotEmpty) return first;
    final second = b?.trim();
    if (second != null && second.isNotEmpty) return second;
    return null;
  }
}
