@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'dart:async' as async;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_data/src/errors/app_failure_mapper.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_domain/errors.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AppFailureMapper', () {
    testSafe('passes through AppFailure', () async {
      const failure = NotFoundFailure(message: 'x');
      final mapped = AppFailureMapper.fromException(failure);
      expect(identical(mapped, failure), isTrue);
    });

    testSafe('maps repository validation to InputValidationFailure', () async {
      final mapped = AppFailureMapper.fromException(
        RepositoryValidationException('bad input'),
      );
      expect(mapped, isA<InputValidationFailure>());
      expect(mapped.message, contains('bad input'));
    });

    testSafe('maps repository not found to NotFoundFailure', () async {
      final mapped = AppFailureMapper.fromException(
        RepositoryNotFoundException('missing'),
      );
      expect(mapped, isA<NotFoundFailure>());
      expect(mapped.message, contains('missing'));
    });

    testSafe('maps repository exception to StorageFailure', () async {
      final mapped = AppFailureMapper.fromException(
        RepositoryException('write failed'),
      );
      expect(mapped, isA<StorageFailure>());
      expect(mapped.message, contains('write failed'));
    });

    testSafe('maps TimeoutException to TimeoutFailure', () async {
      final mapped = AppFailureMapper.fromException(
        async.TimeoutException('slow'),
      );
      expect(mapped, isA<TimeoutFailure>());
      expect(mapped.message, contains('slow'));
    });

    testSafe('maps SocketException to NetworkFailure', () async {
      final mapped = AppFailureMapper.fromException(
        const SocketException('offline'),
      );
      expect(mapped, isA<NetworkFailure>());
      expect(mapped.message, contains('offline'));
    });

    testSafe('maps SqliteException-like errors to StorageFailure', () async {
      final error = SqliteException('disk I/O error');

      final failure = AppFailureMapper.fromException(error);

      expect(failure, isA<StorageFailure>());
      expect(failure.message, contains('disk I/O error'));
    });

    testSafe('maps AuthException 401 to UnauthorizedFailure', () async {
      final mapped = AppFailureMapper.fromException(
        AuthException('unauthorized', statusCode: '401'),
      );
      expect(mapped, isA<UnauthorizedFailure>());
      expect(mapped.message, contains('unauthorized'));
    });

    testSafe('maps AuthException 403 to ForbiddenFailure', () async {
      final mapped = AppFailureMapper.fromException(
        AuthException('forbidden', statusCode: '403'),
      );
      expect(mapped, isA<ForbiddenFailure>());
      expect(mapped.message, contains('forbidden'));
    });

    testSafe('maps AuthException 429 to RateLimitedFailure', () async {
      final mapped = AppFailureMapper.fromException(
        AuthException('rate limited', statusCode: '429'),
      );
      expect(mapped, isA<RateLimitedFailure>());
      expect(mapped.message, contains('rate limited'));
    });

    testSafe('maps PostgrestException to NetworkFailure', () async {
      final mapped = AppFailureMapper.fromException(
        const PostgrestException(message: 'bad request', code: '400'),
      );
      expect(mapped, isA<NetworkFailure>());
      expect(mapped.message, contains('bad request'));
    });

    testSafe('maps PostgrestException 42501 to ForbiddenFailure', () async {
      final mapped = AppFailureMapper.fromException(
        const PostgrestException(message: 'rls denied', code: '42501'),
      );
      expect(mapped, isA<ForbiddenFailure>());
      expect(mapped.message, contains('rls denied'));
    });

    testSafe('falls back to UnknownFailure', () async {
      final mapped = AppFailureMapper.fromException(StateError('boom'));
      expect(mapped, isA<UnknownFailure>());
    });
  });
}

class SqliteException {
  SqliteException(this.message);

  final String message;

  @override
  String toString() => 'SqliteException($message)';
}
