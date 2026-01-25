@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskEffectiveValuesX', () {
    testSafe('includes task overrides alongside project primary', () async {
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
      );

      final task = TestData.task(
        project: project,
        values: [primary, secondary],
        overridePrimaryValueId: 'v2',
        overrideSecondaryValueId: null,
      );

      expect(task.isOverridingValues, isTrue);
      expect(task.effectivePrimaryValueId, 'v1');
      expect(task.effectiveSecondaryValueId, 'v2');
      expect(task.effectiveValues, hasLength(2));
      expect(task.isEffectivelyValueless, isFalse);
    });

    testSafe('inherits project values when not overriding', () async {
      final primary = TestData.value(id: 'v1');
      final project = Project(
        id: 'p1',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        name: 'Project',
        completed: false,
        values: [primary],
        primaryValueId: 'v1',
      );
      final task = TestData.task(project: project);

      expect(task.isInheritingValues, isTrue);
      expect(task.effectivePrimaryValueId, 'v1');
      expect(task.effectiveSecondaryValueId, isNull);
      expect(task.effectiveValues.map((v) => v.id), contains('v1'));
    });

    testSafe('reports valueless when no values present', () async {
      final task = TestData.task();
      expect(task.effectiveValues, isEmpty);
      expect(task.isEffectivelyValueless, isTrue);
    });
  });
}
