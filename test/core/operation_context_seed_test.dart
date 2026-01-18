@Tags(['unit'])
library;

import '../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('OperationContext helpers support forwarding assertions', () async {
    final contextFactory = TestOperationContextFactory(
      correlationIdPrefix: 'seed',
    );

    final created = contextFactory.create(
      feature: 'seed',
      intent: 'save',
      operation: 'seed.operation',
      screen: 'seed_screen',
      entityType: 'seed_entity',
      entityId: 'seed-1',
      extraFields: const <String, Object?>{'k': 'v'},
    );

    // In real tests, you typically capture this via a fake/mock repository.
    final spy = OperationContextSpy();
    spy.last = created;

    expectOperationContextForwarded(created: created, forwarded: spy.last);
  });

  testSafe(
    'TestOperationContextFactory creates unique correlation IDs',
    () async {
      final f = TestOperationContextFactory(correlationIdPrefix: 'seed');

      final a = f.create(feature: 'seed', intent: 'a', operation: 'op');
      final b = f.create(feature: 'seed', intent: 'b', operation: 'op');

      expect(a.correlationId, isNot(equals(b.correlationId)));
      expect(a.correlationId, startsWith('seed-'));
      expect(b.correlationId, startsWith('seed-'));
    },
  );
}
