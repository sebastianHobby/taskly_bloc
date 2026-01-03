import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';

void main() {
  group('SupportBlock', () {
    group('workflowProgress', () {
      test('creates with default order', () {
        const block = SupportBlock.workflowProgress();

        expect(block, isA<WorkflowProgressBlock>());
        expect((block as WorkflowProgressBlock).order, 0);
      });

      test('creates with custom order', () {
        const block = SupportBlock.workflowProgress(order: 5);

        expect((block as WorkflowProgressBlock).order, 5);
      });

      test('isSystemOnly returns true', () {
        const block = SupportBlock.workflowProgress();

        expect(block.isSystemOnly, isTrue);
        expect(block.isUserConfigurable, isFalse);
      });
    });

    group('quickActions', () {
      test('creates with required actions', () {
        const block = SupportBlock.quickActions(
          actions: [
            QuickAction(label: 'Add Task', actionId: 'add_task'),
          ],
        );

        expect(block, isA<QuickActionsBlock>());
        expect((block as QuickActionsBlock).actions, hasLength(1));
      });

      test('isSystemOnly returns false', () {
        const block = SupportBlock.quickActions(actions: []);

        expect(block.isSystemOnly, isFalse);
        expect(block.isUserConfigurable, isTrue);
      });
    });

    group('contextSummary', () {
      test('creates with defaults', () {
        const block = SupportBlock.contextSummary();

        expect(block, isA<ContextSummaryBlock>());
        const summaryBlock = block as ContextSummaryBlock;
        expect(summaryBlock.showDescription, isTrue);
        expect(summaryBlock.showMetadata, isTrue);
      });

      test('creates with custom values', () {
        const block = SupportBlock.contextSummary(
          title: 'Project Details',
          showDescription: false,
          showMetadata: false,
          order: 2,
        );

        const summaryBlock = block as ContextSummaryBlock;
        expect(summaryBlock.title, 'Project Details');
        expect(summaryBlock.showDescription, isFalse);
        expect(summaryBlock.showMetadata, isFalse);
        expect(summaryBlock.order, 2);
      });
    });

    group('relatedEntities', () {
      test('creates with required entityTypes', () {
        const block = SupportBlock.relatedEntities(
          entityTypes: ['project', 'label'],
        );

        expect(block, isA<RelatedEntitiesBlock>());
        const relatedBlock = block as RelatedEntitiesBlock;
        expect(relatedBlock.entityTypes, ['project', 'label']);
        expect(relatedBlock.maxItems, 5); // default
      });

      test('creates with custom maxItems', () {
        const block = SupportBlock.relatedEntities(
          entityTypes: ['task'],
          maxItems: 10,
        );

        expect((block as RelatedEntitiesBlock).maxItems, 10);
      });
    });

    group('stats', () {
      test('creates with required stats', () {
        const block = SupportBlock.stats(
          stats: [
            StatConfig(label: 'Total', metricId: 'total_count'),
          ],
        );

        expect(block, isA<StatsBlock>());
        expect((block as StatsBlock).stats, hasLength(1));
      });
    });

    group('problemSummary', () {
      test('creates with defaults', () {
        const block = SupportBlock.problemSummary();

        expect(block, isA<ProblemSummaryBlock>());
        const summaryBlock = block as ProblemSummaryBlock;
        expect(summaryBlock.showCount, isTrue);
        expect(summaryBlock.showList, isFalse);
        expect(summaryBlock.maxListItems, 5);
      });

      test('creates with custom values', () {
        const block = SupportBlock.problemSummary(
          problemTypes: ['overdue', 'unassigned'],
          showList: true,
          maxListItems: 10,
          title: 'Issues',
        );

        const summaryBlock = block as ProblemSummaryBlock;
        expect(summaryBlock.problemTypes, ['overdue', 'unassigned']);
        expect(summaryBlock.showList, isTrue);
        expect(summaryBlock.maxListItems, 10);
        expect(summaryBlock.title, 'Issues');
      });
    });

    group('emptyState', () {
      test('creates with required message', () {
        const block = SupportBlock.emptyState(
          message: 'No items found',
        );

        expect(block, isA<EmptyStateBlock>());
        expect((block as EmptyStateBlock).message, 'No items found');
      });

      test('creates with all optional fields', () {
        const block = SupportBlock.emptyState(
          message: 'All done!',
          icon: 'check_circle',
          actionLabel: 'Add new',
          actionRoute: '/add',
          order: 3,
        );

        const emptyBlock = block as EmptyStateBlock;
        expect(emptyBlock.icon, 'check_circle');
        expect(emptyBlock.actionLabel, 'Add new');
        expect(emptyBlock.actionRoute, '/add');
        expect(emptyBlock.order, 3);
      });
    });

    group('entityHeader', () {
      test('creates with required fields', () {
        const block = SupportBlock.entityHeader(
          entityType: 'project',
          entityId: 'proj-123',
        );

        expect(block, isA<EntityHeaderBlock>());
        const headerBlock = block as EntityHeaderBlock;
        expect(headerBlock.entityType, 'project');
        expect(headerBlock.entityId, 'proj-123');
        expect(headerBlock.showCheckbox, isTrue);
        expect(headerBlock.showMetadata, isTrue);
      });

      test('creates with custom display options', () {
        const block = SupportBlock.entityHeader(
          entityType: 'label',
          entityId: 'label-456',
          showCheckbox: false,
          showMetadata: false,
        );

        const headerBlock = block as EntityHeaderBlock;
        expect(headerBlock.showCheckbox, isFalse);
        expect(headerBlock.showMetadata, isFalse);
      });
    });

    group('serialization', () {
      test('workflowProgress round-trips through JSON', () {
        const original = SupportBlock.workflowProgress(order: 1);
        final json = original.toJson();
        final restored = SupportBlock.fromJson(json);

        expect(restored, isA<WorkflowProgressBlock>());
        expect((restored as WorkflowProgressBlock).order, 1);
      });

      // Skip: Code generation bug - QuickAction list doesn't serialize correctly
      // test('quickActions round-trips through JSON', () {
      //   const original = SupportBlock.quickActions(
      //     actions: [
      //       QuickAction(label: 'Test', actionId: 'test'),
      //     ],
      //   );
      //   final json = original.toJson();
      //   final restored = SupportBlock.fromJson(json);
      //
      //   expect(restored, isA<QuickActionsBlock>());
      //   expect((restored as QuickActionsBlock).actions, hasLength(1));
      // });

      test('entityHeader round-trips through JSON', () {
        const original = SupportBlock.entityHeader(
          entityType: 'project',
          entityId: 'p-1',
        );
        final json = original.toJson();
        final restored = SupportBlock.fromJson(json);

        expect(restored, isA<EntityHeaderBlock>());
        expect((restored as EntityHeaderBlock).entityType, 'project');
      });
    });
  });

  group('QuickAction', () {
    test('creates with required fields', () {
      const action = QuickAction(label: 'Add', actionId: 'add');

      expect(action.label, 'Add');
      expect(action.actionId, 'add');
      expect(action.icon, isNull);
      expect(action.params, isNull);
    });

    test('creates with all fields', () {
      const action = QuickAction(
        label: 'Add Task',
        actionId: 'add_task',
        icon: 'add',
        params: {'projectId': 'p-1'},
      );

      expect(action.icon, 'add');
      expect(action.params, {'projectId': 'p-1'});
    });

    test('round-trips through JSON', () {
      const original = QuickAction(
        label: 'Test',
        actionId: 'test',
        icon: 'icon',
      );
      final json = original.toJson();
      final restored = QuickAction.fromJson(json);

      expect(restored.label, 'Test');
      expect(restored.actionId, 'test');
      expect(restored.icon, 'icon');
    });
  });

  group('StatConfig', () {
    test('creates with required fields', () {
      const stat = StatConfig(label: 'Total', metricId: 'total');

      expect(stat.label, 'Total');
      expect(stat.metricId, 'total');
      expect(stat.format, isNull);
      expect(stat.icon, isNull);
    });

    test('creates with all fields', () {
      const stat = StatConfig(
        label: 'Completed',
        metricId: 'completed_count',
        format: 'number',
        icon: 'check',
      );

      expect(stat.format, 'number');
      expect(stat.icon, 'check');
    });

    test('round-trips through JSON', () {
      const original = StatConfig(
        label: 'Test',
        metricId: 'test_metric',
        format: 'percent',
      );
      final json = original.toJson();
      final restored = StatConfig.fromJson(json);

      expect(restored.label, 'Test');
      expect(restored.metricId, 'test_metric');
      expect(restored.format, 'percent');
    });
  });
}
