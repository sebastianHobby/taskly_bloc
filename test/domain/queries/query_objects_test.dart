@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskQuery', () {
    testSafe('factory methods populate expected predicates', () async {
      final inbox = TaskQuery.inbox();
      expect(inbox.filter.shared.whereType<TaskProjectPredicate>(), isNotEmpty);

      final today = TaskQuery.today(now: DateTime(2025, 1, 10));
      expect(today.filter.shared.whereType<TaskDatePredicate>(), isNotEmpty);

      final forProject = TaskQuery.forProject(projectId: 'p1');
      expect(forProject.filter.shared.whereType<TaskProjectPredicate>(), isNotEmpty);

      final schedule = TaskQuery.schedule(
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 1, 7),
      );
      expect(schedule.occurrenceExpansion, isNotNull);
      expect(schedule.filter.orGroups, hasLength(2));
    });

    testSafe('copyWith respects occurrence exclusivity', () async {
      final base = TaskQuery.all();
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 1, 2),
      );
      final preview = OccurrencePreview(
        asOfDayKey: DateTime(2025, 1, 1),
        pastDays: 1,
        futureDays: 1,
      );

      final withExpansion = base.withOccurrenceExpansion(expansion);
      expect(withExpansion.shouldExpandOccurrences, isTrue);
      expect(withExpansion.hasOccurrencePreview, isFalse);

      expect(
        () => base.copyWith(
          occurrenceExpansion: expansion,
          occurrencePreview: preview,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testSafe('serializes and deserializes', () async {
      final query = TaskQuery.incomplete().withSortCriteria(
        const [SortCriterion(field: SortField.name)],
      );

      final json = query.toJson();
      final roundTrip = TaskQuery.fromJson(json);

      expect(roundTrip, query);
      expect(roundTrip.hasProjectFilter, isFalse);
      expect(roundTrip.hasDateFilter, isFalse);
    });
  });

  group('ProjectQuery', () {
    testSafe('factory methods populate expected predicates', () async {
      final byId = ProjectQuery.byId('p1');
      expect(byId.filter.shared.whereType<ProjectIdPredicate>(), isNotEmpty);

      final schedule = ProjectQuery.schedule(
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 1, 2),
      );
      expect(schedule.occurrenceExpansion, isNotNull);
      expect(schedule.filter.orGroups, hasLength(2));
    });

    testSafe('copyWith enforces occurrence exclusivity', () async {
      final base = ProjectQuery.all();
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 1, 2),
      );
      final preview = OccurrencePreview(
        asOfDayKey: DateTime(2025, 1, 1),
        pastDays: 1,
        futureDays: 1,
      );

      final withPreview = base.withOccurrencePreview(preview);
      expect(withPreview.hasOccurrencePreview, isTrue);

      expect(
        () => base.copyWith(
          occurrenceExpansion: expansion,
          occurrencePreview: preview,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testSafe('serializes and deserializes', () async {
      final query = ProjectQuery.completed();
      final json = query.toJson();
      final roundTrip = ProjectQuery.fromJson(json);

      expect(roundTrip, query);
      expect(roundTrip.hasDateFilter, isFalse);
    });
  });

  group('ValueQuery', () {
    testSafe('factory methods populate expected predicates', () async {
      final byId = ValueQuery.byId('v1');
      expect(byId.filter.shared.whereType<ValueIdPredicate>(), isNotEmpty);

      final search = ValueQuery.search('health');
      expect(search.filter.shared.whereType<ValueNamePredicate>(), isNotEmpty);

      final byColor = ValueQuery.byColor('#00ff00');
      expect(byColor.filter.shared.whereType<ValueColorPredicate>(), isNotEmpty);
    });

    testSafe('addPredicate and copyWith preserve filters', () async {
      final base = ValueQuery.all();
      final updated = base.addPredicate(
        const ValueNamePredicate(value: 'Work'),
      );

      expect(updated.filter.shared, hasLength(1));
      expect(updated.hasIdFilter, isFalse);

      final json = updated.toJson();
      final roundTrip = ValueQuery.fromJson(json);
      expect(roundTrip, updated);
    });
  });

  group('Comparison operators', () {
    testSafe('bool comparison evaluates both operators', () async {
      expect(
        BoolComparison.evaluate(
          fieldValue: true,
          operator: BoolOperator.isTrue,
        ),
        isTrue,
      );
      expect(
        BoolComparison.evaluate(
          fieldValue: true,
          operator: BoolOperator.isFalse,
        ),
        isFalse,
      );
    });

    testSafe('value comparison evaluates membership and null checks', () async {
      final values = {'v1', 'v2'};
      expect(
        ValueComparison.evaluate(
          entityValueIds: values,
          predicateValueIds: ['v2'],
          operator: ValueOperator.hasAny,
        ),
        isTrue,
      );
      expect(
        ValueComparison.evaluate(
          entityValueIds: values,
          predicateValueIds: ['v1', 'v2'],
          operator: ValueOperator.hasAll,
        ),
        isTrue,
      );
      expect(
        ValueComparison.evaluate(
          entityValueIds: values,
          predicateValueIds: const [],
          operator: ValueOperator.isNull,
        ),
        isFalse,
      );
      expect(
        ValueComparison.evaluate(
          entityValueIds: const {},
          predicateValueIds: const [],
          operator: ValueOperator.isNull,
        ),
        isTrue,
      );
    });

    testSafe('date comparison uses date-only semantics', () async {
      final fieldValue = DateTime(2025, 1, 15, 18);
      final pivot = DateTime(2025, 1, 15, 3);

      expect(
        DateComparison.evaluate(
          fieldValue: fieldValue,
          operator: DateOperator.on,
          date: pivot,
        ),
        isTrue,
      );
      expect(
        DateComparison.evaluateRelative(
          fieldValue: fieldValue,
          comparison: RelativeComparison.on,
          pivot: pivot,
        ),
        isTrue,
      );
    });
  });
}
