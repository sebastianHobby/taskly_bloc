import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('DateField', () {
    test('deadlineDate has correct JSON value', () {
      expect(DateField.deadlineDate.name, 'deadlineDate');
    });

    test('startDate has correct JSON value', () {
      expect(DateField.startDate.name, 'startDate');
    });

    test('scheduledFor has correct JSON value', () {
      expect(DateField.scheduledFor.name, 'scheduledFor');
    });

    test('enum has 3 values', () {
      expect(DateField.values, hasLength(3));
    });
  });

  group('AgendaGrouping', () {
    test('today has correct value', () {
      expect(AgendaGrouping.today.name, 'today');
    });

    test('overdue has correct value', () {
      expect(AgendaGrouping.overdue.name, 'overdue');
    });

    test('enum has expected values', () {
      expect(AgendaGrouping.values, contains(AgendaGrouping.today));
      expect(AgendaGrouping.values, contains(AgendaGrouping.tomorrow));
      expect(AgendaGrouping.values, contains(AgendaGrouping.thisWeek));
      expect(AgendaGrouping.values, contains(AgendaGrouping.nextWeek));
      expect(AgendaGrouping.values, contains(AgendaGrouping.later));
      expect(AgendaGrouping.values, contains(AgendaGrouping.overdue));
    });
  });

  group('AgendaConfig', () {
    test('creates with required fields', () {
      final config = AgendaConfig(
        dateField: DateField.deadlineDate,
        groupingStrategy: AgendaGrouping.today,
      );

      expect(config.dateField, DateField.deadlineDate);
      expect(config.groupingStrategy, AgendaGrouping.today);
    });

    test('equality works correctly', () {
      final config1 = AgendaConfig(
        dateField: DateField.startDate,
        groupingStrategy: AgendaGrouping.thisWeek,
      );
      final config2 = AgendaConfig(
        dateField: DateField.startDate,
        groupingStrategy: AgendaGrouping.thisWeek,
      );

      expect(config1, equals(config2));
    });

    test('copyWith modifies dateField', () {
      final config = AgendaConfig(
        dateField: DateField.deadlineDate,
        groupingStrategy: AgendaGrouping.today,
      );
      final modified = config.copyWith(dateField: DateField.startDate);

      expect(modified.dateField, DateField.startDate);
      expect(modified.groupingStrategy, AgendaGrouping.today);
    });
  });

  group('DetailParentType', () {
    test('project type exists', () {
      expect(DetailParentType.project.name, 'project');
    });

    test('label type exists', () {
      expect(DetailParentType.label.name, 'label');
    });
  });

  group('ViewDefinition.collection', () {
    test('creates CollectionView', () {
      final selector = EntitySelector(entityType: EntityType.task);
      final display = DisplayConfig();
      final view = ViewDefinition.collection(
        selector: selector,
        display: display,
      );

      expect(view, isA<CollectionView>());
      expect((view as CollectionView).selector, selector);
      expect(view.display, display);
    });

    test('supportBlocks defaults to null', () {
      final view = ViewDefinition.collection(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
      );

      expect((view as CollectionView).supportBlocks, isNull);
    });

    test('supportBlocks can be set', () {
      final blocks = [SupportBlock.workflowProgress()];
      final view = ViewDefinition.collection(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
        supportBlocks: blocks,
      );

      expect((view as CollectionView).supportBlocks, blocks);
    });
  });

  group('ViewDefinition.agenda', () {
    test('creates AgendaView', () {
      final selector = EntitySelector(entityType: EntityType.task);
      final display = DisplayConfig();
      final agendaConfig = AgendaConfig(
        dateField: DateField.deadlineDate,
        groupingStrategy: AgendaGrouping.today,
      );

      final view = ViewDefinition.agenda(
        selector: selector,
        display: display,
        agendaConfig: agendaConfig,
      );

      expect(view, isA<AgendaView>());
      expect((view as AgendaView).agendaConfig, agendaConfig);
    });

    test('requires agendaConfig', () {
      // This test verifies the API shape - agendaConfig is required
      final view = ViewDefinition.agenda(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
        agendaConfig: AgendaConfig(
          dateField: DateField.startDate,
          groupingStrategy: AgendaGrouping.overdue,
        ),
      );

      expect((view as AgendaView).agendaConfig.dateField, DateField.startDate);
    });
  });

  group('ViewDefinition.detail', () {
    test('creates DetailView', () {
      final view = ViewDefinition.detail(parentType: DetailParentType.project);

      expect(view, isA<DetailView>());
      expect((view as DetailView).parentType, DetailParentType.project);
    });

    test('childView defaults to null', () {
      final view = ViewDefinition.detail(parentType: DetailParentType.label);

      expect((view as DetailView).childView, isNull);
    });

    test('childView can be nested ViewDefinition', () {
      final childView = ViewDefinition.collection(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
      );
      final view = ViewDefinition.detail(
        parentType: DetailParentType.project,
        childView: childView,
      );

      expect((view as DetailView).childView, childView);
    });
  });

  group('ViewDefinition.allocated', () {
    test('creates AllocatedView', () {
      final selector = EntitySelector(entityType: EntityType.task);
      final display = DisplayConfig();
      final view = ViewDefinition.allocated(
        selector: selector,
        display: display,
      );

      expect(view, isA<AllocatedView>());
      expect((view as AllocatedView).selector, selector);
    });
  });

  group('ViewDefinition pattern matching', () {
    test('can match on collection', () {
      final view = ViewDefinition.collection(
        selector: EntitySelector(entityType: EntityType.project),
        display: DisplayConfig(),
      );

      final result = switch (view) {
        CollectionView() => 'collection',
        AgendaView() => 'agenda',
        DetailView() => 'detail',
        AllocatedView() => 'allocated',
      };

      expect(result, 'collection');
    });

    test('can match on agenda', () {
      final view = ViewDefinition.agenda(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
        agendaConfig: AgendaConfig(
          dateField: DateField.deadlineDate,
          groupingStrategy: AgendaGrouping.today,
        ),
      );

      final result = switch (view) {
        CollectionView() => 'collection',
        AgendaView() => 'agenda',
        DetailView() => 'detail',
        AllocatedView() => 'allocated',
      };

      expect(result, 'agenda');
    });

    test('can match on detail', () {
      final view = ViewDefinition.detail(parentType: DetailParentType.project);

      final result = switch (view) {
        CollectionView() => 'collection',
        AgendaView() => 'agenda',
        DetailView() => 'detail',
        AllocatedView() => 'allocated',
      };

      expect(result, 'detail');
    });

    test('can match on allocated', () {
      final view = ViewDefinition.allocated(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
      );

      final result = switch (view) {
        CollectionView() => 'collection',
        AgendaView() => 'agenda',
        DetailView() => 'detail',
        AllocatedView() => 'allocated',
      };

      expect(result, 'allocated');
    });
  });

  group('ViewDefinition equality', () {
    test('CollectionViews are equal with same properties', () {
      final selector = EntitySelector(entityType: EntityType.task);
      final display = DisplayConfig();
      final view1 = ViewDefinition.collection(
        selector: selector,
        display: display,
      );
      final view2 = ViewDefinition.collection(
        selector: selector,
        display: display,
      );

      expect(view1, equals(view2));
    });

    test('different view types are not equal', () {
      final selector = EntitySelector(entityType: EntityType.task);
      final display = DisplayConfig();
      final collection = ViewDefinition.collection(
        selector: selector,
        display: display,
      );
      final allocated = ViewDefinition.allocated(
        selector: selector,
        display: display,
      );

      expect(collection, isNot(equals(allocated)));
    });
  });
}
