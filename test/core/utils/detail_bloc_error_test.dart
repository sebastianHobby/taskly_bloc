import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';

void main() {
  group('DetailBlocError', () {
    group('constructor', () {
      test('creates with error only', () {
        final error = DetailBlocError<String>(error: 'test error');

        expect(error.error, 'test error');
        expect(error.stackTrace, isNull);
      });

      test('creates with error and stackTrace', () {
        final stack = StackTrace.current;
        final error = DetailBlocError<int>(
          error: Exception('test'),
          stackTrace: stack,
        );

        expect(error.error, isA<Exception>());
        expect(error.stackTrace, stack);
      });
    });

    group('equality', () {
      test('equal errors are equal', () {
        final error1 = DetailBlocError<String>(error: 'same error');
        final error2 = DetailBlocError<String>(error: 'same error');

        expect(error1, error2);
        expect(error1.hashCode, error2.hashCode);
      });

      test('different errors are not equal', () {
        final error1 = DetailBlocError<String>(error: 'error 1');
        final error2 = DetailBlocError<String>(error: 'error 2');

        expect(error1, isNot(error2));
      });

      test('same error with different stackTrace are not equal', () {
        final stack1 = StackTrace.current;
        final stack2 = StackTrace.fromString('different');

        final error1 = DetailBlocError<String>(
          error: 'same',
          stackTrace: stack1,
        );
        final error2 = DetailBlocError<String>(
          error: 'same',
          stackTrace: stack2,
        );

        expect(error1, isNot(error2));
      });

      test('identical returns true for same instance', () {
        final error = DetailBlocError<String>(error: 'test');

        expect(error == error, true);
      });
    });

    group('toString', () {
      test('returns formatted string without stackTrace', () {
        final error = DetailBlocError<String>(error: 'my error');

        expect(
          error.toString(),
          'DetailBlocError<String>{error: my error, stackTrace: null}',
        );
      });

      test('returns formatted string with stackTrace', () {
        final stack = StackTrace.fromString('test stack');
        final error = DetailBlocError<int>(
          error: 'error msg',
          stackTrace: stack,
        );

        expect(
          error.toString(),
          contains('DetailBlocError<int>{error: error msg, stackTrace:'),
        );
      });
    });
  });
}
