import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Helpers for verifying OperationContext propagation (TG-006).
///
/// Tests that validate user-initiated write paths should:
/// 1) create an [OperationContext] at the presentation boundary, and
/// 2) assert the same context (correlation id) is forwarded into domain/data.
class TestOperationContextFactory {
  TestOperationContextFactory({String correlationIdPrefix = 'test-corr'})
    : _correlationIdPrefix = correlationIdPrefix;

  final String _correlationIdPrefix;
  var _counter = 0;

  OperationContext create({
    required String feature,
    required String intent,
    required String operation,
    String? screen,
    String? entityType,
    String? entityId,
    String? severity,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    final correlationId = '$_correlationIdPrefix-${_counter++}';
    return OperationContext(
      correlationId: correlationId,
      feature: feature,
      screen: screen,
      intent: intent,
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      severity: severity,
      extraFields: extraFields,
    );
  }
}

/// Simple recorder for capturing contexts passed into fakes/mocks.
class OperationContextSpy {
  OperationContext? last;
}

/// Asserts that a context was forwarded end-to-end.
void expectOperationContextForwarded({
  required OperationContext created,
  required OperationContext? forwarded,
}) {
  expect(
    forwarded,
    isNotNull,
    reason: 'Expected OperationContext to be passed',
  );
  expect(
    forwarded!.correlationId,
    created.correlationId,
    reason: 'Expected forwarded correlationId to match created context',
  );
}
