@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/telemetry/operation_context.dart';

void main() {
  testSafe(
    'OperationContext.toLogFields omits nulls and merges extras',
    () async {
      const ctx = OperationContext(
        correlationId: 'c1',
        feature: 'feature',
        intent: 'intent',
        operation: 'op',
        entityType: null,
        entityId: null,
        extraFields: <String, Object?>{
          'feature': 'override',
          'x': 1,
        },
      );

      final fields = ctx.toLogFields();

      expect(fields['feature'], 'override');
      expect(fields['intent'], 'intent');
      expect(fields.containsKey('entityType'), isFalse);
      expect(fields['x'], 1);
    },
  );

  testSafe('OperationContext.copyWith overrides specified fields', () async {
    const ctx = OperationContext(
      correlationId: 'c1',
      feature: 'feature',
      intent: 'intent',
      operation: 'op',
    );

    final updated = ctx.copyWith(
      correlationId: 'c2',
      extraFields: const <String, Object?>{'k': 'v'},
    );

    expect(updated.correlationId, 'c2');
    expect(updated.feature, 'feature');
    expect(updated.extraFields, containsPair('k', 'v'));
  });
}
