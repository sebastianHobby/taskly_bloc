import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/infrastructure/powersync/upload_data_normalizer.dart';

void main() {
  group('normalizeUploadData', () {
    test('decodes attention_rules jsonb maps', () {
      final normalized = normalizeUploadData(
        table: 'attention_rules',
        rowId: 'r1',
        opType: 'put',
        data: {
          'trigger_config': '{"threshold_hours":0}',
          'entity_selector': '{"entity_type":"task","predicate":"x"}',
          'display_config': '{"title":"t"}',
          'resolution_actions': '["reviewed","snoozed"]',
        },
      );

      expect(normalized['trigger_config'], isA<Map>());
      expect(normalized['entity_selector'], isA<Map>());
      expect(normalized['display_config'], isA<Map>());
      expect(normalized['resolution_actions'], isA<List>());
    });

    test('decodes user_profiles jsonb maps', () {
      final normalized = normalizeUploadData(
        table: 'user_profiles',
        rowId: 'u1',
        opType: 'patch',
        data: {
          'settings_overrides': '{"a":1}',
        },
      );

      expect(normalized['settings_overrides'], isA<Map>());
    });

    test('decodes pending_notifications payload as any JSON', () {
      final normalized = normalizeUploadData(
        table: 'pending_notifications',
        rowId: 'n1',
        opType: 'put',
        data: {
          'payload': '[{"k":1}]',
        },
      );

      expect(normalized['payload'], isA<List>());
    });

    test('decodes trackers response_config as map', () {
      final normalized = normalizeUploadData(
        table: 'trackers',
        rowId: 't1',
        opType: 'put',
        data: {
          'response_config': '{"type":"scale"}',
        },
      );

      expect(normalized['response_config'], isA<Map>());
    });

    test('decodes tracker_responses response_value as any JSON', () {
      final normalized = normalizeUploadData(
        table: 'tracker_responses',
        rowId: 'tr1',
        opType: 'put',
        data: {
          'response_value': '3',
        },
      );

      expect(normalized['response_value'], 3);
    });

    test('decodes daily_tracker_responses response_value as any JSON', () {
      final normalized = normalizeUploadData(
        table: 'daily_tracker_responses',
        rowId: 'dtr1',
        opType: 'put',
        data: {
          'response_value': 'true',
        },
      );

      expect(normalized['response_value'], true);
    });

    test('decodes analytics_snapshots metrics as map', () {
      final normalized = normalizeUploadData(
        table: 'analytics_snapshots',
        rowId: 'as1',
        opType: 'put',
        data: {
          'metrics': '{"m":1}',
        },
      );

      expect(normalized['metrics'], isA<Map>());
    });

    test('decodes analytics_insights metadata as map', () {
      final normalized = normalizeUploadData(
        table: 'analytics_insights',
        rowId: 'ai1',
        opType: 'put',
        data: {
          'metadata': '{"x":1}',
        },
      );

      expect(normalized['metadata'], isA<Map>());
    });

    test('decodes analytics_correlations jsonb maps', () {
      final normalized = normalizeUploadData(
        table: 'analytics_correlations',
        rowId: 'ac1',
        opType: 'put',
        data: {
          'performance_metrics': '{"p":1}',
          'statistical_significance': '{"alpha":0.05}',
        },
      );

      expect(normalized['performance_metrics'], isA<Map>());
      expect(normalized['statistical_significance'], isA<Map>());
    });

    test(
      'throws in debug when attention_rules.resolution_actions is not a list',
      () {
        expect(
          () => normalizeUploadData(
            table: 'attention_rules',
            rowId: 'r_bad',
            opType: 'put',
            data: {
              // Wrong shape (object instead of array)
              'resolution_actions': '{"actions":["reviewed"]}',
            },
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
