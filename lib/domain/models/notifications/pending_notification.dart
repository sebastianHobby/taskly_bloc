import 'dart:convert';

/// Domain model for a notification enqueued by the server and synced via
/// PowerSync.
class PendingNotification {
  const PendingNotification({
    required this.id,
    required this.userId,
    required this.screenDefinitionId,
    required this.scheduledFor,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.deliveredAt,
    required this.seenAt,
  });

  final String id;
  final String? userId;
  final String screenDefinitionId;
  final DateTime scheduledFor;
  final String status;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;

  static Map<String, dynamic>? tryDecodePayload(String? payloadText) {
    if (payloadText == null || payloadText.isEmpty) return null;
    try {
      final decoded = jsonDecode(payloadText);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'value': decoded};
    } catch (_) {
      return <String, dynamic>{'raw': payloadText};
    }
  }
}
