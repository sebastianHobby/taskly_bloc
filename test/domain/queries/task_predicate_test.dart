import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

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
        final boolPred = predicate as TaskBoolPredicate;
        expect(boolPred.field, TaskBoolField.completed);
        expect(boolPred.operator, BoolOperator.isTrue);
      });

      test('parses date predicate', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'onOrBefore',
          'date': '2025-06-15T00:00:00.000Z',
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskDatePredicate>());
        final datePred = predicate as TaskDatePredicate;
        expect(datePred.field, TaskDateField.deadlineDate);
        expect(datePred.operator, DateOperator.onOrBefore);
        expect(datePred.date, isNotNull);
      });

      test('parses project predicate', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matches',
          'projectId': 'project-1',
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskProjectPredicate>());
        final projPred = predicate as TaskProjectPredicate;
        expect(projPred.operator, ProjectOperator.matches);
        expect(projPred.projectId, 'project-1');
      });

      test('parses value predicate', () {
        final json = <String, dynamic>{
          'type': 'value',
          'operator': 'hasAny',
          'valueIds': ['value-1', 'value-2'],
          'includeInherited': true,
        };

        final predicate = TaskPredicate.fromJson(json);

        expect(predicate, isA<TaskValuePredicate>());
        final valuePred = predicate as TaskValuePredicate;
        expect(valuePred.operator, ValueOperator.hasAny);
        expect(valuePred.valueIds, ['value-1', 'value-2']);
        expect(valuePred.includeInherited, isTrue);
      });

      test('throws for unknown type', () {
        final json = <String, dynamic>{'type': 'unknown'};

        expect(
          () => TaskPredicate.fromJson(json),
          throwsArgumentError,
        );
      });

      test('throws for null type', () {
        final json = <String, dynamic>{'field': 'completed'};

        expect(
          () => TaskPredicate.fromJson(json),
          throwsArgumentError,
        );
      });
    });
  });

  group('TaskBoolPredicate', () {
    group('construction', () {
      test('creates with required fields', () {
        const predicate = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        expect(predicate.field, TaskBoolField.completed);
        expect(predicate.operator, BoolOperator.isTrue);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'type': 'bool',
          'field': 'completed',
          'operator': 'isFalse',
        };

        final predicate = TaskBoolPredicate.fromJson(json);

        expect(predicate.field, TaskBoolField.completed);
        expect(predicate.operator, BoolOperator.isFalse);
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
      test('equal when all fields match', () {
        const pred1 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        const pred2 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when field differs', () {
        const pred1 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        // Only one bool field exists, so we test operator difference
        const pred2 = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        );

        expect(pred1, isNot(equals(pred2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        const original = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );

        final json = original.toJson();
        final restored = TaskBoolPredicate.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });

  group('TaskDatePredicate', () {
    group('construction', () {
      test('creates with required fields', () {
        const predicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.onOrBefore,
        );

        expect(predicate.field, TaskDateField.deadlineDate);
        expect(predicate.operator, DateOperator.onOrBefore);
        expect(predicate.date, isNull);
      });

      test('creates with all optional fields', () {
        final predicate = TaskDatePredicate(
          field: TaskDateField.startDate,
          operator: DateOperator.between,
          date: DateTime.utc(2025, 6, 15),
          startDate: DateTime.utc(2025, 6, 1),
          endDate: DateTime.utc(2025, 6, 30),
          relativeComparison: RelativeComparison.onOrAfter,
          relativeDays: 7,
        );

        expect(predicate.date, DateTime.utc(2025, 6, 15));
        expect(predicate.startDate, DateTime.utc(2025, 6, 1));
        expect(predicate.endDate, DateTime.utc(2025, 6, 30));
        expect(predicate.relativeComparison, RelativeComparison.onOrAfter);
        expect(predicate.relativeDays, 7);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'onOrBefore',
          'date': '2025-06-15T00:00:00.000Z',
        };

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.field, TaskDateField.deadlineDate);
        expect(predicate.operator, DateOperator.onOrBefore);
        expect(predicate.date, DateTime.utc(2025, 6, 15));
      });

      test('parses between operator with range', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'startDate',
          'operator': 'between',
          'startDate': '2025-06-01T00:00:00.000Z',
          'endDate': '2025-06-30T00:00:00.000Z',
        };

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.operator, DateOperator.between);
        expect(predicate.startDate, DateTime.utc(2025, 6, 1));
        expect(predicate.endDate, DateTime.utc(2025, 6, 30));
      });

      test('parses relative operator', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'relative',
          'relativeComparison': 'onOrAfter',
          'relativeDays': 7,
        };

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.operator, DateOperator.relative);
        expect(predicate.relativeComparison, RelativeComparison.onOrAfter);
        expect(predicate.relativeDays, 7);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'date'};

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.field, TaskDateField.createdAt);
        expect(predicate.operator, DateOperator.isNotNull);
      });

      test('handles null date string', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'isNull',
          'date': null,
        };

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.date, isNull);
      });

      test('handles invalid date string', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'on',
          'date': 'not-a-date',
        };

        final predicate = TaskDatePredicate.fromJson(json);

        expect(predicate.date, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final predicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.onOrBefore,
          date: DateTime.utc(2025, 6, 15),
        );

        final json = predicate.toJson();

        expect(json['type'], 'date');
        expect(json['field'], 'deadlineDate');
        expect(json['operator'], 'onOrBefore');
        expect(json['date'], '2025-06-15T00:00:00.000Z');
      });

      test('serializes between operator with range', () {
        final predicate = TaskDatePredicate(
          field: TaskDateField.startDate,
          operator: DateOperator.between,
          startDate: DateTime.utc(2025, 6, 1),
          endDate: DateTime.utc(2025, 6, 30),
        );

        final json = predicate.toJson();

        expect(json['startDate'], '2025-06-01T00:00:00.000Z');
        expect(json['endDate'], '2025-06-30T00:00:00.000Z');
      });

      test('serializes relative operator fields', () {
        const predicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.onOrBefore,
          relativeDays: -3,
        );

        final json = predicate.toJson();

        expect(json['relativeComparison'], 'onOrBefore');
        expect(json['relativeDays'], -3);
      });

      test('serializes null fields as null', () {
        const predicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
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
      test('equal when all fields match', () {
        final pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.onOrBefore,
          date: DateTime.utc(2025, 6, 15),
        );
        final pred2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.onOrBefore,
          date: DateTime.utc(2025, 6, 15),
        );

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('equal when dates are at same moment (UTC vs local)', () {
        final utcDate = DateTime.utc(2025, 6, 15);
        final localDate = utcDate.toLocal();

        final pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: utcDate,
        );
        final pred2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: localDate,
        );

        expect(pred1, equals(pred2));
      });

      test('not equal when field differs', () {
        final pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime.utc(2025, 6, 15),
        );
        final pred2 = TaskDatePredicate(
          field: TaskDateField.startDate,
          operator: DateOperator.on,
          date: DateTime.utc(2025, 6, 15),
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when operator differs', () {
        final pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime.utc(2025, 6, 15),
        );
        final pred2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.onOrBefore,
          date: DateTime.utc(2025, 6, 15),
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when date differs', () {
        final pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime.utc(2025, 6, 15),
        );
        final pred2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime.utc(2025, 6, 16),
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('equal when both dates are null', () {
        const pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.isNull,
        );
        const pred2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.isNull,
        );

        expect(pred1, equals(pred2));
      });

      test('not equal when one date is null', () {
        final pred1 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime.utc(2025, 6, 15),
        );
        const pred2 = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
        );

        expect(pred1, isNot(equals(pred2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips simple operator', () {
        final original = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.onOrBefore,
          date: DateTime.utc(2025, 6, 15),
        );

        final json = original.toJson();
        final restored = TaskDatePredicate.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips between operator', () {
        final original = TaskDatePredicate(
          field: TaskDateField.startDate,
          operator: DateOperator.between,
          startDate: DateTime.utc(2025, 6, 1),
          endDate: DateTime.utc(2025, 6, 30),
        );

        final json = original.toJson();
        final restored = TaskDatePredicate.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips relative operator', () {
        const original = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.after,
          relativeDays: 14,
        );

        final json = original.toJson();
        final restored = TaskDatePredicate.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });

  group('TaskProjectPredicate', () {
    group('construction', () {
      test('creates with required operator', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.isNull,
        );

        expect(predicate.operator, ProjectOperator.isNull);
        expect(predicate.projectId, isNull);
        expect(predicate.projectIds, isEmpty);
      });

      test('creates with projectId', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: 'project-1',
        );

        expect(predicate.projectId, 'project-1');
      });

      test('creates with projectIds list', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );

        expect(predicate.projectIds, ['project-1', 'project-2']);
      });
    });

    group('fromJson', () {
      test('parses valid JSON with projectId', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matches',
          'projectId': 'project-1',
        };

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.operator, ProjectOperator.matches);
        expect(predicate.projectId, 'project-1');
      });

      test('parses valid JSON with projectIds', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matchesAny',
          'projectIds': ['project-1', 'project-2'],
        };

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.operator, ProjectOperator.matchesAny);
        expect(predicate.projectIds, ['project-1', 'project-2']);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'project'};

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.operator, ProjectOperator.isNotNull);
        expect(predicate.projectId, isNull);
        expect(predicate.projectIds, isEmpty);
      });

      test('filters non-string items from projectIds', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matchesAny',
          'projectIds': ['project-1', 123, null, 'project-2'],
        };

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.projectIds, ['project-1', 'project-2']);
      });

      test('handles null projectIds', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'isNull',
          'projectIds': null,
        };

        final predicate = TaskProjectPredicate.fromJson(json);

        expect(predicate.projectIds, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'project-1',
          projectIds: ['project-2', 'project-3'],
        );

        final json = predicate.toJson();

        expect(json['type'], 'project');
        expect(json['operator'], 'matchesAny');
        expect(json['projectId'], 'project-1');
        expect(json['projectIds'], ['project-2', 'project-3']);
      });

      test('serializes isNull operator', () {
        const predicate = TaskProjectPredicate(
          operator: ProjectOperator.isNull,
        );

        final json = predicate.toJson();

        expect(json['operator'], 'isNull');
        expect(json['projectId'], isNull);
        expect(json['projectIds'], isEmpty);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const pred1 = TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: 'project-1',
        );
        const pred2 = TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: 'project-1',
        );

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('equal when projectIds match', () {
        const pred1 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['a', 'b'],
        );
        const pred2 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['a', 'b'],
        );

        expect(pred1, equals(pred2));
      });

      test('not equal when operator differs', () {
        const pred1 = TaskProjectPredicate(
          operator: ProjectOperator.isNull,
        );
        const pred2 = TaskProjectPredicate(
          operator: ProjectOperator.isNotNull,
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when projectId differs', () {
        const pred1 = TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: 'project-1',
        );
        const pred2 = TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: 'project-2',
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when projectIds differ', () {
        const pred1 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['a', 'b'],
        );
        const pred2 = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: ['b', 'c'],
        );

        expect(pred1, isNot(equals(pred2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        const original = TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectId: 'main-project',
          projectIds: ['sub-1', 'sub-2'],
        );

        final json = original.toJson();
        final restored = TaskProjectPredicate.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });

  group('TaskValuePredicate', () {
    group('construction', () {
      test('creates with required fields', () {
        const predicate = TaskValuePredicate(
          operator: ValueOperator.hasAny,
        );

        expect(predicate.operator, ValueOperator.hasAny);
        expect(predicate.valueIds, isEmpty);
        expect(predicate.includeInherited, isFalse);
      });

      test('creates with valueIds', () {
        const predicate = TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
          includeInherited: true,
        );

        expect(predicate.valueIds, ['value-1', 'value-2']);
        expect(predicate.includeInherited, isTrue);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'type': 'value',
          'operator': 'hasAny',
          'valueIds': ['value-1', 'value-2'],
          'includeInherited': true,
        };

        final predicate = TaskValuePredicate.fromJson(json);

        expect(predicate.operator, ValueOperator.hasAny);
        expect(predicate.valueIds, ['value-1', 'value-2']);
        expect(predicate.includeInherited, isTrue);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'value'};

        final predicate = TaskValuePredicate.fromJson(json);

        expect(predicate.operator, ValueOperator.hasAny);
        expect(predicate.valueIds, isEmpty);
        expect(predicate.includeInherited, isFalse);
      });

      test('filters non-string items from valueIds', () {
        final json = <String, dynamic>{
          'type': 'value',
          'operator': 'hasAny',
          'valueIds': ['value-1', 42, null, 'value-2'],
        };

        final predicate = TaskValuePredicate.fromJson(json);

        expect(predicate.valueIds, ['value-1', 'value-2']);
      });

      test('handles null valueIds', () {
        final json = <String, dynamic>{
          'type': 'value',
          'operator': 'isNull',
          'valueIds': null,
        };

        final predicate = TaskValuePredicate.fromJson(json);

        expect(predicate.valueIds, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const predicate = TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: ['val-1', 'val-2'],
          includeInherited: true,
        );

        final json = predicate.toJson();

        expect(json['type'], 'value');
        expect(json['operator'], 'hasAll');
        expect(json['valueIds'], ['val-1', 'val-2']);
        expect(json['includeInherited'], true);
      });

      test('serializes empty valueIds', () {
        const predicate = TaskValuePredicate(
          operator: ValueOperator.isNull,
        );

        final json = predicate.toJson();

        expect(json['valueIds'], isEmpty);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const pred1 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
          valueIds: ['a', 'b'],
          includeInherited: true,
        );
        const pred2 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
          valueIds: ['a', 'b'],
          includeInherited: true,
        );

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when operator differs', () {
        const pred1 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
        );
        const pred2 = TaskValuePredicate(
          operator: ValueOperator.hasAll,
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when includeInherited differs', () {
        const pred1 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
          includeInherited: false,
        );
        const pred2 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
          includeInherited: true,
        );

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when valueIds differ', () {
        const pred1 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
          valueIds: ['a', 'b'],
        );
        const pred2 = TaskValuePredicate(
          operator: ValueOperator.hasAny,
          valueIds: ['a', 'c'],
        );

        expect(pred1, isNot(equals(pred2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        const original = TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
          includeInherited: true,
        );

        final json = original.toJson();
        final restored = TaskValuePredicate.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });

  group('Enums', () {
    test('BoolOperator has expected values', () {
      expect(
        BoolOperator.values,
        containsAll([
          BoolOperator.isTrue,
          BoolOperator.isFalse,
        ]),
      );
    });

    test('DateOperator has expected values', () {
      expect(
        DateOperator.values,
        containsAll([
          DateOperator.onOrAfter,
          DateOperator.onOrBefore,
          DateOperator.before,
          DateOperator.after,
          DateOperator.on,
          DateOperator.between,
          DateOperator.isNull,
          DateOperator.isNotNull,
          DateOperator.relative,
        ]),
      );
    });

    test('RelativeComparison has expected values', () {
      expect(
        RelativeComparison.values,
        containsAll([
          RelativeComparison.on,
          RelativeComparison.before,
          RelativeComparison.after,
          RelativeComparison.onOrAfter,
          RelativeComparison.onOrBefore,
        ]),
      );
    });

    test('ProjectOperator has expected values', () {
      expect(
        ProjectOperator.values,
        containsAll([
          ProjectOperator.matches,
          ProjectOperator.matchesAny,
          ProjectOperator.isNull,
          ProjectOperator.isNotNull,
        ]),
      );
    });

    test('TaskDateField has expected values', () {
      expect(
        TaskDateField.values,
        containsAll([
          TaskDateField.startDate,
          TaskDateField.deadlineDate,
          TaskDateField.createdAt,
          TaskDateField.updatedAt,
          TaskDateField.completedAt,
        ]),
      );
    });

    test('TaskBoolField has expected values', () {
      expect(TaskBoolField.values, contains(TaskBoolField.completed));
    });
  });
}
