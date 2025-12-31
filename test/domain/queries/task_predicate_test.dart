import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

void main() {
  group('TaskPredicate', () {
    group('fromJson', () {
      test('parses bool predicate', () {
        final json = <String, dynamic>{
          'type': 'bool',
          'field': 'completed',
          'operator': 'isTrue',
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskBoolPredicate>());
        final boolPredicate = predicate as TaskBoolPredicate;
        expect(boolPredicate.field, TaskBoolField.completed);
        expect(boolPredicate.operator, BoolOperator.isTrue);
      });

      test('parses date predicate', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'before',
          'date': '2025-06-20T00:00:00.000',
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskDatePredicate>());
        final datePredicate = predicate as TaskDatePredicate;
        expect(datePredicate.field, TaskDateField.deadlineDate);
        expect(datePredicate.operator, DateOperator.before);
        expect(datePredicate.date, DateTime(2025, 6, 20));
      });

      test('parses project predicate', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matches',
          'projectId': 'proj-1',
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskProjectPredicate>());
        final projectPredicate = predicate as TaskProjectPredicate;
        expect(projectPredicate.operator, ProjectOperator.matches);
        expect(projectPredicate.projectId, 'proj-1');
      });

      test('parses label predicate', () {
        final json = <String, dynamic>{
          'type': 'label',
          'operator': 'hasAny',
          'labelType': 'label',
          'labelIds': ['id-1', 'id-2'],
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskLabelPredicate>());
        final labelPredicate = predicate as TaskLabelPredicate;
        expect(labelPredicate.operator, LabelOperator.hasAny);
        expect(labelPredicate.labelType, LabelType.label);
        expect(labelPredicate.labelIds, ['id-1', 'id-2']);
      });

      test('throws for unknown type', () {
        final json = <String, dynamic>{
          'type': 'unknown',
        };

        expect(
          () => TaskPredicate.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });

  group('TaskBoolPredicate', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = <String, dynamic>{
          'type': 'bool',
          'field': 'completed',
          'operator': 'isTrue',
        };

        final predicate = TaskBoolPredicate.fromJson(json);

        expect(predicate.field, TaskBoolField.completed);
        expect(predicate.operator, BoolOperator.isTrue);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'bool'};

        final predicate = TaskBoolPredicate.fromJson(json);

        expect(predicate.field, TaskBoolField.completed);
        expect(predicate.operator, BoolOperator.isFalse);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = TaskBoolPredicate(
          field: TaskBoolField.completed,
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
        const predicate1 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        const predicate2 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('different operator makes predicates unequal', () {
        const predicate1 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        const predicate2 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        );

        expect(predicate1, isNot(predicate2));
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        const original = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        final json = original.toJson();
        final restored = TaskBoolPredicate.fromJson(json);

        expect(restored, original);
      });
    });
  });

  group('TaskDatePredicate', () {
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

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.field, TaskDateField.deadlineDate);
        expect(predicate.operator, DateOperator.between);
        expect(predicate.date, DateTime(2025, 6, 15));
        expect(predicate.startDate, DateTime(2025, 6, 10));
        expect(predicate.endDate, DateTime(2025, 6, 20));
        expect(predicate.relativeComparison, RelativeComparison.on);
        expect(predicate.relativeDays, 5);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'date'};

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.field, TaskDateField.createdAt);
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

        final predicate = TaskDatePredicate.fromJson(json);

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

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.operator, DateOperator.relative);
        expect(predicate.relativeComparison, RelativeComparison.before);
        expect(predicate.relativeDays, 7);
      });

      test('parses all date fields', () {
        for (final field in TaskDateField.values) {
          final json = <String, dynamic>{
            'type': 'date',
            'field': field.name,
            'operator': 'isNotNull',
          };

          final predicate = TaskDatePredicate.fromJson(json);

          expect(predicate.field, field);
        }
      });

      test('parses all date operators', () {
        for (final op in DateOperator.values) {
          final json = <String, dynamic>{
            'type': 'date',
            'field': 'startDate',
            'operator': op.name,
          };

          final predicate = TaskDatePredicate.fromJson(json);

          expect(predicate.operator, op);
        }
      });

      test('parses all relative comparisons', () {
        for (final comp in RelativeComparison.values) {
          final json = <String, dynamic>{
            'type': 'date',
            'field': 'deadlineDate',
            'operator': 'relative',
            'relativeComparison': comp.name,
            'relativeDays': 1,
          };

          final predicate = TaskDatePredicate.fromJson(json);

          expect(predicate.relativeComparison, comp);
        }
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final predicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
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
        const predicate = TaskDatePredicate(
          field: TaskDateField.startDate,
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
        final predicate1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final predicate2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('identical predicates are equal', () {
        final predicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );

        expect(predicate == predicate, isTrue);
      });

      test('different dates make predicates unequal', () {
        final predicate1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final predicate2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 16),
        );

        expect(predicate1, isNot(predicate2));
      });

      test('handles null dates in equality', () {
        const predicate1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.isNull,
        );
        const predicate2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.isNull,
        );

        expect(predicate1, predicate2);
      });

      test('null vs non-null date makes predicates unequal', () {
        const predicate1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.isNull,
        );
        final predicate2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.isNull,
          date: DateTime(2025, 6, 15),
        );

        expect(predicate1, isNot(predicate2));
      });

      test('dates at same moment are equal', () {
        final predicate1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15, 10, 30, 45, 123),
        );
        final predicate2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime(2025, 6, 15, 10, 30, 45, 123),
        );

        expect(predicate1, predicate2);
      });

      test('different relative settings make predicates unequal', () {
        const predicate1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.before,
          relativeDays: 7,
        );
        const predicate2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.after,
          relativeDays: 7,
        );

        expect(predicate1, isNot(predicate2));
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        final original = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );

        final json = original.toJson();
        final restored = TaskDatePredicate.fromJson(json);

        expect(restored.field, original.field);
        expect(restored.operator, original.operator);
        expect(restored.startDate, original.startDate);
        expect(restored.endDate, original.endDate);
      });

      test('round-trips relative predicate', () {
        const original = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.before,
          relativeDays: 7,
        );

        final json = original.toJson();
        final restored = TaskDatePredicate.fromJson(json);

        expect(restored.operator, original.operator);
        expect(restored.relativeComparison, original.relativeComparison);
        expect(restored.relativeDays, original.relativeDays);
      });
    });
  });

  group('TaskProjectPredicate', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matchesAny',
          'projectId': 'proj-1',
          'projectIds': ['proj-1', 'proj-2', 'proj-3'],
        };

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.operator, ProjectOperator.matchesAny);
        expect(predicate.projectId, 'proj-1');
        expect(predicate.projectIds, ['proj-1', 'proj-2', 'proj-3']);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'project'};

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.operator, ProjectOperator.isNotNull);
        expect(predicate.projectId, isNull);
        expect(predicate.projectIds, isEmpty);
      });

      test('filters non-string projectIds', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matchesAny',
          'projectIds': ['id-1', 123, 'id-2', null, 'id-3'],
        };

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.projectIds, ['id-1', 'id-2', 'id-3']);
      });

      test('parses all project operators', () {
        for (final op in ProjectOperator.values) {
          final json = <String, dynamic>{
            'type': 'project',
            'operator': op.name,
          };

          final predicate = TaskProjectPredicate.fromJson(json);

          expect(predicate.operator, op);
        }
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'proj-1',
          projectIds: ['proj-1', 'proj-2'],
        );

        final json = predicate.toJson();

        expect(json['type'], 'project');
        expect(json['operator'], 'matchesAny');
        expect(json['projectId'], 'proj-1');
        expect(json['projectIds'], ['proj-1', 'proj-2']);
      });

      test('serializes empty projectIds', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.isNull,
        );

        final json = predicate.toJson();

        expect(json['projectIds'], isEmpty);
      });
    });

    group('equality', () {
      test('equal predicates are equal', () {
        const predicate1 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'proj-1',
          projectIds: ['proj-1', 'proj-2'],
        );
        const predicate2 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'proj-1',
          projectIds: ['proj-1', 'proj-2'],
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('different projectIds make predicates unequal', () {
        const predicate1 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['proj-1', 'proj-2'],
        );
        const predicate2 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['proj-1', 'proj-3'],
        );

        expect(predicate1, isNot(predicate2));
      });

      test('different order of projectIds makes predicates unequal', () {
        const predicate1 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['proj-1', 'proj-2'],
        );
        const predicate2 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['proj-2', 'proj-1'],
        );

        expect(predicate1, isNot(predicate2));
      });

      test('different operator makes predicates unequal', () {
        const predicate1 = TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: 'proj-1',
        );
        const predicate2 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'proj-1',
        );

        expect(predicate1, isNot(predicate2));
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        const original = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'proj-1',
          projectIds: ['proj-1', 'proj-2', 'proj-3'],
        );

        final json = original.toJson();
        final restored = TaskProjectPredicate.fromJson(json);

        expect(restored, original);
      });
    });
  });

  group('TaskLabelPredicate', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = <String, dynamic>{
          'type': 'label',
          'operator': 'hasAll',
          'labelType': 'value',
          'labelIds': ['id-1', 'id-2', 'id-3'],
        };

        final predicate = TaskLabelPredicate.fromJson(json);

        expect(predicate.operator, LabelOperator.hasAll);
        expect(predicate.labelType, LabelType.value);
        expect(predicate.labelIds, ['id-1', 'id-2', 'id-3']);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'label'};

        final predicate = TaskLabelPredicate.fromJson(json);

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

        final predicate = TaskLabelPredicate.fromJson(json);

        expect(predicate.labelIds, ['id-1', 'id-2', 'id-3']);
      });

      test('parses all label operators', () {
        for (final op in LabelOperator.values) {
          final json = <String, dynamic>{
            'type': 'label',
            'operator': op.name,
            'labelType': 'label',
          };

          final predicate = TaskLabelPredicate.fromJson(json);

          expect(predicate.operator, op);
        }
      });

      test('parses all label types', () {
        for (final type in LabelType.values) {
          final json = <String, dynamic>{
            'type': 'label',
            'operator': 'hasAny',
            'labelType': type.name,
          };

          final predicate = TaskLabelPredicate.fromJson(json);

          expect(predicate.labelType, type);
        }
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = TaskLabelPredicate(
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
        const predicate = TaskLabelPredicate(
          operator: LabelOperator.isNull,
          labelType: LabelType.label,
        );

        final json = predicate.toJson();

        expect(json['labelIds'], isEmpty);
      });
    });

    group('equality', () {
      test('equal predicates are equal', () {
        const predicate1 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );
        const predicate2 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );

        expect(predicate1, predicate2);
        expect(predicate1.hashCode, predicate2.hashCode);
      });

      test('different labelIds make predicates unequal', () {
        const predicate1 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );
        const predicate2 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-3'],
        );

        expect(predicate1, isNot(predicate2));
      });

      test('different order of labelIds makes predicates unequal', () {
        const predicate1 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1', 'id-2'],
        );
        const predicate2 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-2', 'id-1'],
        );

        expect(predicate1, isNot(predicate2));
      });

      test('different labelType makes predicates unequal', () {
        const predicate1 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.label,
          labelIds: ['id-1'],
        );
        const predicate2 = TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelType: LabelType.value,
          labelIds: ['id-1'],
        );

        expect(predicate1, isNot(predicate2));
      });
    });

    group('round-trip', () {
      test('serializes and deserializes correctly', () {
        const original = TaskLabelPredicate(
          operator: LabelOperator.hasAll,
          labelType: LabelType.value,
          labelIds: ['id-1', 'id-2', 'id-3'],
        );

        final json = original.toJson();
        final restored = TaskLabelPredicate.fromJson(json);

        expect(restored, original);
      });
    });
  });
}
