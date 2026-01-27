@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/occurrence_expansion.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

void main() {
  testSafe('TaskQuery.inbox builds expected shared predicates', () async {
    final q = TaskQuery.inbox();

    expect(q.filter.shared, hasLength(2));
    expect(q.filter.shared[0], isA<TaskBoolPredicate>());
    expect(q.filter.shared[1], isA<TaskProjectPredicate>());

    final boolP = q.filter.shared[0] as TaskBoolPredicate;
    expect(boolP.operator, BoolOperator.isFalse);

    final projectP = q.filter.shared[1] as TaskProjectPredicate;
    expect(projectP.operator, ProjectOperator.isNull);
  });

  testSafe('TaskQuery JSON roundtrip', () async {
    final q = TaskQuery.incomplete();
    final decoded = TaskQuery.fromJson(q.toJson());

    expect(decoded, equals(q));
  });

  testSafe(
    'copyWith(clearOccurrenceExpansion) removes occurrenceExpansion',
    () async {
      final q = TaskQuery(
        occurrenceExpansion: OccurrenceExpansion(
          rangeStart: DateTime.utc(2026, 1, 1),
          rangeEnd: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(q.shouldExpandOccurrences, isTrue);

      final cleared = q.copyWith(clearOccurrenceExpansion: true);
      expect(cleared.shouldExpandOccurrences, isFalse);
    },
  );

  testSafe('withAdditionalPredicates appends to shared predicates', () async {
    final q = TaskQuery.incomplete().withAdditionalPredicates(
      const [
        TaskProjectPredicate(operator: ProjectOperator.isNotNull),
      ],
    );

    expect(q.filter.shared.whereType<TaskProjectPredicate>(), hasLength(1));
    expect(q.hasProjectFilter, isTrue);
  });
}
