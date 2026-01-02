import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('BreakdownDimension', () {
    test('project has correct value', () {
      expect(BreakdownDimension.project.name, 'project');
    });

    test('label has correct value', () {
      expect(BreakdownDimension.label.name, 'label');
    });

    test('value has correct value', () {
      expect(BreakdownDimension.value.name, 'value');
    });

    test('priority has correct value', () {
      expect(BreakdownDimension.priority.name, 'priority');
    });

    test('status has correct value', () {
      expect(BreakdownDimension.status.name, 'status');
    });

    test('enum has 5 values', () {
      expect(BreakdownDimension.values, hasLength(5));
    });
  });

  group('SupportBlock.taskStats', () {
    test('creates TaskStatsBlock with required statType', () {
      final block = SupportBlock.taskStats(statType: TaskStatType.totalCount);

      expect(block, isA<TaskStatsBlock>());
      expect((block as TaskStatsBlock).statType, TaskStatType.totalCount);
    });

    test('range defaults to null', () {
      final block = SupportBlock.taskStats(
        statType: TaskStatType.completedCount,
      );

      expect((block as TaskStatsBlock).range, isNull);
    });

    test('creates with date range', () {
      final range = DateRange(
        start: DateTime(2025),
        end: DateTime(2025, 1, 31),
      );
      final block = SupportBlock.taskStats(
        statType: TaskStatType.completionRate,
        range: range,
      );

      expect((block as TaskStatsBlock).range, range);
    });

    test('supports all stat types', () {
      for (final statType in TaskStatType.values) {
        final block = SupportBlock.taskStats(statType: statType);
        expect((block as TaskStatsBlock).statType, statType);
      }
    });
  });

  group('SupportBlock.workflowProgress', () {
    test('creates WorkflowProgressBlock', () {
      final block = SupportBlock.workflowProgress();

      expect(block, isA<WorkflowProgressBlock>());
    });

    test('has no additional properties', () {
      final block1 = SupportBlock.workflowProgress();
      final block2 = SupportBlock.workflowProgress();

      // All workflow progress blocks should be equal
      expect(block1, equals(block2));
    });
  });

  group('SupportBlock.breakdown', () {
    test('creates BreakdownBlock with required fields', () {
      final block = SupportBlock.breakdown(
        statType: TaskStatType.completedCount,
        dimension: BreakdownDimension.project,
      );

      expect(block, isA<BreakdownBlock>());
      expect((block as BreakdownBlock).statType, TaskStatType.completedCount);
      expect(block.dimension, BreakdownDimension.project);
    });

    test('range defaults to null', () {
      final block = SupportBlock.breakdown(
        statType: TaskStatType.totalCount,
        dimension: BreakdownDimension.label,
      );

      expect((block as BreakdownBlock).range, isNull);
    });

    test('maxItems defaults to 10', () {
      final block = SupportBlock.breakdown(
        statType: TaskStatType.totalCount,
        dimension: BreakdownDimension.value,
      );

      expect((block as BreakdownBlock).maxItems, 10);
    });

    test('creates with all optional fields', () {
      final range = DateRange.last30Days();
      final block = SupportBlock.breakdown(
        statType: TaskStatType.velocity,
        dimension: BreakdownDimension.priority,
        range: range,
        maxItems: 5,
      );

      expect((block as BreakdownBlock).range, range);
      expect(block.maxItems, 5);
    });

    test('supports all breakdown dimensions', () {
      for (final dim in BreakdownDimension.values) {
        final block = SupportBlock.breakdown(
          statType: TaskStatType.totalCount,
          dimension: dim,
        );
        expect((block as BreakdownBlock).dimension, dim);
      }
    });
  });

  group('SupportBlock.filteredList', () {
    test('creates FilteredListBlock with required fields', () {
      final filterJson = {'completed': true};
      final block = SupportBlock.filteredList(
        title: 'Completed Tasks',
        entityType: 'task',
        filterJson: filterJson,
      );

      expect(block, isA<FilteredListBlock>());
      expect((block as FilteredListBlock).title, 'Completed Tasks');
      expect(block.entityType, 'task');
      expect(block.filterJson, filterJson);
    });

    test('maxItems defaults to 5', () {
      final block = SupportBlock.filteredList(
        title: 'Test',
        entityType: 'task',
        filterJson: {},
      );

      expect((block as FilteredListBlock).maxItems, 5);
    });

    test('creates with custom maxItems', () {
      final block = SupportBlock.filteredList(
        title: 'Test',
        entityType: 'project',
        filterJson: {'active': true},
        maxItems: 10,
      );

      expect((block as FilteredListBlock).maxItems, 10);
    });

    test('handles complex filterJson', () {
      final filterJson = {
        'status': 'active',
        'priority': ['high', 'medium'],
        'labels': {
          'includes': ['urgent', 'important'],
        },
      };
      final block = SupportBlock.filteredList(
        title: 'Filtered',
        entityType: 'task',
        filterJson: filterJson,
      );

      expect((block as FilteredListBlock).filterJson, filterJson);
    });
  });

  group('SupportBlock.moodCorrelation', () {
    test('creates MoodCorrelationBlock with required statType', () {
      final block = SupportBlock.moodCorrelation(
        statType: TaskStatType.completionRate,
      );

      expect(block, isA<MoodCorrelationBlock>());
      expect(
        (block as MoodCorrelationBlock).statType,
        TaskStatType.completionRate,
      );
    });

    test('range defaults to null', () {
      final block = SupportBlock.moodCorrelation(
        statType: TaskStatType.velocity,
      );

      expect((block as MoodCorrelationBlock).range, isNull);
    });

    test('creates with date range', () {
      final range = DateRange(
        start: DateTime(2025),
        end: DateTime(2025, 1, 15),
      );
      final block = SupportBlock.moodCorrelation(
        statType: TaskStatType.avgDaysToComplete,
        range: range,
      );

      expect((block as MoodCorrelationBlock).range, range);
    });
  });

  group('SupportBlock pattern matching', () {
    test('can match on taskStats', () {
      final block = SupportBlock.taskStats(statType: TaskStatType.totalCount);

      final result = switch (block) {
        TaskStatsBlock() => 'taskStats',
        WorkflowProgressBlock() => 'workflowProgress',
        BreakdownBlock() => 'breakdown',
        FilteredListBlock() => 'filteredList',
        MoodCorrelationBlock() => 'moodCorrelation',
      };

      expect(result, 'taskStats');
    });

    test('can match on workflowProgress', () {
      final block = SupportBlock.workflowProgress();

      final result = switch (block) {
        TaskStatsBlock() => 'taskStats',
        WorkflowProgressBlock() => 'workflowProgress',
        BreakdownBlock() => 'breakdown',
        FilteredListBlock() => 'filteredList',
        MoodCorrelationBlock() => 'moodCorrelation',
      };

      expect(result, 'workflowProgress');
    });

    test('can match on breakdown', () {
      final block = SupportBlock.breakdown(
        statType: TaskStatType.completedCount,
        dimension: BreakdownDimension.project,
      );

      final result = switch (block) {
        TaskStatsBlock() => 'taskStats',
        WorkflowProgressBlock() => 'workflowProgress',
        BreakdownBlock() => 'breakdown',
        FilteredListBlock() => 'filteredList',
        MoodCorrelationBlock() => 'moodCorrelation',
      };

      expect(result, 'breakdown');
    });

    test('can match on filteredList', () {
      final block = SupportBlock.filteredList(
        title: 'Test',
        entityType: 'task',
        filterJson: {},
      );

      final result = switch (block) {
        TaskStatsBlock() => 'taskStats',
        WorkflowProgressBlock() => 'workflowProgress',
        BreakdownBlock() => 'breakdown',
        FilteredListBlock() => 'filteredList',
        MoodCorrelationBlock() => 'moodCorrelation',
      };

      expect(result, 'filteredList');
    });

    test('can match on moodCorrelation', () {
      final block = SupportBlock.moodCorrelation(
        statType: TaskStatType.velocity,
      );

      final result = switch (block) {
        TaskStatsBlock() => 'taskStats',
        WorkflowProgressBlock() => 'workflowProgress',
        BreakdownBlock() => 'breakdown',
        FilteredListBlock() => 'filteredList',
        MoodCorrelationBlock() => 'moodCorrelation',
      };

      expect(result, 'moodCorrelation');
    });
  });

  group('SupportBlock equality', () {
    test('TaskStatsBlocks are equal with same properties', () {
      final block1 = SupportBlock.taskStats(statType: TaskStatType.totalCount);
      final block2 = SupportBlock.taskStats(statType: TaskStatType.totalCount);

      expect(block1, equals(block2));
    });

    test('TaskStatsBlocks are not equal with different statType', () {
      final block1 = SupportBlock.taskStats(statType: TaskStatType.totalCount);
      final block2 = SupportBlock.taskStats(
        statType: TaskStatType.completedCount,
      );

      expect(block1, isNot(equals(block2)));
    });

    test('different block types are not equal', () {
      final taskStats = SupportBlock.taskStats(
        statType: TaskStatType.totalCount,
      );
      final workflowProgress = SupportBlock.workflowProgress();

      expect(taskStats, isNot(equals(workflowProgress)));
    });
  });
}
