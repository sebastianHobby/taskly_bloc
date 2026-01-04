import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_type.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('GroupByField', () {
    test('none has correct value', () {
      expect(GroupByField.none.name, 'none');
    });

    test('project has correct value', () {
      expect(GroupByField.project.name, 'project');
    });

    test('value has correct value', () {
      expect(GroupByField.value.name, 'value');
    });

    test('label has correct value', () {
      expect(GroupByField.label.name, 'label');
    });

    test('date has correct value', () {
      expect(GroupByField.date.name, 'date');
    });

    test('priority has correct value', () {
      expect(GroupByField.priority.name, 'priority');
    });

    test('enum has 6 values', () {
      expect(GroupByField.values, hasLength(6));
    });
  });

  group('SortField', () {
    test('name has correct value', () {
      expect(SortField.name.name, 'name');
    });

    test('createdAt has correct value', () {
      expect(SortField.createdAt.name, 'createdAt');
    });

    test('updatedAt has correct value', () {
      expect(SortField.updatedAt.name, 'updatedAt');
    });

    test('deadlineDate has correct value', () {
      expect(SortField.deadlineDate.name, 'deadlineDate');
    });

    test('startDate has correct value', () {
      expect(SortField.startDate.name, 'startDate');
    });

    test('priority has correct value', () {
      expect(SortField.priority.name, 'priority');
    });

    test('enum has 6 values', () {
      expect(SortField.values, hasLength(6));
    });
  });

  group('SortDirection', () {
    test('asc has correct value', () {
      expect(SortDirection.asc.name, 'asc');
    });

    test('desc has correct value', () {
      expect(SortDirection.desc.name, 'desc');
    });

    test('enum has 2 values', () {
      expect(SortDirection.values, hasLength(2));
    });
  });

  group('SortCriterion', () {
    test('creates with required field', () {
      final criterion = SortCriterion(field: SortField.name);

      expect(criterion.field, SortField.name);
    });

    test('direction defaults to asc', () {
      final criterion = SortCriterion(field: SortField.createdAt);

      expect(criterion.direction, SortDirection.asc);
    });

    test('creates with explicit direction', () {
      final criterion = SortCriterion(
        field: SortField.priority,
        direction: SortDirection.desc,
      );

      expect(criterion.direction, SortDirection.desc);
    });

    test('equality works correctly', () {
      final criterion1 = SortCriterion(
        field: SortField.name,
      );
      final criterion2 = SortCriterion(
        field: SortField.name,
      );

      expect(criterion1, equals(criterion2));
    });

    test('copyWith modifies field', () {
      final criterion = SortCriterion(field: SortField.name);
      final modified = criterion.copyWith(field: SortField.deadlineDate);

      expect(modified.field, SortField.deadlineDate);
      expect(modified.direction, SortDirection.asc);
    });

    test('copyWith modifies direction', () {
      final criterion = SortCriterion(field: SortField.name);
      final modified = criterion.copyWith(direction: SortDirection.desc);

      expect(modified.direction, SortDirection.desc);
    });
  });

  group('DisplayConfig', () {
    group('defaults', () {
      test('groupBy defaults to none', () {
        final config = DisplayConfig();

        expect(config.groupBy, GroupByField.none);
      });

      test('sorting defaults to empty list', () {
        final config = DisplayConfig();

        expect(config.sorting, isEmpty);
      });

      test('problemsToDetect defaults to empty list', () {
        final config = DisplayConfig();

        expect(config.problemsToDetect, isEmpty);
      });

      test('showCompleted defaults to true', () {
        final config = DisplayConfig();

        expect(config.showCompleted, true);
      });

      test('showArchived defaults to false', () {
        final config = DisplayConfig();

        expect(config.showArchived, false);
      });
    });

    group('construction', () {
      test('creates with custom groupBy', () {
        final config = DisplayConfig(groupBy: GroupByField.project);

        expect(config.groupBy, GroupByField.project);
      });

      test('creates with sorting list', () {
        final sorting = [
          SortCriterion(
            field: SortField.priority,
            direction: SortDirection.desc,
          ),
          SortCriterion(field: SortField.name),
        ];
        final config = DisplayConfig(sorting: sorting);

        expect(config.sorting, hasLength(2));
        expect(config.sorting[0].field, SortField.priority);
        expect(config.sorting[1].field, SortField.name);
      });

      test('creates with problemsToDetect', () {
        final problems = [
          ProblemType.taskStale,
          ProblemType.taskOrphan,
        ];
        final config = DisplayConfig(problemsToDetect: problems);

        expect(config.problemsToDetect, problems);
      });

      test('creates with showCompleted false', () {
        final config = DisplayConfig(showCompleted: false);

        expect(config.showCompleted, false);
      });

      test('creates with showArchived true', () {
        final config = DisplayConfig(showArchived: true);

        expect(config.showArchived, true);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final config1 = DisplayConfig(
          groupBy: GroupByField.project,
          showCompleted: false,
        );
        final config2 = DisplayConfig(
          groupBy: GroupByField.project,
          showCompleted: false,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('not equal when groupBy differs', () {
        final config1 = DisplayConfig();
        final config2 = DisplayConfig(groupBy: GroupByField.label);

        expect(config1, isNot(equals(config2)));
      });
    });

    group('copyWith', () {
      test('copies with new groupBy', () {
        final config = DisplayConfig();
        final copied = config.copyWith(groupBy: GroupByField.priority);

        expect(copied.groupBy, GroupByField.priority);
      });

      test('copies with new sorting', () {
        final config = DisplayConfig();
        final sorting = [SortCriterion(field: SortField.name)];
        final copied = config.copyWith(sorting: sorting);

        expect(copied.sorting, sorting);
      });

      test('copies with new showCompleted', () {
        final config = DisplayConfig();
        final copied = config.copyWith(showCompleted: false);

        expect(copied.showCompleted, false);
      });

      test('preserves unchanged fields', () {
        final config = DisplayConfig(
          groupBy: GroupByField.project,
          showCompleted: false,
          showArchived: true,
        );
        final copied = config.copyWith(groupBy: GroupByField.label);

        expect(copied.showCompleted, false);
        expect(copied.showArchived, true);
      });
    });
  });
}
