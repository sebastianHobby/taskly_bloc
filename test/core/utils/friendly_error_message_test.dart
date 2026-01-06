import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/l10n/gen/app_localizations.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

class MockAppLocalizations extends Mock implements AppLocalizations {}

void main() {
  group('friendlyErrorMessage', () {
    test('returns message for RepositoryException', () {
      final error = RepositoryException('Database connection failed');

      final result = friendlyErrorMessage(error);

      expect(result, 'Database connection failed');
    });

    test('returns message for RepositoryNotFoundException', () {
      final error = RepositoryNotFoundException('Task not found');

      final result = friendlyErrorMessage(error);

      expect(result, 'Task not found');
    });

    test('returns generic message for unknown error', () {
      final error = Exception('Something unexpected');

      final result = friendlyErrorMessage(error);

      expect(result, 'Something went wrong. Please try again.');
    });

    test('returns generic message for string error', () {
      const error = 'Raw error message';

      final result = friendlyErrorMessage(error);

      expect(result, 'Something went wrong. Please try again.');
    });

    test('returns generic message for FormatException', () {
      final error = FormatException('Invalid data');

      final result = friendlyErrorMessage(error);

      expect(result, 'Something went wrong. Please try again.');
    });
  });

  group('friendlyErrorMessageForUi', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();
      when(() => mockL10n.taskNotFound).thenReturn('Task not found');
      when(() => mockL10n.projectNotFound).thenReturn('Project not found');
      when(() => mockL10n.labelNotFound).thenReturn('Label not found');
      when(() => mockL10n.genericErrorFallback).thenReturn('An error occurred');
    });

    test('returns error string when error is String', () {
      const error = 'Direct error message';

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'Direct error message');
    });

    test('returns localized message for NotFoundEntity.task', () {
      const error = NotFoundEntity.task;

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'Task not found');
      verify(() => mockL10n.taskNotFound).called(1);
    });

    test('returns localized message for NotFoundEntity.project', () {
      const error = NotFoundEntity.project;

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'Project not found');
      verify(() => mockL10n.projectNotFound).called(1);
    });

    test('returns localized message for NotFoundEntity.value', () {
      const error = NotFoundEntity.value;

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'Value not found');
      verify(() => mockL10n.valueNotFound).called(1);
    });

    test('returns message for RepositoryException', () {
      final error = RepositoryException('Custom repository error');

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'Custom repository error');
    });

    test('returns fallback for unknown error type', () {
      final error = Exception('Unknown error');

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'An error occurred');
      verify(() => mockL10n.genericErrorFallback).called(1);
    });

    test('returns fallback for FormatException', () {
      final error = FormatException('Parse error');

      final result = friendlyErrorMessageForUi(error, mockL10n);

      expect(result, 'An error occurred');
      verify(() => mockL10n.genericErrorFallback).called(1);
    });
  });
}
