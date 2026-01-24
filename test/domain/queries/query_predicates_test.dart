@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/queries.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('QueryFilter', () {
    testSafe('serializes and deserializes shared + orGroups', () async {
      final filter = QueryFilter<TaskPredicate>(
        shared: const [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
        orGroups: const [
          [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNotNull,
            ),
          ],
          [
            TaskProjectPredicate(operator: ProjectOperator.isNull),
          ],
        ],
      );

      final json = filter.toJson((p) => p.toJson());
      final roundTrip = QueryFilter.fromJson<TaskPredicate>(
        json,
        TaskPredicate.fromJson,
      );

      expect(roundTrip, filter);
      expect(roundTrip.isMatchAll, isFalse);
      expect(roundTrip.toDnfTerms(), hasLength(2));
    });

    testSafe('matchAll reports empty shared and orGroups', () async {
      const filter = QueryFilter<TaskPredicate>.matchAll();
      expect(filter.isMatchAll, isTrue);
      expect(filter.toDnfTerms(), [const <TaskPredicate>[]]);
    });

    testSafe('merge combines shared and orGroups', () async {
      const base = QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      );
      const other = QueryFilter<TaskPredicate>(
        orGroups: [
          [
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: 'p1',
            ),
          ],
        ],
      );

      final merged = base.merge(other);
      expect(merged.shared, base.shared);
      expect(merged.orGroups, other.orGroups);
    });
  });

  group('TaskPredicate', () {
    testSafe('round-trips json for bool/date/project/value', () async {
      const boolPred = TaskBoolPredicate(
        field: TaskBoolField.completed,
        operator: BoolOperator.isTrue,
      );
      final datePred = TaskDatePredicate(
        field: TaskDateField.deadlineDate,
        operator: DateOperator.between,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 10),
      );
      const projectPred = TaskProjectPredicate(
        operator: ProjectOperator.matchesAny,
        projectIds: ['p1', 'p2'],
      );
      const valuePred = TaskValuePredicate(
        operator: ValueOperator.hasAll,
        valueIds: ['v1'],
        includeInherited: true,
      );

      expect(TaskPredicate.fromJson(boolPred.toJson()), boolPred);
      expect(TaskPredicate.fromJson(datePred.toJson()), datePred);
      expect(TaskPredicate.fromJson(projectPred.toJson()), projectPred);
      expect(TaskPredicate.fromJson(valuePred.toJson()), valuePred);
    });

    testSafe('throws on unknown predicate type', () async {
      expect(
        () => TaskPredicate.fromJson(const <String, dynamic>{'type': 'nope'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ProjectPredicate', () {
    testSafe('round-trips json for id/bool/date/value', () async {
      const idPred = ProjectIdPredicate(id: 'p1');
      const boolPred = ProjectBoolPredicate(
        field: ProjectBoolField.completed,
        operator: BoolOperator.isTrue,
      );
      final datePred = ProjectDatePredicate(
        field: ProjectDateField.createdAt,
        operator: DateOperator.on,
        date: DateTime(2025, 1, 1),
      );
      const valuePred = ProjectValuePredicate(
        operator: ValueOperator.hasAny,
        valueIds: ['v1', 'v2'],
      );

      expect(ProjectPredicate.fromJson(idPred.toJson()), idPred);
      expect(ProjectPredicate.fromJson(boolPred.toJson()), boolPred);
      expect(ProjectPredicate.fromJson(datePred.toJson()), datePred);
      expect(ProjectPredicate.fromJson(valuePred.toJson()), valuePred);
    });

    testSafe('throws on unknown predicate type', () async {
      expect(
        () => ProjectPredicate.fromJson(
          const <String, dynamic>{'type': 'nope'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ValuePredicate', () {
    testSafe('round-trips json for name/color/id/ids', () async {
      const namePred = ValueNamePredicate(
        value: 'Work',
        operator: StringOperator.startsWith,
      );
      const colorPred = ValueColorPredicate(colorHex: '#ff00ff');
      const idPred = ValueIdPredicate(valueId: 'v1');
      const idsPred = ValueIdsPredicate(valueIds: ['v1', 'v2']);

      expect(ValuePredicate.fromJson(namePred.toJson()), namePred);
      expect(ValuePredicate.fromJson(colorPred.toJson()), colorPred);
      expect(ValuePredicate.fromJson(idPred.toJson()), idPred);
      expect(ValuePredicate.fromJson(idsPred.toJson()), idsPred);
    });

    testSafe('throws on unknown predicate type', () async {
      expect(
        () => ValuePredicate.fromJson(const <String, dynamic>{'type': 'nope'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
