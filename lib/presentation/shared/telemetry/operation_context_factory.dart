import 'package:taskly_domain/telemetry.dart';
import 'package:uuid/uuid.dart';

/// Creates [OperationContext] instances for presentation-triggered operations.
///
/// The returned context is intended to be threaded through domain/data write
/// APIs to enable structured logging and correlation.
final class OperationContextFactory {
  const OperationContextFactory();

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
    return OperationContext(
      correlationId: const Uuid().v4(),
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
