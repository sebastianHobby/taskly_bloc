import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';

void main() {
  group('PendingNotification', () {
    test('creates with all required fields', () {
      final now = DateTime.now();
      final notification = PendingNotification(
        id: 'notif-1',
        userId: 'user-1',
        screenKey: 'inbox',
        scheduledFor: now,
        status: 'pending',
        payload: {'title': 'Test'},
        createdAt: now,
        deliveredAt: null,
        seenAt: null,
      );

      expect(notification.id, 'notif-1');
      expect(notification.userId, 'user-1');
      expect(notification.screenKey, 'inbox');
      expect(notification.scheduledFor, now);
      expect(notification.status, 'pending');
      expect(notification.payload, {'title': 'Test'});
      expect(notification.createdAt, now);
      expect(notification.deliveredAt, isNull);
      expect(notification.seenAt, isNull);
    });

    test('creates with nullable userId', () {
      final notification = PendingNotification(
        id: 'notif-2',
        userId: null,
        screenKey: 'today',
        scheduledFor: DateTime.now(),
        status: 'sent',
        payload: null,
        createdAt: DateTime.now(),
        deliveredAt: DateTime.now(),
        seenAt: null,
      );

      expect(notification.userId, isNull);
    });

    test('creates with nullable payload', () {
      final notification = PendingNotification(
        id: 'notif-3',
        userId: 'user-1',
        screenKey: 'upcoming',
        scheduledFor: DateTime.now(),
        status: 'delivered',
        payload: null,
        createdAt: DateTime.now(),
        deliveredAt: DateTime.now(),
        seenAt: DateTime.now(),
      );

      expect(notification.payload, isNull);
    });
  });

  group('tryDecodePayload', () {
    test('returns null for null input', () {
      final result = PendingNotification.tryDecodePayload(null);

      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = PendingNotification.tryDecodePayload('');

      expect(result, isNull);
    });

    test('decodes valid JSON object', () {
      final json = jsonEncode({'title': 'Test', 'count': 5});
      final result = PendingNotification.tryDecodePayload(json);

      expect(result, isA<Map<String, dynamic>>());
      expect(result!['title'], 'Test');
      expect(result['count'], 5);
    });

    test('wraps non-map JSON in value key', () {
      final json = jsonEncode('just a string');
      final result = PendingNotification.tryDecodePayload(json);

      expect(result, {'value': 'just a string'});
    });

    test('wraps array in value key', () {
      final json = jsonEncode([1, 2, 3]);
      final result = PendingNotification.tryDecodePayload(json);

      expect(result, {
        'value': [1, 2, 3],
      });
    });

    test('wraps number in value key', () {
      final json = jsonEncode(42);
      final result = PendingNotification.tryDecodePayload(json);

      expect(result, {'value': 42});
    });

    test('returns raw wrapper for invalid JSON', () {
      final result = PendingNotification.tryDecodePayload('not valid json {');

      expect(result, {'raw': 'not valid json {'});
    });

    test('returns raw wrapper for malformed JSON', () {
      final result = PendingNotification.tryDecodePayload('{broken:');

      expect(result, {'raw': '{broken:'});
    });
  });
}
