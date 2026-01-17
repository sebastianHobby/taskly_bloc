import 'package:meta/meta.dart';

/// Correlation and structured context for a user or system operation.
///
/// This is created in presentation when dispatching an intent and then passed
/// explicitly into domain/data APIs.
@immutable
final class OperationContext {
  const OperationContext({
    required this.correlationId,
    required this.feature,
    required this.intent,
    required this.operation,
    this.screen,
    this.entityType,
    this.entityId,
    this.severity,
    this.extraFields = const <String, Object?>{},
  });

  /// A unique ID for this operation (recommended: UUID v4).
  final String correlationId;

  /// High-level feature area (e.g. `auth`, `my_day`, `scheduled`).
  final String feature;

  /// Optional screen identifier (e.g. `sign_in`, `settings`).
  final String? screen;

  /// User intent name (e.g. `sign_in_requested`).
  final String intent;

  /// Operation name used for logging/metrics (e.g. `auth.sign_in`).
  final String operation;

  /// Optional entity identity for operations tied to a single entity.
  final String? entityType;
  final String? entityId;

  /// Optional severity hint for logging/reporting.
  final String? severity;

  /// Additional structured fields to attach to logs.
  final Map<String, Object?> extraFields;

  Map<String, Object?> toLogFields() {
    return <String, Object?>{
      'feature': feature,
      'screen': screen,
      'intent': intent,
      'operation': operation,
      'correlationId': correlationId,
      'entityType': entityType,
      'entityId': entityId,
      'severity': severity,
      ...extraFields,
    }..removeWhere((_, v) => v == null);
  }

  OperationContext copyWith({
    String? correlationId,
    String? feature,
    String? screen,
    String? intent,
    String? operation,
    String? entityType,
    String? entityId,
    String? severity,
    Map<String, Object?>? extraFields,
  }) {
    return OperationContext(
      correlationId: correlationId ?? this.correlationId,
      feature: feature ?? this.feature,
      screen: screen ?? this.screen,
      intent: intent ?? this.intent,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      severity: severity ?? this.severity,
      extraFields: extraFields ?? this.extraFields,
    );
  }
}
