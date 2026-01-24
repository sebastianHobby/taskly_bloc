@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskEffectiveValuesX', () {
    testSafe('uses task values when overriding', () async {
      final primary = TestData.value(id: 'v1');
      final secondary = TestData.value(id: 'v2');

      final task = TestData.task(
        values: [primary, secondary],
        overridePrimaryValueId: 'v1',
        overrideSecondaryValueId: 'v2',
      );

      expect(task.isOverridingValues, isTrue);
      expect(task.effectivePrimaryValueId, 'v1');
      expect(task.effectiveSecondaryValueId, 'v2');
      expect(task.effectiveValues, hasLength(2));
      expect(task.isEffectivelyValueless, isFalse);
    });

    testSafe('inherits project values when not overriding', () async {
      final primary = TestData.value(id: 'v1');
      final secondary = TestData.value(id: 'v2');
      final project = Project(
        id: 'p1',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        name: 'Project',
        completed: false,
        values: [primary, secondary],
        primaryValueId: 'v1',
        secondaryValueId: 'v2',
      );
      final task = TestData.task(project: project);

      expect(task.isInheritingValues, isTrue);
      expect(task.effectivePrimaryValueId, 'v1');
      expect(task.effectiveSecondaryValueId, 'v2');
      expect(task.effectiveValues.map((v) => v.id), containsAll(['v1', 'v2']));
    });

    testSafe('reports valueless when no values present', () async {
      final task = TestData.task();
      expect(task.effectiveValues, isEmpty);
      expect(task.isEffectivelyValueless, isTrue);
    });
  });
}
