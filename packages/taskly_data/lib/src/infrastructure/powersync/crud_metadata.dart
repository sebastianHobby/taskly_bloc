import 'dart:convert';

import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

/// Encodes PowerSync CRUD metadata for a write operation.
///
/// PowerSync attaches this metadata to the queued CRUD entry, and it becomes
/// visible to the upload connector as `CrudEntry.metadata`.
///
/// Keep this payload small and stable; it is intended for correlation and
/// debugging (not business logic).
String? encodeCrudMetadata(OperationContext? context, {Clock clock = systemClock}) {
  if (context == null) return null;

  final nowUtcIso = clock.nowUtc().toIso8601String();

  final payload = <String, Object?>{
    // Short keys used by the upload anomaly pipeline.
    'cid': context.correlationId,
    'src': context.feature,
    'ts': nowUtcIso,

    // Full context for richer debugging.
    'feature': context.feature,
    'screen': context.screen,
    'intent': context.intent,
    'operation': context.operation,
    'entityType': context.entityType,
    'entityId': context.entityId,
    'severity': context.severity,
    ...context.extraFields,
  }..removeWhere((_, v) => v == null);

  return jsonEncode(payload);
}
