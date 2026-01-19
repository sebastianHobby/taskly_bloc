@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'dart:convert';

import 'package:taskly_data/testing.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('tryDecodeJsonValue', () {
    testSafe('returns unchanged for non-String', () async {
      final result = tryDecodeJsonValue(<String, dynamic>{'a': 1});
      expect(result.changed, isFalse);
      expect(result.doubleEncoded, isFalse);
      expect(result.value, equals(<String, dynamic>{'a': 1}));
    });

    testSafe('decodes JSON map string', () async {
      final result = tryDecodeJsonValue('{"a":1}');
      expect(result.changed, isTrue);
      expect(result.doubleEncoded, isFalse);
      expect(result.value, equals(<String, dynamic>{'a': 1}));
    });

    testSafe('decodes double-encoded JSON map', () async {
      final doubleEncoded = jsonEncode('{"a":1}');
      final result = tryDecodeJsonValue(doubleEncoded);
      expect(result.changed, isTrue);
      expect(result.doubleEncoded, isTrue);
      expect(result.value, equals(<String, dynamic>{'a': 1}));
    });

    testSafe('does not decode when string does not look like JSON', () async {
      final result = tryDecodeJsonValue('hello world');
      expect(result.changed, isFalse);
      expect(result.doubleEncoded, isFalse);
      expect(result.value, equals('hello world'));
    });
  });

  group('normalizeUploadData', () {
    testSafe('decodes expected json columns for known table', () async {
      final normalized = normalizeUploadData(
        table: 'user_profiles',
        rowId: 'row1',
        opType: 'U',
        data: <String, dynamic>{'settings_overrides': '{"x":1}'},
      );

      expect(
        normalized['settings_overrides'],
        equals(<String, dynamic>{'x': 1}),
      );
    });

    testSafe(
      'throws in debug when decoded type mismatches expectation',
      () async {
        // user_profiles.settings_overrides expects a map.
        expect(
          () => normalizeUploadData(
            table: 'user_profiles',
            rowId: 'row1',
            opType: 'U',
            data: <String, dynamic>{'settings_overrides': '[1,2,3]'},
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    testSafe('leaves unknown tables unchanged', () async {
      final input = <String, dynamic>{'a': 1};
      final normalized = normalizeUploadData(
        table: 'unknown_table',
        rowId: 'row1',
        opType: 'U',
        data: input,
      );

      expect(identical(normalized, input), isTrue);
    });
  });
}
