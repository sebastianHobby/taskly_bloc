import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';

// Test implementation of the mixin
class TestFormSubmission with FormSubmissionMixin {}

void main() {
  late TestFormSubmission formSubmission;

  setUp(() {
    formSubmission = TestFormSubmission();
  });

  group('FormSubmissionMixin', () {
    group('validateAndGetFormValues', () {
      testWidgets('returns null when form key has no current state', (
        tester,
      ) async {
        final formKey = GlobalKey<FormBuilderState>();

        final result = formSubmission.validateAndGetFormValues(formKey);

        expect(result, isNull);
      });

      testWidgets('returns null when form validation fails', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FormBuilder(
                key: formKey,
                child: FormBuilderTextField(
                  name: 'email',
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
            ),
          ),
        );

        final result = formSubmission.validateAndGetFormValues(formKey);

        expect(result, isNull);
      });

      testWidgets('returns form values when validation succeeds', (
        tester,
      ) async {
        final formKey = GlobalKey<FormBuilderState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FormBuilder(
                key: formKey,
                child: FormBuilderTextField(
                  name: 'email',
                  initialValue: 'test@example.com',
                ),
              ),
            ),
          ),
        );

        final result = formSubmission.validateAndGetFormValues(formKey);

        expect(result, isNotNull);
        expect(result?['email'], equals('test@example.com'));
      });
    });

    group('extractStringValue', () {
      test('returns value when key exists', () {
        final formValues = {'name': 'John Doe'};

        final result = formSubmission.extractStringValue(formValues, 'name');

        expect(result, equals('John Doe'));
      });

      test('returns default value when key does not exist', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractStringValue(
          formValues,
          'name',
          defaultValue: 'Unknown',
        );

        expect(result, equals('Unknown'));
      });

      test('returns default value when value is null', () {
        final formValues = {'name': null};

        final result = formSubmission.extractStringValue(
          formValues,
          'name',
          defaultValue: 'Unknown',
        );

        expect(result, equals('Unknown'));
      });

      test('returns empty string as default when no default provided', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractStringValue(formValues, 'name');

        expect(result, equals(''));
      });
    });

    group('extractNullableStringValue', () {
      test('returns value when key exists and is not empty', () {
        final formValues = {'description': 'Task description'};

        final result = formSubmission.extractNullableStringValue(
          formValues,
          'description',
        );

        expect(result, equals('Task description'));
      });

      test('returns null when key does not exist', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractNullableStringValue(
          formValues,
          'description',
        );

        expect(result, isNull);
      });

      test('returns null when value is null', () {
        final formValues = {'description': null};

        final result = formSubmission.extractNullableStringValue(
          formValues,
          'description',
        );

        expect(result, isNull);
      });

      test('returns null when value is empty string', () {
        final formValues = {'description': ''};

        final result = formSubmission.extractNullableStringValue(
          formValues,
          'description',
        );

        expect(result, isNull);
      });

      test('returns null when value is whitespace only', () {
        final formValues = {'description': '   '};

        final result = formSubmission.extractNullableStringValue(
          formValues,
          'description',
        );

        expect(result, isNull);
      });

      test('trims whitespace from value', () {
        final formValues = {'description': '  Task description  '};

        final result = formSubmission.extractNullableStringValue(
          formValues,
          'description',
        );

        expect(result, equals('Task description'));
      });
    });

    group('extractBoolValue', () {
      test('returns value when key exists', () {
        final formValues = {'completed': true};

        final result = formSubmission.extractBoolValue(formValues, 'completed');

        expect(result, isTrue);
      });

      test('returns default value when key does not exist', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractBoolValue(
          formValues,
          'completed',
          defaultValue: true,
        );

        expect(result, isTrue);
      });

      test('returns default value when value is null', () {
        final formValues = {'completed': null};

        final result = formSubmission.extractBoolValue(
          formValues,
          'completed',
          defaultValue: true,
        );

        expect(result, isTrue);
      });

      test('returns false as default when no default provided', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractBoolValue(formValues, 'completed');

        expect(result, isFalse);
      });
    });

    group('extractDateTimeValue', () {
      test('returns value when key exists', () {
        final now = DateTime.now();
        final formValues = {'deadline': now};

        final result = formSubmission.extractDateTimeValue(
          formValues,
          'deadline',
        );

        expect(result, equals(now));
      });

      test('returns null when key does not exist', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractDateTimeValue(
          formValues,
          'deadline',
        );

        expect(result, isNull);
      });

      test('returns null when value is null', () {
        final formValues = {'deadline': null};

        final result = formSubmission.extractDateTimeValue(
          formValues,
          'deadline',
        );

        expect(result, isNull);
      });
    });

    group('extractStringListValue', () {
      test('returns list when key exists', () {
        final formValues = {
          'labels': ['label1', 'label2', 'label3'],
        };

        final result = formSubmission.extractStringListValue(
          formValues,
          'labels',
        );

        expect(result, equals(['label1', 'label2', 'label3']));
      });

      test('returns empty list when key does not exist', () {
        final formValues = <String, dynamic>{};

        final result = formSubmission.extractStringListValue(
          formValues,
          'labels',
        );

        expect(result, isEmpty);
      });

      test('returns empty list when value is null', () {
        final formValues = {'labels': null};

        final result = formSubmission.extractStringListValue(
          formValues,
          'labels',
        );

        expect(result, isEmpty);
      });

      test('casts dynamic list to string list', () {
        final formValues = {
          'labels': <dynamic>['label1', 'label2'],
        };

        final result = formSubmission.extractStringListValue(
          formValues,
          'labels',
        );

        expect(result, isA<List<String>>());
        expect(result, equals(['label1', 'label2']));
      });
    });
  });
}
