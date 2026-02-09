import 'package:go_router/go_router.dart';
import 'package:taskly_core/logging.dart';

/// Centralized route parameter parsing/validation.
///
/// Today this returns validated `String` IDs only.
/// A future migration work item will promote these to typed IDs
/// (`TaskId`/`ProjectId`/`ValueId`) end-to-end.
abstract final class RouteCodec {
  static final RegExp _uuidV4OrV5 = RegExp(
    '^[0-9a-fA-F]{8}-'
    '[0-9a-fA-F]{4}-'
    '[45][0-9a-fA-F]{3}-'
    '[89abAB][0-9a-fA-F]{3}-'
    r'[0-9a-fA-F]{12}$',
  );

  static bool isUuidV4OrV5(String raw) => _uuidV4OrV5.hasMatch(raw.trim());

  /// Returns a `/not-found?...` location when [paramName] is missing/invalid.
  /// Returns null when the param is valid.
  ///
  /// This is intended to be used from `GoRoute.redirect`.
  static String? redirectIfInvalidUuidParam(
    GoRouterState state, {
    required String paramName,
    required String entityType,
    required String operation,
  }) {
    final raw = state.pathParameters[paramName];
    final trimmed = raw?.trim() ?? '';

    if (trimmed.isNotEmpty && isUuidV4OrV5(trimmed)) return null;

    // Structured fields (DEC-044A style). This is a first step toward a richer
    // structured logger; for now we encode fields in a stable key=value schema.
    final fields = <String, Object?>{
      'feature': 'routing',
      'screen': state.matchedLocation,
      'intent': 'deep_link',
      'operation': operation,
      'correlationId': state.pageKey.value,
      'entityType': entityType,
      'entityId': trimmed,
      'param': paramName,
    };

    AppLog.warnStructured(
      'routing',
      'Invalid route parameter: $paramName',
      fields: fields,
    );

    return notFoundLocation(fields: fields);
  }

  static String notFoundLocation({
    String? message,
    Map<String, Object?>? fields,
  }) {
    final qp = <String, String>{};
    if (message != null && message.trim().isNotEmpty) {
      qp['message'] = message;
    }
    if (fields != null && fields.isNotEmpty) {
      qp['details'] = _encodeFields(fields);
    }

    return Uri(path: '/not-found', queryParameters: qp).toString();
  }

  static String _encodeFields(Map<String, Object?> fields) {
    // Keep it URL-safe and reasonably small.
    // Example: key=value;key2=value2
    return fields.entries
        .map((e) => '${e.key}=${e.value?.toString() ?? ''}')
        .join(';');
  }
}
