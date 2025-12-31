import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, LabelOperator, RelativeComparison;

void main() {
  group('ProjectPredicate', () {
    group('fromJson', () {
      test('parses bool predicate', () {
        final json = <String, dynamic>{
          'type': 'bool',
          'field': 'completed',
          'operator': 'isTrue',
        };

        final predicate = ProjectPredicate.fromJson(json);

        expect(predicate, isA<ProjectBoolPredicate>());
        final boolPredicate = predicate as ProjectBoolPredicate;
        expect(boolPredicate.field, ProjectBoolField.completed);
        expect(boolPredicate.operator, BoolOperator.isTrue);
      });

      test('parses date predicate', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'before',
          'date': '2025-06-20T00:00:00.000',
        };

        final predicate = ProjectPredicate.fromJson(json);

        expect(predicate, isA<ProjectDatePredicate>());
        final datePredicate = predicate as ProjectDatePredicate;
        expect(datePredicate.field, ProjectDateField.deadlineDate);
        expect(datePredicate.operator, DateOperator.before);
        expect(datePredicate.date, DateTime(2025, 6, 20));
      });

      test('parses label predicate', () {
        final json = <String, dynamic>{
          'type': 'label',
          'operator': 'hasAny',
          'labelType': 'label',
          'labelIds': ['id-1', 'id-2'],
        };

        final predicate = ProjectPredicate.fromJson(json);

        expect(predicate, isA<ProjectLabelPredicate>());
        final labelPredicate = predicate as ProjectLabelPredicate;
        expect(labelPredicate.operator, LabelOperator.hasAny);
        expect(labelPredicate.labelType, LabelType.label);
        expect(labelPredicate.labelIds, ['id-1', 'id-2']);
      });

      test('throws for unknown type', () {
        final json = <String, dynamic>{
          'type': 'unknown',
        };

        expect(
          () => ProjectPredicate.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });

  group('ProjectBoolPredicate', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = <String, dynamic>{
          'type': 'bool',
          'field': 'completed',
          'operator': 'isTrue',
        };

        final predicate = ProjectBoolPredicate.fromJson(json);

        expect(predicate.field, ProjectBoolField.completed);
        expect(predicate.operator, BoolOperator.isTrue);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'bool'};

        final predicate = ProjectBoolPredicate.fromJson(json);

        expect(predicate.field, ProjectBoolField.completed);
        expect(predicate.operator, BoolOperator.isFalse);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        final json = predicate.toJson();

        expect(json['type'], 'bool');
        expect(json['field'], 'completed');
        expect(json['operator'], 'isTrue');
      });
    });

    group('equality', () {
      test('equal predicates are equal', () {
        const predicate1 = ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        const predicate2 = ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('different field makes predicates unequal', () {
        const predicate1 = ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        const predicate2 = ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isFalse,
        );

        expect(predicate1, isNot(predicate2));
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        const original = ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        final json = original.toJson();
        final restored = ProjectBoolPredicate.fromJson(json);

        expect(restored, original);
      });
    });
  });

  group('ProjectDatePredicate', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'between',
          'date': '2025-06-15T00:00:00.000',
          'startDate': '2025-06-10T00:00:00.000',
          'endDate': '2025-06-20T00:00:00.000',
          'relativeComparison': 'on',
          'relativeDays': 5,
        };

        final predicate = ProjectDatePredicate.fromJson(json);

        expect(predicate.field, ProjectDateField.deadlineDate);
        expect(predicate.operator, DateOperator.between);
        expect(predicate.date, DateTime(2025, 6, 15));
        expect(predicate.startDate, DateTime(2025, 6, 10));
        expect(predicate.endDate, DateTime(2025, 6, 20));
        expect(predicate.relativeComparison, RelativeComparison.on);
        expect(predicate.relativeDays, 5);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'date'};

        final predicate = ProjectDatePredicate.fromJson(json);

        expect(predicate.field, ProjectDateField.createdAt);
        expect(predicate.operator, DateOperator.isNotNull);
        expect(predicate.date, isNull);
        expect(predicate.startDate, isNull);
        expect(predicate.endDate, isNull);
        expect(predicate.relativeComparison, isNull);
        expect(predicate.relativeDays, isNull);
      });

      test('handles null date strings gracefully', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'startDate',
          'operator': 'isNull',
          'date': null,
        };

        final predicate = ProjectDatePredicate.fromJson(json);

        expect(predicate.date, isNull);
      });

      test('parses relative date predicate', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'relative',
          'relativeComparison': 'before',
          'relativeDays': 7,
        };

        final predicate = ProjectDatePredicate.fromJson(json);

        expect(predicate.operator, DateOperator.relative);
        expect(predicate.relativeComparison, RelativeComparison.before);
        expect(predicate.relativeDays, 7);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final predicate = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.between,
          date: DateTime(2025, 6, 15),
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
          relativeComparison: RelativeComparison.on,
          relativeDays: 5,
        );

        final json = predicate.toJson();

        expect(json['type'], 'date');
        expect(json['field'], 'deadlineDate');
        expect(json['operator'], 'between');
        expect(json['date'], '2025-06-15T00:00:00.000');
        expect(json['startDate'], '2025-06-10T00:00:00.000');
        expect(json['endDate'], '2025-06-20T00:00:00.000');
        expect(json['relativeComparison'], 'on');
        expect(json['relativeDays'], 5);
      });

      test('serializes null optional fields as null', () {
        const predicate = ProjectDatePredicate(
          field: ProjectDateField.startDate,
          operator: DateOperator.isNull,
        );

        final json = predicate.toJson();

        expect(json['date'], isNull);
        expect(json['startDate'], isNull);
        expect(json['endDate'], isNull);
        expect(json['relativeComparison'], isNull);
        expect(json['relativeDays'], isNull);
      });
    });

    group('equality', () {
      test('equal predicates are equal', () {
        final predicate1 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final predicate2 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('different dates make predicates unequal', () {
        final predicate1 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final predicate2 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 16),
        );

        expect(predicate1, isNot(predicate2));
      });

      test('handles null dates in equality', () {
        const predicate1 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.isNull,
        );
        const predicate2 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.isNull,
        );

        expect(predicate1, predicate2);
      });

      test('dates at same moment are equal', () {
        final predicate1 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15, 10, 30, 45, 123),
        );
        final predicate2 = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15, 10, 30, 45, 123),
        );

        expect(predicate1, predicate2);
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        final original = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );

        final json = original.toJson();
        final restored = ProjectDatePredicate.fromJson(json);

        expect(restored.field, original.field);
        expect(restored.operator, original.operator);
        expect(restored.startDate, original.startDate);
        expect(restored.endDate, original.endDate);
      });

      test('round-trips relative predicate', () {
        const original = ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.before,
          relativeDays: 7,
        );

        final json = original.toJson();
        final restored = ProjectDatePredicate.fromJson(json);

        expect(restored.operator, original.operator);
        expect(restored.relativeComparison, original.relativeComparison);
        expect(restored.relativeDays, original.relativeDays);
      });
    });
  });

  group('ProjectLabelPredicate', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = <String, dynamic>{
          'type': 'label',
          'operator': 'hasAll',
          'labelType': 'value',
          'labelIds': ['id-1', 'id-2', 'id-3'],
        };

        final predicate = ProjectLabelPredicate.fromJson(json);

        expect(predicate.operator, LabelOperator.hasAll);
        expect(predicate.labelType, LabelType.value);
        expect(predicate.labelIds, ['id-1', 'id-2', 'id-3']);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'label'};

        final predicate = ProjectLabelPredicate.fromJson(json);

        expect(predicate.operator, LabelOperator.hasAny);
        expect(predicate.labelType, LabelType.label);
        expect(predicate.labelIds, isEmpty);
      });

      test('filters non-string labelIds', () {
        final json = <String, dynamic>{
          'type': 'label',
          'operator': 'hasAny',
          'labelType': 'label',
          'labelIds': ['id-1', 123, 'id-2', null, 'id-3'],
        };

        final predicate = ProjectLabelPredicate.fromJson(json);

        expect(predicate.labelIds, ['id-1', 'id-2', 'id-3']);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = ProjectLabelPredicate(
          operator: LabelOperator.hasAll,
          labelType: LabelType.value,
          labelIds: ['id-1', 'id-2'],
        );

        final json = predicate.toJson();

        expect(json['type'], 'label');
        expect(json['operator'], 'hasAll');
        expect(json['labelType'], 'value');
        expect(json['labelIds'], ['id-1', 'id-2']);
      });

      test('serializes empty labelIds', () {
        const predicate = ProjectLabelPredicate(
          operator: LabelOperator.isNull,
          labelType: LabelType.label,
        );

        final json = predicate.toJson();

        expect(json['labelIds'], isEmpty);
      });
    });

    group('equality', () {
      test('equal predicates are equal', () {
        const predicate1 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );
        const predicate2 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('different labelIds make predicates unequal', () {
        const predicate1 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );
        const predicate2 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-3'],
        );

        expect(predicate1, isNot(predicate2));
      });

      test('different order of labelIds makes predicates unequal', () {
        const predicate1 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );
        const predicate2 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-2', 'id-1'],
        );

        expect(predicate1, isNot(predicate2));
      });

      test('different labelType makes predicates unequal', () {
        const predicate1 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1'],
        );
        const predicate2 = ProjectLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.value,
          labelIds: ['id-1'],
        );

        expect(predicate1, isNot(predicate2));
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        const original = ProjectLabelPredicate(
          operator: LabelOperator.hasAll,
          labelType: LabelType.value,
          labelIds: ['id-1', 'id-2', 'id-3'],
        );

        final json = original.toJson();
        final restored = ProjectLabelPredicate.fromJson(json);

        expect(restored, original);
      });
    });
  });
}
