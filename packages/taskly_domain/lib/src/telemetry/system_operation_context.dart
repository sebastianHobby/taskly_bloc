import 'package:taskly_domain/src/telemetry/operation_context.dart';
import 'package:uuid/uuid.dart';

/// Creates an [OperationContext] for non-user system/background operations.
OperationContext systemOperationContext({
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
    extraFields: <String, Object?>{'actor': 'system', ...extraFields},
  );
}
