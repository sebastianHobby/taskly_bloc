import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_data/repository_exceptions.dart';

void main() {
  group('RepositoryException', () {
    test('creates with message only', () {
      final exception = RepositoryException('test error');

      expect(exception.message, 'test error');
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates with message and cause', () {
      final cause = Exception('underlying error');
      final exception = RepositoryException('test error', cause);

      expect(exception.message, 'test error');
      expect(exception.cause, cause);
      expect(exception.stackTrace, isNull);
    });

    test('creates with message, cause, and stackTrace', () {
      final cause = Exception('underlying');
      final stackTrace = StackTrace.current;
      final exception = RepositoryException('error', cause, stackTrace);

      expect(exception.message, 'error');
      expect(exception.cause, cause);
      expect(exception.stackTrace, stackTrace);
    });

    group('toString', () {
      test('returns message without cause', () {
        final exception = RepositoryException('connection failed');

        expect(exception.toString(), 'RepositoryException: connection failed');
      });

      test('returns message with cause', () {
        final cause = Exception('timeout');
        final exception = RepositoryException('connection failed', cause);

        expect(
          exception.toString(),
          'RepositoryException: connection failed (cause: Exception: timeout)',
        );
      });
    });

    test('is an Exception', () {
      final exception = RepositoryException('test');

      expect(exception, isA<Exception>());
    });
  });

  group('RepositoryNotFoundException', () {
    test('creates with message only', () {
      final exception = RepositoryNotFoundException('not found');

      expect(exception.message, 'not found');
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates with all parameters', () {
      final cause = Exception('db lookup failed');
      final stackTrace = StackTrace.current;
      final exception = RepositoryNotFoundException(
        'not found',
        cause,
        stackTrace,
      );

      expect(exception.message, 'not found');
      expect(exception.cause, cause);
      expect(exception.stackTrace, stackTrace);
    });

    test('is a RepositoryException', () {
      final exception = RepositoryNotFoundException('not found');

      expect(exception, isA<RepositoryException>());
    });

    test('is an Exception', () {
      final exception = RepositoryNotFoundException('not found');

      expect(exception, isA<Exception>());
    });

    test('toString includes cause', () {
      final cause = Exception('database error');
      final exception = RepositoryNotFoundException('Entity not found', cause);

      expect(
        exception.toString(),
        contains('Entity not found'),
      );
      expect(
        exception.toString(),
        contains('database error'),
      );
    });
  });
}
